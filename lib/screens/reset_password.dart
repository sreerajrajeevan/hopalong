import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Forced password reset: shown after the first sign-in with a temporary
/// password (admin-created account, or an admin reset it). The user must
/// pick their own password before they can use the app.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await widget.state.resetOwnPassword(_password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      showHopError(context, widget.state.error);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set your password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pick a password only you know',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'You signed in with a temporary password. Choose your own '
                'now — after this, only you know it.',
                style: TextStyle(color: HopColors.inkSoft),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (v) => v == null || v.length < 6
                    ? 'At least 6 characters.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Repeat new password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (v) => v != _password.text
                    ? 'The passwords do not match.'
                    : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save password & continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
