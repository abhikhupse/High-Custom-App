import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class TrackingApi {
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
      // --------------------------------------------------------
      // Current token key used by High Custom App
      // --------------------------------------------------------

      final token = await storage.read(
        key: 'auth_token',
      );

      if (token != null &&
          token.trim().isNotEmpty) {
        return token.trim();
      }

      // --------------------------------------------------------
      // Legacy token fallback
      // --------------------------------------------------------

      final legacyToken =
          await storage.read(
        key: 'token',
      );

      if (legacyToken != null &&
          legacyToken.trim().isNotEmpty) {
        final cleanToken =
            legacyToken.trim();

        // Migrate legacy token
        // to current auth_token key.

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

  static Future<
      Map<String, String>?> _headers() async {
    final token = await _token();

    if (token == null ||
        token.isEmpty) {
      return null;
    }

    return {
      'Accept': 'application/json',
      'Content-Type':
          'application/json',
      'Authorization':
          'Bearer $token',
    };
  }

  // ============================================================
  // GET TRACKING REPORT
  // ============================================================

  static Future<
      Map<String, dynamic>> getTrackingReport({
    String? sequenceId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers =
          await _headers();

      // --------------------------------------------------------
      // Authentication check
      // --------------------------------------------------------

      if (headers == null) {
        return {
          'success': false,
          'message':
              'Authentication token not found. Please login again.',
        };
      }

      // --------------------------------------------------------
      // Query parameters
      // --------------------------------------------------------

      final queryParameters =
          <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (sequenceId != null &&
          sequenceId.trim().isNotEmpty) {
        queryParameters[
                'sequenceId'] =
            sequenceId.trim();
      }

      // --------------------------------------------------------
      // URL
      // --------------------------------------------------------

      final uri = Uri.parse(
        '$baseUrl/email-tracking/report',
      ).replace(
        queryParameters:
            queryParameters,
      );

      // --------------------------------------------------------
      // API request
      // --------------------------------------------------------

      final response =
          await http
              .get(
                uri,
                headers: headers,
              )
              .timeout(
                const Duration(
                  seconds: 15,
                ),
              );

      return _decodeResponse(
        response,
      );
    } catch (error) {
      return {
        'success': false,
        'message':
            'Unable to connect to server.',
        'error':
            error.toString(),
      };
    }
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  static Map<String, dynamic>
      _decodeResponse(
    http.Response response,
  ) {
    try {
      final decoded =
          jsonDecode(response.body);

      if (decoded is Map) {
        return {
          'statusCode':
              response.statusCode,
          ...Map<String, dynamic>.from(
            decoded,
          ),
        };
      }

      return {
        'success': false,
        'statusCode':
            response.statusCode,
        'message':
            'Invalid server response.',
      };
    } catch (_) {
      return {
        'success': false,
        'statusCode':
            response.statusCode,
        'message':
            response.body.isNotEmpty
                ? response.body
                : 'Invalid server response.',
      };
    }
  }
}