import 'dart:async';

import 'package:uuid/uuid.dart';

import '../models.dart';
import 'repository.dart';
import 'sample_data.dart';

class DemoRepository implements HopRepository {
  DemoRepository() {
    _seed();
  }

  final _uuid = const Uuid();
  final _changesController = StreamController<void>.broadcast();

  late List<Profile> _profiles;
  late List<Ride> _rides;
  late List<RideRequest> _requests;
  late List<Conversation> _conversations;
  late List<ChatMessage> _messages;
  late List<AppNotification> _notifications;
  late List<Report> _reports;
  late List<BlockedUser> _blocked;
  Profile? _currentUser;

  @override
  Stream<void> get changes => _changesController.stream;

  void _seed() {
    _profiles = [...sampleHosts, ...sampleMembers, demoUser];
    _rides = buildSampleRides();
    _requests = buildSampleRequests(_rides);
    _conversations = buildSampleConversations(_rides);
    _messages = buildSampleMessages(_conversations);
    _notifications = buildSampleNotifications(demoUser.id);
    _reports = [];
    _blocked = [];
    _currentUser = demoUser;
  }

  void _notify() {
    if (!_changesController.isClosed) _changesController.add(null);
  }

  void _replaceRide(Ride ride) {
    final i = _rides.indexWhere((r) => r.id == ride.id);
    if (i >= 0) _rides[i] = ride;
  }

  void _replaceRequest(RideRequest req) {
    final i = _requests.indexWhere((r) => r.id == req.id);
    if (i >= 0) _requests[i] = req;
  }

  void _addNotification(AppNotification n) {
    _notifications.insert(0, n);
  }

  Ride? _findRide(String id) {
    for (final r in _rides) {
      if (r.id == id) return r;
    }
    return null;
  }

