import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class LeadsApi {
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
    required String businessType,
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
              'businessType': businessType.trim(),
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
  // UPLOAD LEADS EXCEL
  //
  // Excel columns:
  //
  // First Name
  // Last Name
  // Email
  // Company
  // Type
  //
  // TRACKING IS NOT INCLUDED.
  // ============================================================

  static Future<Map<String, dynamic>> uploadLeadsExcel({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final token = await _token();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message':
              'Authentication token not found. Please login again.',
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$baseUrl/leads/import-excel',
        ),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request
          .send()
          .timeout(
            const Duration(minutes: 2),
          );

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      return _decodeResponse(response);
    } catch (error) {
      return {
        'success': false,
        'message':
            'Unable to upload Excel file.',
        'error': error.toString(),
      };
    }
  }

  // ============================================================
  // OLD IMPORT METHOD
  //
  // Kept for compatibility.
  // ============================================================

  static Future<Map<String, dynamic>> importLeadsFromExcel({
    required String filePath,
    required Uint8List bytes,
  }) async {
    final fileName = filePath
        .split(RegExp(r'[\\/]'))
        .last;

    return uploadLeadsExcel(
      bytes: bytes,
      fileName: fileName,
    );
  }

  // ============================================================
  // DOWNLOAD LEADS EXCEL
  //
  // Tracking is NOT included.
  //
  // IMPORTANT:
  // This returns http.Response because the response
  // contains binary Excel data.
  // ============================================================

  static Future<http.Response?> downloadLeadsExcel() async {
    try {
      final token = await _token();

      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/leads/export-excel',
            ),
            headers: {
              'Accept':
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              'Authorization':
                  'Bearer $token',
            },
          )
          .timeout(
            const Duration(minutes: 2),
          );

      return response;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    try {
      final body = response.body.trim();

      if (body.isEmpty) {
        return {
          'success':
              response.statusCode >= 200 &&
              response.statusCode < 300,
          'statusCode':
              response.statusCode,
          'message':
              response.statusCode >= 200 &&
                      response.statusCode < 300
                  ? 'Request completed successfully.'
                  : 'Server returned an empty response.',
        };
      }

      final decoded = jsonDecode(body);

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
