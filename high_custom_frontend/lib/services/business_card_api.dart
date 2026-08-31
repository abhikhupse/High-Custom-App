import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class BusinessCardApi {
  static const String baseUrl =
      'https://high-custom-app.onrender.com/api/business-card';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> _token() async {
    final authToken = await _storage.read(key: 'auth_token');
    if (authToken != null && authToken.trim().isNotEmpty) {
      return authToken.trim();
    }

    final legacyToken = await _storage.read(key: 'token');
    if (legacyToken == null || legacyToken.trim().isEmpty) return null;
    final token = legacyToken.trim();
    await _storage.write(key: 'auth_token', value: token);
    await _storage.delete(key: 'token');
    return token;
  }

  static Future<Map<String, String>?> _headers() async {
    final token = await _token();
    if (token == null) return null;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> fetch() async {
    return _request(method: 'GET', path: '/fetch-businessCard');
  }

  static Future<Map<String, dynamic>> create({
    required Map<String, dynamic> card,
  }) async {
    return _request(method: 'POST', path: '/create-BusinessCard', body: card);
  }

  static Future<Map<String, dynamic>> update({
    required Map<String, dynamic> card,
  }) async {
    return _request(method: 'PUT', path: '/update-businessCard', body: card);
  }

  static Future<Map<String, dynamic>> delete() async {
    return _request(method: 'DELETE', path: '/delete-businessCard');
  }

  static Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Authentication token not found. Please login again.',
        };
      }

      final uri = Uri.parse('$baseUrl$path');
      late http.Response response;
      switch (method) {
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 20));
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 20));
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 20));
        default:
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 20));
      }

      final decoded = _decode(response.body);
      return {
        ...decoded,
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Unable to connect to the server.',
        'error': error.toString(),
      };
    }
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic>
          ? value
          : {'message': 'Unexpected server response.'};
    } catch (_) {
      return {'message': 'Unexpected server response.'};
    }
  }
}
