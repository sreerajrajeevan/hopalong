import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'safety.dart';

/// Chat detail: pinned ride card, messages, read receipts,
/// inline accept/reject for a pending request, block/report menu.
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen(
      {super.key, required this.state, required this.conversationId});

  final AppState state;
  final String conversationId;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    widget.state.loadMessages(widget.conversationId).then((_) {
      widget.state.markMessagesRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    await widget.state.sendMessage(widget.conversationId, text);
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final state = widget.state;
        final convo = state.conversations
            .where((c) => c.id == widget.conversationId)
            .firstOrNull;
        if (convo == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const HopEmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat not found',
                subtitle: 'It may have been removed.'),
          );
        }
        final me = state.currentUser!;
        final isHost = convo.hostId == me.id;
        final otherId = isHost ? convo.memberId : convo.hostId;
        final other = state.profileById(otherId);
        final ride = state.rides
            .where((r) => r.id == convo.rideId)
            .firstOrNull;
        final messages = state.messagesByConversation[convo.id] ?? [];
        final pendingRequest = isHost
            ? state.requestsForRide(convo.rideId)
                .where((r) => r.memberId == convo.memberId)
                .where((r) => r.status == 'pending')
                .firstOrNull
            : null;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                HopAvatar(
                    photoUrl: other?.avatarUrl ?? '',
                    name: other?.fullName ?? 'Rider',
                    radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(other?.fullName ?? 'Rider',
                          style: const TextStyle(fontSize: 16)),
                      if (other != null)
                        Text('${ageFromDob(other.dob)} · ${other.gender}',
                            style: const TextStyle(
                                fontSize: 12, color: HopColors.inkSoft)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'report') {
                    await showReportDialog(context, state,
                        rideId: convo.rideId, reportedUserId: otherId);
                  } else if (v == 'block') {
                    await state.blockUser(otherId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('User blocked.')));
                      Navigator.of(context).pop();
                    }
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'report', child: Text('Report user')),
                  PopupMenuItem(value: 'block', child: Text('Block user')),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (ride != null)
                InkWell(
                  onTap: () => Navigator.of(context)
                      .pushNamed('/ride', arguments: ride.id),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: HopColors.sageSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car_rounded,
                            color: HopColors.sage),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${ride.fromLocation} → ${ride.toLocation}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(
                                  '${formatDate(ride.travelDate)} · ${formatTimeOfDay(ride.departureHour, ride.departureMinute)} · ${ride.seatsLeft} seats left',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: HopColors.inkSoft),
                      ],
                    ),
                  ),
                ),
              if (pendingRequest != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: HopColors.peachSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${other?.fullName ?? 'This member'} asked to join your ride.',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (pendingRequest.message != null &&
                          pendingRequest.message!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('“${pendingRequest.message}”',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic)),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await state
                                    .acceptRequest(pendingRequest.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Accepted! They are on your ride.')));
                                }
                              },
                              child: const Text('Accept'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await state
                                    .rejectRequest(pendingRequest.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
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
              Expanded(
                child: messages.isEmpty
                    ? const HopEmptyState(
                        icon: Icons.waving_hand_rounded,
                        title: 'Say hello!',
                        subtitle:
                            'Ask about pickup points, luggage space, or music taste.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final msg = messages[i];
                          final mine = msg.senderId == me.id;
                          final showDate = i == 0 ||
                              !_sameDay(messages[i - 1].createdAt,
                                  msg.createdAt);
                          return Column(
                            children: [
                              if (showDate)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: HopColors.surfaceSoft,
                                        borderRadius:
                                            BorderRadius.circular(999)),
                                    child: Text(formatDate(msg.createdAt),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: HopColors.inkSoft)),
                                  ),
                                ),
                              Align(
                                alignment: mine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.72),
                                  decoration: BoxDecoration(
                                    color: mine
                                        ? HopColors.sage
                                        : HopColors.surface,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: Radius.circular(
                                          mine ? 18 : 4),
                                      bottomRight: Radius.circular(
                                          mine ? 4 : 18),
                                    ),
                                    border: mine
                                        ? null
                                        : Border.all(color: HopColors.line),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(msg.body,
                                          style: TextStyle(
                                              color: mine
                                                  ? Colors.white
                                                  : HopColors.ink)),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              formatTimeOfDay(
                                                  msg.createdAt.hour,
                                                  msg.createdAt.minute),
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: mine
                                                      ? Colors.white70
                                                      : HopColors.inkSoft)),
                                          if (mine) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              msg.isRead
                                                  ? Icons.done_all_rounded
                                                  : Icons.done_rounded,
                                              size: 14,
                                              color: msg.isRead
                                                  ? Colors.white
                                                  : Colors.white70,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (mine && msg.isRead && i == messages.length - 1)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6, top: 2),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('Seen',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: HopColors.inkSoft)),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(
                              hintText: 'Type a message…'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: const BoxDecoration(
                            color: HopColors.sage, shape: BoxShape.circle),
                        child: IconButton(
                          onPressed: _send,
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
