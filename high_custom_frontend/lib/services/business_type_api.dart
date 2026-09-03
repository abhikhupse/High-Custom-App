import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class BusinessTypeApi {
  static const String baseUrl =
      'https://high-custom-app.onrender.com/api/business-types';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<Map<String, String>?> _headers() async {
    var token = await _storage.read(key: 'auth_token');
    token ??= await _storage.read(key: 'token');
    if (token == null || token.trim().isEmpty) return null;

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.trim()}',
    };
  }

  static Future<Map<String, dynamic>> getBusinessTypes() async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return {'success': false, 'message': 'Authentication required.'};
      }
      final response = await http.get(Uri.parse(baseUrl), headers: headers);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {...body, 'statusCode': response.statusCode};
    } catch (_) {
      return {'success': false, 'message': 'Unable to load business types.'};
    }
  }

  static Future<Map<String, dynamic>> createBusinessType(String name) async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return {'success': false, 'message': 'Authentication required.'};
      }
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode({'name': name.trim()}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {...body, 'statusCode': response.statusCode};
    } catch (_) {
      return {'success': false, 'message': 'Unable to add business type.'};
    }
  }

  static Future<Map<String, dynamic>> updateBusinessType(
    String id,
    String name,
  ) async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return {'success': false, 'message': 'Authentication required.'};
      }
      final response = await http.patch(
        Uri.parse('$baseUrl/${Uri.encodeComponent(id)}'),
        headers: headers,
        body: jsonEncode({'name': name.trim()}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {...body, 'statusCode': response.statusCode};
    } catch (_) {
      return {'success': false, 'message': 'Unable to update business type.'};
    }
  }

  static Future<Map<String, dynamic>> deleteBusinessType(String id) async {
    try {
      final headers = await _headers();
      if (headers == null) {
        return {'success': false, 'message': 'Authentication required.'};
      }
      final response = await http.delete(
        Uri.parse('$baseUrl/${Uri.encodeComponent(id)}'),
        headers: headers,
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {...body, 'statusCode': response.statusCode};
    } catch (_) {
      return {'success': false, 'message': 'Unable to delete business type.'};
    }
  }
}
