import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/auth_api.dart';

class LoginController extends ChangeNotifier {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  // ============================================================
  // STORAGE
  // ============================================================

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  // ============================================================
  // STATE
  // ============================================================

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
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
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
    final password = value ?? '';

    if (password.isEmpty) {
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

    final email =
        emailController.text.trim().toLowerCase();

    final password =
        passwordController.text;

    errorMessage = null;

    // ==========================================================
    // DEBUG
    // ==========================================================

    debugPrint(
      '======================================',
    );

    debugPrint(
      'LOGIN CONTROLLER STARTED',
    );

    debugPrint(
      'EMAIL: "$email"',
    );

    debugPrint(
      'PASSWORD LENGTH: ${password.length}',
    );

    // ==========================================================
    // VALIDATE EMAIL
    // ==========================================================

    final emailError =
        validateEmail(email);

    if (emailError != null) {
      debugPrint(
        'EMAIL VALIDATION ERROR: $emailError',
      );

      errorMessage = emailError;

      notifyListeners();

      return false;
    }

    // ==========================================================
    // VALIDATE PASSWORD
    // ==========================================================

    final passwordError =
        validatePassword(password);

    if (passwordError != null) {
      debugPrint(
        'PASSWORD VALIDATION ERROR: $passwordError',
      );

      errorMessage = passwordError;

      notifyListeners();

      return false;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      debugPrint(
        'CALLING AUTH API...',
      );

      // ========================================================
      // LOGIN API
      // ========================================================

      final response =
          await AuthApi.login(
        email: email,
        password: password,
      );

      debugPrint(
        'LOGIN CONTROLLER RESPONSE: $response',
      );

      // ========================================================
      // FAILED
      // ========================================================

      if (response['success'] != true) {
        errorMessage =
            response['message']
                    ?.toString() ??
                'Login failed. Please try again.';

        debugPrint(
          'LOGIN FAILED: $errorMessage',
        );

        return false;
      }

      // ========================================================
      // TOKEN
      // ========================================================

      final token =
          response['token']
              ?.toString()
              .trim();

      if (token == null ||
          token.isEmpty) {
        errorMessage =
            'Authentication token was not received.';

        debugPrint(
          errorMessage,
        );

        return false;
      }

      // ========================================================
      // SAVE TOKEN
      // ========================================================

      await _storage.write(
        key: 'auth_token',
        value: token,
      );

      // Remove old token key if it exists.
      await _storage.delete(
        key: 'token',
      );

      // ========================================================
      // VERIFY TOKEN
      // ========================================================

      final storedToken =
          await _storage.read(
        key: 'auth_token',
      );

      if (storedToken == null ||
          storedToken.trim().isEmpty) {
        errorMessage =
            'Unable to save login session.';

        debugPrint(
          errorMessage,
        );

        return false;
      }

      // ========================================================
      // SAVE USER DATA
      // ========================================================

      final dynamic userData =
          response['user'];

      if (userData is Map) {
        final user =
            Map<String, dynamic>.from(
          userData,
        );

        final id =
            (user['id'] ?? user['_id'])
                ?.toString();

        final userEmail =
            user['email']?.toString();

        final firstName =
            user['firstName']?.toString();

        final lastName =
            user['lastName']?.toString();

        final employerCode =
            user['employerCode']
                ?.toString();

        if (id != null &&
            id.trim().isNotEmpty) {
          await _storage.write(
            key: 'user_id',
            value: id.trim(),
          );
        }

        if (userEmail != null &&
            userEmail.trim().isNotEmpty) {
          await _storage.write(
            key: 'user_email',
            value: userEmail.trim(),
          );
        }

        if (firstName != null &&
            firstName.trim().isNotEmpty) {
          await _storage.write(
            key: 'user_first_name',
            value: firstName.trim(),
          );
        }

        if (lastName != null &&
            lastName.trim().isNotEmpty) {
          await _storage.write(
            key: 'user_last_name',
            value: lastName.trim(),
          );
        }

        if (employerCode != null &&
            employerCode.trim().isNotEmpty) {
          await _storage.write(
            key: 'user_employer_code',
            value: employerCode.trim(),
          );
        }
      }

      debugPrint(
        '======================================',
      );

      debugPrint(
        'LOGIN SUCCESS',
      );

      debugPrint(
        'TOKEN STORED SUCCESSFULLY',
      );

      debugPrint(
        '======================================',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        'LOGIN CONTROLLER ERROR: $e',
      );

      debugPrint(
        'STACK TRACE: $stackTrace',
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
  // GET TOKEN
  // ============================================================

  Future<String?> getToken() async {
    final token =
        await _storage.read(
      key: 'auth_token',
    );

    if (token != null &&
        token.trim().isNotEmpty) {
      return token.trim();
    }

    final legacyToken =
        await _storage.read(
      key: 'token',
    );

    if (legacyToken != null &&
        legacyToken.trim().isNotEmpty) {
      final cleanToken =
          legacyToken.trim();

      await _storage.write(
        key: 'auth_token',
        value: cleanToken,
      );

      await _storage.delete(
        key: 'token',
      );

      return cleanToken;
    }

    return null;
  }

  // ============================================================
  // CHECK LOGIN
  // ============================================================

  Future<bool> isLoggedIn() async {
    final token =
        await getToken();

    return token != null &&
        token.isNotEmpty;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await Future.wait([
      _storage.delete(
        key: 'auth_token',
      ),
      _storage.delete(
        key: 'token',
      ),
      _storage.delete(
        key: 'user_id',
      ),
      _storage.delete(
        key: 'user_email',
      ),
      _storage.delete(
        key: 'user_first_name',
      ),
      _storage.delete(
        key: 'user_last_name',
      ),
      _storage.delete(
        key: 'user_employer_code',
      ),
    ]);

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