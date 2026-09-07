import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class BusinessLinkSettingsApi {
  static const _base = 'https://high-custom-app.onrender.com/api/business-link-settings';
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> save(String businessType, List<String> actionLinkIds) =>
      _request('PUT', body: {'businessType': businessType, 'actionLinkIds': actionLinkIds});

  static Future<Map<String, dynamic>> get(String businessType) =>
      _request('GET', query: businessType);

  static Future<Map<String, dynamic>> _request(String method, {Map<String, dynamic>? body, String? query}) async {
    try {
      final token = (await _storage.read(key: 'auth_token'))?.trim();
      if (token == null || token.isEmpty) return {'success': false, 'message': 'Please login again.'};
      final uri = Uri.parse(_base).replace(queryParameters: query == null ? null : {'businessType': query});
      final headers = {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
      final response = await (method == 'PUT' ? http.put(uri, headers: headers, body: jsonEncode(body)) : http.get(uri, headers: headers)).timeout(const Duration(seconds: 20));
      final data = jsonDecode(response.body);
      return {if (data is Map) ...Map<String, dynamic>.from(data), 'success': response.statusCode >= 200 && response.statusCode < 300};
    } catch (_) { return {'success': false, 'message': 'Unable to connect to the server.'}; }
  }
}
