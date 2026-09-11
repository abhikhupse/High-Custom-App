import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/auth_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'constants/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'widgets/app_permission_gate.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Web push requires Firebase web options, which are not configured yet.
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(const HighCustomApp());
}

class HighCustomApp extends StatelessWidget {
  const HighCustomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: PushNotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'High Custom Jewellers',
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _storage.read(key: 'auth_token');
    final legacyToken = await _storage.read(key: 'token');
    final normalizedToken = (token ?? legacyToken ?? '').trim();

    if (normalizedToken.isNotEmpty) {
      if (token == null || token.trim().isEmpty) {
        await _storage.write(key: 'auth_token', value: normalizedToken);
      }

      if (legacyToken != null && legacyToken.trim().isNotEmpty) {
        await _storage.delete(key: 'token');
      }
    }

    final profile = normalizedToken.isNotEmpty ? await AuthApi.getUserDetails() : null;
    final authorized = profile?['success'] == true;
    if (!mounted) {
      return;
    }
    if (profile != null && !authorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(profile['message']?.toString() ?? 'Please sign in again.')));
      });
    }

    setState(() {
      _isLoggedIn = authorized;
      _isChecking = false;
    });

    if (authorized) {
      await PushNotificationService.startForSignedInUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const ColoredBox(color: Colors.black);
    }

    return _isLoggedIn
        ? const AppPermissionGate(
            child: DashboardScreen(),
          )
        : const LoginScreen();
  }
}
