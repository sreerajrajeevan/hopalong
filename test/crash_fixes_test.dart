// Regression tests for the Nov 28 crash audit + DOB/photo-optional change.
//
// Every test here maps to a crash Sree reported on device:
//  - editing/renaming a profile crashed when the save failed
//  - the date picker crashed on the second tap (midnight vs now)
//  - the gender dropdown crashed on a stored value outside the 4 options
//  - any failed server action used to crash the app instead of showing
//    "try again" (AppState methods rethrew; screens never caught)
//  - a failed chat send permanently killed the send button
//  - DOB and photo are now optional at signup
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopalong/app_state.dart';
import 'package:hopalong/data/demo_repository.dart';
import 'package:hopalong/main.dart';
import 'package:hopalong/models.dart';
import 'package:hopalong/screens/admin_screen.dart';
import 'package:hopalong/screens/auth.dart';
import 'package:hopalong/screens/profile.dart';
import 'package:hopalong/utils.dart';

/// A repo that fails every write, like a dead network. Used to prove
/// AppState actions return false (and never throw) instead of crashing.
class FailingRepository extends DemoRepository {
  @override
  Future<Profile> signInWithPassword({
    required String phone,
    required String password,
  }) async =>
      throw Exception('network down');

  @override
  Future<Profile> updateProfile(Profile p) async =>
      throw Exception('network down');

  @override
  Future<Ride> createRide(Ride r) async => throw Exception('network down');

  @override
  Future<Ride> updateRide(Ride r) async => throw Exception('network down');

  @override
  Future<void> cancelRide(String id) async =>
      throw Exception('network down');

  @override
  Future<RideRequest> createRequest({
    required String rideId,
    required String memberId,
    String? message,
  }) async =>
      throw Exception('network down');

  @override
  Future<RideRequest> acceptRequest(String id) async =>
      throw Exception('network down');

  @override
  Future<RideRequest> rejectRequest(String id) async =>
      throw Exception('network down');

  @override
  Future<RideRequest> withdrawRequest(String id) async =>
      throw Exception('network down');

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
  }) async =>
      throw Exception('network down');

  @override
  Future<Conversation> getOrCreateConversation({
    required String rideId,
    required String memberId,
    required String hostId,
  }) async =>
      throw Exception('network down');

  @override
  Future<Report> createReport(Report r) async =>
      throw Exception('network down');

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async =>
      throw Exception('network down');

  @override
  Future<void> deleteAccount(String id) async =>
      throw Exception('network down');
}

Profile _profile({String gender = 'Female', DateTime? dob}) => Profile(
      id: 'user-1',
      fullName: 'Test User',
      dob: dob,
      gender: gender,
      phone: '9876543210',
    );

Ride _ride() => Ride(
      id: 'ride-1',
      hostId: 'user-1',
      fromLocation: 'Kochi',
      toLocation: 'Alappuzha',
      travelDate: DateTime.now().add(const Duration(days: 1)),
      departureHour: 9,
      departureMinute: 0,
      vehicleType: 'car',
      vehicleModel: 'Swift',
      totalSeats: 3,
      seatsLeft: 3,
      createdAt: DateTime.now(),
    );

