import '../models.dart';

abstract class HopRepository {
  /// Broadcast stream that fires on any local mutation (demo) so
  /// watchers can re-emit snapshots.
  Stream<void> get changes;

  Future<Profile?> getCurrentProfile();

  Future<Profile> signInWithOtp({String? email, String? phone});

  Future<Profile> verifyOtp({required String code, String? email, String? phone});

  Future<Profile> createProfile(Profile profile);

  Future<Profile> updateProfile(Profile profile);

  Future<void> signOut();

  Future<List<Ride>> getRides();

  Future<Ride> createRide(Ride ride);

  Future<Ride> updateRide(Ride ride);

  Future<void> cancelRide(String rideId);

  Future<List<RideRequest>> getRequestsForRide(String rideId);

  Future<List<RideRequest>> getMyRequests(String memberId);

  Future<RideRequest> createRequest({
    required String rideId,
    required String memberId,
    String? message,
  });

  Future<RideRequest> acceptRequest(String requestId);

  Future<RideRequest> rejectRequest(String requestId);

  Future<RideRequest> withdrawRequest(String requestId);

  Future<List<Conversation>> getConversations(String userId);

  Future<Conversation> getOrCreateConversation({
    required String rideId,
    required String memberId,
    required String hostId,
  });

  Future<List<ChatMessage>> getMessages(String conversationId);

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
  });

  Future<void> markMessagesRead({
    required String conversationId,
    required String readerId,
  });

  Stream<List<ChatMessage>> watchMessages(String conversationId);

  Stream<List<AppNotification>> watchNotifications(String userId);

  Future<List<AppNotification>> getNotifications(String userId);

  Future<void> markNotificationRead(String id);

  Future<void> markAllNotificationsRead(String userId);

  Future<Report> createReport(Report report);

  Future<List<Report>> getReports();

  Future<void> resolveReport(String id, String status);

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  });

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  });

  Future<List<Profile>> getBlockedProfiles(String blockerId);

  Future<List<Profile>> getProfilesByIds(List<String> ids);

  Future<List<String>> getLocationHistory(String userId);

  Future<void> deleteAccount(String userId);

  Future<List<Ride>> getRidesByHost(String hostId);
}
