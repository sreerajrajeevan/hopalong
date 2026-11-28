import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../theme.dart';

/// Password login: mobile number + password.
///
/// Accounts are created by an admin (name + mobile + temporary password);
/// there is no self sign-up and no SMS code. The first sign-in forces a
/// password reset. If you forget your password, an admin resets it for you.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state, required this.startMode});

  final AppState state;
  final String startMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _busy = false;
  String? _error;
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await widget.state.passwordSignIn(
      _phoneController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      setState(() =>
          _error = 'Wrong number or password. Please try again.');
      return;
    }
    if (widget.state.currentUser?.mustResetPassword == true) {
      Navigator.of(context).pushReplacementNamed('/reset-password');
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
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
                'Hop in!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Log in with your mobile number and password.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: HopColors.inkSoft),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phoneController,
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
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Please enter your password.'
                    : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _signIn,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Sign in'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: HopColors.danger)),
              ],
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Forgot your password? Ask an admin to reset it for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: HopColors.inkSoft),
                ),
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
                    'Demo mode: any mobile number and any password '
                    '(6+ characters) will sign you in.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
