import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ProfileApi {
  // ============================================================
  // CONFIGURATION
  // ============================================================

  static const String serverUrl =
      'https://high-custom-app.onrender.com';

  static const String baseUrl =
      '$serverUrl/api/user';

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  // ============================================================
  // GET TOKEN
  // ============================================================

  static Future<String?> _getToken() async {
    try {
      String? token = await _storage.read(
        key: 'auth_token',
      );

      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }

      // Legacy token support
      token = await _storage.read(
        key: 'token',
      );

      if (token != null && token.trim().isNotEmpty) {
        await _storage.write(
          key: 'auth_token',
          value: token.trim(),
        );

        await _storage.delete(
          key: 'token',
        );

        return token.trim();
      }

      return null;
    } catch (error) {
      debugPrint(
        'PROFILE TOKEN ERROR: $error',
      );

      return null;
    }
  }

  // ============================================================
  // GET PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found.',
        };
      }

      final url = Uri.parse(
        '$baseUrl/profile',
      );

      debugPrint('================================');
      debugPrint('GET PROFILE');
      debugPrint('URL: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        'PROFILE STATUS: ${response.statusCode}',
      );

      debugPrint(
        'PROFILE RESPONSE: ${response.body}',
      );

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(
            response.body,
          );

          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (error) {
          debugPrint(
            'PROFILE JSON ERROR: $error',
          );

          return {
            'success': false,
            'message': 'Invalid response from server.',
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
        'message':
            data['message'] ??
            'Unable to load profile.',
      };
    } catch (error) {
      debugPrint(
        'GET PROFILE ERROR: $error',
      );

      return {
        'success': false,
        'message':
            'Unable to connect to the server.',
        'error': error.toString(),
      };
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    Uint8List? profileImageBytes,
    String? profileImageName,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found.',
        };
      }

      final url = Uri.parse(
        '$baseUrl/edit-profile',
      );

      debugPrint('================================');
      debugPrint('UPDATE PROFILE');
      debugPrint('URL: $url');

      // ========================================================
      // MULTIPART REQUEST
      // ========================================================

      final request =
          http.MultipartRequest(
        'PUT',
        url,
      );

      // ========================================================
      // HEADERS
      // ========================================================

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // ========================================================
      // TEXT FIELDS
      // ========================================================

      request.fields['firstName'] =
          firstName.trim();

      request.fields['lastName'] =
          lastName.trim();

      request.fields['email'] =
          email.trim().toLowerCase();

      request.fields['phone'] =
          phone.trim();

      // ========================================================
      // PROFILE IMAGE
      // ========================================================

      if (profileImageBytes != null) {
        final fileName =
            profileImageName ??
            'profile_image.jpg';

        request.files.add(
          http.MultipartFile.fromBytes(
            'profileImage',
            profileImageBytes,
            filename: fileName,
          ),
        );

        debugPrint(
          'PROFILE IMAGE: $fileName',
        );
      }

      // ========================================================
      // SEND
      // ========================================================

      final streamedResponse =
          await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        'UPDATE PROFILE STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'UPDATE PROFILE RESPONSE: '
        '${response.body}',
      );

      // ========================================================
      // PARSE RESPONSE
      // ========================================================

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(
            response.body,
          );

          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (error) {
          debugPrint(
            'UPDATE PROFILE JSON ERROR: $error',
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

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          'success': true,
          ...data,
        };
      }

      // ========================================================
      // ERROR
      // ========================================================

      return {
        'success': false,
        'message':
            data['message'] ??
            'Profile update failed.',
        'error': data['error'],
      };
    } catch (error) {
      debugPrint(
        'UPDATE PROFILE ERROR: $error',
      );

      return {
        'success': false,
        'message':
            'Unable to connect to the server.',
        'error': error.toString(),
      };
    }
  }

  // ============================================================
  // BUILD IMAGE URL
  // ============================================================

  static String? getImageUrl(
    dynamic profileImage,
  ) {
    if (profileImage == null) {
      return null;
    }

    final value =
        profileImage.toString().trim();

    if (value.isEmpty) {
      return null;
    }

    // Already full URL
    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }

    // Stored path:
    // /uploads/profile/image.jpg
    if (value.startsWith('/')) {
      return '$serverUrl$value';
    }

    return '$serverUrl/$value';
  }
}
