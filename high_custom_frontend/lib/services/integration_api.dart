import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class IntegrationApi {
  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl =
      'https://high-custom-app.onrender.com/api';

  // ============================================================
  // STORAGE
  // ============================================================

  static const FlutterSecureStorage storage =
      FlutterSecureStorage();

  // ============================================================
  // TOKEN
  // ============================================================

  static Future<String?> _token() async {
    try {
      // --------------------------------------------------------
      // NEW TOKEN
      // --------------------------------------------------------

      final token = await storage.read(
        key: 'auth_token',
      );

      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }

      // --------------------------------------------------------
      // LEGACY TOKEN
      // --------------------------------------------------------

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
    } catch (error) {
      return null;
    }
  }

  // ============================================================
  // GMAIL STATUS
  // ============================================================

  static Future<Map<String, dynamic>> gmailStatus() async {
    try {
      final token = await _token();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Authentication token not found.',
        };
      }

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/integrations/gmail/status',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      return _decodeResponse(response);
    } catch (error) {
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Unable to connect to the server.',
        'error': error.toString(),
      };
    }
  }

  // ============================================================
  // CONNECT GMAIL
  // ============================================================

  static Future<Map<String, dynamic>> connectGmail() async {
    try {
      final token = await _token();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Authentication token not found.',
        };
      }

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/integrations/gmail/connect',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      return _decodeResponse(response);
    } catch (error) {
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Unable to connect to the server.',
        'error': error.toString(),
      };
    }
  }

  // ============================================================
  // DISCONNECT GMAIL
  // ============================================================

  static Future<Map<String, dynamic>> disconnectGmail() async {
    try {
      final token = await _token();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Authentication token not found.',
        };
      }

      final response = await http
          .delete(
            Uri.parse(
              '$baseUrl/integrations/gmail/disconnect',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      return _decodeResponse(response);
    } catch (error) {
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Unable to connect to the server.',
        'error': error.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> zohoStatus() =>
      _authorizedRequest('GET', '/integrations/zoho/status');

  static Future<Map<String, dynamic>> connectZoho() =>
      _authorizedRequest('GET', '/integrations/zoho/connect');

  static Future<Map<String, dynamic>> disconnectZoho() =>
      _authorizedRequest('DELETE', '/integrations/zoho/disconnect');

  static Future<Map<String, dynamic>> _authorizedRequest(
    String method,
    String path,
  ) async {
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Authentication token not found.',
        };
      }
      final uri = Uri.parse('$baseUrl$path');
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = method == 'DELETE'
          ? await http.delete(uri, headers: headers).timeout(
                const Duration(seconds: 15),
              )
          : await http.get(uri, headers: headers).timeout(
                const Duration(seconds: 15),
              );
      return _decodeResponse(response);
    } catch (error) {
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Unable to connect to the server.',
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
    } catch (error) {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Invalid server response.',
        'rawResponse': response.body,
      };
    }
  }
}
