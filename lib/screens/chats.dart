import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

/// Chats list: conversations with unread badge, last message + time.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final me = state.currentUser;
        if (me == null) {
          return const HopEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Not signed in',
              subtitle: 'Sign in to see your chats.');
        }
        final convos = state.conversations;
        if (convos.isEmpty) {
          return const HopEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No chats yet',
            subtitle:
                'Message a host from any ride card to ask about the trip before you join.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: convos.length,
          itemBuilder: (context, i) {
            final convo = convos[i];
            final otherId =
                convo.hostId == me.id ? convo.memberId : convo.hostId;
            final other = state.profileById(otherId);
            final ride = state.rides
                .where((r) => r.id == convo.rideId)
                .firstOrNull;
            final messages = state.messagesByConversation[convo.id] ?? [];
            final last = messages.isEmpty ? null : messages.last;
            final unread = state.unreadMessagesCount(convo.id);
            return ListTile(
              leading: HopAvatar(
                  photoUrl: other?.avatarUrl ?? '',
                  name: other?.fullName ?? 'Rider',
                  radius: 26),
              title: Text(other?.fullName ?? 'Rider',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                last == null
                    ? (ride == null
                        ? 'Say hello!'
                        : '${ride.fromLocation} → ${ride.toLocation}')
                    : last.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (last != null)
                    Text(_timeAgo(last.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: HopColors.inkSoft)),
                  if (unread > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: const BoxDecoration(
                          color: HopColors.peachDeep,
                          shape: BoxShape.circle),
                      child: Text('$unread',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  ],
                ],
              ),
              onTap: () => Navigator.of(context)
                  .pushNamed('/chat', arguments: convo.id),
            );
          },
        );
      },
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return formatDate(t);
  }
}
