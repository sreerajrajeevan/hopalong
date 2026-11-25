import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

/// Rider home: create ride, upcoming rides, pending requests,
/// accepted members, completed / cancelled.
class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final user = state.currentUser;
        final myRides = state.rides
            .where((r) => r.hostId == user?.id)
            .toList()
          ..sort((a, b) => a.travelDate.compareTo(b.travelDate));
        final active =
            myRides.where((r) => r.status == 'active').toList();
        final completed =
            myRides.where((r) => r.status == 'completed').toList();
        final cancelled =
            myRides.where((r) => r.status == 'cancelled').toList();
        final pending = state.pendingRequestsForMyRides;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                HopAvatar(
                    photoUrl: user?.avatarUrl ?? '',
                    name: user?.fullName ?? 'Rider',
                    radius: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your dashboard',
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(user?.fullName.split(' ').first ?? 'Rider',
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/notifications'),
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined, size: 26),
                      if (state.unreadNotificationCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                color: HopColors.peachDeep,
                                shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/create-ride'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create a Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HopColors.peachDeep,
                  padding:
                      const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionTitle(title: 'Pending requests (${pending.length})'),
              const SizedBox(height: 12),
              ...pending.map((req) => _PendingRequestCard(
                  state: state, request: req)),
            ],
            const SizedBox(height: 24),
            const SectionTitle(title: 'Upcoming rides'),
            const SizedBox(height: 12),
            if (active.isEmpty)
              const HopEmptyState(
                icon: Icons.directions_car_outlined,
                title: 'No upcoming rides',
                subtitle: 'Create your first ride and share your empty seats!',
              )
            else
              ...active.map((ride) => _MyRideCard(state: state, ride: ride)),
            if (completed.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionTitle(title: 'Completed (${completed.length})'),
              const SizedBox(height: 12),
              ...completed.map((ride) => _MyRideCard(state: state, ride: ride)),
            ],
            if (cancelled.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionTitle(title: 'Cancelled (${cancelled.length})'),
              const SizedBox(height: 12),
              ...cancelled.map((ride) => _MyRideCard(state: state, ride: ride)),
            ],
          ],
        );
      },
    );
  }
}

class _MyRideCard extends StatelessWidget {
  const _MyRideCard({required this.state, required this.ride});

  final AppState state;
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final pending =
        state.requestsForRide(ride.id).where((r) => r.status == 'pending').length;
    final accepted = state.requestsForRide(ride.id)
        .where((r) => r.status == 'accepted')
        .length;
    final status =
        rideStatus(seatsLeft: ride.seatsLeft, totalSeats: ride.totalSeats);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () =>
            Navigator.of(context).pushNamed('/ride', arguments: ride.id),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${ride.fromLocation} → ${ride.toLocation}',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (ride.status == 'active')
                    RideStatusChip(status: status)
                  else
                    Chip(
                        label: Text(ride.status == 'completed'
                            ? 'Completed'
                            : 'Cancelled')),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                  '${formatDate(ride.travelDate)} · ${formatTimeOfDay(ride.departureHour, ride.departureMinute)} · ${ride.vehicleType == 'car' ? 'Car' : 'Bike'} · ${ride.vehicleModel}'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MiniStat(
                      icon: Icons.event_seat_rounded,
                      label: '${ride.seatsLeft}/${ride.totalSeats} seats'),
                  const SizedBox(width: 16),
                  _MiniStat(
                      icon: Icons.hourglass_top_rounded,
                      label: '$pending pending'),
                  const SizedBox(width: 16),
                  _MiniStat(
                      icon: Icons.group_rounded, label: '$accepted joined'),
                ],
              ),
              if (ride.status == 'active' && pending > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'You have $pending request${pending == 1 ? '' : 's'} waiting below.',
                    style: const TextStyle(
                        color: HopColors.peachDeep,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: HopColors.sage),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({required this.state, required this.request});

  final AppState state;
  final RideRequest request;

  @override
  Widget build(BuildContext context) {
    final member = state.profileById(request.memberId);
    final ride = state.rides
        .where((r) => r.id == request.rideId)
        .firstOrNull;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HopAvatar(
                    photoUrl: member?.avatarUrl ?? '',
                    name: member?.fullName ?? 'Member',
                    radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member?.fullName ?? 'Member',
                          style: Theme.of(context).textTheme.titleMedium),
                      if (member != null)
                        Text(
                            '${ageFromDob(member.dob)} · ${member.gender}',
                            style:
                                Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (member != null) {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HopAvatar(
                                  photoUrl: member.avatarUrl,
                                  name: member.fullName,
                                  radius: 40),
                              const SizedBox(height: 12),
                              Text(member.fullName,
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .titleMedium),
                              Text(
                                  '${ageFromDob(member.dob)} · ${member.gender}'),
                              Text(
                                  '${member.completedRides} rides completed'),
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(),
                                child: const Text('Close')),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Text('View profile'),
                ),
              ],
            ),
            if (ride != null) ...[
              const SizedBox(height: 8),
              Text('${ride.fromLocation} → ${ride.toLocation} · '
                  '${formatDate(ride.travelDate)}'),
            ],
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: HopColors.peachSoft,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('“${request.message}”',
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await state.acceptRequest(request.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Accepted! They are now on your ride.')));
                        }
                      } on StateError catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(e.message == 'full'
                                      ? 'No seats left on this ride.'
                                      : e.message)));
                        }
                      }
                    },
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await state.rejectRequest(request.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Request declined politely.')));
                      }
                    },
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
