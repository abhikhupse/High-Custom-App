import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'otp_verification_screen.dart';
import 'signup_controller.dart';
import 'signup_form.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
  });

  @override
  State<SignupScreen> createState() =>
      _SignupScreenState();
}

class _SignupScreenState
    extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final SignupController _controller =
      SignupController();

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  void _handleLogin() {
    FocusManager.instance.primaryFocus
        ?.unfocus();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
    );
  }

  // ============================================================
  // SIGNUP
  // ============================================================

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    FocusManager.instance.primaryFocus
        ?.unfocus();

    final success =
        await _controller.signup();

    if (!mounted) {
      return;
    }

    // ==========================================================
    // FAILED
    // ==========================================================

    if (!success) {
      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,

          backgroundColor:
              const Color(
            0xFF33191C,
          ),

          content: Text(
            _controller.errorMessage ??
                'Unable to create account. Please try again.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // SUCCESS
    // ==========================================================

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            Color(
          0xFF1F1B12,
        ),

        content: Text(
          'Account created successfully.',
        ),
      ),
    );

    await Future.delayed(
      const Duration(
        milliseconds: 500,
      ),
    );

    if (!mounted) {
      return;
    }

    // ==========================================================
    // OTP
    // ==========================================================

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OtpVerificationScreen(
          email:
              _controller
                  .emailController
                  .text
                  .trim(),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation:
          _controller,

      builder:
          (
        context,
        child,
      ) {
        return Scaffold(
          // ======================================================
          // IMPORTANT
          // Makes registration form move above keyboard.
          // ======================================================

          resizeToAvoidBottomInset:
              true,

          backgroundColor:
              const Color(
            0xFF080D14,
          ),

          body:
              GestureDetector(
            behavior:
                HitTestBehavior
                    .translucent,

            onTap: () {
              FocusManager
                  .instance
                  .primaryFocus
                  ?.unfocus();
            },

            child:
                SignupForm(
              formKey:
                  _formKey,

              controller:
                  _controller,

              onSubmit:
                  _handleSubmit,

              onLogin:
                  _handleLogin,
            ),
          ),
        );
      },
    );
  }
}