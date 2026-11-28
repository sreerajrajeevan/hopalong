import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import 'common.dart';

/// Social-style ride card: host, dotted journey, details, join/message.
class RideCard extends StatelessWidget {
  const RideCard({
    super.key,
    required this.ride,
    required this.state,
    this.onTap,
    this.showJoinButton = true,
  });

  final Ride ride;
  final AppState state;
  final VoidCallback? onTap;
  final bool showJoinButton;

  @override
  Widget build(BuildContext context) {
    final host = state.profileById(ride.hostId);
    final status = rideStatus(seatsLeft: ride.seatsLeft, totalSeats: ride.totalSeats);
    final myRequest = state.myRequests
        .where((r) => r.rideId == ride.id)
        .where((r) => r.status == 'pending' || r.status == 'accepted')
        .firstOrNull;
    final isMine = state.currentUser?.id == ride.hostId;
    final blocked = host != null && state.isBlocked(host.id);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HopAvatar(
                      photoUrl: host?.avatarUrl ?? '',
                      name: host?.fullName ?? 'HopAlong rider',
                      radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(host?.fullName ?? 'HopAlong rider',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontSize: 16)),
                        if (host != null)
                          Text(
                              ageGender(host.dob, host.gender),
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  RideStatusChip(status: status),
                ],
              ),
              const SizedBox(height: 18),
              JourneyGraphic(from: ride.fromLocation, to: ride.toLocation),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                      icon: ride.vehicleType == 'car'
                          ? Icons.directions_car_rounded
                          : Icons.two_wheeler_rounded,
                      label:
                          '${ride.vehicleType == 'car' ? 'Car' : 'Bike'} · ${ride.vehicleModel}'),
                  _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: formatDate(ride.travelDate)),
                  _InfoChip(
                      icon: Icons.schedule_rounded,
                      label: formatTimeOfDay(
                          ride.departureHour, ride.departureMinute)),
                  _InfoChip(
                      icon: Icons.event_seat_rounded,
                      label:
                          '${ride.seatsLeft} of ${ride.totalSeats} seats left'),
                  if (ride.contribution != null)
                    _InfoChip(
                        icon: Icons.handshake_rounded,
                        label: formatContribution(ride.contribution)),
                ],
              ),
              if (ride.notes.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(ride.notes,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
              if (showJoinButton) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isMine || blocked || status == RideStatus.full
                            ? null
                            : () => _requestToJoin(context),
                        child: Text(myRequest == null
                            ? 'Request to Join'
                            : myRequest.status == 'accepted'
                                ? 'You\'re in ✓'
                                : 'Requested · Pending'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: blocked || isMine
                          ? null
                          : () => _messageHost(context),
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 18),
                      label: const Text('Message'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestToJoin(BuildContext context) async {
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Request to join'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Say a quick hello to ${state.profileById(ride.hostId)?.fullName ?? 'the host'}. A short note helps!',
                  style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLength: 140,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Hi! I\'d love to join your ride…'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(controller.text.trim()),
                child: const Text('Send request')),
          ],
        );
      },
    );
    if (message == null || !context.mounted) return;
    final ok = await state.sendJoinRequest(ride.id,
        message: message.isEmpty ? null : message);
    if (context.mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Request sent! The host will let you know soon.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyJoinError(state.error))));
      }
    }
  }

  Future<void> _messageHost(BuildContext context) async {
    final convo = await state.openConversation(
        rideId: ride.id, hostId: ride.hostId);
    if (!context.mounted) return;
    if (convo == null) {
      showHopError(context, state.error);
      return;
    }
    Navigator.of(context).pushNamed('/chat', arguments: convo.id);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: HopColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: HopColors.sage),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
