import 'package:image_picker/image_picker.dart';

import '../models.dart';

abstract class HopRepository {
  /// Broadcast stream that fires on any local mutation (demo) so
  /// watchers can re-emit snapshots.
  Stream<void> get changes;

  Future<Profile?> getCurrentProfile();

  /// Id of the signed-in auth user, if any (live mode). Used to name the
  /// avatar upload folder, which the storage policy ties to the auth uid.
  String? get currentUserId;

  /// Uploads a picked photo and returns the URL to store as the avatar.
  /// Demo mode just keeps the local path.
  Future<String> uploadAvatar(String userId, XFile file);

  /// Phone-only sign-in: Supabase sends a 6-digit OTP by SMS to the
  /// user's mobile number. No email sign-in, no WhatsApp.
  /// Kept only for the one-time first-time password setup; normal
  /// sign-in is [signInWithPassword].
  Future<Profile> signInWithOtp({String? phone});

  Future<Profile> verifyOtp({required String code, String? phone});

  /// Password sign-in (admin-managed accounts): mobile number + password.
  /// The number is converted to a login email internally; the user never
  /// sees it.
  Future<Profile> signInWithPassword({
    required String phone,
    required String password,
  });

  /// Changes the signed-in user's own password (first-login reset).
  Future<void> updateOwnPassword(String newPassword);

  /// True when the signed-in user is an admin.
  Future<bool> isCurrentUserAdmin();

  /// All profiles, newest first — for the admin screen.
  Future<List<Profile>> getAllProfiles();

  /// Ids of the current admins.
  Future<List<String>> getAdminUserIds();

  /// Admin actions — these call the manage-users Edge Function, which
  /// holds the service key. The app never touches admin APIs directly.
  /// [adminCreateUser] returns the new user's id.
  Future<String> adminCreateUser({
    required String name,
    required String phone,
    required String tempPassword,
  });

  /// Sets a user's password and forces a reset at their next sign-in.
  Future<void> adminSetPassword({
    required String userId,
    required String tempPassword,
  });

  Future<void> adminSetAdmin({
    required String userId,
    required bool makeAdmin,
  });

  /// First-admin bootstrap: when no admin exists yet, the signed-in user
  /// promotes themselves and sets their own password. Afterwards this
  /// always fails.
  Future<void> bootstrapAdmin({required String password});

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
