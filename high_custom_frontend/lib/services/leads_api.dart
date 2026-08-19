import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class LeadsApi {
  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl =
      'http://192.168.1.18:3000/api';

  // ============================================================
  // STORAGE
  // ============================================================

  static const FlutterSecureStorage storage =
      FlutterSecureStorage();

  // ============================================================
  // GET TOKEN
  // ============================================================

  static Future<String?> _token() async {
    try {
      final token = await storage.read(
        key: 'auth_token',
      );

      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }

      final legacyToken = await storage.read(
        key: 'token',
      );

      if (legacyToken != null &&
          legacyToken.trim().isNotEmpty) {
        final cleanToken = legacyToken.trim();

        await storage.write(
          key: 'auth_token',
          value: cleanToken,
        );

        await storage.delete(
          key: 'token',
        );

        return cleanToken;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // COMMON HEADERS
  // ============================================================

  static Future<Map<String, String>?> _headers() async {
    final token = await _token();

    if (token == null || token.isEmpty) {
      return null;
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // GET LEADS
  // ============================================================

  static Future<Map<String, dynamic>> getLeads() async {
    try {
      final headers = await _headers();

      if (headers == null) {
        return {
          'success': false,
          'message':
              'Authentication token not found. Please login again.',
        };
      }

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/leads/get-leads',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 15),
          );

      return _decodeResponse(response);
    } catch (error) {
      return {
        'success': false,
        'message': 'Unable to connect to server.',
        'error': error.toString(),
      };
    }
  }

  // ============================================================
  // CREATE LEAD
  // ============================================================

  static Future<Map<String, dynamic>> createLead({
    required String email,
    required String firstName,
    required String lastName,
    required String company,
    required String type,
    required bool tracking,
  }) async {
    try {
      final headers = await _headers();

      if (headers == null) {
        return {
          'success': false,
          'message':
              'Authentication token not found. Please login again.',
        };
      }

      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/leads/create-lead',
            ),
            headers: headers,
            body: jsonEncode({
              'email': email.trim(),
              'firstName': firstName.trim(),
              'lastName': lastName.trim(),
              'company': company.trim(),
              'type': type,
              'tracking': tracking,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      return _decodeResponse(response);
    } catch (error) {
      return {
        'success': false,
        'message': 'Unable to connect to server.',
        'error': error.toString(),
      };
    }
  }

  // ============================================================
  // UPDATE LEAD
  // ============================================================

  static Future<Map<String, dynamic>> updateLead({
    required String leadId,
    required String email,
    required String firstName,
    required String lastName,
    required String company,
    required String type,
    required bool tracking,
  }) async {
    try {
      final headers = await _headers();

      if (headers == null) {
        return {
          'success': false,
          'message':
              'Authentication token not found. Please login again.',
        };
      }

      final response = await http
          .put(
            Uri.parse(
              '$baseUrl/leads/update-lead/$leadId',
            ),
            headers: headers,
            body: jsonEncode({
              'email': email.trim(),
              'firstName': firstName.trim(),
              'lastName': lastName.trim(),
              'company': company.trim(),
              'type': type,
              'tracking': tracking,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      return _decodeResponse(response);
    } catch (error) {
      return {
        'success': false,
        'message': 'Unable to connect to server.',
        'error': error.toString(),
      };
    }
  }

  // ============================================================
  // DELETE LEAD
  // ============================================================

  static Future<Map<String, dynamic>> deleteLead({
    required String leadId,
  }) async {
    try {
      final headers = await _headers();

      if (headers == null) {
        return {
          'success': false,
          'message':
              'Authentication token not found. Please login again.',
        };
      }

      final response = await http
          .delete(
            Uri.parse(
              '$baseUrl/leads/delete-lead/$leadId',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 15),
          );

      return _decodeResponse(response);
    } catch (error) {
      return {
        'success': false,
        'message': 'Unable to connect to server.',
        'error': error.toString(),
      };
    }
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        return {
          'statusCode': response.statusCode,
          ...Map<String, dynamic>.from(decoded),
        };
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Invalid server response.',
      };
    } catch (_) {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message':
            response.body.isNotEmpty
                ? response.body
                : 'Invalid server response.',
      };
    }
  }
}