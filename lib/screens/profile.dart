import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'safety.dart';

/// Profile: photo, details, mode switch, settings, safety, account.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final user = state.currentUser;
        if (user == null) {
          return const HopEmptyState(
              icon: Icons.person_outline_rounded,
              title: 'Not signed in',
              subtitle: 'Sign in to see your profile.');
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  HopAvatar(
                      photoUrl: user.avatarUrl,
                      name: user.fullName,
                      radius: 52),
                  const SizedBox(height: 12),
                  Text(user.fullName,
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text(
                      '${ageFromDob(user.dob)} · ${user.gender} · ${user.completedRides} rides completed',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: HopColors.inkSoft)),
                ],
              ),
            ),
            if (AppConfig.isDemoMode) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: HopColors.peachSoft,
                    borderRadius: BorderRadius.circular(14)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: HopColors.peachDeep),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            'Demo mode — connect Supabase to go live.',
                            style:
                                TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('I want to',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'member',
                            icon: Icon(Icons.search_rounded),
                            label: Text('Find rides')),
                        ButtonSegment(
                            value: 'rider',
                            icon: Icon(Icons.directions_car_rounded),
                            label: Text('Offer rides')),
                      ],
                      selected: {state.mode},
                      onSelectionChanged: (s) async {
                        await state.setMode(s.first);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Switched to ${s.first == 'member' ? 'Member' : 'Rider'} mode.')));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.mode == 'member'
                          ? 'Member mode — browse rides and request to join.'
                          : 'Rider mode — post rides and welcome passengers.',
                      style: const TextStyle(color: HopColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Account',
              children: [
                _Tile(
                  icon: Icons.edit_outlined,
                  label: 'Edit profile',
                  onTap: () => _editProfile(context),
                ),
                _Tile(
                  icon: Icons.notifications_outlined,
                  label: 'Notification preferences',
                  onTap: () => _notificationPrefs(context),
                ),
                _Tile(
                  icon: Icons.block_outlined,
                  label: 'Blocked users',
                  trailing: state.blockedProfiles.isEmpty
                      ? null
                      : Text('${state.blockedProfiles.length}'),
                  onTap: () => _blockedUsers(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Community & safety',
              children: [
                _Tile(
                  icon: Icons.favorite_outline_rounded,
                  label: 'Community Guidelines',
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const GuidelinesScreen())),
                ),
                _Tile(
                  icon: Icons.shield_outlined,
                  label: 'Moderation (demo admin)',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ModerationScreen(state: state))),
                ),
                _Tile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HelpScreen())),
                ),
                _Tile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PrivacyScreen())),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Danger zone',
              children: [
                _Tile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete account',
                  danger: true,
                  onTap: () => _deleteAccount(context),
                ),
                _Tile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  danger: true,
                  onTap: () async {
                    await state.signOut();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (_) => false);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('HopAlong v0.1.0 · Made with care in Kerala',
                  style: TextStyle(fontSize: 12, color: HopColors.inkSoft)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final user = state.currentUser!;
    final name = TextEditingController(text: user.fullName);
    String gender = user.gender;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Edit profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration:
                    const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: gender,
                items: const [
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(
                      value: 'Non-binary', child: Text('Non-binary')),
                  DropdownMenuItem(
                      value: 'Prefer not to say',
                      child: Text('Prefer not to say')),
                ],
                onChanged: (v) => setLocal(() => gender = v ?? gender),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    final newName = name.text.trim();
    name.dispose();
    if (saved == true && newName.isNotEmpty) {
      await state.updateProfile(
          user.copyWith(fullName: newName, gender: gender));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated.')));
      }
    }
  }

  Future<void> _notificationPrefs(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Notification preferences'),
        content: AnimatedBuilder(
          animation: state,
          builder: (ctx, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: state.notificationPrefs.entries
                .map((e) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_prefLabel(e.key)),
                      value: e.value,
                      onChanged: (v) => state.setNotificationPref(e.key, v),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done')),
        ],
      ),
    );
  }

  String _prefLabel(String key) {
    return switch (key) {
      'request' => 'New join requests',
      'accepted' => 'Accepted requests',
      'rejected' => 'Rejected requests',
      'message' => 'New messages',
      'cancellation' => 'Ride cancellations',
      'modification' => 'Ride changes',
      'reminder' => 'Upcoming ride reminders',
      _ => key,
    };
  }

  Future<void> _blockedUsers(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Blocked users'),
        content: AnimatedBuilder(
          animation: state,
          builder: (ctx, _) {
            if (state.blockedProfiles.isEmpty) {
              return const Text('Nobody blocked. Peaceful, isn\'t it?');
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: state.blockedProfiles
                  .map((p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: HopAvatar(
                            photoUrl: p.avatarUrl,
                            name: p.fullName,
                            radius: 18),
                        title: Text(p.fullName),
                        trailing: TextButton(
                          onPressed: () => state.unblockUser(p.id),
                          child: const Text('Unblock'),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Delete your account?'),
        content: const Text(
            'This removes your profile, rides, requests and messages. '
            'It cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep my account')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete forever',
                  style: TextStyle(color: HopColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      await state.deleteAccount();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(title,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(
      {required this.icon,
      required this.label,
      this.trailing,
      this.danger = false,
      required this.onTap});

  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: danger ? HopColors.danger : HopColors.sage),
      title: Text(label,
          style: TextStyle(
              color: danger ? HopColors.danger : HopColors.ink)),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded, color: HopColors.inkSoft),
      onTap: onTap,
    );
  }
}
