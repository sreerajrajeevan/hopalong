import '../models.dart';

/// DOB for someone currently [age] years old (birthday 15 Jan that year).
DateTime _dob(int age) {
  final now = DateTime.now();
  return DateTime(now.year - age, 1, 15);
}

const List<String> sampleAvatars = [
  'https://randomuser.me/api/portraits/women/44.jpg',
  'https://randomuser.me/api/portraits/women/68.jpg',
  'https://randomuser.me/api/portraits/women/12.jpg',
  'https://randomuser.me/api/portraits/women/33.jpg',
  'https://randomuser.me/api/portraits/men/32.jpg',
  'https://randomuser.me/api/portraits/men/75.jpg',
];

/// The signed-in demo user.
final Profile demoUser = Profile(
  id: 'demo-user',
  fullName: 'Asha Kumar',
  dob: _dob(26),
  gender: 'Female',
  phone: '+91 98765 00000',
  email: 'asha.kumar@example.com',
  avatarUrl: sampleAvatars[0],
  mode: 'member',
  completedRides: 3,
);

/// 8 sample hosts. Names/routes are deterministic so the SQL seed can match.
final List<Profile> sampleHosts = [
  Profile(
    id: 'host-1',
    fullName: 'Meera Nair',
    dob: _dob(24),
    gender: 'Female',
    phone: '+91 98765 43210',
    email: 'meera.nair@example.com',
    avatarUrl: sampleAvatars[1],
    mode: 'rider',
    completedRides: 12,
  ),
  Profile(
    id: 'host-2',
    fullName: 'Arjun Pillai',
    dob: _dob(27),
    gender: 'Male',
    phone: '+91 98765 43211',
    email: 'arjun.pillai@example.com',
    avatarUrl: sampleAvatars[4],
    mode: 'rider',
    completedRides: 8,
  ),
  Profile(
    id: 'host-3',
    fullName: 'Lakshmi S',
    dob: _dob(31),
    gender: 'Female',
    phone: '+91 98765 43212',
    email: 'lakshmi.s@example.com',
    avatarUrl: sampleAvatars[2],
    mode: 'rider',
    completedRides: 21,
  ),
  Profile(
    id: 'host-4',
    fullName: 'Rohit Kumar',
    dob: _dob(23),
    gender: 'Male',
    phone: '+91 98765 43213',
    email: 'rohit.kumar@example.com',
    avatarUrl: sampleAvatars[5],
    mode: 'rider',
    completedRides: 5,
  ),
  Profile(
    id: 'host-5',
    fullName: 'Divya Menon',
    dob: _dob(29),
    gender: 'Female',
    phone: '+91 98765 43214',
    email: 'divya.menon@example.com',
    avatarUrl: sampleAvatars[3],
    mode: 'rider',
    completedRides: 15,
  ),
  Profile(
    id: 'host-6',
    fullName: 'Anand Raj',
    dob: _dob(34),
    gender: 'Male',
    phone: '+91 98765 43215',
    email: 'anand.raj@example.com',
    avatarUrl: sampleAvatars[4],
    mode: 'rider',
    completedRides: 30,
  ),
  Profile(
    id: 'host-7',
    fullName: 'Priya Thomas',
    dob: _dob(21),
    gender: 'Female',
    phone: '+91 98765 43216',
    email: 'priya.thomas@example.com',
    avatarUrl: sampleAvatars[1],
    mode: 'rider',
    completedRides: 4,
  ),
  Profile(
    id: 'host-8',
    fullName: 'Vikram Nair',
    dob: _dob(26),
    gender: 'Male',
    phone: '+91 98765 43217',
    email: 'vikram.nair@example.com',
    avatarUrl: sampleAvatars[5],
    mode: 'rider',
    completedRides: 9,
  ),
];

final List<Profile> sampleMembers = [
  Profile(
    id: 'member-1',
    fullName: 'Ananya Nair',
    dob: _dob(24),
    gender: 'Female',
    phone: '+91 98765 11101',
    email: 'ananya.nair@example.com',
    avatarUrl: sampleAvatars[2],
    mode: 'member',
    completedRides: 6,
  ),
  Profile(
    id: 'member-2',
    fullName: 'Rahul Menon',
    dob: _dob(27),
    gender: 'Male',
    phone: '+91 98765 11102',
    email: 'rahul.menon@example.com',
    avatarUrl: sampleAvatars[4],
    mode: 'member',
    completedRides: 2,
  ),
  Profile(
    id: 'member-3',
    fullName: 'Devika S',
    dob: _dob(22),
    gender: 'Female',
    phone: '+91 98765 11103',
    email: 'devika.s@example.com',
    avatarUrl: sampleAvatars[3],
    mode: 'member',
    completedRides: 1,
  ),
];

