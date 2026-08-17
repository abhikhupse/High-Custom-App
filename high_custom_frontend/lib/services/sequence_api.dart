import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SequenceApi {
  static const String baseUrl =
      'http://192.168.1.18:3000/api/sequence';

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  // ============================================================
  // GET TOKEN
  // ============================================================

  static Future<String?> _getToken() async {
    final token = await _storage.read(
      key: 'auth_token',
    );

    final legacyToken = await _storage.read(
      key: 'token',
    );

    final activeToken =
        (token ?? legacyToken ?? '').trim();

    if (activeToken.isEmpty) {
      return null;
    }

    return activeToken;
  }

  // ============================================================
  // CREATE SEQUENCE
  // ============================================================

  static Future<Map<String, dynamic>> createSequence({
    required int step,
    required int gapDays,
    required String variant,
    required String type,
    required String subject,

    String? logoUrl,
    String? logoPosition,

    String? heroImageUrl,
    String? heroImageLink,

    required String content,

    String? font,
    String? fontSize,
    String? textColor,

    bool bold = false,
    bool italic = false,
    bool underline = false,

    String? attachmentName,
    String? attachmentUrl,
    String? attachmentMimeType,
    int attachmentSize = 0,

    String? whatsapp,

    bool trackingEnabled = true,

    String status = 'draft',

    String? scheduledAt,
  }) async {
    final url = Uri.parse(
      '$baseUrl/create-sequence',
    );

    try {
      final activeToken = await _getToken();

      if (activeToken == null) {
        return {
          'success': false,
          'message':
              'Authentication token not found. Please login again.',
          'sessionExpired': true,
        };
      }

      final Map<String, dynamic> requestBody = {
        'step': step,
        'gapDays': gapDays,
        'variant': variant.trim().toUpperCase(),
        'type': type,
        'subject': subject.trim(),

        'brand': {
          'logoUrl': logoUrl,
          'logoPosition':
              logoPosition ?? 'Center',
        },

        'heroImage': {
          'url': heroImageUrl,
          'link': heroImageLink,
        },

        'content': content,

        'editor': {
          'font': font ?? 'Arial',
          'fontSize': fontSize ?? '16px',
          'textColor': textColor ?? 'Black',
          'bold': bold,
          'italic': italic,
          'underline': underline,
        },

        'attachment': {
          'name': attachmentName,
          'url': attachmentUrl,
          'mimeType': attachmentMimeType,
          'size': attachmentSize,
        },

        'actionLinks': {
          'whatsapp': whatsapp,
        },

        'tracking': {
          'enabled': trackingEnabled,
        },

        'status': status,

        'scheduledAt': scheduledAt,

        'statistics': {
          'sent': 0,
          'delivered': 0,
          'opened': 0,
          'clicked': 0,
          'failed': 0,
          'interested': 0,
          'notInterested': 0,
        },
      };

      debugPrint(
        'CREATE SEQUENCE BODY: ${jsonEncode(requestBody)}',
      );

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization':
                  'Bearer $activeToken',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      debugPrint(
        'CREATE STATUS: ${response.statusCode}',
      );

      debugPrint(
        'CREATE RESPONSE: ${response.body}',
      );

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded =
              jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (e) {
          return {
            'success': false,
            'message':
                'Invalid response from server.',
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

      if (response.statusCode == 401) {
        await _storage.delete(
          key: 'auth_token',
        );

        await _storage.delete(
          key: 'token',
        );

        return {
          'success': false,
          'message':
              data['message'] ??
                  'Session expired. Please login again.',
          'sessionExpired': true,
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'Unable to create sequence.',
        'errors': data['errors'],
      };
    } catch (e) {
      debugPrint(
        'CREATE SEQUENCE ERROR: $e',
      );

      return {
        'success': false,
        'message':
            'Unable to connect to the server.',
        'error': e.toString(),
      };
    }
  }

  // ============================================================
  // GET SEQUENCES
  // ============================================================

  static Future<Map<String, dynamic>> getSequences({
    int page = 1,
    int limit = 10,
    String search = '',
    String status = '',
  }) async {
    try {
      final activeToken = await _getToken();

      if (activeToken == null) {
        return {
          'success': false,
          'message':
              'Authentication token not found. Please login again.',
          'sessionExpired': true,
        };
      }

      // ========================================================
      // QUERY PARAMETERS
      // ========================================================

      final queryParameters = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search.trim().isNotEmpty) {
        queryParameters['search'] =
            search.trim();
      }

      if (status.trim().isNotEmpty) {
        queryParameters['status'] =
            status.trim();
      }

      final uri = Uri.parse(baseUrl)
          .replace(
        queryParameters: queryParameters,
      );

      debugPrint(
        'GET SEQUENCES URL: $uri',
      );

      // ========================================================
      // GET REQUEST
      // ========================================================

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization':
                  'Bearer $activeToken',
            },
          )
          .timeout(
            const Duration(seconds: 20),
          );

      debugPrint(
        'GET SEQUENCES STATUS: ${response.statusCode}',
      );

      debugPrint(
        'GET SEQUENCES RESPONSE: ${response.body}',
      );

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded =
              jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (e) {
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
      // UNAUTHORIZED
      // ========================================================

      if (response.statusCode == 401) {
        await _storage.delete(
          key: 'auth_token',
        );

        await _storage.delete(
          key: 'token',
        );

        return {
          'success': false,
          'message':
              data['message'] ??
                  'Session expired. Please login again.',
          'sessionExpired': true,
        };
      }

      // ========================================================
      // ERROR
      // ========================================================

      return {
        'success': false,
        'message':
            data['message'] ??
                'Unable to fetch sequences.',
        'errors': data['errors'],
      };
    } catch (e) {
      debugPrint(
        'GET SEQUENCES ERROR: $e',
      );

      return {
        'success': false,
        'message':
            'Unable to connect to the server.',
        'error': e.toString(),
      };
    }
  }
}