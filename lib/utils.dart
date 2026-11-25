import 'package:intl/intl.dart';

/// Returns the whole-years age on [now] (defaults to [DateTime.now]).
int ageFromDob(DateTime dob, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  var age = ref.year - dob.year;
  if (ref.month < dob.month ||
      (ref.month == dob.month && ref.day < dob.day)) {
    age--;
  }
  return age;
}

/// True iff the person is at least 18 on [now]. A future DOB is never adult.
bool isAdult(DateTime dob, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  if (dob.isAfter(ref)) return false;
  return ageFromDob(dob, now: ref) >= 18;
}

enum RideStatus { available, fillingFast, full }

RideStatus rideStatus({required int seatsLeft, required int totalSeats}) {
  if (seatsLeft <= 0 || totalSeats <= 0) return RideStatus.full;
  if (seatsLeft <= 1 || seatsLeft / totalSeats <= 0.25) {
    return RideStatus.fillingFast;
  }
  return RideStatus.available;
}

String formatDate(DateTime d) => DateFormat('EEE, d MMM yyyy').format(d);

/// Formats hour/minute (24h) as e.g. "9:30 AM" without a BuildContext.
String formatTimeOfDay(int hour, int minute) {
  final period = hour >= 12 ? 'PM' : 'AM';
  var h12 = hour % 12;
  if (h12 == 0) h12 = 12;
  return '$h12:${minute.toString().padLeft(2, '0')} $period';
}

String formatContribution(double? amount) {
  if (amount == null || amount <= 0) return 'Free ride';
  final text = amount.truncateToDouble() == amount
      ? amount.toInt().toString()
      : amount.toStringAsFixed(2);
  return '₹$text / person';
}

/// Case-insensitive contains match over [history], max 5 results.
/// An empty query returns up to 5 most recent entries ([history] is
/// ordered most-recent-first).
List<String> locationSuggestions(String query, List<String> history) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return history.take(5).toList();
  return history
      .where((loc) => loc.toLowerCase().contains(q))
      .take(5)
      .toList();
}
