import 'package:flutter/foundation.dart';

class ApiConfig {
  static const _override = String.fromEnvironment('API_BASE_URL');
  static final String baseUrl = _override.isNotEmpty
      ? _override
      : kDebugMode && kIsWeb && ['localhost', '127.0.0.1'].contains(Uri.base.host)
          ? 'http://localhost:3000/api'
          : 'https://high-custom-app.onrender.com/api';
}
