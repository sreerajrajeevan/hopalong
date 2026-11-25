import 'package:flutter_test/flutter_test.dart';
import 'package:hopalong/app_state.dart';
import 'package:hopalong/data/demo_repository.dart';
import 'package:hopalong/models.dart';
import 'package:hopalong/utils.dart';

void main() {
  group('isAdult', () {
    // Fixed "today" so the tests are deterministic.
    final now = DateTime(2026, 6, 15);

    test('17 years 11 months fails', () {
      expect(isAdult(DateTime(2008, 7, 15), now: now), isFalse);
    });

    test('exactly 18 passes', () {
      expect(isAdult(DateTime(2008, 6, 15), now: now), isTrue);
    });

    test('future DOB fails', () {
      expect(isAdult(DateTime(2027, 1, 1), now: now), isFalse);
    });
  });

  group('rideStatus', () {
    test('full at 0 seats', () {
      expect(
        rideStatus(seatsLeft: 0, totalSeats: 4),
        RideStatus.full,
      );
    });

    test('fillingFast at 1 seat left', () {
      expect(
        rideStatus(seatsLeft: 1, totalSeats: 4),
        RideStatus.fillingFast,
      );
    });

    test('fillingFast at 75% full (3 of 4 taken)', () {
      expect(
        rideStatus(seatsLeft: 1, totalSeats: 4),
        RideStatus.fillingFast,
      );
      // 2 of 8 left is exactly 25% remaining.
      expect(
        rideStatus(seatsLeft: 2, totalSeats: 8),
        RideStatus.fillingFast,
      );
    });

    test('available otherwise', () {
      expect(
        rideStatus(seatsLeft: 3, totalSeats: 4),
        RideStatus.available,
      );
      expect(
        rideStatus(seatsLeft: 4, totalSeats: 4),
        RideStatus.available,
      );
    });
  });

  group('DemoRepository acceptRequest atomicity', () {
    test('second accept throws and seatsLeft stays 0', () async {
      final repo = DemoRepository();
      final ride = await repo.createRide(
        Ride(
          id: '',
          hostId: 'host-1',
          fromLocation: 'Kakkanad',
          toLocation: 'Infopark',
          travelDate: DateTime.now().add(const Duration(days: 1)),
          totalSeats: 1,
          seatsLeft: 1,
          createdAt: DateTime.now(),
        ),
      );
      final first = await repo.createRequest(
        rideId: ride.id,
        memberId: 'member-1',
      );
      final second = await repo.createRequest(
        rideId: ride.id,
        memberId: 'member-2',
      );

      final accepted = await repo.acceptRequest(first.id);
      expect(accepted.status, 'accepted');

      expect(() => repo.acceptRequest(second.id), throwsStateError);

      final rides = await repo.getRides();
      final updated = rides.firstWhere((r) => r.id == ride.id);
      expect(updated.seatsLeft, 0);
      expect(updated.isFull, isTrue);
    });
  });

  group('DemoRepository duplicate request prevention', () {
    test('createRequest twice for same ride+member throws', () async {
      final repo = DemoRepository();
      final rides = await repo.getRides();
      // ride-6 has no seeded requests, so the first create is clean.
      final ride = rides.firstWhere((r) => r.id == 'ride-6');

      await repo.createRequest(rideId: ride.id, memberId: 'member-1');
      expect(
        () => repo.createRequest(rideId: ride.id, memberId: 'member-1'),
        throwsStateError,
      );
    });
  });

  group('AppState.searchRides', () {
    test('filters by from/to/date', () async {
      final state = AppState(repo: DemoRepository());
      await state.init();
      expect(state.rides.length, 8);

      final fromKakkanad = state.searchRides(from: 'Kakkanad');
      expect(fromKakkanad, isNotEmpty);
      expect(
        fromKakkanad.every(
          (r) => r.fromLocation.toLowerCase().contains('kakkanad'),
        ),
        isTrue,
      );

      final toKochi = state.searchRides(to: 'Kochi');
      expect(toKochi, isNotEmpty);
      expect(
        toKochi.every((r) => r.toLocation.toLowerCase().contains('kochi')),
        isTrue,
      );

      final date = state.rides.first.travelDate;
      final onDate = state.searchRides(date: date);
      expect(onDate, isNotEmpty);
      expect(
        onDate.every(
          (r) =>
              r.travelDate.year == date.year &&
              r.travelDate.month == date.month &&
              r.travelDate.day == date.day,
        ),
        isTrue,
      );

      final combined = state.searchRides(
        from: 'Kakkanad',
        to: 'Infopark',
        date: date,
      );
      // Only ride-1 matches all three on its own travel date.
      expect(combined.map((r) => r.id), contains('ride-1'));
      expect(combined.length, 1);
    });
  });
}
