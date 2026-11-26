import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../config.dart';
import '../theme.dart';

/// Phone-only login with a 6-digit OTP code sent by SMS.
/// Demo mode: any 6 digits work. Live mode: real Supabase phone OTP.
/// No email sign-in, no WhatsApp.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state, required this.startMode});

  final AppState state;
  final String startMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  String _phone = '';
  final _contactController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// Normalise an Indian mobile number to E.164 (+91...), which is
  /// what Supabase phone auth needs.
  String _toE164(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length == 10) return '+91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    return '+$digits';
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
      _phone = _toE164(_contactController.text.trim());
      await widget.state.repo.signInWithOtp(phone: _phone);
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
        phone: _phone,
      );
      final profile = await widget.state.repo.getCurrentProfile();
      if (profile == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/signup',
              arguments: {
                'mode': widget.startMode,
                'contact': _phone,
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
                    ? 'We sent a 6-digit code by SMS to $_phone.'
                    : 'Log in with your mobile number to find and offer rides.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: HopColors.inkSoft),
              ),
              const SizedBox(height: 24),
              if (!_codeSent) ...[
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
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
                      'Demo mode: no real SMS is sent. '
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
                  child: const Text('Use a different number'),
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