/// 8 rides over the next 7 days, computed relative to call time.
List<Ride> buildSampleRides() {
  final now = DateTime.now();
  DateTime day(int offset, int hour, int minute) {
    final d = now.add(Duration(days: offset));
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  return [
    Ride(
      id: 'ride-1',
      hostId: 'host-1',
      fromLocation: 'Kakkanad',
      toLocation: 'Infopark',
      travelDate: day(1, 9, 0),
      departureHour: 9,
      departureMinute: 0,
      vehicleType: 'car',
      vehicleModel: 'Maruti Swift',
      totalSeats: 3,
      seatsLeft: 1,
      contribution: 50,
      pickupLandmark: 'Kakkanad Bus Stop',
      dropoffLandmark: 'Infopark Main Gate',
      notes: 'Leaving sharp at 9 — playlist on, good vibes only!',
      status: 'active',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    Ride(
      id: 'ride-2',
      hostId: 'host-2',
      fromLocation: 'Ernakulam',
      toLocation: 'Kakkanad',
      travelDate: day(1, 18, 30),
      departureHour: 18,
      departureMinute: 30,
      vehicleType: 'bike',
      vehicleModel: 'Honda Activa',
      totalSeats: 1,
      seatsLeft: 1,
      contribution: 30,
      pickupLandmark: 'Ernakulam South Railway Station',
      dropoffLandmark: 'Kakkanad Junction',
      notes: 'Evening ride back home, helmet provided.',
      status: 'active',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    Ride(
      id: 'ride-3',
      hostId: 'host-3',
      fromLocation: 'Thrissur',
      toLocation: 'Guruvayur',
      travelDate: day(2, 7, 30),
      departureHour: 7,
      departureMinute: 30,
      vehicleType: 'car',
      vehicleModel: 'Hyundai i20',
      totalSeats: 4,
      seatsLeft: 2,
      contribution: 80,
      pickupLandmark: 'Thrissur Round',
      dropoffLandmark: 'Guruvayur Temple East Gate',
      notes: 'Early morning temple trip, back by noon.',
      status: 'active',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    Ride(
      id: 'ride-4',
      hostId: 'host-4',
      fromLocation: 'Calicut',
      toLocation: 'Wayanad (Kalpetta)',
      travelDate: day(3, 8, 0),
      departureHour: 8,
      departureMinute: 0,
      vehicleType: 'car',
      vehicleModel: 'Tata Nexon',
      totalSeats: 4,
      seatsLeft: 0,
      contribution: 150,
      pickupLandmark: 'Calicut Beach',
      dropoffLandmark: 'Kalpetta Bus Stand',
      notes: 'Weekend getaway drive — car is full, join the waitlist vibe!',
      status: 'active',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    Ride(
      id: 'ride-5',
      hostId: 'host-5',
      fromLocation: 'Trivandrum',
      toLocation: 'Kovalam',
      travelDate: day(4, 16, 0),
      departureHour: 16,
      departureMinute: 0,
      vehicleType: 'bike',
      vehicleModel: 'Royal Enfield Classic 350',
      totalSeats: 1,
      seatsLeft: 1,
      contribution: null,
      pickupLandmark: 'Trivandrum Central',
      dropoffLandmark: 'Kovalam Beach',
      notes: 'Free sunset ride to the beach, just bring good stories.',
      status: 'active',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    Ride(
      id: 'ride-6',
      hostId: 'host-6',
      fromLocation: 'Kottayam',
      toLocation: 'Kochi',
      travelDate: day(5, 10, 15),
      departureHour: 10,
      departureMinute: 15,
      vehicleType: 'car',
      vehicleModel: 'Maruti Baleno',
      totalSeats: 3,
      seatsLeft: 3,
      contribution: 120,
      pickupLandmark: 'Kottayam Bus Stand',
      dropoffLandmark: 'Vyttila Hub, Kochi',
      notes: 'Comfortable drive, AC on, space for one bag each.',
      status: 'active',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    Ride(
      id: 'ride-7',
      hostId: 'host-7',
      fromLocation: 'Palakkad',
      toLocation: 'Coimbatore',
      travelDate: day(6, 9, 45),
      departureHour: 9,
      departureMinute: 45,
      vehicleType: 'car',
      vehicleModel: 'Honda City',
      totalSeats: 2,
      seatsLeft: 1,
      contribution: 100,
      pickupLandmark: 'Palakkad Junction',
      dropoffLandmark: 'Gandhipuram, Coimbatore',
      notes: 'Crossing over for a shopping day, back by evening.',
      status: 'active',
      createdAt: now.subtract(const Duration(days: 3)),
    ),
    Ride(
      id: 'ride-8',
      hostId: 'host-8',
      fromLocation: 'Alappuzha',
      toLocation: 'Kochi',
      travelDate: day(7, 8, 30),
      departureHour: 8,
      departureMinute: 30,
      vehicleType: 'bike',
      vehicleModel: 'TVS Jupiter',
      totalSeats: 1,
      seatsLeft: 1,
      contribution: 0,
      pickupLandmark: 'Alappuzha Beach',
      dropoffLandmark: 'Marine Drive, Kochi',
      notes: 'Morning coastal ride, free for early birds.',
      status: 'active',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
  ];
}

/// Convenience getter (rebuilds from now each time).
List<Ride> get sampleRides => buildSampleRides();

List<RideRequest> buildSampleRequests(List<Ride> rides) {
  final now = DateTime.now();
  String rideId(int index) =>
      rides.length > index ? rides[index].id : 'ride-${index + 1}';
  return [
    RideRequest(
      id: 'request-1',
      rideId: rideId(0),
      memberId: 'member-1',
      message: 'Hi! I work at Infopark too, would love to join.',
      status: 'pending',
      createdAt: now.subtract(const Duration(hours: 5)),
    ),
    RideRequest(
      id: 'request-2',
      rideId: rideId(1),
      memberId: 'member-2',
      message: 'Can I hop on after my shift ends?',
      status: 'pending',
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
    RideRequest(
      id: 'request-3',
      rideId: rideId(2),
      memberId: 'member-3',
      message: 'Planning a temple visit with family, one seat please!',
      status: 'pending',
      createdAt: now.subtract(const Duration(hours: 1)),
    ),
  ];
}

List<AppNotification> buildSampleNotifications(String userId) {
  final now = DateTime.now();
  return [
    AppNotification(
      id: 'notif-1',
      userId: userId,
      type: 'request',
      title: 'New ride request',
      body: 'Ananya Nair wants to join your ride to Infopark.',
      rideId: 'ride-1',
      createdAt: now.subtract(const Duration(hours: 5)),
    ),
    AppNotification(
      id: 'notif-2',
      userId: userId,
      type: 'accepted',
      title: 'Request accepted',
      body: 'Arjun Pillai accepted your request for Ernakulam → Kakkanad.',
      rideId: 'ride-2',
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'notif-3',
      userId: userId,
      type: 'message',
      title: 'New message',
      body: 'Meera Nair: See you at Kakkanad Bus Stop at 9!',
      rideId: 'ride-1',
      conversationId: 'conv-1',
      createdAt: now.subtract(const Duration(minutes: 40)),
    ),
    AppNotification(
      id: 'notif-4',
      userId: userId,
      type: 'reminder',
      title: 'Ride tomorrow',
      body: 'Your ride Kakkanad → Infopark leaves tomorrow at 9:00 AM.',
      rideId: 'ride-1',
      createdAt: now.subtract(const Duration(minutes: 15)),
    ),
    AppNotification(
      id: 'notif-5',
      userId: userId,
      type: 'cancellation',
      title: 'Ride cancelled',
      body: 'The ride Thrissur → Guruvayur on Sunday was cancelled.',
      rideId: 'ride-3',
      createdAt: now.subtract(const Duration(minutes: 5)),
    ),
  ];
}

List<Conversation> buildSampleConversations([List<Ride>? rides]) {
  final now = DateTime.now();
  final ride1 = rides != null && rides.isNotEmpty ? rides[0].id : 'ride-1';
  final ride2 = rides != null && rides.length > 1 ? rides[1].id : 'ride-2';
  return [
    Conversation(
      id: 'conv-1',
      rideId: ride1,
      memberId: 'demo-user',
      hostId: 'host-1',
      createdAt: now.subtract(const Duration(hours: 6)),
    ),
    Conversation(
      id: 'conv-2',
      rideId: ride2,
      memberId: 'demo-user',
      hostId: 'host-2',
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
  ];
}

List<ChatMessage> buildSampleMessages([List<Conversation>? conversations]) {
  final convs = conversations ?? buildSampleConversations();
  final now = DateTime.now();
  final conv1 = convs.isNotEmpty ? convs[0].id : 'conv-1';
  final conv2 = convs.length > 1 ? convs[1].id : 'conv-2';
  return [
    ChatMessage(
      id: 'msg-1',
      conversationId: conv1,
      senderId: 'demo-user',
      body: 'Hi Meera! Is the pickup at Kakkanad Bus Stop okay?',
      readAt: now.subtract(const Duration(hours: 5)),
      createdAt: now.subtract(const Duration(hours: 5, minutes: 30)),
    ),
    ChatMessage(
      id: 'msg-2',
      conversationId: conv1,
      senderId: 'host-1',
      body: 'Yes, perfect! I will be there by 8:55. Look for the white Swift.',
      createdAt: now.subtract(const Duration(hours: 5)),
    ),
    ChatMessage(
      id: 'msg-3',
      conversationId: conv1,
      senderId: 'host-1',
      body: 'Also, please bring exact change if you can 🙂',
      createdAt: now.subtract(const Duration(minutes: 40)),
    ),
    ChatMessage(
      id: 'msg-4',
      conversationId: conv2,
      senderId: 'host-2',
      body: 'Hey Asha, your seat is confirmed for this evening.',
      readAt: now.subtract(const Duration(hours: 1)),
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    ChatMessage(
      id: 'msg-5',
      conversationId: conv2,
      senderId: 'demo-user',
      body: 'Great, thank you! See you at the station.',
      readAt: now.subtract(const Duration(hours: 1)),
      createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
    ),
  ];
}
