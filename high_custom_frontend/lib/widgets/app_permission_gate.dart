import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissionGate extends StatefulWidget {
  const AppPermissionGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppPermissionGate> createState() => _AppPermissionGateState();
}

class _AppPermissionGateState extends State<AppPermissionGate> {
  static const _storage = FlutterSecureStorage();
  static const _promptKey = 'app_permissions_prompt_seen_v1';
  static const _gold = Color(0xFFF2C45F);
  static const _surface = Color(0xFF101113);
  static const _mutedText = Color(0xFF9B9CA3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPromptIfNeeded());
  }

  Future<void> _showPromptIfNeeded() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final promptSeen = await _storage.read(key: _promptKey);
    if (!mounted || promptSeen == 'true') return;

    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _gold.withValues(alpha: 0.35)),
        ),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: _gold),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Enable app features',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PermissionExplanation(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              description: 'Receive alerts for replies and sequence activity.',
            ),
            SizedBox(height: 18),
            _PermissionExplanation(
              icon: Icons.photo_library_outlined,
              title: 'Photos and files',
              description:
                  'Choose profile photos, lead files, and email attachments.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Not now',
              style: TextStyle(color: _mutedText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    await _storage.write(key: _promptKey, value: 'true');

    if (allow == true) {
      await _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();

    if (Platform.isIOS) {
      await Permission.photos.request();
      return;
    }

    // Android 13+ uses READ_MEDIA_IMAGES. Older Android releases use the
    // legacy storage permission, which is capped at API 32 in the manifest.
    await Permission.photos.request();
    await Permission.storage.request();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PermissionExplanation extends StatelessWidget {
  const _PermissionExplanation({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _AppPermissionGateState._gold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: _AppPermissionGateState._gold,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: _AppPermissionGateState._mutedText,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
