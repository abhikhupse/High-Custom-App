import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ============================================================
// AUTH API
// ============================================================

class AuthApi {
  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl =
      'https://high-custom-app.onrender.com/api/user';

  // ============================================================
  // STORAGE
  // ============================================================

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  // ============================================================
  // JSON HEADERS
  // ============================================================

  static Map<String, String> get _jsonHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ============================================================
  // DECODE RESPONSE
  // ============================================================

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    if (response.body.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {};
    } catch (e) {
      debugPrint('JSON DECODE ERROR: $e');

      return {};
    }
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  static Future<String?> getToken() async {
    try {
      final token = await _storage.read(
        key: 'auth_token',
      );

      if (token != null &&
          token.trim().isNotEmpty) {
        return token.trim();
      }

      final legacyToken = await _storage.read(
        key: 'token',
      );

      if (legacyToken != null &&
          legacyToken.trim().isNotEmpty) {
        final cleanToken = legacyToken.trim();

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
    } catch (e) {
      debugPrint('GET TOKEN ERROR: $e');

      return null;
    }
  }

  // ============================================================
  // READ EMPLOYER CODE
  // ============================================================

  static Future<String?>
      readStoredEmployerCode() async {
    try {
      final code = await _storage.read(
        key: 'user_employer_code',
      );

      if (code != null &&
          code.trim().isNotEmpty) {
        return code.trim();
      }

      return null;
    } catch (e) {
      debugPrint(
        'READ EMPLOYER CODE ERROR: $e',
      );

      return null;
    }
  }

  // ============================================================
  // SAVE DATA FROM JWT
  // ============================================================

  static Future<void>
      _persistUserSessionFromToken(
    String token,
  ) async {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        debugPrint('INVALID JWT FORMAT');
        return;
      }

      final payload = parts[1];

      final normalized = payload
          .replaceAll('-', '+')
          .replaceAll('_', '/');

      final padded =
          normalized.length % 4 == 0
              ? normalized
              : '$normalized${'=' * (4 - normalized.length % 4)}';

      final decoded = utf8.decode(
        base64.decode(padded),
      );

      final dynamic json =
          jsonDecode(decoded);

      if (json is! Map) {
        return;
      }

      final data =
          Map<String, dynamic>.from(json);

      final id =
          data['id']?.toString();

      if (id != null &&
          id.trim().isNotEmpty) {
        await _storage.write(
          key: 'user_id',
          value: id.trim(),
        );
      }

      final email =
          data['email']?.toString();

      if (email != null &&
          email.trim().isNotEmpty) {
        await _storage.write(
          key: 'user_email',
          value: email.trim(),
        );
      }

      final employerCode =
          data['employerCode']?.toString();

      if (employerCode != null &&
          employerCode.trim().isNotEmpty) {
        await _storage.write(
          key: 'user_employer_code',
          value: employerCode.trim(),
        );
      }

      debugPrint(
        'JWT USER DATA SAVED',
      );
    } catch (e) {
      debugPrint(
        'JWT DECODE ERROR: $e',
      );
    }
  }

  // ============================================================
  // SAVE USER OBJECT
  // ============================================================

  static Future<void> _saveUserData(
    dynamic userData,
  ) async {
    if (userData is! Map) {
      return;
    }

    final user =
        Map<String, dynamic>.from(
      userData,
    );

    final id =
        (user['id'] ?? user['_id'])
            ?.toString();

    if (id != null &&
        id.trim().isNotEmpty) {
      await _storage.write(
        key: 'user_id',
        value: id.trim(),
      );
    }

    final email =
        user['email']?.toString();

    if (email != null &&
        email.trim().isNotEmpty) {
      await _storage.write(
        key: 'user_email',
        value: email.trim(),
      );
    }

    final firstName =
        user['firstName']?.toString();

    if (firstName != null &&
        firstName.trim().isNotEmpty) {
      await _storage.write(
        key: 'user_first_name',
        value: firstName.trim(),
      );
    }

    final lastName =
        user['lastName']?.toString();

    if (lastName != null &&
        lastName.trim().isNotEmpty) {
      await _storage.write(
        key: 'user_last_name',
        value: lastName.trim(),
      );
    }

    final employerCode =
        user['employerCode']?.toString();

    if (employerCode != null &&
        employerCode.trim().isNotEmpty) {
      await _storage.write(
        key: 'user_employer_code',
        value: employerCode.trim(),
      );
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<Map<String, dynamic>>
      register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String employerCode,
    required String password,
  }) async {
    final url =
        Uri.parse('$baseUrl/register');

    debugPrint(
      '======================================',
    );
    debugPrint('REGISTER API');
    debugPrint('URL: $url');

    try {
      final response = await http
          .post(
            url,
            headers: _jsonHeaders,
            body: jsonEncode({
              'firstName':
                  firstName.trim(),
              'lastName':
                  lastName.trim(),
              'phone':
                  phone.trim(),
              'email': email
                  .trim()
                  .toLowerCase(),
              'employerCode':
                  employerCode.trim(),
              'password':
                  password,
            }),
          )
          .timeout(
            const Duration(
              seconds: 20,
            ),
          );

      debugPrint(
        'REGISTER STATUS: ${response.statusCode}',
      );

      debugPrint(
        'REGISTER RESPONSE: ${response.body}',
      );

      final data =
          _decodeResponse(response);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          ...data,
          'success': true,
        };
      }

      return {
        ...data,
        'success': false,
        'message':
            data['message']?.toString() ??
                'Registration failed. Please try again.',
      };
    } catch (e) {
      debugPrint(
        'REGISTER ERROR: $e',
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
  // VERIFY OTP
  // ============================================================

  static Future<Map<String, dynamic>>
      verifyOtp({
    required String email,
    required String otp,
  }) async {
    final url =
        Uri.parse('$baseUrl/verify-otp');

    final cleanEmail =
        email.trim().toLowerCase();

    final cleanOtp =
        otp.trim();

    debugPrint(
      '======================================',
    );
    debugPrint('VERIFY OTP API');
    debugPrint('URL: $url');

    try {
      final response = await http
          .post(
            url,
            headers: _jsonHeaders,
            body: jsonEncode({
              'email': cleanEmail,
              'otp': cleanOtp,
            }),
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      debugPrint(
        'VERIFY OTP STATUS: ${response.statusCode}',
      );

      debugPrint(
        'VERIFY OTP RESPONSE: ${response.body}',
      );

      final data =
          _decodeResponse(response);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          ...data,
          'success': true,
        };
      }

      return {
        ...data,
        'success': false,
        'message':
            data['message']?.toString() ??
                'OTP verification failed.',
      };
    } catch (e) {
      debugPrint(
        'VERIFY OTP ERROR: $e',
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
  // RESEND OTP
  // ============================================================

  static Future<Map<String, dynamic>>
      resendOtp({
    required String email,
  }) async {
    final url =
        Uri.parse('$baseUrl/resend-otp');

    final cleanEmail =
        email.trim().toLowerCase();

    debugPrint(
      '======================================',
    );
    debugPrint('RESEND OTP API');
    debugPrint('URL: $url');

    try {
      final response = await http
          .post(
            url,
            headers: _jsonHeaders,
            body: jsonEncode({
              'email': cleanEmail,
            }),
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      debugPrint(
        'RESEND STATUS: ${response.statusCode}',
      );

      debugPrint(
        'RESEND RESPONSE: ${response.body}',
      );

      final data =
          _decodeResponse(response);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          ...data,
          'success': true,
        };
      }

      return {
        ...data,
        'success': false,
        'message':
            data['message']?.toString() ??
                'Unable to resend OTP.',
      };
    } catch (e) {
      debugPrint(
        'RESEND OTP ERROR: $e',
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
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>>
      login({
    required String email,
    required String password,
  }) async {
    final cleanEmail =
        email.trim().toLowerCase();

    final url =
        Uri.parse('$baseUrl/login');

    debugPrint(
      '======================================',
    );
    debugPrint('LOGIN API');
    debugPrint('URL: $url');
    debugPrint('EMAIL: $cleanEmail');

    try {
      final response = await http
          .post(
            url,
            headers: _jsonHeaders,
            body: jsonEncode({
              'email': cleanEmail,
              'password': password,
            }),
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      debugPrint(
        'LOGIN STATUS: ${response.statusCode}',
      );

      debugPrint(
        'LOGIN RESPONSE: ${response.body}',
      );

      final data =
          _decodeResponse(response);

      // ========================================================
      // SUCCESS
      // ========================================================

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        final token =
            data['token']
                ?.toString()
                .trim();

        if (token == null ||
            token.isEmpty) {
          return {
            'success': false,
            'message':
                'Login successful but authentication token was not received.',
          };
        }

        await _storage.write(
          key: 'auth_token',
          value: token,
        );

        await _storage.delete(
          key: 'token',
        );

        await _persistUserSessionFromToken(
          token,
        );

        if (data['user'] != null) {
          await _saveUserData(
            data['user'],
          );
        }

        final savedToken =
            await _storage.read(
          key: 'auth_token',
        );

        if (savedToken == null ||
            savedToken
                .trim()
                .isEmpty) {
          return {
            'success': false,
            'message':
                'Unable to save login session.',
          };
        }

        debugPrint(
          'JWT TOKEN SAVED SUCCESSFULLY',
        );

        debugPrint(
          'LOGIN SUCCESS',
        );

        return {
          ...data,
          'success': true,
          'token': token,
        };
      }

      // ========================================================
      // FAILED
      // ========================================================

      return {
        ...data,
        'success': false,
        'message':
            data['message']?.toString() ??
                'Login failed. Please try again.',
        'statusCode':
            response.statusCode,
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
  // GET USER DETAILS
  // ============================================================

  static Future<Map<String, dynamic>>
      getUserDetails() async {
    final url =
        Uri.parse('$baseUrl/profile');

    debugPrint(
      '======================================',
    );
    debugPrint(
      'GET USER DETAILS API',
    );
    debugPrint('URL: $url');

    try {
      final token = await getToken();

      if (token == null ||
          token.isEmpty) {
        return {
          'success': false,
          'message':
              'Authentication token not found.',
          'sessionExpired': true,
        };
      }

      final response = await http
          .get(
            url,
            headers: {
              'Accept':
                  'application/json',
              'Authorization':
                  'Bearer $token',
            },
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      debugPrint(
        'GET USER DETAILS STATUS: ${response.statusCode}',
      );

      debugPrint(
        'GET USER DETAILS RESPONSE: ${response.body}',
      );

      final data =
          _decodeResponse(response);

      if (response.statusCode == 200) {
        if (data['user'] != null) {
          await _saveUserData(
            data['user'],
          );
        }

        return {
          ...data,
          'success': true,
        };
      }

      if (response.statusCode == 401) {
        await clearLocalSession();

        return {
          ...data,
          'success': false,
          'message':
              data['message']?.toString() ??
                  'Session expired. Please login again.',
          'sessionExpired': true,
        };
      }

      return {
        ...data,
        'success': false,
        'message':
            data['message']?.toString() ??
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
  // EDIT PROFILE
  // ============================================================

  static Future<Map<String, dynamic>>
      editProfile({
    required String firstName,
    required String lastName,
    required String phone,
    File? profileImage,
  }) async {
    final url =
        Uri.parse('$baseUrl/edit-profile');

    debugPrint(
      '======================================',
    );
    debugPrint(
      'EDIT PROFILE API',
    );
    debugPrint('URL: $url');

    try {
      final token =
          await getToken();

      if (token == null ||
          token.isEmpty) {
        return {
          'success': false,
          'message':
              'Authentication token not found.',
          'sessionExpired': true,
        };
      }

      final request =
          http.MultipartRequest(
        'PUT',
        url,
      );

      request.headers.addAll({
        'Accept':
            'application/json',
        'Authorization':
            'Bearer $token',
      });

      request.fields['firstName'] =
          firstName.trim();

      request.fields['lastName'] =
          lastName.trim();

      request.fields['phone'] =
          phone.trim();

      if (profileImage != null) {
        final file =
            await http.MultipartFile
                .fromPath(
          'profileImage',
          profileImage.path,
        );

        request.files.add(file);
      }

      final streamedResponse =
          await request
              .send()
              .timeout(
                const Duration(
                  seconds: 30,
                ),
              );

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        'EDIT PROFILE STATUS: ${response.statusCode}',
      );

      debugPrint(
        'EDIT PROFILE RESPONSE: ${response.body}',
      );

      final data =
          _decodeResponse(response);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        if (data['user'] != null) {
          await _saveUserData(
            data['user'],
          );
        }

        return {
          ...data,
          'success': true,
        };
      }

      if (response.statusCode == 401) {
        await clearLocalSession();

        return {
          ...data,
          'success': false,
          'message':
              data['message']?.toString() ??
                  'Session expired. Please login again.',
          'sessionExpired': true,
        };
      }

      return {
        ...data,
        'success': false,
        'message':
            data['message']?.toString() ??
                'Unable to update profile.',
      };
    } catch (e) {
      debugPrint(
        'EDIT PROFILE ERROR: $e',
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

  static Future<Map<String, dynamic>>
      logout() async {
    final url =
        Uri.parse('$baseUrl/logout');

    debugPrint(
      '======================================',
    );
    debugPrint('LOGOUT API');
    debugPrint('URL: $url');

    try {
      final token =
          await getToken();

      if (token == null ||
          token.isEmpty) {
        await clearLocalSession();

        return {
          'success': true,
          'message':
              'Logged out successfully.',
        };
      }

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type':
                  'application/json',
              'Accept':
                  'application/json',
              'Authorization':
                  'Bearer $token',
            },
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      debugPrint(
        'LOGOUT STATUS: ${response.statusCode}',
      );

      debugPrint(
        'LOGOUT RESPONSE: ${response.body}',
      );

      final data =
          _decodeResponse(response);

      await clearLocalSession();

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          ...data,
          'success': true,
        };
      }

      if (response.statusCode == 401) {
        return {
          'success': true,
          'message':
              'Logged out successfully.',
        };
      }

      return {
        ...data,
        'success': false,
        'message':
            data['message']?.toString() ??
                'Logout failed.',
      };
    } catch (e) {
      debugPrint(
        'LOGOUT ERROR: $e',
      );

      await clearLocalSession();

      return {
        'success': true,
        'message':
            'Logged out successfully.',
      };
    }
  }

  // ============================================================
  // CLEAR LOCAL SESSION
  // ============================================================

  static Future<void>
      clearLocalSession() async {
    try {
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
        'LOCAL SESSION CLEARED',
      );
    } catch (e) {
      debugPrint(
        'CLEAR SESSION ERROR: $e',
      );
    }
  }

  // ============================================================
  // IS LOGGED IN
  // ============================================================

  static Future<bool>
      isLoggedIn() async {
    final token = await getToken();

    return token != null &&
        token.isNotEmpty;
  }

  // ============================================================
  // READ STORED EMAIL
  // ============================================================

  static Future<String?>
      readStoredEmail() async {
    try {
      return await _storage.read(
        key: 'user_email',
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // READ STORED USER ID
  // ============================================================

  static Future<String?>
      readStoredUserId() async {
    try {
      return await _storage.read(
        key: 'user_id',
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // READ STORED FIRST NAME
  // ============================================================

  static Future<String?>
      readStoredFirstName() async {
    try {
      return await _storage.read(
        key: 'user_first_name',
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // READ STORED LAST NAME
  // ============================================================

  static Future<String?>
      readStoredLastName() async {
    try {
      return await _storage.read(
        key: 'user_last_name',
      );
    } catch (_) {
      return null;
    }
  }
}
