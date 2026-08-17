import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthApi {
  static const String baseUrl =
      'http://192.168.1.18:3000/api/user';

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static Future<String?> readStoredEmployerCode() async {
    try {
      final code = await _storage.read(
        key: 'user_employer_code',
      );

      if (code != null && code.trim().isNotEmpty) {
        return code.trim();
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _persistUserSessionFromToken(
    String token,
  ) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return;
      }

      final payload = parts[1];
      final normalized = payload
          .replaceAll('-', '+')
          .replaceAll('_', '/');

      final padded = normalized.length % 4 == 0
          ? normalized
          : '${normalized}${'=' * (4 - normalized.length % 4)}';

      final decoded = utf8.decode(
        base64Url.decode(padded),
      );

      final data = jsonDecode(decoded);
      if (data is Map<String, dynamic>) {
        final employerCode = data['employerCode'];
        if (employerCode != null && employerCode.toString().trim().isNotEmpty) {
          await _storage.write(
            key: 'user_employer_code',
            value: employerCode.toString().trim(),
          );
        }

        final email = data['email'];
        if (email != null && email.toString().trim().isNotEmpty) {
          await _storage.write(
            key: 'user_email',
            value: email.toString().trim(),
          );
        }
      }
    } catch (_) {
      // Ignore token decode issues and keep the user session intact.
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String employerCode,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/register');

    debugPrint('======================================');
    debugPrint('REGISTER API');
    debugPrint('URL: $url');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'firstName': firstName.trim(),
              'lastName': lastName.trim(),
              'phone': phone.trim(),
              'email': email.trim().toLowerCase(),
              'employerCode': employerCode.trim(),
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        'REGISTER STATUS: ${response.statusCode}',
      );

      debugPrint(
        'REGISTER RESPONSE: ${response.body}',
      );

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (e) {
          debugPrint(
            'REGISTER JSON ERROR: $e',
          );

          return {
            'success': false,
            'message': 'Invalid response from server',
          };
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          'success': true,
          ...data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ??
            'Registration failed. Please try again.',
        'errors': data['errors'],
      };
    } catch (e) {
      debugPrint(
        'REGISTER ERROR: $e',
      );

      return {
        'success': false,
        'message': 'Unable to connect to the server.',
        'error': e.toString(),
      };
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse(
      '$baseUrl/verify-otp',
    );

    final cleanEmail =
        email.trim().toLowerCase();

    final cleanOtp =
        otp.trim();

    debugPrint('======================================');
    debugPrint('VERIFY OTP API');
    debugPrint('URL: $url');
    debugPrint('EMAIL: $cleanEmail');
    debugPrint('OTP: $cleanOtp');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': cleanEmail,
              'otp': cleanOtp,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        'VERIFY OTP STATUS: ${response.statusCode}',
      );

      debugPrint(
        'VERIFY OTP RESPONSE: ${response.body}',
      );

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (e) {
          debugPrint(
            'VERIFY JSON ERROR: $e',
          );

          return {
            'success': false,
            'message': 'Invalid response from server',
          };
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          'success': true,
          ...data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ??
            'OTP verification failed.',
      };
    } catch (e) {
      debugPrint(
        'VERIFY OTP ERROR: $e',
      );

      return {
        'success': false,
        'message': 'Unable to connect to the server.',
        'error': e.toString(),
      };
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  static Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    final url = Uri.parse(
      '$baseUrl/resend-otp',
    );

    final cleanEmail =
        email.trim().toLowerCase();

    debugPrint('======================================');
    debugPrint('RESEND OTP API');
    debugPrint('URL: $url');
    debugPrint('EMAIL: $cleanEmail');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': cleanEmail,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        'RESEND STATUS: ${response.statusCode}',
      );

      debugPrint(
        'RESEND RESPONSE: ${response.body}',
      );

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (e) {
          debugPrint(
            'RESEND JSON ERROR: $e',
          );

          return {
            'success': false,
            'message': 'Invalid response from server',
          };
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          'success': true,
          ...data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ??
            'Unable to resend OTP.',
      };
    } catch (e) {
      debugPrint(
        'RESEND ERROR: $e',
      );

      return {
        'success': false,
        'message': 'Unable to connect to the server.',
        'error': e.toString(),
      };
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login({
    String? email,
    String? employerCode,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    final cleanEmail =
        email?.trim().toLowerCase();

    final cleanEmployerCode =
        employerCode?.trim();

    final hasEmail =
        cleanEmail != null && cleanEmail.isNotEmpty;
    final hasEmployerCode =
        cleanEmployerCode != null &&
            cleanEmployerCode.isNotEmpty;

    debugPrint('======================================');
    debugPrint('LOGIN API');
    debugPrint('URL: $url');
    debugPrint('EMAIL: ${hasEmail ? cleanEmail : 'not provided'}');
    debugPrint(
      'EMPLOYER CODE: ${hasEmployerCode ? cleanEmployerCode : 'not provided'}',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              if (hasEmail) 'email': cleanEmail,
              if (hasEmployerCode)
                'employerCode': cleanEmployerCode,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        'LOGIN STATUS: ${response.statusCode}',
      );

      debugPrint(
        'LOGIN RESPONSE: ${response.body}',
      );

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (e) {
          debugPrint(
            'LOGIN JSON ERROR: $e',
          );

          return {
            'success': false,
            'message': 'Invalid response from server',
          };
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {

        // ======================================================
        // SAVE JWT TOKEN
        // ======================================================

        final token = data['token'];

        if (token == null ||
            token.toString().isEmpty) {
          return {
            'success': false,
            'message':
                'Login successful but token was not received.',
          };
        }

        final tokenValue = token.toString();

        await _storage.write(
          key: 'auth_token',
          value: tokenValue,
        );

        await _persistUserSessionFromToken(tokenValue);

        await _storage.delete(
          key: 'token',
        );

        debugPrint(
          'JWT TOKEN SAVED SUCCESSFULLY',
        );

        return {
          'success': true,
          ...data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ??
            'Login failed. Please try again.',
        'errors': data['errors'],
      };
    } catch (e) {
      debugPrint(
        'LOGIN ERROR: $e',
      );

      return {
        'success': false,
        'message':
            'Unable to connect to the server.',
        'error': e.toString(),
      };
    }
  }

  // ============================================================
  // GET LOGGED-IN USER DETAILS
  // ============================================================

  static Future<Map<String, dynamic>>
      getUserDetails() async {

    final url = Uri.parse(
      '$baseUrl/profile',
    );

    debugPrint('======================================');
    debugPrint('GET USER DETAILS API');
    debugPrint('URL: $url');

    try {
      // ========================================================
      // GET JWT TOKEN
      // ========================================================

      final token = await _storage.read(
        key: 'auth_token',
      );

      final legacyToken = await _storage.read(
        key: 'token',
      );

      final activeToken = (token ?? legacyToken ?? '').trim();

      if (activeToken.isEmpty) {

        debugPrint(
          'TOKEN NOT FOUND',
        );

        return {
          'success': false,
          'message':
              'Authentication token not found.',
        };
      }

      if (token == null || token.trim().isEmpty) {
        await _storage.write(
          key: 'auth_token',
          value: activeToken,
        );
      }

      if (legacyToken != null && legacyToken.trim().isNotEmpty) {
        await _storage.delete(
          key: 'token',
        );
      }

      debugPrint(
        'TOKEN FOUND',
      );

      // ========================================================
      // API REQUEST
      // ========================================================

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $activeToken',
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        'GET USER DETAILS STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'GET USER DETAILS RESPONSE: '
        '${response.body}',
      );

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded =
              jsonDecode(response.body);

          if (decoded
              is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (e) {
          debugPrint(
            'GET USER DETAILS JSON ERROR: $e',
          );

          return {
            'success': false,
            'message':
                'Invalid response from server.',
          };
        }
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      if (response.statusCode == 200) {
        return {
          'success': true,
          ...data,
        };
      }

      // ========================================================
      // UNAUTHORIZED
      // ========================================================

      if (response.statusCode == 401) {

        await _storage.delete(
          key: 'auth_token',
        );

        await _storage.delete(
          key: 'token',
        );

        return {
          'success': false,
          'message':
              'Session expired. Please login again.',
          'sessionExpired': true,
        };
      }

      // ========================================================
      // OTHER ERROR
      // ========================================================

      return {
        'success': false,
        'message': data['message'] ??
            'Unable to fetch user details.',
      };
    } catch (e) {

      debugPrint(
        'GET USER DETAILS ERROR: $e',
      );

      return {
        'success': false,
        'message':
            'Unable to connect to the server.',
        'error': e.toString(),
      };
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<Map<String, dynamic>> logout() async {
    final url = Uri.parse('$baseUrl/logout');

    try {
      final token = await _storage.read(key: 'auth_token');
      final legacyToken = await _storage.read(key: 'token');
      final activeToken = (token ?? legacyToken ?? '').trim();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (activeToken.isNotEmpty)
            'Authorization': 'Bearer $activeToken',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('LOGOUT STATUS: ${response.statusCode}');
      debugPrint('LOGOUT RESPONSE: ${response.body}');

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (e) {
          debugPrint('LOGOUT JSON ERROR: $e');
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _clearAuthStorage();
        return {
          'success': true,
          'message': data['message'] ?? 'Logout successful.',
        };
      }

      await _clearAuthStorage();

      return {
        'success': false,
        'message': data['message'] ?? 'Logout failed. Please try again.',
      };
    } catch (e) {
      debugPrint('LOGOUT ERROR: $e');
      await _clearAuthStorage();
      return {
        'success': false,
        'message': 'Unable to connect to the server.',
        'error': e.toString(),
      };
    }
  }

  static Future<void> _clearAuthStorage() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_first_name');
    await _storage.delete(key: 'user_last_name');
  }
}