import 'dart:async';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import 'repository.dart';

/// Supabase-backed implementation of [HopRepository].
///
/// Tables (snake_case columns matching the models' toJson):
/// profiles, rides, ride_requests, conversations, messages,
/// notifications, reports, blocked_users.
/// Accept/reject go through the `accept_ride_request` /
/// `reject_ride_request` RPCs (param `p_request_id`).
/// Nothing here calls Supabase at import time.
class SupabaseRepository implements HopRepository {
  SupabaseRepository();

  final _uuid = const Uuid();
  final _changesController = StreamController<void>.broadcast();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Stream<void> get changes => _changesController.stream;

  void _notify() {
    if (!_changesController.isClosed) _changesController.add(null);
  }

  List<Map<String, dynamic>> _rows(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Map<String, dynamic>? _row(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Profile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      final row = _row(data);
      // No row yet means this signed-in user has not created a profile:
      // return null so the caller routes them to the signup screen.
      // (Never return a blank placeholder profile here — the home screens
      // render the profile's name/photo and crash on an empty name.)
      if (row == null) return null;
      return Profile.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Profile> signInWithOtp({String? phone}) async {
    if (phone == null) {
      throw ArgumentError('Provide a phone number.');
    }
    // Phone SMS OTP via the provider configured in Supabase Auth
    // (Phone provider). The 6-digit code arrives as an SMS.
    await _client.auth.signInWithOtp(phone: phone);
    // OTP not verified yet, so there is no signed-in user/profile.
    // Return a placeholder carrying the contact detail so the UI can
    // move to the verify step; verifyOtp returns the real profile.
    final current = await getCurrentProfile();
    return current ??
        Profile(
          id: '',
          fullName: '',
          dob: DateTime(2000, 1, 1),
          gender: '',
          phone: phone,
          email: null,
        );
  }

  @override
  Future<Profile> verifyOtp({
    required String code,
    String? phone,
  }) async {
    if (phone == null) {
      throw ArgumentError('Provide a phone number.');
    }
    await _client.auth.verifyOTP(
      type: OtpType.sms,
      token: code,
      phone: phone,
    );
    final profile = await getCurrentProfile();
    final user = _client.auth.currentUser;
    return profile ??
        Profile(
          id: user?.id ?? '',
          fullName: '',
          dob: DateTime(2000, 1, 1),
          gender: '',
          phone: phone,
          email: user?.email,
        );
  }

  @override
  Future<Profile> createProfile(Profile profile) async {
    // The profile row's id must be the signed-in user's auth uid: it is
    // the primary key and references auth.users(id). The signup screen
    // passes a throwaway 'user-<timestamp>' id, which is not a uuid and
    // would fail the insert — always prefer the real uid when signed in.
    final uid = _client.auth.currentUser?.id;
    final toSave = uid != null
        ? profile.copyWith(id: uid)
        : (profile.id.isEmpty
            ? profile.copyWith(id: _uuid.v4())
            : profile);
    final data = await _client
        .from('profiles')
        .upsert(toSave.toJson())
        .select()
        .single();
    final row = _row(data);
    _notify();
    return row == null ? toSave : Profile.fromJson(row);
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    final data = await _client
        .from('profiles')
        .upsert(profile.toJson())
        .select()
        .single();
    final row = _row(data);
    _notify();
    return row == null ? profile : Profile.fromJson(row);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _notify();
  }

  /// Uploads an avatar image to the `avatars` bucket and returns its
  /// public URL.
  @override
  Future<String> uploadAvatar(String userId, XFile file) async {
    final path = '$userId/avatar.jpg';
    await _client.storage.from('avatars').upload(
      path,
      File(file.path),
      fileOptions: const FileOptions(upsert: true),
    );
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  @override
  Future<List<Ride>> getRides() async {
    final data = await _client
        .from('rides')
        .select()
        .order('travel_date', ascending: true);
    return _rows(data).map(Ride.fromJson).toList();
  }

  @override
  Future<Ride> createRide(Ride ride) async {
    final toSave = ride.id.isEmpty
        ? ride.copyWith(id: _uuid.v4(), createdAt: DateTime.now())
        : ride;
    final data = await _client
        .from('rides')
        .insert(toSave.toJson())
        .select()
        .single();
    final row = _row(data);
    _notify();
    return row == null ? toSave : Ride.fromJson(row);
  }

  @override
  Future<Ride> updateRide(Ride ride) async {
    final data = await _client
        .from('rides')
        .update(ride.toJson())
        .eq('id', ride.id)
        .select()
        .single();
    final row = _row(data);
    _notify();
    return row == null ? ride : Ride.fromJson(row);
  }

  @override
  Future<void> cancelRide(String rideId) async {
    await _client
        .from('rides')
        .update({'status': 'cancelled'})
        .eq('id', rideId);
    final rideData = await _client
        .from('rides')
        .select()
        .eq('id', rideId)
        .maybeSingle();
    final ride = _row(rideData) == null ? null : Ride.fromJson(_row(rideData)!);
    final accepted = await _client
        .from('ride_requests')
        .select()
        .eq('ride_id', rideId)
        .eq('status', 'accepted');
    for (final row in _rows(accepted)) {
      final req = RideRequest.fromJson(row);
      await _client.from('notifications').insert(
        AppNotification(
          id: _uuid.v4(),
          userId: req.memberId,
          type: 'cancellation',
          title: 'Ride cancelled',
          body: ride == null
              ? 'A ride you joined was cancelled by the host.'
              : 'The ride ${ride.fromLocation} → ${ride.toLocation} '
                    'was cancelled by the host.',
          rideId: rideId,
          createdAt: DateTime.now(),
        ).toJson(),
      );
    }
    _notify();
  }

  @override
  Future<List<RideRequest>> getRequestsForRide(String rideId) async {
    final data = await _client
        .from('ride_requests')
        .select()
        .eq('ride_id', rideId)
        .order('created_at', ascending: true);
    return _rows(data).map(RideRequest.fromJson).toList();
  }

  @override
  Future<List<RideRequest>> getMyRequests(String memberId) async {
    final data = await _client
        .from('ride_requests')
        .select()
        .eq('member_id', memberId)
        .order('created_at', ascending: false);
    return _rows(data).map(RideRequest.fromJson).toList();
  }

  @override
  Future<RideRequest> createRequest({
    required String rideId,
    required String memberId,
    String? message,
  }) async {
    final existing = await _client
        .from('ride_requests')
        .select()
        .eq('ride_id', rideId)
        .eq('member_id', memberId)
        .inFilter('status', ['pending', 'accepted']);
    if (_rows(existing).isNotEmpty) throw StateError('duplicate');
    final rideData = await _client
        .from('rides')
        .select()
        .eq('id', rideId)
        .maybeSingle();
    final rideRow = _row(rideData);
    if (rideRow == null) throw StateError('not_found');
    final ride = Ride.fromJson(rideRow);
    if (ride.seatsLeft <= 0) throw StateError('full');
    final request = RideRequest(
      id: _uuid.v4(),
      rideId: rideId,
      memberId: memberId,
      message: message,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    final data = await _client
        .from('ride_requests')
        .insert(request.toJson())
        .select()
        .single();
    final row = _row(data);
    await _client.from('notifications').insert(
      AppNotification(
        id: _uuid.v4(),
        userId: ride.hostId,
        type: 'request',
        title: 'New ride request',
        body: 'Someone wants to join your ride '
            '${ride.fromLocation} → ${ride.toLocation}.',
        rideId: rideId,
        createdAt: DateTime.now(),
      ).toJson(),
    );
    _notify();
    return row == null ? request : RideRequest.fromJson(row);
  }

  Future<RideRequest> _fetchRequest(String requestId) async {
    final data = await _client
        .from('ride_requests')
        .select()
        .eq('id', requestId)
        .single();
    final row = _row(data);
    if (row == null) throw StateError('not_found');
    return RideRequest.fromJson(row);
  }

  @override
  Future<RideRequest> acceptRequest(String requestId) async {
    // Atomicity lives in the RPC: it re-checks the request is pending
    // and seats are available, then decrements seats, notifies the
    // member and ensures the conversation exists.
    await _client.rpc(
      'accept_ride_request',
      params: {'p_request_id': requestId},
    );
    _notify();
    return _fetchRequest(requestId);
  }

  @override
  Future<RideRequest> rejectRequest(String requestId) async {
    await _client.rpc(
      'reject_ride_request',
      params: {'p_request_id': requestId},
    );
    _notify();
    return _fetchRequest(requestId);
  }

  @override
  Future<RideRequest> withdrawRequest(String requestId) async {
    final data = await _client
        .from('ride_requests')
        .update({'status': 'withdrawn'})
        .eq('id', requestId)
        .select()
        .single();
    final row = _row(data);
    _notify();
    if (row == null) throw StateError('not_found');
    return RideRequest.fromJson(row);
  }

  @override
  Future<List<Conversation>> getConversations(String userId) async {
    final data = await _client
        .from('conversations')
        .select()
        .or('member_id.eq.$userId,host_id.eq.$userId')
        .order('created_at', ascending: false);
    return _rows(data).map(Conversation.fromJson).toList();
  }

  @override
  Future<Conversation> getOrCreateConversation({
    required String rideId,
    required String memberId,
    required String hostId,
  }) async {
    final existing = await _client
        .from('conversations')
        .select()
        .eq('ride_id', rideId)
        .eq('member_id', memberId)
        .maybeSingle();
    final existingRow = _row(existing);
    if (existingRow != null) return Conversation.fromJson(existingRow);
    final conv = Conversation(
      id: _uuid.v4(),
      rideId: rideId,
      memberId: memberId,
      hostId: hostId,
      createdAt: DateTime.now(),
    );
    final data = await _client
        .from('conversations')
        .insert(conv.toJson())
        .select()
        .single();
    final row = _row(data);
    _notify();
    return row == null ? conv : Conversation.fromJson(row);
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final data = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return _rows(data).map(ChatMessage.fromJson).toList();
  }

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
  }) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      body: body,
      createdAt: DateTime.now(),
    );
    final data = await _client
        .from('messages')
        .insert(message.toJson())
        .select()
        .single();
    final row = _row(data);
    _notify();
    return row == null ? message : ChatMessage.fromJson(row);
  }

