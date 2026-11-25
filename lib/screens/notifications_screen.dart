import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

/// Notifications list: tap navigates to the ride/chat; mark-all-read.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => state.markAllNotificationsRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final notes = state.notifications;
          if (notes.isEmpty) {
            return const HopEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'All quiet here',
              subtitle: 'Ride updates, requests and messages will pop up here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notes.length,
            itemBuilder: (context, i) {
              final n = notes[i];
              return ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: n.read ? HopColors.surfaceSoft : HopColors.peachSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconFor(n.type),
                      color: n.read ? HopColors.inkSoft : HopColors.peachDeep),
                ),
                title: Text(n.title,
                    style: TextStyle(
                        fontWeight:
                            n.read ? FontWeight.w500 : FontWeight.w800)),
                subtitle: Text(n.body),
                trailing: Text(_timeAgo(n.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: HopColors.inkSoft)),
                onTap: () async {
                  await state.markNotificationRead(n.id);
                  if (!context.mounted) return;
                  if (n.conversationId != null) {
                    Navigator.of(context)
                        .pushNamed('/chat', arguments: n.conversationId);
                  } else if (n.rideId != null) {
                    Navigator.of(context)
                        .pushNamed('/ride', arguments: n.rideId);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'request' => Icons.person_add_alt_rounded,
      'accepted' => Icons.check_circle_rounded,
      'rejected' => Icons.cancel_outlined,
      'message' => Icons.chat_bubble_rounded,
      'cancellation' => Icons.event_busy_rounded,
      'modification' => Icons.edit_rounded,
      'reminder' => Icons.alarm_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return formatDate(t);
  }
}
