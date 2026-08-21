import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'otp_verification_controller.dart';
import 'otp_verification_form.dart';

class OtpVerificationScreen
    extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpVerificationScreen>
      createState() =>
          _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  late final OtpVerificationController
      _controller;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller =
        OtpVerificationController(
      email: widget.email,
    );

    // ==========================================================
    // AUTO FOCUS FIRST OTP BOX
    // ==========================================================

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        _controller
            .focusNodes
            .first
            .requestFocus();
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _handleVerify() async {
    final error =
        _controller.validateOtp();

    if (error != null) {
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

          content:
              Text(
            error,
          ),
        ),
      );

      return;
    }

    FocusManager.instance.primaryFocus
        ?.unfocus();

    final success =
        await _controller.verifyOtp();

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
        const SnackBar(
          behavior:
              SnackBarBehavior.floating,

          backgroundColor:
              Color(
            0xFF33191C,
          ),

          content:
              Text(
            'Invalid OTP. Please try again.',
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

        content:
            Text(
          'Email verified successfully.',
        ),
      ),
    );

    await Future.delayed(
      const Duration(
        milliseconds: 700,
      ),
    );

    if (!mounted) {
      return;
    }

    // ==========================================================
    // GO TO LOGIN
    // ==========================================================

    Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute(
        builder:
            (_) =>
                const LoginScreen(),
      ),

      (route) =>
          false,
    );
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _handleResend() async {
    final success =
        await _controller.resendOtp();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            success
                ? const Color(
                    0xFF1F1B12,
                  )
                : const Color(
                    0xFF33191C,
                  ),

        content:
            Text(
          success
              ? 'A new OTP has been sent to your email.'
              : 'Unable to resend OTP. Please try again.',
        ),
      ),
    );

    // ==========================================================
    // FOCUS FIRST BOX AGAIN
    // ==========================================================

    if (success &&
        _controller.focusNodes.isNotEmpty) {
      _controller
          .focusNodes
          .first
          .requestFocus();
    }
  }

  // ============================================================
  // BACK TO LOGIN
  // ============================================================

  void _handleBackToLogin() {
    FocusManager.instance.primaryFocus
        ?.unfocus();

    Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute(
        builder:
            (_) =>
                const LoginScreen(),
      ),

      (route) =>
          false,
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
          // KEYBOARD HANDLING
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
                HitTestBehavior.translucent,

            // ====================================================
            // TAP OUTSIDE OTP TO CLOSE KEYBOARD
            // ====================================================

            onTap:
                () {
              FocusManager
                  .instance
                  .primaryFocus
                  ?.unfocus();
            },

            child:
                OtpVerificationForm(
              formKey:
                  _formKey,

              controller:
                  _controller,

              onVerify:
                  _handleVerify,

              onResend:
                  _handleResend,

              onBackToLogin:
                  _handleBackToLogin,
            ),
          ),
        );
      },
    );
  }
}