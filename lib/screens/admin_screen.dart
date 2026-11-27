import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Admin screen: add users, reset passwords, make/remove admins.
/// Only reachable when state.isAdmin is true.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.state});

  final AppState state;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _tempPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.state.loadAllProfiles();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _tempPassword.dispose();
    super.dispose();
  }

  bool _isValidMobile(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) return RegExp(r'^[6-9]').hasMatch(digits);
    if (digits.length == 12) {
      return digits.startsWith('91') && RegExp(r'^91[6-9]').hasMatch(digits);
    }
    if (digits.length == 11) {
      return digits.startsWith('0') && RegExp(r'^0[6-9]').hasMatch(digits);
    }
    return false;
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await widget.state.adminCreateUser(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      tempPassword: _tempPassword.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      showHopError(context, widget.state.error);
      return;
    }
    _name.clear();
    _phone.clear();
    _tempPassword.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'User added. Share their number and temporary password — they will pick their own on first sign-in.')));
  }

  Future<void> _resetPassword(Profile user) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Reset password for ${user.fullName}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'They will sign in with this temporary password, then must pick their own.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Temporary password (6+ characters)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reset')),
        ],
      ),
    );
    final temp = controller.text;
    controller.dispose();
    if (ok != true || temp.length < 6) {
      if (ok == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Temporary password must be 6+ characters.')));
      }
      return;
    }
    final done = await widget.state.adminSetPassword(
      userId: user.id,
      tempPassword: temp,
    );
    if (mounted) {
      if (done) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Password reset for ${user.fullName}. Share the temporary password with them.')));
      } else {
        showHopError(context, widget.state.error);
      }
    }
  }

  Future<void> _toggleAdmin(Profile user, bool makeAdmin) async {
    final done = await widget.state.adminSetAdmin(
      userId: user.id,
      makeAdmin: makeAdmin,
    );
    if (mounted && !done) showHopError(context, widget.state.error);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Scaffold(
      appBar: AppBar(title: const Text('Manage users')),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final me = state.currentUser;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Add a user',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          const Text(
                            'They sign in with their mobile number and the '
                            'temporary password, then pick their own.',
                            style: TextStyle(color: HopColors.inkSoft),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                                labelText: 'Full name *',
                                prefixIcon: Icon(Icons.person_outline_rounded)),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter their name.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                                labelText: 'Mobile number *',
                                prefixIcon: Icon(Icons.phone_outlined),
                                hintText: '98765 43210'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter their mobile number.';
                              }
                              if (!_isValidMobile(v.trim())) {
                                return 'Enter a valid 10-digit number.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _tempPassword,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Temporary password *',
                                prefixIcon:
                                    Icon(Icons.lock_outline_rounded)),
                            validator: (v) => v == null || v.length < 6
                                ? 'At least 6 characters.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _busy ? null : _addUser,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Add user'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Everyone (${state.allProfiles.length})',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...state.allProfiles.map((user) {
                  final isAdmin = state.adminIds.contains(user.id);
                  final isMe = me?.id == user.id;
                  return Card(
                    child: ListTile(
                      leading: HopAvatar(
                          photoUrl: user.avatarUrl,
                          name: user.fullName,
                          radius: 20),
                      title: Text(user.fullName),
                      subtitle: Text(
                        '${user.phone}'
                        '${isAdmin ? ' · Admin' : ''}'
                        '${user.mustResetPassword ? ' · Must reset password' : ''}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'reset') {
                            await _resetPassword(user);
                          } else if (v == 'make-admin') {
                            await _toggleAdmin(user, true);
                          } else if (v == 'remove-admin') {
                            await _toggleAdmin(user, false);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                              value: 'reset',
                              child: Text('Reset password')),
                          if (!isAdmin)
                            const PopupMenuItem(
                                value: 'make-admin',
                                child: Text('Make admin')),
                          if (isAdmin && !isMe)
                            const PopupMenuItem(
                                value: 'remove-admin',
                                child: Text('Remove admin')),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
