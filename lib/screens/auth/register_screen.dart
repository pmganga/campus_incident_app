import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onShowLogin;

  const RegisterScreen({super.key, required this.onShowLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Fields are only checked on submit at first; after a failed submit they are
  // re-checked as the user types, so fixed errors disappear straight away.
  var _autovalidateMode = AutovalidateMode.disabled;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    FocusScope.of(context).unfocus();

    final error = await context.read<AuthProvider>().register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
    // On success, AuthGate shows the "verify your email" screen.
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
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
                    icon: Icons.person_add_alt_1_outlined,
                    title: 'Create account',
                    subtitle: 'Only ALU email addresses can register',
                  ),
                  const SizedBox(height: 36),
                  AppTextField(
                    controller: _nameController,
                    label: 'Full name',
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    validator: Validators.name,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailController,
                    label: 'ALU email',
                    icon: Icons.email_outlined,
                    helperText: 'e.g. name@alustudent.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    helperText: 'At least 8 characters, including a number',
                    isPassword: true,
                    validator: Validators.newPassword,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirmController,
                    label: 'Confirm password',
                    icon: Icons.lock_reset_outlined,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) =>
                        Validators.confirmPassword(value, _passwordController.text),
                    onFieldSubmitted: (_) => _register(),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Create account',
                    onPressed: _register,
                    isLoading: isBusy,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: isBusy ? null : widget.onShowLogin,
                        child: const Text('Sign in'),
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
