import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onShowRegister;

  const LoginScreen({super.key, required this.onShowRegister});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Fields are only checked on submit at first; after a failed submit they are
  // re-checked as the user types, so fixed errors disappear straight away.
  var _autovalidateMode = AutovalidateMode.disabled;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    FocusScope.of(context).unfocus();

    final error = await context
        .read<AuthProvider>()
        .signIn(_emailController.text, _passwordController.text);
    // On success, AuthGate switches screens automatically.
    if (error != null && mounted) _showMessage(error);
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text;
    final emailError = Validators.email(email);
    if (emailError != null) {
      _showMessage('Enter your ALU email above first, then tap "Forgot password?"');
      return;
    }
    final error = await context.read<AuthProvider>().sendPasswordReset(email);
    if (!mounted) return;
    _showMessage(error ?? 'Password reset link sent to ${email.trim()}');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.watch<AuthProvider>().isBusy;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    icon: Icons.campaign_outlined,
                    title: 'Campus Reports',
                    subtitle: 'Sign in with your ALU account to report and track campus issues',
                  ),
                  const SizedBox(height: 36),
                  AppTextField(
                    controller: _emailController,
                    label: 'ALU email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: Validators.requiredPassword,
                    onFieldSubmitted: (_) => _signIn(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isBusy ? null : _resetPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(label: 'Sign in', onPressed: _signIn, isLoading: isBusy),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: isBusy ? null : widget.onShowRegister,
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
