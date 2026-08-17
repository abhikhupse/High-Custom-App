import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'otp_verification_controller.dart';
import 'otp_verification_form.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  late final OtpVerificationController _controller;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _controller = OtpVerificationController(
      email: widget.email,
    );

    // Automatically focus first OTP box.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _controller.focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final error = _controller.validateOtp();

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF241414),
          content: Text(error),
        ),
      );

      return;
    }

    final success =
        await _controller.verifyOtp();

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF241414),
          content: Text(
            'Invalid OTP. Please try again.',
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
          'Email verified successfully.',
        ),
      ),
    );

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _handleResend() async {
    final success =
        await _controller.resendOtp();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? const Color(0xFF1F1B12)
            : const Color(0xFF241414),
        content: Text(
          success
              ? 'A new OTP has been sent to your email.'
              : 'Unable to resend OTP. Please try again.',
        ),
      ),
    );
  }

  void _handleBackToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor:
              const Color(0xFF050505),
          resizeToAvoidBottomInset: true,
          body: OtpVerificationForm(
            formKey: _formKey,
            controller: _controller,
            onVerify: _handleVerify,
            onResend: _handleResend,
            onBackToLogin: _handleBackToLogin,
          ),
        );
      },
    );
  }
}