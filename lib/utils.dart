import 'package:intl/intl.dart';

/// Returns the whole-years age on [now] (defaults to [DateTime.now]).
/// Null when no date of birth was shared.
int? ageFromDob(DateTime? dob, {DateTime? now}) {
  if (dob == null) return null;
  final ref = now ?? DateTime.now();
  var age = ref.year - dob.year;
  if (ref.month < dob.month ||
      (ref.month == dob.month && ref.day < dob.day)) {
    age--;
  }
  return age;
}

/// True iff the person is at least 18 on [now]. A future DOB is never adult.
/// No DOB on file means "not proven underage" — true, so an optional DOB
/// never blocks signup.
bool isAdult(DateTime? dob, {DateTime? now}) {
  if (dob == null) return true;
  final ref = now ?? DateTime.now();
  if (dob.isAfter(ref)) return false;
  return (ageFromDob(dob, now: ref) ?? 0) >= 18;
}

/// Short age text for profile lines: '26' or null when no DOB was shared.
String? ageText(DateTime? dob) {
  final age = ageFromDob(dob);
  return age == null ? null : '$age';
}

/// Clamps a stored travel date into the picker's valid window
/// [today, today + 60 days]. showDatePicker asserts the initial date is
/// inside that window, and a date stored at midnight is *before*
/// DateTime.now() (which carries the current time) — so an unclamped
/// "today" crashes the picker on the second tap.
DateTime clampPickerDate(DateTime? date, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final first = DateTime(ref.year, ref.month, ref.day);
  final last = first.add(const Duration(days: 60));
  if (date == null) return first;
  if (date.isBefore(first)) return first;
  if (date.isAfter(last)) return last;
  return date;
}

/// The login email for a mobile number: `<digits>@hopalong.app`.
/// The app never shows this address; users sign in with their number and
/// password. Must match the manage-users Edge Function exactly.
String loginEmailForPhone(String phone) {
  final d = phone.replaceAll(RegExp(r'\D'), '');
  final digits = d.length == 10
      ? '91$d'
      : (d.length == 12 && d.startsWith('91'))
          ? d
          : (d.length == 11 && d.startsWith('0'))
              ? '91${d.substring(1)}'
              : d;
  return '$digits@hopalong.app';
}

/// "26 · Female", or just "Female" when no DOB was shared.
String ageGender(DateTime? dob, String gender) {
  final age = ageFromDob(dob);
  return age == null ? gender : '$age · $gender';
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
