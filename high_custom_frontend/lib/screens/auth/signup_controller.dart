
import 'package:flutter/material.dart';

import '../../services/auth_api.dart';

class SignupController extends ChangeNotifier {
  final TextEditingController firstNameController =
      TextEditingController();

  final TextEditingController lastNameController =
      TextEditingController();

  final TextEditingController employerCodeController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String? errorMessage;

String? validateFirstName(String? value) {
  final name = value?.trim() ?? '';

  if (name.isEmpty) {
    return 'First name is required';
  }

  if (name.length < 2) {
    return 'First name must be at least 2 characters';
  }

  if (name.length > 50) {
    return 'First name must not exceed 50 characters';
  }

  if (!RegExp(r'^[A-Z][a-zA-Z]*$').hasMatch(name)) {
    return 'First character must be uppercase and only letters are allowed';
  }

  return null;
}

String? validateLastName(String? value) {
  final name = value?.trim() ?? '';

  if (name.isEmpty) {
    return 'Last name is required';
  }

  if (name.length < 2) {
    return 'Last name must be at least 2 characters';
  }

  if (name.length > 50) {
    return 'Last name must not exceed 50 characters';
  }

  if (!RegExp(r'^[A-Z][a-zA-Z]*$').hasMatch(name)) {
    return 'First character must be uppercase and only letters are allowed';
  }

  return null;
}

  String? validateEmployerCode(String? value) {
    final code = value?.trim() ?? '';

    if (code.isEmpty) {
      return 'Employer code is required';
    }

    if (!RegExp(
      r'^[a-zA-Z][a-zA-Z0-9]*$',
    ).hasMatch(code)) {
      return 'Must start with a letter and contain only letters and numbers';
    }

    return null;
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email address is required';
    }

    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? validatePhone(String? value) {
    final phone = value?.replaceAll(
          RegExp(r'\s+'),
          '',
        ) ??
        '';

    if (phone.isEmpty) {
      return 'Phone number is required';
    }

    if (!RegExp(
      r'^[0-9]{10}$',
    ).hasMatch(phone)) {
      return 'Enter a valid 10 digit phone number';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (!RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[!@#$%^&*]).{8,}$',
    ).hasMatch(value)) {
      return 'Min 8 chars, 1 uppercase, 1 lowercase & 1 special character';
    }

    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  Future<bool> signup() async {
    if (isLoading) {
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthApi.register(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phone: phoneController.text
            .replaceAll(RegExp(r'\s+'), '')
            .trim(),
        email: emailController.text.trim().toLowerCase(),
        employerCode: employerCodeController.text.trim(),
        password: passwordController.text,
      );

      if (result['success'] == true) {
        return true;
      }

      errorMessage =
          result['message'] ?? 'Registration failed.';

      return false;
    } catch (e) {
      debugPrint('Signup error: $e');

      errorMessage =
          'Something went wrong. Please try again.';

      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    employerCodeController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}

