import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

const List<String> reportReasons = [
  'Suspicious behaviour',
  'Inappropriate content',
  'Fake ride / no-show',
  'Harassment',
  'Spam or scam',
  'Something else',
];

/// Report user / ride dialog.
Future<void> showReportDialog(BuildContext context, AppState state,
    {String? rideId, String? reportedUserId}) async {
  String reason = reportReasons.first;
  final details = TextEditingController();
  final submitted = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Thanks for keeping HopAlong safe. Reports are reviewed by our moderators.'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: reason,
              items: reportReasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setLocal(() => reason = v ?? reason),
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: details,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                  hintText: 'What happened?'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Submit report')),
        ],
      ),
    ),
  );
  details.dispose();
  if (submitted != true) return;
  final user = state.currentUser;
  if (user == null) return;
  await state.submitReport(Report(
    id: 'rep-${DateTime.now().millisecondsSinceEpoch}',
    reporterId: user.id,
    reportedUserId: reportedUserId,
    rideId: rideId,
    reason: reason,
    details: details.text.trim().isEmpty ? null : details.text.trim(),
    status: 'open',
    createdAt: DateTime.now(),
  ));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Report submitted. Thank you for looking out.')));
  }
}

/// Community guidelines screen.
class GuidelinesScreen extends StatelessWidget {
  const GuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Be kind, always',
          'Say hello, be on time, and treat fellow travellers like neighbours.'),
      ('Show up',
          'If you can\'t make it, cancel early so someone else can take the seat.'),
      ('Adults only',
          'HopAlong is for people 18 and older, with a real photo on their profile.'),
      ('Keep it in the app',
          'Chat here first. Never share phone numbers or payment details publicly.'),
      ('Share fairly',
          'Contributions are voluntary and agreed in advance — no haggling on the road.'),
      ('Report, don\'t confront',
          'See something off? Report it. Our moderators will take a look.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Community Guidelines')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'HopAlong is a friendly community, not a taxi service. '
            'These few rules keep every ride pleasant.',
            style: TextStyle(color: HopColors.inkSoft, fontSize: 15),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.favorite_rounded,
                      color: HopColors.peachDeep),
                  title: Text(item.$1,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(item.$2),
                ),
              )),
        ],
      ),
    );
  }
}

/// Privacy policy screen (summary).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          'HopAlong collects only what it needs to run a friendly ride community:\n\n'
          '• Your name, age, gender and profile photo — shown to other members so they know who they are travelling with.\n'
          '• Your mobile number and email — used only to sign you in. They are never shown publicly.\n'
          '• Your rides, join requests and chats — visible only to the people involved in that ride.\n'
          '• We do not track your live location, and we do not sell your data.\n\n'
          'You can delete your account at any time from Profile → Delete account. '
          'Deleting removes your profile, rides, requests and messages.\n\n'
          'Questions? Write to us from Help & Support.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
      ),
    );
  }
}

/// Help & support screen.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _HelpTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Chat with us',
              subtitle: 'We usually reply within a day.'),
          _HelpTile(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: 'hello@hopalong.app'),
          _HelpTile(
              icon: Icons.question_answer_outlined,
              title: 'Common questions',
              subtitle:
                  'How do I join a ride? Tap "Request to Join" on any ride card — the host approves you.\n\n'
                  'Can I cancel? Yes — withdraw a pending request or cancel your seat from My Trips.\n\n'
                  'Is there a fee? No. Contributions are optional and agreed between you and the host.'),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile(
      {required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: HopColors.sage),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

/// Basic admin moderation dashboard (demo admin).
class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moderation (demo admin)')),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final reports = state.reports;
          if (reports.isEmpty) {
            return const HopEmptyState(
              icon: Icons.shield_outlined,
              title: 'No reports',
              subtitle: 'Nothing to review right now. Nice and quiet!',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reports.length,
            itemBuilder: (context, i) {
              final report = reports[i];
              final reporter = state.profileById(report.reporterId);
              final reported = report.reportedUserId == null
                  ? null
                  : state.profileById(report.reportedUserId!);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(report.reason,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                          ),
                          Chip(
                              label: Text(report.status),
                              backgroundColor: report.status == 'open'
                                  ? HopColors.peachSoft
                                  : HopColors.sageSoft),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                          'Reported by ${reporter?.fullName ?? 'someone'}'
                          '${reported != null ? ' about ${reported.fullName}' : ''}'
                          '${report.rideId != null ? ' · ride ${report.rideId!.substring(0, 8)}…' : ''}'),
                      if (report.details != null) ...[
                        const SizedBox(height: 6),
                        Text(report.details!),
                      ],
                      if (report.status == 'open') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    state.resolveReport(report.id, 'resolved'),
                                child: const Text('Resolve'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => state.resolveReport(
                                    report.id, 'dismissed'),
                                child: const Text('Dismiss'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
