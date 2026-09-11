import 'api_config.dart';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SocialLinksApi {
  static final String _baseUrl = '${ApiConfig.baseUrl}/social-links';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<Map<String, String>?> _headers() async {
    final token = (await _storage.read(key: 'auth_token'))?.trim();
    if (token == null || token.isEmpty) return null;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> list() => _request('GET', '');
  static Future<Map<String, dynamic>> listQr() => _request('GET', '/qr');

  static Future<Map<String, dynamic>> create({
    required String name,
    required String url,
    required String platform,
  }) => _request('POST', '', body: {'name': name, 'url': url, 'platform': platform});

  static Future<Map<String, dynamic>> update(
    String id, {
    String? name,
    String? url,
    bool? selected,
    String? qrTitle,
  }) => _request('PATCH', '/$id', body: {
    if (name != null) 'name': name,
    if (url != null) 'url': url,
    if (selected != null) 'selected': selected,
    if (qrTitle != null) 'qrTitle': qrTitle,
  });

  static Future<Map<String, dynamic>> delete(String id) => _request('DELETE', '/$id');
  static Future<Map<String, dynamic>> deleteQr(String id) => _request('DELETE', '/$id/qr');

  static Future<Map<String, dynamic>> generateQr(List<String> linkIds) =>
      _request('POST', '/generate-qr', body: {'linkIds': linkIds});

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await _headers();
      if (headers == null) return {'success': false, 'message': 'Please login again.'};
      final uri = Uri.parse('$_baseUrl$path');
      final Future<http.Response> request;
      switch (method) {
        case 'POST':
          request = http.post(uri, headers: headers, body: jsonEncode(body));
        case 'PATCH':
          request = http.patch(uri, headers: headers, body: jsonEncode(body));
        case 'DELETE':
          request = http.delete(uri, headers: headers);
        default:
          request = http.get(uri, headers: headers);
      }
      final response = await request.timeout(const Duration(seconds: 20));
      final decoded = jsonDecode(response.body);
      return {
        if (decoded is Map) ...Map<String, dynamic>.from(decoded),
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
      };
    } catch (_) {
      return {'success': false, 'message': 'Unable to connect to the server.'};
    }
  }
}
