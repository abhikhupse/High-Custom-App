import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SequenceApi {
  static const String baseUrl =
      'https://high-custom-app.onrender.com/api/sequence';

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
  // CLEAR TOKEN
  // ============================================================

  static Future<void> _clearToken() async {
    await _storage.delete(
      key: 'auth_token',
    );

    await _storage.delete(
      key: 'token',
    );
  }

  // ============================================================
  // CREATE SEQUENCE
  // ============================================================

  static Future<Map<String, dynamic>> createSequence({
    required int step,
    required int gapDays,
    required String variant,
    required String businessType,
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

      // ========================================================
      // CLEAN OPTIONAL VALUES
      // ========================================================

      final cleanLogoUrl =
          logoUrl?.trim() ?? '';

      final cleanHeroImageUrl =
          heroImageUrl?.trim() ?? '';

      final cleanHeroImageLink =
          heroImageLink?.trim() ?? '';

      final cleanAttachmentName =
          attachmentName?.trim() ?? '';

      final cleanAttachmentUrl =
          attachmentUrl?.trim() ?? '';

      final cleanAttachmentMimeType =
          attachmentMimeType?.trim() ?? '';

      final cleanWhatsapp =
          whatsapp?.trim() ?? '';

      // ========================================================
      // REQUEST BODY
      //
      // IMPORTANT:
      //
      // Do NOT send empty logo/image/pdf/whatsapp objects.
      //
      // Only add them when the user actually selected/provided
      // them.
      // ========================================================

      final Map<String, dynamic> requestBody = {
        'step': step,
        'gapDays': gapDays,
        'variant': variant.trim().toUpperCase(),
        'type': 'Email',
        'channel': 'Email',
        'businessType': businessType.trim(),
        'subject': subject.trim(),

        'content': content,

        // ------------------------------------------------------
        // EDITOR
        // ------------------------------------------------------

        'editor': {
          'font': font ?? 'Arial',
          'fontSize': fontSize ?? '16px',
          'textColor': textColor ?? 'Black',
          'bold': bold,
          'italic': italic,
          'underline': underline,
        },

        // ------------------------------------------------------
        // TRACKING
        // ------------------------------------------------------

        'tracking': {
          'enabled': trackingEnabled,
        },

        'status': status,
      };

      // ========================================================
      // LOGO
      //
      // ONLY SEND IF ACTUALLY PROVIDED
      // ========================================================

      if (cleanLogoUrl.isNotEmpty) {
        requestBody['brand'] = {
          'logoUrl': cleanLogoUrl,
          'logoPosition': logoPosition ?? 'Center',
        };
      }

      // ========================================================
      // HERO IMAGE
      //
      // ONLY SEND IF ACTUALLY PROVIDED
      // ========================================================

      if (cleanHeroImageUrl.isNotEmpty) {
        requestBody['heroImage'] = {
          'url': cleanHeroImageUrl,
          'link': cleanHeroImageLink.isNotEmpty
              ? cleanHeroImageLink
              : null,
        };
      }

      // ========================================================
      // ATTACHMENT / PDF
      //
      // ONLY SEND IF ACTUALLY PROVIDED
      // ========================================================

      final bool hasAttachment =
          cleanAttachmentUrl.isNotEmpty ||
          cleanAttachmentName.isNotEmpty;

      if (hasAttachment) {
        requestBody['attachment'] = {
          'name': cleanAttachmentName.isNotEmpty
              ? cleanAttachmentName
              : null,
          'url': cleanAttachmentUrl.isNotEmpty
              ? cleanAttachmentUrl
              : null,
          'mimeType': cleanAttachmentMimeType.isNotEmpty
              ? cleanAttachmentMimeType
              : null,
          'size': attachmentSize,
        };
      }

      // ========================================================
      // WHATSAPP
      //
      // ONLY SEND IF ACTUALLY PROVIDED
      // ========================================================

      if (cleanWhatsapp.isNotEmpty) {
        requestBody['actionLinks'] = {
          'whatsapp': cleanWhatsapp,
        };
      }

      // ========================================================
      // SCHEDULED AT
      // ========================================================

      if (scheduledAt != null &&
          scheduledAt.trim().isNotEmpty) {
        requestBody['scheduledAt'] =
            scheduledAt.trim();
      }

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint(
        '================================================',
      );

      debugPrint(
        'CREATE SEQUENCE REQUEST',
      );

      debugPrint(
        const JsonEncoder.withIndent('  ')
            .convert(requestBody),
      );

      debugPrint(
        '================================================',
      );

      // ========================================================
      // REQUEST
      // ========================================================

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

      // ========================================================
      // RESPONSE DEBUG
      // ========================================================

      debugPrint(
        'CREATE SEQUENCE STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'CREATE SEQUENCE RESPONSE: '
        '${response.body}',
      );

      // ========================================================
      // DECODE
      // ========================================================

      final data = _decodeResponse(
        response.body,
      );

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
        await _clearToken();

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
  // UPDATE SEQUENCE
  // ============================================================

  static Future<Map<String, dynamic>> updateSequence({
    required String sequenceId,
    required int step,
    required int gapDays,
    required String variant,
    required String businessType,
    required String subject,
    required String content,
    String? logoUrl,
    String? logoPosition,
    String? heroImageUrl,
    String? heroImageLink,
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
    String? ctaText,
    String? ctaUrl,
    bool trackingEnabled = true,
    String status = 'draft',
    String? scheduledAt,
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

      final cleanSequenceId = sequenceId.trim();

      if (cleanSequenceId.isEmpty) {
        return {
          'success': false,
          'message': 'Sequence ID is required.',
        };
      }

      final requestBody = <String, dynamic>{
        'step': step,
        'gapDays': gapDays,
        'variant': variant.trim().toUpperCase(),
        'type': 'Email',
        'channel': 'Email',
        'businessType': businessType.trim(),
        'subject': subject.trim(),
        'content': content,
        'brand': {
          'logoUrl': logoUrl?.trim() ?? '',
          'logoPosition': logoPosition ?? 'Center',
        },
        'heroImage': {
          'url': heroImageUrl?.trim() ?? '',
          'link': heroImageLink?.trim() ?? '',
        },
        'editor': {
          'font': font ?? 'Arial',
          'fontSize': fontSize ?? '16px',
          'textColor': textColor ?? 'Black',
          'bold': bold,
          'italic': italic,
          'underline': underline,
        },
        'attachment': {
          'name': attachmentName?.trim() ?? '',
          'url': attachmentUrl?.trim() ?? '',
          'mimeType': attachmentMimeType?.trim() ?? '',
          'size': attachmentSize,
        },
        'actionLinks': {
          'whatsapp': whatsapp?.trim() ?? '',
          'cta': {
            'text': ctaText?.trim() ?? '',
            'url': ctaUrl?.trim() ?? '',
          },
        },
        'tracking': {
          'enabled': trackingEnabled,
        },
        'status': status,
        'scheduledAt': scheduledAt,
      };

      final response = await http
          .put(
            Uri.parse('$baseUrl/$cleanSequenceId'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $activeToken',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      debugPrint('UPDATE SEQUENCE STATUS: ${response.statusCode}');
      debugPrint('UPDATE SEQUENCE RESPONSE: ${response.body}');

      final data = _decodeResponse(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          ...data,
        };
      }

      if (response.statusCode == 401) {
        await _clearToken();

        return {
          'success': false,
          'message': data['message'] ??
              'Session expired. Please login again.',
          'sessionExpired': true,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Unable to update sequence.',
        'errors': data['errors'],
      };
    } catch (e) {
      debugPrint('UPDATE SEQUENCE ERROR: $e');

      return {
        'success': false,
        'message': 'Unable to connect to the server.',
        'error': e.toString(),
      };
    }
  }

  // ============================================================
  // GET TRACKING SUMMARY
  // ============================================================

  static Future<Map<String, dynamic>> getTrackingSummary({
    DateTime? startDate,
    DateTime? endDate,
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

      final queryParameters =
          <String, String>{};

      if (startDate != null) {
        queryParameters['startDate'] =
            _formatDateForApi(startDate);
      }

      if (endDate != null) {
        queryParameters['endDate'] =
            _formatDateForApi(endDate);
      }

      final uri = Uri.parse(
        '$baseUrl/tracking-summary',
      ).replace(
        queryParameters:
            queryParameters.isEmpty
                ? null
                : queryParameters,
      );

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
        'TRACKING SUMMARY STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'TRACKING SUMMARY RESPONSE: '
        '${response.body}',
      );

      final data = _decodeResponse(
        response.body,
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          'success': true,
          ...data,
        };
      }

      if (response.statusCode == 401) {
        await _clearToken();

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
                'Unable to fetch tracking summary.',
        'errors': data['errors'],
      };
    } catch (e) {
      debugPrint(
        'GET TRACKING SUMMARY ERROR: $e',
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

      final uri = Uri.parse(
        baseUrl,
      ).replace(
        queryParameters: queryParameters,
      );

      debugPrint(
        'GET SEQUENCES URL: $uri',
      );

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
        'GET SEQUENCES STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'GET SEQUENCES RESPONSE: '
        '${response.body}',
      );

      final data = _decodeResponse(
        response.body,
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          'success': true,
          ...data,
        };
      }

      if (response.statusCode == 401) {
        await _clearToken();

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

  // ============================================================
  // DELETE SEQUENCE
  // ============================================================

  static Future<Map<String, dynamic>> deleteSequence({
    required String sequenceId,
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

      final cleanSequenceId = sequenceId.trim();

      if (cleanSequenceId.isEmpty) {
        return {
          'success': false,
          'message': 'Sequence ID is required.',
        };
      }

      final uri = Uri.parse(
        '$baseUrl/$cleanSequenceId',
      );

      final response = await http
          .delete(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $activeToken',
            },
          )
          .timeout(
            const Duration(seconds: 20),
          );

      debugPrint(
        'DELETE SEQUENCE STATUS: ${response.statusCode}',
      );

      debugPrint(
        'DELETE SEQUENCE RESPONSE: ${response.body}',
      );

      final data = _decodeResponse(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          'success': true,
          ...data,
        };
      }

      if (response.statusCode == 401) {
        await _clearToken();

        return {
          'success': false,
          'message': data['message'] ??
              'Session expired. Please login again.',
          'sessionExpired': true,
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ?? 'Unable to delete sequence.',
        'errors': data['errors'],
      };
    } catch (e) {
      debugPrint(
        'DELETE SEQUENCE ERROR: $e',
      );

      return {
        'success': false,
        'message': 'Unable to connect to the server.',
        'error': e.toString(),
      };
    }
  }

  // ============================================================
  // RUN SEQUENCE
  // ============================================================

  static Future<Map<String, dynamic>> runSequence() async {
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

      final uri = Uri.parse(
        '$baseUrl/run',
      );

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization':
                  'Bearer $activeToken',
            },
          )
          .timeout(
            const Duration(seconds: 30),
          );

      debugPrint(
        'RUN SEQUENCE STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'RUN SEQUENCE RESPONSE: '
        '${response.body}',
      );

      final data = _decodeResponse(
        response.body,
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return {
          'success': true,
          ...data,
        };
      }

      if (response.statusCode == 401) {
        await _clearToken();

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
                'Unable to run sequence.',
        'errors': data['errors'],
      };
    } catch (e) {
      debugPrint(
        'RUN SEQUENCE ERROR: $e',
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
  // FORMAT DATE FOR API
  // ============================================================

  static String _formatDateForApi(
    DateTime date,
  ) {
    final year =
        date.year.toString().padLeft(
              4,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    return '$year-$month-$day';
  }

  // ============================================================
  // DECODE RESPONSE
  // ============================================================

  static Map<String, dynamic> _decodeResponse(
    String body,
  ) {
    if (body.trim().isEmpty) {
      return {};
    }

    try {
      final decoded =
          jsonDecode(body);

      if (decoded
          is Map<String, dynamic>) {
        return decoded;
      }

      return {};
    } catch (e) {
      debugPrint(
        'JSON DECODE ERROR: $e',
      );

      return {};
    }
  }
}