  @override
  Future<void> markMessagesRead({
    required String conversationId,
    required String readerId,
  }) async {
    await _client
        .from('messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .neq('sender_id', readerId)
        .isFilter('read_at', null);
    _notify();
  }

  Stream<List<T>> _watchTable<T>({
    required String channelName,
    required String table,
    PostgresChangeFilter? filter,
    required Future<List<T>> Function() fetch,
  }) {
    late final StreamController<List<T>> controller;
    RealtimeChannel? channel;
    controller = StreamController<List<T>>.broadcast(
      onListen: () async {
        controller.add(await fetch());
        channel = _client.channel(channelName);
        channel!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              filter: filter,
              callback: (_) async {
                if (!controller.isClosed) controller.add(await fetch());
              },
            )
            .subscribe();
      },
      onCancel: () async {
        if (channel != null) await _client.removeChannel(channel!);
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _watchTable<ChatMessage>(
      channelName: 'messages-$conversationId',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      fetch: () => getMessages(conversationId),
    );
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _watchTable<AppNotification>(
      channelName: 'notifications-$userId',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      fetch: () => getNotifications(userId),
    );
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return _rows(data).map(AppNotification.fromJson).toList();
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'read': true}).eq('id', id);
    _notify();
  }

  @override
  Future<void> markAllNotificationsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
    _notify();
  }

  @override
  Future<Report> createReport(Report report) async {
    final toSave = report.id.isEmpty
        ? Report(
            id: _uuid.v4(),
            reporterId: report.reporterId,
            reportedUserId: report.reportedUserId,
            rideId: report.rideId,
            reason: report.reason,
            details: report.details,
            status: report.status,
            createdAt: DateTime.now(),
          )
        : report;
    final data = await _client
        .from('reports')
        .insert(toSave.toJson())
        .select()
        .single();
    final row = _row(data);
    _notify();
    return row == null ? toSave : Report.fromJson(row);
  }

  @override
  Future<List<Report>> getReports() async {
    final data = await _client
        .from('reports')
        .select()
        .order('created_at', ascending: false);
    return _rows(data).map(Report.fromJson).toList();
  }

  @override
  Future<void> resolveReport(String id, String status) async {
    await _client.from('reports').update({'status': status}).eq('id', id);
    _notify();
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await _client.from('blocked_users').upsert({
      'blocker_id': blockerId,
      'blocked_id': blockedId,
      'created_at': DateTime.now().toIso8601String(),
    });
    _notify();
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await _client
        .from('blocked_users')
        .delete()
        .eq('blocker_id', blockerId)
        .eq('blocked_id', blockedId);
    _notify();
  }

  @override
  Future<List<Profile>> getBlockedProfiles(String blockerId) async {
    final data = await _client
        .from('blocked_users')
        .select()
        .eq('blocker_id', blockerId);
    final ids = _rows(data)
        .map((row) => row['blocked_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    return getProfilesByIds(ids);
  }

  @override
  Future<List<Profile>> getProfilesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final data = await _client
        .from('profiles')
        .select()
        .inFilter('id', ids);
    return _rows(data).map(Profile.fromJson).toList();
  }

  @override
  Future<List<String>> getLocationHistory(String userId) async {
    final seen = <String>{};
    final result = <String>[];
    void add(String? loc) {
      if (loc != null && loc.isNotEmpty && seen.add(loc)) result.add(loc);
    }

    final hosted = await _client
        .from('rides')
        .select('from_location,to_location')
        .eq('host_id', userId);
    for (final row in _rows(hosted)) {
      add(row['from_location']?.toString());
      add(row['to_location']?.toString());
    }
    final myRequests = await _client
        .from('ride_requests')
        .select('ride_id')
        .eq('member_id', userId);
    final rideIds = _rows(myRequests)
        .map((row) => row['ride_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (rideIds.isNotEmpty) {
      final requested = await _client
          .from('rides')
          .select('from_location,to_location')
          .inFilter('id', rideIds);
      for (final row in _rows(requested)) {
        add(row['from_location']?.toString());
        add(row['to_location']?.toString());
      }
    }
    return result;
  }

  @override
  Future<void> deleteAccount(String userId) async {
    // Client-side deletion can only remove the profile row; removing the
    // auth user itself needs a server-side (service-role) call.
    await _client.from('profiles').delete().eq('id', userId);
    await _client.auth.signOut();
    _notify();
  }

  @override
  Future<List<Ride>> getRidesByHost(String hostId) async {
    final data = await _client
        .from('rides')
        .select()
        .eq('host_id', hostId)
        .order('travel_date', ascending: true);
    return _rows(data).map(Ride.fromJson).toList();
  }
}
