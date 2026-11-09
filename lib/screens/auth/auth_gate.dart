import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../staff/staff_shell.dart';
import '../student/student_shell.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

/// Decides which screen to show from the current authentication state and role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const _LoadingScreen();
      case AuthStatus.unauthenticated:
        return const _AuthScreen();
      case AuthStatus.unverified:
        return const VerifyEmailScreen();
      case AuthStatus.loadingProfile:
        return _LoadingScreen(error: auth.profileError, onSignOut: auth.signOut);
      case AuthStatus.authenticated:
        return auth.isStaff ? const StaffShell() : const StudentShell();
    }
  }
}

/// Switches between the login and register forms.
class _AuthScreen extends StatefulWidget {
  const _AuthScreen();

  @override
  State<_AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<_AuthScreen> {
  bool _showLogin = true;

  void _toggle() => setState(() => _showLogin = !_showLogin);

  @override
  Widget build(BuildContext context) {
    return _showLogin
        ? LoginScreen(onShowRegister: _toggle)
        : RegisterScreen(onShowLogin: _toggle);
  }
}

class _LoadingScreen extends StatelessWidget {
  final String? error;
  final VoidCallback? onSignOut;

  const _LoadingScreen({this.error, this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: error == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(onPressed: onSignOut, child: const Text('Sign out')),
                  ],
                ),
        ),
      ),
    );
  }
}
