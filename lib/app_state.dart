import 'package:flutter/foundation.dart';

import 'config.dart';
import 'data/demo_repository.dart';
import 'data/repository.dart';
import 'data/supabase_repository.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  AppState({required this.repo});

  /// Picks the Supabase repository only when credentials are configured;
  /// in demo mode the Supabase client is never constructed.
  factory AppState.create() {
    return AppState(
      repo: AppConfig.isDemoMode ? DemoRepository() : SupabaseRepository(),
    );
  }

  final HopRepository repo;

  Profile? currentUser;
  String mode = 'member';
  List<Ride> rides = [];
  List<RideRequest> myRequests = [];
  List<RideRequest> requestsForMyRides = [];
  List<Conversation> conversations = [];
  Map<String, List<ChatMessage>> messagesByConversation = {};
  List<AppNotification> notifications = [];
  List<Report> reports = [];
  List<Profile> blockedProfiles = [];
  List<String> locationHistory = [];
  bool isLoading = false;
  String? error;
  Map<String, bool> notificationPrefs = {
    'request': true,
    'accepted': true,
    'rejected': true,
    'message': true,
    'cancellation': true,
    'modification': true,
    'reminder': true,
  };

  final Map<String, Profile> _profileCache = {};

  void _cacheProfiles(List<Profile> profiles) {
    for (final p in profiles) {
      _profileCache[p.id] = p;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> init() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      currentUser = await repo.getCurrentProfile();
      mode = currentUser?.mode ?? 'member';
      if (currentUser != null) _profileCache[currentUser!.id] = currentUser!;
      rides = await repo.getRides();
      _cacheProfiles(
        await repo.getProfilesByIds(rides.map((r) => r.hostId).toList()),
      );
    } catch (e) {
      // Core data failed; keep going with the per-user loads below so a
      // single failed request never leaves the whole home empty.
      error ??= e.toString();
    }
    // Each per-user load is guarded on its own: one failing request
    // (network blip, expired session) used to skip all the rest.
    if (currentUser != null) {
      final userId = currentUser!.id;
      Future<void> load(Future<void> Function() f) async {
        try {
          await f();
        } catch (e) {
          error ??= e.toString();
        }
      }
      await load(() async {
        myRequests = await repo.getMyRequests(userId);
      });
      await load(() async {
        notifications = await repo.getNotifications(userId);
      });
      await load(() async {
        locationHistory = await repo.getLocationHistory(userId);
      });
      await load(() async {
        conversations = await repo.getConversations(userId);
      });
      await load(() async {
        blockedProfiles = await repo.getBlockedProfiles(userId);
      });
      await load(() async {
        isAdmin = await repo.isCurrentUserAdmin();
      });
      await load(() async {
        reports = await repo.getReports();
      });
      await load(() async {
        await _loadRequestsForMyRides();
      });
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadRequestsForMyRides() async {
    final userId = currentUser?.id;
    if (userId == null) {
      requestsForMyRides = [];
      return;
    }
    final myRideIds = rides
        .where((r) => r.hostId == userId)
        .map((r) => r.id)
        .toSet();
    final all = <RideRequest>[];
    for (final rideId in myRideIds) {
      all.addAll(await repo.getRequestsForRide(rideId));
    }
    requestsForMyRides = all;
  }

  Future<void> refreshRides() async {
    try {
      rides = await repo.getRides();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshAll() async {
    isLoading = true;
    notifyListeners();
    try {
      rides = await repo.getRides();
      if (currentUser != null) {
        final userId = currentUser!.id;
        myRequests = await repo.getMyRequests(userId);
        notifications = await repo.getNotifications(userId);
        conversations = await repo.getConversations(userId);
        locationHistory = await repo.getLocationHistory(userId);
        await _loadRequestsForMyRides();
      }
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setMode(String m) async {
    final user = currentUser;
    if (user == null) return false;
    final previousMode = mode;
    mode = m;
    notifyListeners();
    try {
      currentUser = await repo.updateProfile(user.copyWith(mode: m));
      _profileCache[currentUser!.id] = currentUser!;
      error = null;
      return true;
    } catch (e) {
      // Revert the local switch: leaving it changed would show the
      // wrong home tab while the server still has the old mode.
      mode = previousMode;
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  List<Ride> searchRides({String? from, String? to, DateTime? date}) {
    return rides.where((ride) {
      if (ride.status != 'active') return false;
      if (from != null && from.trim().isNotEmpty) {
        if (!ride.fromLocation.toLowerCase().contains(from.toLowerCase())) {
          return false;
        }
      }
      if (to != null && to.trim().isNotEmpty) {
        if (!ride.toLocation.toLowerCase().contains(to.toLowerCase())) {
          return false;
        }
      }
      if (date != null && !_isSameDay(ride.travelDate, date)) return false;
      return true;
    }).toList();
  }

  List<Ride> get upcomingRidesForMe {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final acceptedRideIds = myRequests
        .where((r) => r.status == 'accepted')
        .map((r) => r.rideId)
        .toSet();
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return rides.where((ride) {
      if (ride.status != 'active') return false;
      if (ride.travelDate.isBefore(startOfToday)) return false;
      return ride.hostId == userId || acceptedRideIds.contains(ride.id);
    }).toList();
  }

  /// Demo-mode one-tap sign-in used by "Continue in demo" on Welcome.
  /// In live mode this is never offered; it simply verifies a demo code.
  Future<void> demoSignIn() async {
    await repo.verifyOtp(code: '123456');
    await init();
  }

  // ---- Password login + admin-managed accounts ----

  /// True when the signed-in user is an admin (loaded by init()).
  bool isAdmin = false;

  /// All profiles, for the admin screen (admins only).
  List<Profile> allProfiles = [];

  /// Ids of the current admins.
  Set<String> adminIds = {};

  Future<bool> _runBool(Future<void> Function() f) async {
    try {
      await f();
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Password sign-in: mobile number + password. On success the full
  /// state is loaded; the caller checks `currentUser.mustResetPassword`
  /// to decide whether the reset screen comes first.
  Future<bool> passwordSignIn(String phone, String password) async {
    try {
      currentUser = await repo.signInWithPassword(
        phone: phone,
        password: password,
      );
      await init();
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sets the signed-in user's own password and clears the forced-reset
  /// flag, so the next sign-in goes straight to home.
  Future<bool> resetOwnPassword(String newPassword) async {
    final user = currentUser;
    if (user == null) return false;
    return _runBool(() async {
      await repo.updateOwnPassword(newPassword);
      currentUser = await repo.updateProfile(
        user.copyWith(mustResetPassword: false),
      );
      if (currentUser != null) _profileCache[currentUser!.id] = currentUser!;
    });
  }

  /// First-admin bootstrap: when no admin exists yet, the signed-in user
  /// becomes the first admin and sets their password.
  Future<bool> bootstrapAdmin(String password) async {
    return _runBool(() async {
      await repo.bootstrapAdmin(password: password);
      await init();
    });
  }

  Future<bool> loadAllProfiles() async {
    try {
      allProfiles = await repo.getAllProfiles();
      adminIds = (await repo.getAdminUserIds()).toSet();
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminCreateUser({
    required String name,
    required String phone,
    required String tempPassword,
  }) async {
    return _runBool(() async {
      await repo.adminCreateUser(
        name: name,
        phone: phone,
        tempPassword: tempPassword,
      );
      allProfiles = await repo.getAllProfiles();
    });
  }

  Future<bool> adminSetPassword({
    required String userId,
    required String tempPassword,
  }) async {
    return _runBool(() async {
      await repo.adminSetPassword(
        userId: userId,
        tempPassword: tempPassword,
      );
      allProfiles = await repo.getAllProfiles();
    });
  }

  Future<bool> adminSetAdmin({
    required String userId,
    required bool makeAdmin,
  }) async {
    return _runBool(() async {
      await repo.adminSetAdmin(userId: userId, makeAdmin: makeAdmin);
      isAdmin = await repo.isCurrentUserAdmin();
      allProfiles = await repo.getAllProfiles();
      adminIds = (await repo.getAdminUserIds()).toSet();
    });
  }

  bool isBlocked(String userId) =>
      blockedProfiles.any((p) => p.id == userId);

  void setNotificationPref(String key, bool value) {
    notificationPrefs[key] = value;
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await repo.markNotificationRead(id);
      notifications = notifications
          .map((n) => n.id == id ? n.copyWith(read: true) : n)
          .toList();
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    final userId = currentUser?.id;
    if (userId == null) return;
    try {
      await repo.markAllNotificationsRead(userId);
      notifications =
          notifications.map((n) => n.copyWith(read: true)).toList();
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> updateRide(Ride ride) async {
    try {
      final updated = await repo.updateRide(ride);
      final i = rides.indexWhere((r) => r.id == ride.id);
      if (i >= 0) rides[i] = updated;
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> resolveReport(String id, String status) async {
    try {
      await repo.resolveReport(id, status);
      reports = await repo.getReports();
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> createRide(Ride ride) async {
    try {
      final created = await repo.createRide(ride);
      rides.add(created);
      rides.sort((a, b) => a.travelDate.compareTo(b.travelDate));
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> cancelRide(String rideId) async {
    try {
      await repo.cancelRide(rideId);
      final i = rides.indexWhere((r) => r.id == rideId);
      if (i >= 0) rides[i] = rides[i].copyWith(status: 'cancelled');
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> completeRide(String rideId) async {
    try {
      final i = rides.indexWhere((r) => r.id == rideId);
      if (i < 0) return false;
      final updated = await repo.updateRide(
        rides[i].copyWith(status: 'completed'),
      );
      rides[i] = updated;
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> sendJoinRequest(String rideId, {String? message}) async {
    final userId = currentUser?.id;
    if (userId == null) {
      error = 'not_signed_in';
      notifyListeners();
      return false;
    }
    try {
      final request = await repo.createRequest(
        rideId: rideId,
        memberId: userId,
        message: message,
      );
      myRequests.add(request);
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> acceptRequest(String requestId) async {
    try {
      await repo.acceptRequest(requestId);
      await refreshRides();
      await _loadRequestsForMyRides();
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> rejectRequest(String requestId) async {
    try {
      await repo.rejectRequest(requestId);
      await _loadRequestsForMyRides();
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> withdrawRequest(String requestId) async {
    try {
      await repo.withdrawRequest(requestId);
      if (currentUser != null) {
        myRequests = await repo.getMyRequests(currentUser!.id);
      }
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String conversationId, String body) async {
    final userId = currentUser?.id;
    if (userId == null) {
      error = 'not_signed_in';
      notifyListeners();
      return false;
    }
    try {
      final message = await repo.sendMessage(
        conversationId: conversationId,
        senderId: userId,
        body: body,
      );
      messagesByConversation.putIfAbsent(conversationId, () => []).add(message);
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      messagesByConversation[conversationId] = await repo.getMessages(
        conversationId,
      );
      error = null;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> markMessagesRead(String conversationId) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    try {
      await repo.markMessagesRead(
        conversationId: conversationId,
        readerId: userId,
      );
      final now = DateTime.now();
      final msgs = messagesByConversation[conversationId];
      if (msgs != null) {
        messagesByConversation[conversationId] = msgs
            .map(
              (m) => m.senderId != userId && m.readAt == null
                  ? m.copyWith(readAt: now)
                  : m,
            )
            .toList();
      }
      error = null;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<Conversation?> openConversation({
    required String rideId,
    required String hostId,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) {
      error = 'not_signed_in';
      notifyListeners();
      return null;
    }
    try {
      final conv = await repo.getOrCreateConversation(
        rideId: rideId,
        memberId: userId,
        hostId: hostId,
      );
      if (!conversations.any((c) => c.id == conv.id)) {
        conversations.add(conv);
      }
      error = null;
      notifyListeners();
      return conv;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> blockUser(String userId) async {
    final blockerId = currentUser?.id;
    if (blockerId == null) return false;
    try {
      await repo.blockUser(blockerId: blockerId, blockedId: userId);
      blockedProfiles = await repo.getBlockedProfiles(blockerId);
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> unblockUser(String userId) async {
    final blockerId = currentUser?.id;
    if (blockerId == null) return false;
    try {
      await repo.unblockUser(blockerId: blockerId, blockedId: userId);
      blockedProfiles = await repo.getBlockedProfiles(blockerId);
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> submitReport(Report report) async {
    try {
      await repo.createReport(report);
      reports = await repo.getReports();
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await repo.signOut();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      // Always clear local state, even if the server sign-out failed:
      // the user asked to log out and must not stay "signed in" locally.
      currentUser = null;
      mode = 'member';
      myRequests = [];
      requestsForMyRides = [];
      conversations = [];
      messagesByConversation = {};
      notifications = [];
      reports = [];
      blockedProfiles = [];
      locationHistory = [];
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    final userId = currentUser?.id;
    if (userId == null) return false;
    try {
      await repo.deleteAccount(userId);
      currentUser = null;
      mode = 'member';
      myRequests = [];
      requestsForMyRides = [];
      conversations = [];
      messagesByConversation = {};
      notifications = [];
      reports = [];
      blockedProfiles = [];
      locationHistory = [];
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Profile p) async {
    try {
      currentUser = await repo.updateProfile(p);
      _profileCache[currentUser!.id] = currentUser!;
      mode = currentUser!.mode;
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  int get unreadNotificationCount {
    return notifications.where((n) => !n.read).length;
  }

  int unreadMessagesCount(String conversationId) {
    final userId = currentUser?.id;
    final msgs = messagesByConversation[conversationId] ?? [];
    return msgs
        .where((m) => m.senderId != userId && m.readAt == null)
        .length;
  }

  int get totalUnreadChats {
    var total = 0;
    for (final conv in conversations) {
      total += unreadMessagesCount(conv.id);
    }
    return total;
  }

  Profile? profileById(String id) => _profileCache[id];

  Future<Profile?> fetchProfile(String id) async {
    final cached = _profileCache[id];
    if (cached != null) return cached;
    final profiles = await repo.getProfilesByIds([id]);
    if (profiles.isEmpty) return null;
    _profileCache[id] = profiles.first;
    notifyListeners();
    return profiles.first;
  }

  List<RideRequest> requestsForRide(String rideId) {
    return requestsForMyRides.where((r) => r.rideId == rideId).toList();
  }

  List<RideRequest> get pendingRequestsForMyRides {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final myRideIds = rides
        .where((r) => r.hostId == userId)
        .map((r) => r.id)
        .toSet();
    return requestsForMyRides
        .where((r) => r.status == 'pending' && myRideIds.contains(r.rideId))
        .toList();
  }
}
