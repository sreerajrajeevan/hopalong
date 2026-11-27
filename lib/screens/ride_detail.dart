import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'safety.dart';

/// Full ride detail: host card, journey, passengers, join/withdraw,
/// report, edit/cancel for the host.
class RideDetailScreen extends StatelessWidget {
  const RideDetailScreen({super.key, required this.state, required this.rideId});

  final AppState state;
  final String rideId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final ride = state.rides.where((r) => r.id == rideId).firstOrNull;
        if (ride == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const HopEmptyState(
                icon: Icons.search_off_rounded,
                title: 'Ride not found',
                subtitle: 'It may have been cancelled.'),
          );
        }
        final host = state.profileById(ride.hostId);
        final isHost = state.currentUser?.id == ride.hostId;
        final status =
            rideStatus(seatsLeft: ride.seatsLeft, totalSeats: ride.totalSeats);
        final confirmed = state.requestsForRide(ride.id)
            .where((r) => r.status == 'accepted')
            .toList();
        final myRequest = state.myRequests
            .where((r) => r.rideId == ride.id)
            .where((r) => r.status == 'pending' || r.status == 'accepted')
            .firstOrNull;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ride details'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'report') {
                    showReportDialog(context, state,
                        rideId: ride.id, reportedUserId: ride.hostId);
                  } else if (v == 'block') {
                    final ok = await state.blockUser(ride.hostId);
                    if (context.mounted) {
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Host blocked.')));
                      } else {
                        showHopError(context, state.error);
                      }
                    }
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                      value: 'report',
                      child: Text('Report this ride')),
                  PopupMenuItem(
                      value: 'block', child: Text('Block host')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HopAvatar(
                              photoUrl: host?.avatarUrl ?? '',
                              name: host?.fullName ?? 'Rider',
                              radius: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(host?.fullName ?? 'Rider',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                if (host != null)
                                  Text(
                                      '${ageGender(host.dob, host.gender)} · ${host.completedRides} rides completed',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                              ],
                            ),
                          ),
                          RideStatusChip(status: status),
                        ],
                      ),
                      const SizedBox(height: 18),
                      JourneyGraphic(
                          from: ride.fromLocation, to: ride.toLocation),
                      const SizedBox(height: 16),
                      _DetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: formatDate(ride.travelDate)),
                      _DetailRow(
                          icon: Icons.schedule_rounded,
                          label: 'Departure',
                          value: formatTimeOfDay(
                              ride.departureHour, ride.departureMinute)),
                      _DetailRow(
                          icon: ride.vehicleType == 'car'
                              ? Icons.directions_car_rounded
                              : Icons.two_wheeler_rounded,
                          label: 'Vehicle',
                          value:
                              '${ride.vehicleType == 'car' ? 'Car' : 'Bike'} · ${ride.vehicleModel}'),
                      _DetailRow(
                          icon: Icons.event_seat_rounded,
                          label: 'Seats',
                          value:
                              '${ride.seatsLeft} of ${ride.totalSeats} left'),
                      _DetailRow(
                          icon: Icons.handshake_rounded,
                          label: 'Contribution',
                          value: formatContribution(ride.contribution)),
                      _DetailRow(
                          icon: Icons.flag_rounded,
                          label: 'Pickup',
                          value: ride.pickupLandmark.isEmpty
                              ? '—'
                              : ride.pickupLandmark),
                      _DetailRow(
                          icon: Icons.flag_outlined,
                          label: 'Drop-off',
                          value: ride.dropoffLandmark.isEmpty
                              ? '—'
                              : ride.dropoffLandmark),
                      if (ride.notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(ride.notes,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                      if (ride.status != 'active')
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Chip(
                              label: Text(ride.status == 'completed'
                                  ? 'Completed'
                                  : 'Cancelled')),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SectionTitle(
                  title:
                      'Passengers (${confirmed.length}/${ride.totalSeats})'),
              const SizedBox(height: 10),
              if (confirmed.isEmpty)
                const Text('No confirmed passengers yet.',
                    style: TextStyle(color: HopColors.inkSoft))
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: confirmed.map((req) {
                    final member = state.profileById(req.memberId);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HopAvatar(
                            photoUrl: member?.avatarUrl ?? '',
                            name: member?.fullName ?? '?',
                            radius: 26),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 64,
                          child: Text(
                            member?.fullName.split(' ').first ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
              if (isHost) ...[
                if (ride.status == 'active') ...[
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pushNamed('/create-ride', arguments: ride),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit ride'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _completeRide(context, ride),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Mark as completed'),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => _cancelRide(context, ride),
                    icon: const Icon(Icons.cancel_outlined,
                        color: HopColors.danger),
                    label: const Text('Cancel ride',
                        style: TextStyle(color: HopColors.danger)),
                  ),
                ],
              ] else if (myRequest == null &&
                  ride.status == 'active' &&
                  status != RideStatus.full) ...[
                ElevatedButton(
                  onPressed: () => _join(context, ride),
                  child: const Text('Request to Join'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _messageHost(context, ride),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message host'),
                ),
              ] else if (myRequest != null &&
                  myRequest.status == 'pending') ...[
                OutlinedButton(
                  onPressed: () async {
                    final ok = await state.withdrawRequest(myRequest.id);
                    if (context.mounted) {
                      if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Request withdrawn.')));
                      } else {
                        showHopError(context, state.error);
                      }
                    }
                  },
                  child: const Text('Withdraw request'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _messageHost(context, ride),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message host'),
                ),
              ] else if (myRequest != null &&
                  myRequest.status == 'accepted') ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: HopColors.sageSoft,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: HopColors.sage),
                      SizedBox(width: 10),
                      Expanded(
                          child: Text(
                              'You\'re confirmed on this ride. See you there!')),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _messageHost(context, ride),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message host'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel your seat?'),
                        content: const Text(
                            'The host will be notified that you can no longer make it.'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(false),
                              child: const Text('Keep my seat')),
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(true),
                              child: const Text('Cancel seat')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      final done = await state.withdrawRequest(myRequest.id);
                      if (context.mounted) {
                        if (done) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Your seat has been cancelled.')));
                        } else {
                          showHopError(context, state.error);
                        }
                      }
                    }
                  },
                  child: const Text('Cancel my seat',
                      style: TextStyle(color: HopColors.danger)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _join(BuildContext context, Ride ride) async {
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Request to join'),
          content: TextField(
            controller: c,
            maxLength: 140,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Add a short message (optional)'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
                child: const Text('Send request')),
          ],
        );
      },
    );
    if (message == null || !context.mounted) return;
    final ok = await state.sendJoinRequest(ride.id,
        message: message.isEmpty ? null : message);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Request sent! The host will let you know soon.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyJoinError(state.error))));
    }
  }

  Future<void> _messageHost(BuildContext context, Ride ride) async {
    final convo =
        await state.openConversation(rideId: ride.id, hostId: ride.hostId);
    if (!context.mounted) return;
    if (convo == null) {
      showHopError(context, state.error);
      return;
    }
    Navigator.of(context).pushNamed('/chat', arguments: convo.id);
  }

  Future<void> _cancelRide(BuildContext context, Ride ride) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this ride?'),
        content: const Text(
            'Confirmed passengers will be notified right away.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep it')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Cancel ride',
                  style: TextStyle(color: HopColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      final done = await state.cancelRide(ride.id);
      if (context.mounted) {
        if (done) {
          Navigator.of(context).pop();
        } else {
          showHopError(context, state.error);
        }
      }
    }
  }

  Future<void> _completeRide(BuildContext context, Ride ride) async {
    final ok = await state.completeRide(ride.id);
    if (context.mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ride marked as completed. Thanks for hopping!')));
      } else {
        showHopError(context, state.error);
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: HopColors.sage),
          const SizedBox(width: 10),
          SizedBox(
              width: 86,
              child: Text(label,
                  style: const TextStyle(color: HopColors.inkSoft))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
