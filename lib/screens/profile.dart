import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../models.dart';
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
                      '${ageGender(user.dob, user.gender)} · ${user.completedRides} rides completed',
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
                    borderRadius: BorderRadius.circular(18)),
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
                        final ok = await state.setMode(s.first);
                        if (context.mounted) {
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Switched to ${s.first == 'member' ? 'Member' : 'Rider'} mode.')));
                          } else {
                            showHopError(context, state.error);
                          }
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
                if (state.isAdmin)
                  _Tile(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Manage users (admin)',
                    onTap: () => Navigator.of(context).pushNamed('/admin'),
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
    final user = state.currentUser;
    if (user == null) return;
    final result = await showDialog<_EditProfileResult>(
      context: context,
      builder: (_) => _EditProfileDialog(user: user),
    );
    if (result == null) return;
    final newName = result.name.trim();
    if (newName.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Name cannot be empty — nothing was changed.')));
      }
      return;
    }
    final ok = await state.updateProfile(
        user.copyWith(fullName: newName, gender: result.gender));
    if (context.mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated.')));
      } else {
        showHopError(context, state.error);
      }
    }
  }

  Future<void> _notificationPrefs(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
      final done = await state.deleteAccount();
      if (context.mounted) {
        if (done) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        } else {
          showHopError(context, state.error);
        }
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

/// What the edit-profile dialog hands back on Save (null on Cancel).
class _EditProfileResult {
  const _EditProfileResult({required this.name, required this.gender});

  final String name;
  final String gender;
}

/// Edit-profile dialog. It owns its [TextEditingController] so the
/// controller lives exactly as long as the dialog's text field: disposing
/// a controller while the dialog is still animating out crashes the app
/// with a red screen ("used after being disposed").
class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.user});

  final Profile user;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  // A stored gender outside the four options (old row, blank value)
  // would make the dropdown throw on open — fall back to a valid one.
  static const _genderOptions = [
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];

  late final TextEditingController _name =
      TextEditingController(text: widget.user.fullName);
  late String _gender = _genderOptions.contains(widget.user.gender)
      ? widget.user.gender
      : 'Prefer not to say';

  @override
  void dispose() {
    // Runs only when the dialog route is fully unmounted, so the text
    // field is already gone by the time the controller is disposed.
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Edit profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            items: const [
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(
                  value: 'Non-binary', child: Text('Non-binary')),
              DropdownMenuItem(
                  value: 'Prefer not to say',
                  child: Text('Prefer not to say')),
            ],
            onChanged: (v) => setState(() => _gender = v ?? _gender),
            decoration: const InputDecoration(labelText: 'Gender'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_EditProfileResult(
                name: _name.text, gender: _gender)),
            child: const Text('Save')),
      ],
    );
  }
}
