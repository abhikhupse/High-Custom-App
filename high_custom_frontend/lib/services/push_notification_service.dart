import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../screens/dashboard/notifications_screen.dart';
import 'tracking_api.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static bool _started = false;

  static Future<void> startForSignedInUser() async {
    if (kIsWeb) return;
    if (!_started) {
      _started = true;
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _openNotifications());
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) _openNotifications();
      FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerToken(token);
  }

  static Future<void> _registerToken(String token) async {
    await TrackingApi.registerDeviceToken(token);
  }

  static void _openNotifications() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }
}
