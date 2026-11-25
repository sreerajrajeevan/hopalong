import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../config.dart';
import '../theme.dart';

/// Phone-or-email login with a 6-digit OTP code.
/// Demo mode: any 6 digits work. Live mode: real Supabase email OTP.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state, required this.startMode});

  final AppState state;
  final String startMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _useEmail = false;
  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  final _contactController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _contactController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.state.repo.signInWithOtp(
        email: _useEmail ? _contactController.text.trim() : null,
        phone: _useEmail ? null : _contactController.text.trim(),
      );
      setState(() {
        _codeSent = true;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Could not send the code. Please try again.';
      });
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.state.repo.verifyOtp(
        code: code,
        email: _useEmail ? _contactController.text.trim() : null,
        phone: _useEmail ? null : _contactController.text.trim(),
      );
      final profile = await widget.state.repo.getCurrentProfile();
      if (profile == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/signup',
              arguments: {
                'mode': widget.startMode,
                'contact': _contactController.text.trim(),
                'useEmail': _useEmail,
              });
        }
        return;
      }
      await widget.state.init();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'That code did not work. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome back')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _codeSent ? 'Enter your code' : 'Hop in!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'We sent a 6-digit code to ${_contactController.text.trim()}.'
                    : 'Log in with your mobile number or email to find and offer rides.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: HopColors.inkSoft),
              ),
              const SizedBox(height: 24),
              if (!_codeSent) ...[
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                        value: false,
                        icon: Icon(Icons.phone_rounded),
                        label: Text('Mobile')),
                    ButtonSegment(
                        value: true,
                        icon: Icon(Icons.email_rounded),
                        label: Text('Email')),
                  ],
                  selected: {_useEmail},
                  onSelectionChanged: (s) =>
                      setState(() => _useEmail = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  keyboardType: _useEmail
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  decoration: InputDecoration(
                    labelText:
                        _useEmail ? 'Email address' : 'Mobile number',
                    prefixIcon: Icon(_useEmail
                        ? Icons.email_outlined
                        : Icons.phone_outlined),
                    hintText: _useEmail
                        ? 'you@example.com'
                        : '+91 98765 43210',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your ${_useEmail ? 'email' : 'mobile number'}.';
                    }
                    if (_useEmail &&
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(v.trim())) {
                      return 'That email doesn\'t look right.';
                    }
                    if (!_useEmail && v.trim().length < 10) {
                      return 'Enter a valid mobile number.';
                    }
                    return null;
                  },
                ),
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
                if (AppConfig.isDemoMode) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: HopColors.peachSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Demo mode: no real SMS or email is sent. '
                      'Tap "Send code", then enter any 6 digits.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ] else ...[
                TextFormField(
                  controller: _codeController,
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
                if (AppConfig.isDemoMode)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Demo: enter any 6 digits.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: HopColors.inkSoft)),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _busy ? null : _verify,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Verify & continue'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() {
                    _codeSent = false;
                    _codeController.clear();
                  }),
                  child: const Text('Use a different number or email'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: HopColors.danger)),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed('/signup', arguments: {
                  'mode': widget.startMode,
                  'contact': '',
                  'useEmail': _useEmail,
                }),
                child: const Text('New here? Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
