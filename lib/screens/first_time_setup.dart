import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../theme.dart';

/// One-time move from OTP to password login.
///
/// For the very first admin (Sree): verifies the mobile number with one
/// last SMS code, then sets the password and makes this account the first
/// admin. After that the bootstrap is closed and this screen is useless —
/// which is the point. Later users are created by an admin and never see
/// this screen.
class FirstTimeSetupScreen extends StatefulWidget {
  const FirstTimeSetupScreen({super.key, required this.state});

  final AppState state;

  @override
  State<FirstTimeSetupScreen> createState() => _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends State<FirstTimeSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

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

  String _toE164(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length == 10) return '+91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    return '+$digits';
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.state.repo.signInWithOtp(phone: _toE164(_phone.text.trim()));
      if (mounted) {
        setState(() {
          _codeSent = true;
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not send the code. Check the number and try again.';
        });
      }
    }
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_code.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.state.repo.verifyOtp(
        code: _code.text.trim(),
        phone: _toE164(_phone.text.trim()),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'That code did not work. Please try again.';
        });
      }
      return;
    }
    final ok = await widget.state.bootstrapAdmin(_password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      setState(() => _error =
          'Could not finish the setup. An admin may already exist — '
          'ask them to create your account instead.');
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up password login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'One last code, then no more codes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Verify your number once with an SMS code, pick your '
                'password, and this account becomes the first admin. '
                'After this, you sign in with your password only.',
                style: TextStyle(color: HopColors.inkSoft),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                enabled: !_codeSent,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '98765 43210',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your mobile number.';
                  }
                  if (!_isValidMobile(v.trim())) {
                    return 'Enter a valid 10-digit mobile number.';
                  }
                  return null;
                },
              ),
              if (!_codeSent) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _busy ? null : _sendCode,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Send code'),
                ),
              ] else ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26,
                      letterSpacing: 10,
                      fontWeight: FontWeight.w800),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Your new password',
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
                    labelText: 'Repeat password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) => v != _password.text
                      ? 'The passwords do not match.'
                      : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _busy ? null : _finish,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Set password & continue'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() {
                    _codeSent = false;
                    _code.clear();
                  }),
                  child: const Text('Use a different number'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: HopColors.danger)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
