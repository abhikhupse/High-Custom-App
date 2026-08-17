import 'package:flutter/material.dart';
import '../../services/auth_api.dart';

class OtpVerificationController extends ChangeNotifier {
  final String email;

  OtpVerificationController({
    required this.email,
  });

  // ============================================================
  // OTP CONTROLLERS
  // ============================================================

  final List<TextEditingController> otpControllers =
      List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNodes =
      List.generate(
    6,
    (_) => FocusNode(),
  );

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = false;
  bool isResending = false;

  String? errorMessage;

  // ============================================================
  // OTP
  // ============================================================

  String get otp {
    return otpControllers
        .map((controller) => controller.text)
        .join();
  }

  bool get isOtpComplete {
    return otp.length == 6 &&
        RegExp(r'^[0-9]{6}$').hasMatch(otp);
  }

  // ============================================================
  // VALIDATE OTP
  // ============================================================

  String? validateOtp() {
    final cleanOtp = otp.trim();

    if (cleanOtp.isEmpty) {
      return 'Please enter the OTP';
    }

    if (cleanOtp.length != 6) {
      return 'Please enter the complete 6-digit OTP';
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(cleanOtp)) {
      return 'OTP must contain only numbers';
    }

    return null;
  }

  // ============================================================
  // OTP BOX CHANGE
  // ============================================================

  void onOtpChanged(
    String value,
    int index,
  ) {
    // Keep numbers only.
    final digits = value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    // ----------------------------------------------------------
    // Empty
    // ----------------------------------------------------------

    if (digits.isEmpty) {
      otpControllers[index].clear();

      notifyListeners();
      return;
    }

    // ----------------------------------------------------------
    // Multiple digits / pasted OTP
    // ----------------------------------------------------------

    if (digits.length > 1) {
      final remaining = digits.length > 6
          ? digits.substring(0, 6)
          : digits;

      // Clear all boxes first.
      for (final controller in otpControllers) {
        controller.clear();
      }

      // Fill OTP boxes.
      for (
        int i = 0;
        i < remaining.length && i < 6;
        i++
      ) {
        otpControllers[i].text = remaining[i];
      }

      // Move focus.
      if (remaining.length == 6) {
        focusNodes[5].unfocus();
      } else {
        focusNodes[remaining.length]
            .requestFocus();
      }

      notifyListeners();
      return;
    }

    // ----------------------------------------------------------
    // Single digit
    // ----------------------------------------------------------

    otpControllers[index].text = digits;

    otpControllers[index].selection =
        TextSelection.collapsed(
      offset: otpControllers[index].text.length,
    );

    // Move to next box.
    if (index < 5) {
      focusNodes[index + 1].requestFocus();
    } else {
      focusNodes[index].unfocus();
    }

    notifyListeners();
  }

  // ============================================================
  // BACKSPACE
  // ============================================================

  void handleBackspace(
    String value,
    int index,
  ) {
    if (value.isEmpty && index > 0) {
      otpControllers[index - 1].clear();

      focusNodes[index - 1].requestFocus();

      notifyListeners();
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<bool> verifyOtp() async {
    // Validate first.
    final validationError = validateOtp();

    if (validationError != null) {
      errorMessage = validationError;
      notifyListeners();
      return false;
    }

    // Prevent duplicate API calls.
    if (isLoading) {
      return false;
    }

    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanOtp = otp.trim();

      debugPrint(
        '======================================',
      );

      debugPrint(
        'OTP CONTROLLER - VERIFY OTP',
      );

      debugPrint(
        'EMAIL: $cleanEmail',
      );

      debugPrint(
        'OTP: $cleanOtp',
      );

      // ========================================================
      // REAL BACKEND API CALL
      // ========================================================

      final result = await AuthApi.verifyOtp(
        email: cleanEmail,
        otp: cleanOtp,
      );

      debugPrint(
        'VERIFY RESULT: $result',
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (result['success'] == true) {
        errorMessage = null;

        debugPrint(
          'OTP VERIFICATION SUCCESS',
        );

        return true;
      }

      // ========================================================
      // API ERROR
      // ========================================================

      errorMessage =
          result['message'] ??
              'OTP verification failed.';

      debugPrint(
        'OTP VERIFICATION FAILED: $errorMessage',
      );

      return false;
    } catch (e) {
      errorMessage =
          'Unable to verify OTP. Please try again.';

      debugPrint(
        'OTP CONTROLLER ERROR: $e',
      );

      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<bool> resendOtp() async {
    if (isResending) {
      return false;
    }

    isResending = true;
    errorMessage = null;

    notifyListeners();

    try {
      final cleanEmail =
          email.trim().toLowerCase();

      debugPrint(
        '======================================',
      );

      debugPrint(
        'OTP CONTROLLER - RESEND OTP',
      );

      debugPrint(
        'EMAIL: $cleanEmail',
      );

      // ========================================================
      // REAL BACKEND API CALL
      // ========================================================

      final result = await AuthApi.resendOtp(
        email: cleanEmail,
      );

      debugPrint(
        'RESEND RESULT: $result',
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (result['success'] == true) {
        clearOtp(requestFocus: true);

        errorMessage = null;

        debugPrint(
          'OTP RESEND SUCCESS',
        );

        return true;
      }

      // ========================================================
      // ERROR
      // ========================================================

      errorMessage =
          result['message'] ??
              'Unable to resend OTP.';

      debugPrint(
        'OTP RESEND FAILED: $errorMessage',
      );

      return false;
    } catch (e) {
      errorMessage =
          'Unable to resend OTP. Please try again.';

      debugPrint(
        'RESEND OTP ERROR: $e',
      );

      return false;
    } finally {
      isResending = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR OTP
  // ============================================================

  void clearOtp({
    bool requestFocus = true,
  }) {
    for (final controller in otpControllers) {
      controller.clear();
    }

    errorMessage = null;

    if (requestFocus) {
      focusNodes.first.requestFocus();
    }

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    for (final controller in otpControllers) {
      controller.dispose();
    }

    for (final node in focusNodes) {
      node.dispose();
    }

    super.dispose();
  }
}