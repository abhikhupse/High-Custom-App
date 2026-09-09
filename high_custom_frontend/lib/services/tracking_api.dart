import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class TrackingApi {
  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://high-custom-app.onrender.com/api',
  );

  // ============================================================
  // STORAGE
  // ============================================================

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  // ============================================================
  // GET TOKEN
  // ============================================================

  static Future<String?> _token() async {
    try {
      // --------------------------------------------------------
      // Current token key used by High Custom App
      // --------------------------------------------------------

      final token = await storage.read(key: 'auth_token');

      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }

      // --------------------------------------------------------
      // Legacy token fallback
      // --------------------------------------------------------

      final legacyToken = await storage.read(key: 'token');

      if (legacyToken != null && legacyToken.trim().isNotEmpty) {
        final cleanToken = legacyToken.trim();

        // Migrate legacy token
        // to current auth_token key.

        await storage.write(key: 'auth_token', value: cleanToken);

        await storage.delete(key: 'token');

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
  // GET TRACKING REPORT
  // ============================================================

  static Future<Map<String, dynamic>> getTrackingReport({
    String? sequenceId,
    String? search,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _headers();

      // --------------------------------------------------------
      // Authentication check
      // --------------------------------------------------------

      if (headers == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }

      // --------------------------------------------------------
      // Query parameters
      // --------------------------------------------------------

      final queryParameters = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (sequenceId != null && sequenceId.trim().isNotEmpty) {
        queryParameters['sequenceId'] = sequenceId.trim();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }
      if (status != null && status != 'All Status') {
        queryParameters['status'] = status;
      }
      if (startDate != null) {
        queryParameters['startDate'] = startDate.toUtc().toIso8601String();
      }
      if (endDate != null) {
        queryParameters['endDate'] = endDate.toUtc().toIso8601String();
      }

      // --------------------------------------------------------
      // URL
      // --------------------------------------------------------

      final uri = Uri.parse(
        '$baseUrl/email-tracking/report',
      ).replace(queryParameters: queryParameters);

      // --------------------------------------------------------
      // API request
      // --------------------------------------------------------

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      return _decodeResponse(response);
    } catch (error) {
      return {
        'success': false,
        'message': 'Unable to connect to server.',
        'error': error.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getNotifications({int limit = 50}) async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return {'success': false, 'message': 'Please login again.'};
      }

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/notifications',
            ).replace(queryParameters: {'limit': '$limit'}),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));
      return _decodeResponse(response);
    } catch (_) {
      return {'success': false, 'message': 'Unable to load notifications.'};
    }
  }

  static Future<bool> markNotificationsRead() async {
    try {
      final headers = await _headers();
      if (headers == null) return false;
      final response = await http
          .patch(Uri.parse('$baseUrl/notifications/read'), headers: headers)
          .timeout(const Duration(seconds: 15));
      return _decodeResponse(response)['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteNotification(String id) async {
    try {
      final headers = await _headers();
      if (headers == null || id.trim().isEmpty) return false;
      final response = await http
          .delete(
            Uri.parse('$baseUrl/notifications/${id.trim()}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));
      return _decodeResponse(response)['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // GET INTERESTED LEAD CONTACT DETAILS
  // ============================================================

  static Future<Map<String, dynamic>> getInterestDetails({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _headers();

      if (headers == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }
      final uri = Uri.parse('$baseUrl/email-tracking/interest-details').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

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

  static Map<String, dynamic> _decodeResponse(http.Response response) {
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
        'message': response.body.isNotEmpty
            ? response.body
            : 'Invalid server response.',
      };
    }
  }
}
