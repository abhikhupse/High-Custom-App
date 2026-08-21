import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import 'signup_screen.dart';
import 'login_controller.dart';
import 'login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  // ============================================================
  // CONTROLLER
  // ============================================================

  final LoginController _controller =
      LoginController();

  // ============================================================
  // PREVENT DOUBLE LOGIN
  // ============================================================

  bool _isNavigating = false;

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

  Future<void> _handleSubmit() async {
    if (_controller.isLoading ||
        _isNavigating) {
      return;
    }

    debugPrint(
      '======================================',
    );

    debugPrint(
      'LOGIN BUTTON CLICKED',
    );

    // ==========================================================
    // READ VALUES
    // ==========================================================

    final email =
        _controller.emailController.text
            .trim();

    final password =
        _controller.passwordController.text;

    debugPrint(
      'EMAIL: "$email"',
    );

    debugPrint(
      'PASSWORD LENGTH: ${password.length}',
    );

    // ==========================================================
    // CHECK INDIVIDUAL VALIDATORS
    // ==========================================================

    final emailError =
        _controller.validateEmail(
      email,
    );

    final passwordError =
        _controller.validatePassword(
      password,
    );

    debugPrint(
      'EMAIL ERROR: $emailError',
    );

    debugPrint(
      'PASSWORD ERROR: $passwordError',
    );

    // ==========================================================
    // FORM STATE
    // ==========================================================

    final formState =
        _formKey.currentState;

    if (formState == null) {
      debugPrint(
        'LOGIN FORM STATE IS NULL',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              Color(0xFF33191C),
          content: Text(
            'Login form is not ready. Please try again.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // VALIDATE FORM
    // ==========================================================

    final bool isValid =
        formState.validate();

    debugPrint(
      'FORM VALID: $isValid',
    );

    if (!isValid) {
      debugPrint(
        'LOGIN FORM VALIDATION FAILED',
      );

      return;
    }

    debugPrint(
      'LOGIN FORM VALIDATION SUCCESS',
    );

    // ==========================================================
    // CLOSE KEYBOARD
    // ==========================================================

    FocusManager.instance.primaryFocus
        ?.unfocus();

    // ==========================================================
    // LOGIN
    // ==========================================================

    debugPrint(
      'CALLING LOGIN CONTROLLER...',
    );

    final success =
        await _controller.login();

    debugPrint(
      'LOGIN CONTROLLER FINISHED',
    );

    debugPrint(
      'LOGIN SUCCESS VALUE: $success',
    );

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
                'Login failed. Please try again.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // SUCCESS
    // ==========================================================

    _isNavigating = true;

    debugPrint(
      '======================================',
    );

    debugPrint(
      'LOGIN SUCCESS - OPENING DASHBOARD',
    );

    debugPrint(
      '======================================',
    );

    // ==========================================================
    // NAVIGATE
    // ==========================================================

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (
          context,
        ) {
          return const DashboardScreen();
        },
      ),
      (
        route,
      ) =>
          false,
    );
  }

  // ============================================================
  // SIGN UP
  // ============================================================

  void _handleSignup() {
    FocusManager.instance.primaryFocus
        ?.unfocus();

    Navigator.of(context)
        .pushReplacement(
      MaterialPageRoute(
        builder: (
          context,
        ) {
          return const SignupScreen();
        },
      ),
    );
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  void _handleForgotPassword() {
    FocusManager.instance.primaryFocus
        ?.unfocus();

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            Color(
          0xFF20242E,
        ),
        content: Text(
          'Forgot password feature is not connected yet.',
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
          resizeToAvoidBottomInset:
              true,

          backgroundColor:
              const Color(
            0xFF080D14,
          ),

          body:
              GestureDetector(
            behavior:
                HitTestBehavior.translucent,

            // ==================================================
            // CLOSE KEYBOARD
            // ==================================================

            onTap: () {
              FocusManager
                  .instance
                  .primaryFocus
                  ?.unfocus();
            },

            child:
                LoginForm(
              formKey:
                  _formKey,

              controller:
                  _controller,

              onSubmit:
                  _handleSubmit,

              onSignup:
                  _handleSignup,

              onForgotPassword:
                  _handleForgotPassword,
            ),
          ),
        );
      },
    );
  }
}