void main() {
  group('date picker clamp', () {
    test('today at midnight stays valid (the second-tap crash)', () {
      final now = DateTime(2026, 11, 28, 15, 30);
      final today = DateTime(2026, 11, 28);
      expect(clampPickerDate(today, now: now), today);
    });

    test('a past date clamps to today', () {
      final now = DateTime(2026, 11, 28, 15, 30);
      expect(clampPickerDate(DateTime(2026, 11, 20), now: now),
          DateTime(2026, 11, 28));
    });

    test('a date beyond 60 days clamps to the last day', () {
      final now = DateTime(2026, 11, 28, 15, 30);
      expect(clampPickerDate(DateTime(2027, 3, 1), now: now),
          DateTime(2027, 1, 27));
    });

    test('null clamps to today', () {
      final now = DateTime(2026, 11, 28, 15, 30);
      expect(clampPickerDate(null, now: now), DateTime(2026, 11, 28));
    });
  });

  group('optional DOB', () {
    test('ageFromDob(null) is null, isAdult(null) does not block', () {
      expect(ageFromDob(null), isNull);
      expect(isAdult(null), isTrue);
      expect(ageGender(null, 'Female'), 'Female');
      expect(ageGender(DateTime(2000, 1, 1), 'Female'), startsWith('2'));
    });

    test('Profile round-trips a null DOB', () {
      final p = _profile(dob: null);
      expect(p.toJson()['dob'], isNull);
      final back = Profile.fromJson(p.toJson());
      expect(back.dob, isNull);
      expect(back.fullName, 'Test User');
    });

    test('Profile.fromJson with a missing dob does not invent 2000-01-01',
        () {
      final back = Profile.fromJson({
        'id': 'user-1',
        'full_name': 'No Dob',
        'gender': 'Male',
        'phone': '9876543210',
      });
      expect(back.dob, isNull);
    });
  });

  group('failed actions return false instead of throwing', () {
    test('every AppState action survives a dead network', () async {
      final state = AppState(repo: FailingRepository());
      state.currentUser = _profile();
      expect(await state.updateProfile(_profile()), isFalse);
      expect(await state.createRide(_ride()), isFalse);
      expect(await state.updateRide(_ride()), isFalse);
      expect(await state.cancelRide('ride-1'), isFalse);
      expect(await state.completeRide('ride-1'), isFalse);
      expect(await state.sendJoinRequest('ride-1'), isFalse);
      expect(await state.acceptRequest('req-1'), isFalse);
      expect(await state.rejectRequest('req-1'), isFalse);
      expect(await state.withdrawRequest('req-1'), isFalse);
      expect(await state.sendMessage('conv-1', 'hi'), isFalse);
      expect(await state.submitReport(Report(
        id: 'rep-1',
        reporterId: 'user-1',
        reportedUserId: 'user-2',
        reason: 'Spam',
        status: 'open',
        createdAt: DateTime.now(),
      )), isFalse);
      expect(await state.blockUser('user-2'), isFalse);
      expect(await state.deleteAccount(), isFalse);
      expect(await state.setMode('rider'), isFalse);
      expect(
          await state.openConversation(rideId: 'ride-1', hostId: 'user-2'),
          isNull);
      expect(state.error, isNotNull);
    });
  });

  group('widget: edit profile with an odd stored gender', () {
    testWidgets('opens the dialog instead of throwing', (tester) async {
      final state = AppState(repo: DemoRepository());
      state.currentUser = _profile(gender: '');
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ProfileScreen(state: state))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      expect(find.text('Edit profile'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('loginEmailForPhone', () {
    test('maps every number form to the same login email', () {
      expect(loginEmailForPhone('98765 43210'), '919876543210@hopalong.app');
      expect(loginEmailForPhone('+919876543210'), '919876543210@hopalong.app');
      expect(loginEmailForPhone('09876543210'), '919876543210@hopalong.app');
      expect(loginEmailForPhone('919876543210'), '919876543210@hopalong.app');
    });
  });

  group('must_reset_password flag', () {
    test('survives a model round-trip', () {
      final p = _profile().copyWith(mustResetPassword: true);
      expect(Profile.fromJson(p.toJson()).mustResetPassword, isTrue);
      expect(Profile.fromJson(_profile().toJson()).mustResetPassword, isFalse);
    });
  });

  group('widget: password login', () {
    testWidgets('signs in with number + password and reaches home',
        (tester) async {
      final state = AppState(repo: DemoRepository());
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(state: state, startMode: 'member'),
          routes: {
            '/home': (_) => const Scaffold(body: Text('Home loaded')),
            '/reset-password': (_) =>
                const Scaffold(body: Text('Reset loaded')),
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Mobile number'),
          '9876543210');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'secret123');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Home loaded'), findsOneWidget);
    });

    testWidgets('shows an error on a wrong password instead of crashing',
        (tester) async {
      final state = AppState(repo: FailingRepository());
      await tester.pumpWidget(
        MaterialApp(home: AuthScreen(state: state, startMode: 'member')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Mobile number'),
          '9876543210');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'secret123');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Wrong number or password. Please try again.'),
          findsOneWidget);
    });
  });

  group('widget: admin adds a user without DOB or photo', () {
    testWidgets('the new user appears in the list', (tester) async {
      final state = AppState(repo: DemoRepository());
      await tester.pumpWidget(
        MaterialApp(home: AdminScreen(state: state)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full name *'), 'New Person');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Mobile number *'),
          '9876543210');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Temporary password *'),
          'temp1234');
      await tester.ensureVisible(find.text('Add user'));
      await tester.tap(find.text('Add user'));
      await tester.pumpAndSettle();
      expect(find.text('New Person'), findsOneWidget);
    });
  });

  group('widget: welcome screen', () {
    testWidgets('renders in demo mode', (tester) async {
      final state = AppState.create();
      await tester.pumpWidget(HopAlongApp(state: state));
      await tester.pumpAndSettle();
      expect(find.text('HopAlong'), findsWidgets);
      expect(find.text('Find a ride'), findsOneWidget);
    });
  });
}
