import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'constants/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HighCustomApp());
}

class HighCustomApp extends StatelessWidget {
  const HighCustomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        await _storage.write(
          key: 'auth_token',
          value: normalizedToken,
        );
      }

      if (legacyToken != null && legacyToken.trim().isNotEmpty) {
        await _storage.delete(key: 'token');
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoggedIn = normalizedToken.isNotEmpty;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const DashboardScreen() : const LoginScreen();
  }
}