  RideRequest? _findRequest(String id) {
    for (final r in _requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  Stream<List<T>> _watch<T>(List<T> Function() snapshot) {
    StreamSubscription<void>? sub;
    late final StreamController<List<T>> controller;
    controller = StreamController<List<T>>.broadcast(
      onListen: () {
        controller.add(snapshot());
        sub = _changesController.stream.listen((_) {
          if (!controller.isClosed) controller.add(snapshot());
        });
      },
      onCancel: () async {
        await sub?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<Profile?> getCurrentProfile() async => _currentUser;

  @override
  Future<Profile> signInWithOtp({String? phone}) async {
    _currentUser = demoUser;
    _notify();
    return demoUser;
  }

  @override
  Future<Profile> verifyOtp({
    required String code,
    String? phone,
  }) async {
    if (code.length != 6 || int.tryParse(code) == null) {
      throw const FormatException('Enter the 6-digit code.');
    }
    _currentUser = demoUser;
    _notify();
    return demoUser;
  }

  @override
  Future<Profile> createProfile(Profile profile) async {
    final existing = _profiles.indexWhere((p) => p.id == profile.id);
    if (existing >= 0) {
      _profiles[existing] = profile;
    } else {
      _profiles.add(profile);
    }
    _currentUser = profile;
    _notify();
    return profile;
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    final existing = _profiles.indexWhere((p) => p.id == profile.id);
    if (existing >= 0) {
      _profiles[existing] = profile;
    } else {
      _profiles.add(profile);
    }
    if (_currentUser?.id == profile.id) _currentUser = profile;
    _notify();
    return profile;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _notify();
  }

  @override
  Future<List<Ride>> getRides() async {
    final rides = List<Ride>.of(_rides);
    rides.sort((a, b) => a.travelDate.compareTo(b.travelDate));
    return rides;
  }

  @override
  Future<Ride> createRide(Ride ride) async {
    final created = ride.id.isEmpty
        ? ride.copyWith(id: _uuid.v4(), createdAt: DateTime.now())
        : ride;
    _rides.add(created);
    _notify();
    return created;
  }

  @override
  Future<Ride> updateRide(Ride ride) async {
    _replaceRide(ride);
    _notify();
    return ride;
  }

  @override
  Future<void> cancelRide(String rideId) async {
    final ride = _findRide(rideId);
    if (ride == null) return;
    _replaceRide(ride.copyWith(status: 'cancelled'));
    for (final req in _requests.where(
      (r) => r.rideId == rideId && r.status == 'accepted',
    )) {
      // Mirror the SQL cancel_ride RPC: accepted requests become
      // 'cancelled', so they land in the member's Cancelled tab.
      _replaceRequest(req.copyWith(status: 'cancelled'));
      _addNotification(
        AppNotification(
          id: _uuid.v4(),
          userId: req.memberId,
          type: 'cancellation',
          title: 'Ride cancelled',
          body:
              'The ride ${ride.fromLocation} → ${ride.toLocation} was cancelled by the host.',
          rideId: rideId,
          createdAt: DateTime.now(),
        ),
      );
    }
    _notify();
  }

  @override
  Future<List<RideRequest>> getRequestsForRide(String rideId) async {
    return _requests.where((r) => r.rideId == rideId).toList();
  }

  @override
  Future<List<RideRequest>> getMyRequests(String memberId) async {
    return _requests.where((r) => r.memberId == memberId).toList();
  }

  @override
  Future<RideRequest> createRequest({
    required String rideId,
    required String memberId,
    String? message,
  }) async {
    final duplicate = _requests.any(
      (r) =>
          r.rideId == rideId &&
          r.memberId == memberId &&
          (r.status == 'pending' || r.status == 'accepted'),
    );
    if (duplicate) throw StateError('duplicate');
    final ride = _findRide(rideId);
    if (ride == null) throw StateError('not_found');
    if (ride.seatsLeft <= 0) throw StateError('full');
    final request = RideRequest(
      id: _uuid.v4(),
      rideId: rideId,
      memberId: memberId,
      message: message,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    _requests.add(request);
    _addNotification(
      AppNotification(
        id: _uuid.v4(),
        userId: ride.hostId,
        type: 'request',
        title: 'New ride request',
        body: 'Someone wants to join your ride '
            '${ride.fromLocation} → ${ride.toLocation}.',
        rideId: rideId,
        createdAt: DateTime.now(),
      ),
    );
    _notify();
    return request;
  }

  @override
  Future<RideRequest> acceptRequest(String requestId) async {
    // Single synchronized step: no await before the check + mutation,
    // so a second accept cannot interleave.
    final request = _findRequest(requestId);
    if (request == null) throw StateError('not_found');
    if (request.status != 'pending') throw StateError('not_pending');
    final ride = _findRide(request.rideId);
    if (ride == null) throw StateError('not_found');
    if (ride.seatsLeft <= 0) throw StateError('full');
    final accepted = request.copyWith(status: 'accepted');
    _replaceRequest(accepted);
    _replaceRide(ride.copyWith(seatsLeft: ride.seatsLeft - 1));
    _addNotification(
      AppNotification(
        id: _uuid.v4(),
        userId: request.memberId,
        type: 'accepted',
        title: 'Request accepted',
        body: 'Your request for ${ride.fromLocation} → '
            '${ride.toLocation} was accepted!',
        rideId: ride.id,
        createdAt: DateTime.now(),
      ),
    );
    // Ensure a conversation exists for host <-> member.
    await getOrCreateConversation(
      rideId: ride.id,
      memberId: request.memberId,
      hostId: ride.hostId,
    );
    _notify();
    return accepted;
  }

  @override
  Future<RideRequest> rejectRequest(String requestId) async {
    final request = _findRequest(requestId);
    if (request == null) throw StateError('not_found');
    if (request.status != 'pending') throw StateError('not_pending');
    final rejected = request.copyWith(status: 'rejected');
    _replaceRequest(rejected);
    final ride = _findRide(request.rideId);
    if (ride != null) {
      _addNotification(
        AppNotification(
          id: _uuid.v4(),
          userId: request.memberId,
          type: 'rejected',
          title: 'Request declined',
          body: 'Your request for ${ride.fromLocation} → '
              '${ride.toLocation} was declined.',
          rideId: ride.id,
          createdAt: DateTime.now(),
        ),
      );
    }
    _notify();
    return rejected;
  }

  @override
  Future<RideRequest> withdrawRequest(String requestId) async {
    final request = _findRequest(requestId);
    if (request == null) throw StateError('not_found');
    final withdrawn = request.copyWith(status: 'withdrawn');
    _replaceRequest(withdrawn);
    _notify();
    return withdrawn;
  }

  @override
  Future<List<Conversation>> getConversations(String userId) async {
    return _conversations
        .where((c) => c.memberId == userId || c.hostId == userId)
        .toList();
  }

  @override
  Future<Conversation> getOrCreateConversation({
    required String rideId,
    required String memberId,
    required String hostId,
  }) async {
    for (final c in _conversations) {
      if (c.rideId == rideId && c.memberId == memberId) return c;
    }
    final conv = Conversation(
      id: _uuid.v4(),
      rideId: rideId,
      memberId: memberId,
      hostId: hostId,
      createdAt: DateTime.now(),
    );
    _conversations.add(conv);
    _notify();
    return conv;
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final msgs = _messages
        .where((m) => m.conversationId == conversationId)
        .toList();
    msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return msgs;
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
    _messages.add(message);
    final conv = _conversations
        .where((c) => c.id == conversationId)
        .firstOrNull;
    if (conv != null) {
      final otherId = conv.memberId == senderId ? conv.hostId : conv.memberId;
      _addNotification(
        AppNotification(
          id: _uuid.v4(),
          userId: otherId,
          type: 'message',
          title: 'New message',
          body: body,
          rideId: conv.rideId,
          conversationId: conversationId,
          createdAt: DateTime.now(),
        ),
      );
    }
    _notify();
    return message;
  }

  @override
  Future<void> markMessagesRead({
    required String conversationId,
    required String readerId,
  }) async {
    final now = DateTime.now();
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      if (m.conversationId == conversationId &&
          m.senderId != readerId &&
          m.readAt == null) {
        _messages[i] = m.copyWith(readAt: now);
      }
    }
    _notify();
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _watch(() => _messages
        .where((m) => m.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _watch(
      () => _notifications.where((n) => n.userId == userId).toList(),
    );
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    final notifs = _notifications.where((n) => n.userId == userId).toList();
    notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifs;
  }

  @override
  Future<void> markNotificationRead(String id) async {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].id == id) {
        _notifications[i] = _notifications[i].copyWith(read: true);
      }
    }
    _notify();
  }

  @override
  Future<void> markAllNotificationsRead(String userId) async {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userId) {
        _notifications[i] = _notifications[i].copyWith(read: true);
      }
    }
    _notify();
  }

  @override
  Future<Report> createReport(Report report) async {
    final created = report.id.isEmpty
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
    _reports.add(created);
    _notify();
    return created;
  }

  @override
  Future<List<Report>> getReports() async => List<Report>.of(_reports);

  @override
  Future<void> resolveReport(String id, String status) async {
    for (var i = 0; i < _reports.length; i++) {
      if (_reports[i].id == id) {
        _reports[i] = _reports[i].copyWith(status: status);
      }
    }
    _notify();
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    final exists = _blocked.any(
      (b) => b.blockerId == blockerId && b.blockedId == blockedId,
    );
    if (!exists) {
      _blocked.add(
        BlockedUser(
          blockerId: blockerId,
          blockedId: blockedId,
          createdAt: DateTime.now(),
        ),
      );
    }
    _notify();
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _blocked.removeWhere(
      (b) => b.blockerId == blockerId && b.blockedId == blockedId,
    );
    _notify();
  }

  @override
  Future<List<Profile>> getBlockedProfiles(String blockerId) async {
    final ids = _blocked
        .where((b) => b.blockerId == blockerId)
        .map((b) => b.blockedId)
        .toList();
    return getProfilesByIds(ids);
  }

  @override
  Future<List<Profile>> getProfilesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    return _profiles.where((p) => ids.contains(p.id)).toList();
  }

  @override
  Future<List<String>> getLocationHistory(String userId) async {
    final seen = <String>{};
    final result = <String>[];
    void add(String loc) {
      if (loc.isNotEmpty && seen.add(loc)) result.add(loc);
    }

    for (final ride in _rides) {
      add(ride.fromLocation);
      add(ride.toLocation);
    }
    // Sample locations a demo user has used before.
    for (final loc in [
      'Kakkanad',
      'Infopark',
      'Ernakulam',
      'Vyttila',
      'Marine Drive',
    ]) {
      add(loc);
    }
    return result;
  }

  @override
  Future<void> deleteAccount(String userId) async {
    // Demo semantics: wipe local data and reseed fresh.
    _seed();
    _notify();
  }

  @override
  Future<List<Ride>> getRidesByHost(String hostId) async {
    final rides = _rides.where((r) => r.hostId == hostId).toList();
    rides.sort((a, b) => a.travelDate.compareTo(b.travelDate));
    return rides;
  }
}
