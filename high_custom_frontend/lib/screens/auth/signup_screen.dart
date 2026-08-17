
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'otp_verification_screen.dart';
import 'signup_controller.dart';
import 'signup_form.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final SignupController _controller =
      SignupController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await _controller.signup();

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF241414),
          content: Text(
            _controller.errorMessage ??
                'Unable to create account. Please try again.',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1F1B12),
        content: Text(
          'Account created successfully.',
        ),
      ),
    );

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          email: _controller.emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF050505),
          body: SignupForm(
            formKey: _formKey,
            controller: _controller,
            onSubmit: _handleSubmit,
            onLogin: _handleLogin,
          ),
        );
      },
    );
  }
}

