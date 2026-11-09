import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/primary_button.dart';

/// Shown after sign-up (or sign-in) until the user clicks the link in their inbox.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _resendCooldownSeconds = 30;

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Check automatically every few seconds, so the app moves on by itself
    // once the link has been clicked.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => context.read<AuthProvider>().checkEmailVerified(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkNow() async {
    setState(() => _isChecking = true);
    final verified = await context.read<AuthProvider>().checkEmailVerified();
    if (!mounted) return;
    setState(() => _isChecking = false);
    if (!verified) {
      _showMessage('Not verified yet. Open the link in the email, then try again.');
    }
  }

  Future<void> _resend() async {
    final error = await context.read<AuthProvider>().resendVerificationEmail();
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    _showMessage('Verification email sent again. Check your spam folder too.');
    _startCooldown();
  }

  void _startCooldown() {
    setState(() => _cooldownRemaining = _resendCooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownRemaining <= 1) timer.cancel();
      setState(() => _cooldownRemaining--);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.firebaseUser?.email ?? 'your email';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(
                  icon: Icons.mark_email_unread_outlined,
                  title: 'Verify your email',
                  subtitle: 'We sent a verification link to\n$email\n\n'
                      'Open it on this phone or your computer, then come back here.',
                ),
                const SizedBox(height: 36),
                PrimaryButton(
                  label: "I've verified my email",
                  onPressed: _checkNow,
                  isLoading: _isChecking,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: auth.isBusy || _cooldownRemaining > 0 ? null : _resend,
                  child: Text(_cooldownRemaining > 0
                      ? 'Resend email in ${_cooldownRemaining}s'
                      : 'Resend verification email'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: auth.signOut,
                  child: const Text('Use a different account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
