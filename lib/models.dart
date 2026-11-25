// Plain data models for HopAlong. All fromJson constructors tolerate
// missing keys (defaults) and accept both snake_case (Supabase) and
// camelCase keys.

String _s(Map<String, dynamic> json, String snake, String camel, String def) {
  final v = json[snake] ?? json[camel];
  if (v == null) return def;
  return v.toString();
}

String? _sOpt(Map<String, dynamic> json, String snake, String camel) {
  final v = json[snake] ?? json[camel];
  if (v == null) return null;
  return v.toString();
}

int _i(Map<String, dynamic> json, String snake, String camel, int def) {
  final v = json[snake] ?? json[camel];
  if (v == null) return def;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? def;
}

double? _dOpt(Map<String, dynamic> json, String snake, String camel) {
  final v = json[snake] ?? json[camel];
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool _b(Map<String, dynamic> json, String snake, String camel, bool def) {
  final v = json[snake] ?? json[camel];
  if (v == null) return def;
  if (v is bool) return v;
  return v.toString().toLowerCase() == 'true';
}

DateTime _dt(
  Map<String, dynamic> json,
  String snake,
  String camel,
  DateTime def,
) {
  final v = json[snake] ?? json[camel];
  if (v == null) return def;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString()) ?? def;
}

DateTime? _dtOpt(Map<String, dynamic> json, String snake, String camel) {
  final v = json[snake] ?? json[camel];
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class Profile {
  final String id;
  final String fullName;
  final DateTime dob;
  final String gender;
  final String phone;
  final String? email;
  final String avatarUrl;
  final String mode; // 'member' or 'rider'
  final int completedRides;
  final bool demoAdmin;

  const Profile({
    required this.id,
    required this.fullName,
    required this.dob,
    required this.gender,
    required this.phone,
    this.email,
    this.avatarUrl = '',
    this.mode = 'member',
    this.completedRides = 0,
    this.demoAdmin = false,
  });

  Profile copyWith({
    String? id,
    String? fullName,
    DateTime? dob,
    String? gender,
    String? phone,
    String? email,
    String? avatarUrl,
    String? mode,
    int? completedRides,
    bool? demoAdmin,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      mode: mode ?? this.mode,
      completedRides: completedRides ?? this.completedRides,
      demoAdmin: demoAdmin ?? this.demoAdmin,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: _s(json, 'id', 'id', ''),
      fullName: _s(json, 'full_name', 'fullName', ''),
      dob: _dt(json, 'dob', 'dob', DateTime(2000, 1, 1)),
      gender: _s(json, 'gender', 'gender', ''),
      phone: _s(json, 'phone', 'phone', ''),
      email: _sOpt(json, 'email', 'email'),
      avatarUrl: _s(json, 'avatar_url', 'avatarUrl', ''),
      mode: _s(json, 'mode', 'mode', 'member'),
      completedRides: _i(json, 'completed_rides', 'completedRides', 0),
      demoAdmin: _b(json, 'demo_admin', 'demoAdmin', false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'dob': dob.toIso8601String(),
      'gender': gender,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
      'mode': mode,
      'completed_rides': completedRides,
      'demo_admin': demoAdmin,
    };
  }
}

class Ride {
  final String id;
  final String hostId;
  final String fromLocation;
  final String toLocation;
  final DateTime travelDate;
  final int departureHour;
  final int departureMinute;
  final String vehicleType; // 'car' | 'bike'
  final String vehicleModel;
  final int totalSeats;
  final int seatsLeft;
  final double? contribution;
  final String pickupLandmark;
  final String dropoffLandmark;
  final String notes;
  final String status; // 'active' | 'completed' | 'cancelled'
  final DateTime createdAt;

  const Ride({
    required this.id,
    required this.hostId,
    required this.fromLocation,
    required this.toLocation,
    required this.travelDate,
    this.departureHour = 9,
    this.departureMinute = 0,
    this.vehicleType = 'car',
    this.vehicleModel = '',
    this.totalSeats = 4,
    this.seatsLeft = 4,
    this.contribution,
    this.pickupLandmark = '',
    this.dropoffLandmark = '',
    this.notes = '',
    this.status = 'active',
    required this.createdAt,
  });

  bool get isFull => seatsLeft <= 0;

  Ride copyWith({
    String? id,
    String? hostId,
    String? fromLocation,
    String? toLocation,
    DateTime? travelDate,
    int? departureHour,
    int? departureMinute,
    String? vehicleType,
    String? vehicleModel,
    int? totalSeats,
    int? seatsLeft,
    double? contribution,
    String? pickupLandmark,
    String? dropoffLandmark,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return Ride(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      travelDate: travelDate ?? this.travelDate,
      departureHour: departureHour ?? this.departureHour,
      departureMinute: departureMinute ?? this.departureMinute,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      totalSeats: totalSeats ?? this.totalSeats,
      seatsLeft: seatsLeft ?? this.seatsLeft,
      contribution: contribution ?? this.contribution,
      pickupLandmark: pickupLandmark ?? this.pickupLandmark,
      dropoffLandmark: dropoffLandmark ?? this.dropoffLandmark,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Ride.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Ride(
      id: _s(json, 'id', 'id', ''),
      hostId: _s(json, 'host_id', 'hostId', ''),
      fromLocation: _s(json, 'from_location', 'fromLocation', ''),
      toLocation: _s(json, 'to_location', 'toLocation', ''),
      travelDate: _dt(json, 'travel_date', 'travelDate', now),
      departureHour: _i(json, 'departure_hour', 'departureHour', 9),
      departureMinute: _i(json, 'departure_minute', 'departureMinute', 0),
      vehicleType: _s(json, 'vehicle_type', 'vehicleType', 'car'),
      vehicleModel: _s(json, 'vehicle_model', 'vehicleModel', ''),
      totalSeats: _i(json, 'total_seats', 'totalSeats', 4),
      seatsLeft: _i(json, 'seats_left', 'seatsLeft', 4),
      contribution: _dOpt(json, 'contribution', 'contribution'),
      pickupLandmark: _s(json, 'pickup_landmark', 'pickupLandmark', ''),
      dropoffLandmark: _s(json, 'dropoff_landmark', 'dropoffLandmark', ''),
      notes: _s(json, 'notes', 'notes', ''),
      status: _s(json, 'status', 'status', 'active'),
      createdAt: _dt(json, 'created_at', 'createdAt', now),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'from_location': fromLocation,
      'to_location': toLocation,
      'travel_date': travelDate.toIso8601String(),
      'departure_hour': departureHour,
      'departure_minute': departureMinute,
      'vehicle_type': vehicleType,
      'vehicle_model': vehicleModel,
      'total_seats': totalSeats,
      'seats_left': seatsLeft,
      'contribution': contribution,
      'pickup_landmark': pickupLandmark,
      'dropoff_landmark': dropoffLandmark,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class RideRequest {
  final String id;
  final String rideId;
  final String memberId;
  final String? message;
  final String status; // pending | accepted | rejected | withdrawn | cancelled
  final DateTime createdAt;

  const RideRequest({
    required this.id,
    required this.rideId,
    required this.memberId,
    this.message,
    this.status = 'pending',
    required this.createdAt,
  });

  RideRequest copyWith({
    String? id,
    String? rideId,
    String? memberId,
    String? message,
    String? status,
    DateTime? createdAt,
  }) {
    return RideRequest(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      memberId: memberId ?? this.memberId,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: _s(json, 'id', 'id', ''),
      rideId: _s(json, 'ride_id', 'rideId', ''),
      memberId: _s(json, 'member_id', 'memberId', ''),
      message: _sOpt(json, 'message', 'message'),
      status: _s(json, 'status', 'status', 'pending'),
      createdAt: _dt(json, 'created_at', 'createdAt', DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'member_id': memberId,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Conversation {
  final String id;
  final String rideId;
  final String memberId;
  final String hostId;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.rideId,
    required this.memberId,
    required this.hostId,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: _s(json, 'id', 'id', ''),
      rideId: _s(json, 'ride_id', 'rideId', ''),
      memberId: _s(json, 'member_id', 'memberId', ''),
      hostId: _s(json, 'host_id', 'hostId', ''),
      createdAt: _dt(json, 'created_at', 'createdAt', DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'member_id': memberId,
      'host_id': hostId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? body,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      body: body ?? this.body,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _s(json, 'id', 'id', ''),
      conversationId: _s(json, 'conversation_id', 'conversationId', ''),
      senderId: _s(json, 'sender_id', 'senderId', ''),
      body: _s(json, 'body', 'body', ''),
      readAt: _dtOpt(json, 'read_at', 'readAt'),
      createdAt: _dt(json, 'created_at', 'createdAt', DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'body': body,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String type; // request | accepted | rejected | message |
  // cancellation | modification | reminder
  final String title;
  final String body;
  final String? rideId;
  final String? conversationId;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.rideId,
    this.conversationId,
    this.read = false,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    String? rideId,
    String? conversationId,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      rideId: rideId ?? this.rideId,
      conversationId: conversationId ?? this.conversationId,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _s(json, 'id', 'id', ''),
      userId: _s(json, 'user_id', 'userId', ''),
      type: _s(json, 'type', 'type', 'message'),
      title: _s(json, 'title', 'title', ''),
      body: _s(json, 'body', 'body', ''),
      rideId: _sOpt(json, 'ride_id', 'rideId'),
      conversationId: _sOpt(json, 'conversation_id', 'conversationId'),
      read: _b(json, 'read', 'read', false),
      createdAt: _dt(json, 'created_at', 'createdAt', DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'ride_id': rideId,
      'conversation_id': conversationId,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Report {
  final String id;
  final String reporterId;
  final String? reportedUserId;
  final String? rideId;
  final String reason;
  final String? details;
  final String status; // open | resolved | dismissed
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterId,
    this.reportedUserId,
    this.rideId,
    required this.reason,
    this.details,
    this.status = 'open',
    required this.createdAt,
  });

  Report copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? rideId,
    String? reason,
    String? details,
    String? status,
    DateTime? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      rideId: rideId ?? this.rideId,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: _s(json, 'id', 'id', ''),
      reporterId: _s(json, 'reporter_id', 'reporterId', ''),
      reportedUserId: _sOpt(json, 'reported_user_id', 'reportedUserId'),
      rideId: _sOpt(json, 'ride_id', 'rideId'),
      reason: _s(json, 'reason', 'reason', ''),
      details: _sOpt(json, 'details', 'details'),
      status: _s(json, 'status', 'status', 'open'),
      createdAt: _dt(json, 'created_at', 'createdAt', DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reported_user_id': reportedUserId,
      'ride_id': rideId,
      'reason': reason,
      'details': details,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class BlockedUser {
  final String blockerId;
  final String blockedId;
  final DateTime createdAt;

  const BlockedUser({
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      blockerId: _s(json, 'blocker_id', 'blockerId', ''),
      blockedId: _s(json, 'blocked_id', 'blockedId', ''),
      createdAt: _dt(json, 'created_at', 'createdAt', DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blocker_id': blockerId,
      'blocked_id': blockedId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
