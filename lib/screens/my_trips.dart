import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ride_card.dart';

/// My Trips: Upcoming / Pending / Completed / Cancelled.
class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Trips'),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: HopColors.sage,
            unselectedLabelColor: HopColors.inkSoft,
            indicatorColor: HopColors.sage,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Pending'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: state,
          builder: (context, _) {
            final me = state.currentUser;
            if (me == null) {
              return const HopEmptyState(
                  icon: Icons.directions_car_outlined,
                  title: 'Not signed in',
                  subtitle: 'Sign in to see your trips.');
            }
            final myReqs = state.myRequests;
            Ride? rideFor(String rideId) => state.rides
                .where((r) => r.id == rideId)
                .firstOrNull;
            final upcoming = myReqs
                .where((r) => r.status == 'accepted')
                .map((r) => rideFor(r.rideId))
                .whereType<Ride>()
                .where((r) => r.status == 'active')
                .toList();
            // Also include rides I host that are active.
            for (final ride in state.rides.where((r) =>
                r.hostId == me.id && r.status == 'active')) {
              if (!upcoming.any((r) => r.id == ride.id)) upcoming.add(ride);
            }
            final pending = myReqs
                .where((r) => r.status == 'pending')
                .map((r) => rideFor(r.rideId))
                .whereType<Ride>()
                .where((r) => r.status == 'active')
                .toList();
            final completed = myReqs
                .where((r) => r.status == 'accepted')
                .map((r) => rideFor(r.rideId))
                .whereType<Ride>()
                .where((r) => r.status == 'completed')
                .toList();
            for (final ride in state.rides.where((r) =>
                r.hostId == me.id && r.status == 'completed')) {
              if (!completed.any((r) => r.id == ride.id)) completed.add(ride);
            }
            final cancelled = <Ride>{};
            for (final req in myReqs.where((r) =>
                r.status == 'withdrawn' ||
                r.status == 'cancelled' ||
                r.status == 'rejected')) {
              final ride = rideFor(req.rideId);
              if (ride != null) cancelled.add(ride);
            }
            for (final ride in state.rides.where((r) =>
                (r.hostId == me.id && r.status == 'cancelled'))) {
              cancelled.add(ride);
            }
            return TabBarView(
              children: [
                _TripList(
                    state: state,
                    rides: upcoming,
                    emptyTitle: 'No upcoming trips',
                    emptySubtitle:
                        'Rides you join or host will show up here.'),
                _TripList(
                    state: state,
                    rides: pending,
                    emptyTitle: 'No pending requests',
                    emptySubtitle:
                        'Requests waiting for the host\'s reply live here.'),
                _TripList(
                    state: state,
                    rides: completed,
                    emptyTitle: 'No completed trips yet',
                    emptySubtitle: 'Finished rides will gather here.'),
                _TripList(
                    state: state,
                    rides: cancelled.toList(),
                    emptyTitle: 'Nothing cancelled',
                    emptySubtitle: 'Cancelled or withdrawn trips show here.'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  const _TripList(
      {required this.state,
      required this.rides,
      required this.emptyTitle,
      required this.emptySubtitle});

  final AppState state;
  final List<Ride> rides;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) {
      return HopEmptyState(
          icon: Icons.luggage_rounded,
          title: emptyTitle,
          subtitle: emptySubtitle);
    }
    final sorted = [...rides]
      ..sort((a, b) => a.travelDate.compareTo(b.travelDate));
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final ride = sorted[i];
        final isHost = state.currentUser?.id == ride.hostId;
        final myReq = state.myRequests
            .where((r) => r.rideId == ride.id)
            .where((r) => r.status == 'pending' || r.status == 'accepted')
            .firstOrNull;
        final confirmed = state.requestsForRide(ride.id)
            .where((r) => r.status == 'accepted')
            .toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RideCard(
                ride: ride,
                state: state,
                showJoinButton: false,
                onTap: () => Navigator.of(context)
                    .pushNamed('/ride', arguments: ride.id),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isHost && ride.status == 'active') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await state.completeRide(ride.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Ride marked as completed.')));
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Mark completed'),
                      ),
                    ),
                  ] else if (myReq != null && myReq.status == 'pending') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await state.withdrawRequest(myReq.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Request withdrawn.')));
                          }
                        },
                        child: const Text('Withdraw request'),
                      ),
                    ),
                  ] else if (myReq != null && myReq.status == 'accepted' &&
                      ride.status == 'active') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await state.withdrawRequest(myReq.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Your seat has been cancelled.')));
                          }
                        },
                        child: const Text('Cancel my seat'),
                      ),
                    ),
                  ],
                  if (confirmed.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: HopColors.sageSoft,
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.group_rounded,
                              size: 18, color: HopColors.sage),
                          const SizedBox(width: 6),
                          Text('${confirmed.length} confirmed',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
