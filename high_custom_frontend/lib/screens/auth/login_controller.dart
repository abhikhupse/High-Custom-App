import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/auth_api.dart';

class LoginController extends ChangeNotifier {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  bool isLoading = false;
  bool obscurePassword = true;

  String? errorMessage;

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

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

  // ============================================================
  // PASSWORD VALIDATION
  // ============================================================

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    return null;
  }

  // ============================================================
  // PASSWORD VISIBILITY
  // ============================================================

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login() async {
    if (isLoading) {
      return false;
    }

    errorMessage = null;

    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    // Validate email
    final emailError = validateEmail(email);

    if (emailError != null) {
      errorMessage = emailError;
      notifyListeners();
      return false;
    }

    // Validate password
    final passwordError = validatePassword(password);

    if (passwordError != null) {
      errorMessage = passwordError;
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      debugPrint('======================================');
      debugPrint('LOGIN CONTROLLER');
      debugPrint('EMAIL: $email');

      final response = await AuthApi.login(
        email: email,
        password: password,
      );

      debugPrint(
        'LOGIN CONTROLLER RESPONSE: $response',
      );

      // ========================================================
      // LOGIN SUCCESS
      // ========================================================

      if (response['success'] == true) {
        final token = response['token'];

        if (token == null ||
            token.toString().trim().isEmpty) {
          errorMessage =
              'Login successful, but authentication token was not received.';

          return false;
        }

        // Store JWT securely on the device.
        await _storage.write(
          key: 'auth_token',
          value: token.toString(),
        );

        // Optional: store user information
        if (response['user'] != null) {
          final user = response['user'];

          if (user is Map<String, dynamic>) {
            if (user['id'] != null) {
              await _storage.write(
                key: 'user_id',
                value: user['id'].toString(),
              );
            }

            if (user['email'] != null) {
              await _storage.write(
                key: 'user_email',
                value: user['email'].toString(),
              );
            }

            if (user['firstName'] != null) {
              await _storage.write(
                key: 'user_first_name',
                value: user['firstName'].toString(),
              );
            }

            if (user['lastName'] != null) {
              await _storage.write(
                key: 'user_last_name',
                value: user['lastName'].toString(),
              );
            }
          }
        }

        debugPrint(
          'JWT TOKEN STORED SUCCESSFULLY',
        );

        return true;
      }

      // ========================================================
      // LOGIN FAILED
      // ========================================================

      errorMessage =
          response['message']?.toString() ??
              'Login failed. Please try again.';

      return false;
    } catch (e) {
      debugPrint(
        'LOGIN CONTROLLER ERROR: $e',
      );

      errorMessage =
          'Unable to connect to the server.';

      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // GET STORED TOKEN
  // ============================================================

  Future<String?> getToken() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null && token.trim().isNotEmpty) {
      return token;
    }

    final legacyToken = await _storage.read(key: 'token');
    if (legacyToken != null && legacyToken.trim().isNotEmpty) {
      await _storage.write(
        key: 'auth_token',
        value: legacyToken,
      );
      await _storage.delete(key: 'token');
      return legacyToken;
    }

    return null;
  }

  // ============================================================
  // CHECK LOGIN
  // ============================================================

  Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null &&
        token.trim().isNotEmpty;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _storage.delete(
      key: 'auth_token',
    );

    await _storage.delete(
      key: 'token',
    );

    await _storage.delete(
      key: 'user_id',
    );

    await _storage.delete(
      key: 'user_email',
    );

    await _storage.delete(
      key: 'user_first_name',
    );

    await _storage.delete(
      key: 'user_last_name',
    );

    debugPrint(
      'USER LOGGED OUT',
    );

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }
}