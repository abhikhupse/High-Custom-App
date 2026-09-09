import 'package:flutter/material.dart';

import '../../services/tracking_api.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _background = Color(0xFF020507);
  static const _card = Color(0xFF0A0E13);
  static const _gold = Color(0xFFF2C45F);
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await TrackingApi.getNotifications();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final raw = result['notifications'];
        _items = raw is List
            ? raw
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : [];
      } else {
        _error =
            result['message']?.toString() ?? 'Unable to load notifications.';
      }
    });
  }

  Future<void> _markAllRead() async {
    final saved = await TrackingApi.markNotificationsRead();
    if (saved && mounted) await _load();
  }

  ({IconData icon, Color color, String message}) _presentation(
    Map<String, dynamic> item,
  ) {
    final email = item['email']?.toString() ?? 'A lead';
    switch (item['type']) {
      case 'opened':
        return (
          icon: Icons.visibility_outlined,
          color: const Color(0xFF9A4DFF),
          message: '$email has read your email.',
        );
      case 'replied':
        return (
          icon: Icons.reply_rounded,
          color: const Color(0xFF36D67A),
          message: '$email has replied to your email.',
        );
      case 'interested':
        return (
          icon: Icons.thumb_up_alt_outlined,
          color: const Color(0xFF18C6A1),
          message: '$email is interested in your email.',
        );
      case 'unsubscribed':
        return (
          icon: Icons.unsubscribe_outlined,
          color: const Color(0xFFFF7A45),
          message: '$email unsubscribed from your emails.',
        );
      default:
        return (
          icon: Icons.notifications_none_rounded,
          color: _gold,
          message: '$email has an email update.',
        );
    }
  }

  String _timeLabel(Map<String, dynamic> item) {
    final value = DateTime.tryParse(
      item['occurredAt']?.toString() ?? '',
    )?.toLocal();
    if (value == null) return '';
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: RefreshIndicator(
        color: _gold,
        backgroundColor: _card,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 27, 20, 32),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _items.isEmpty ? null : _markAllRead,
                  child: const Text('Mark all read'),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Text(
              'Stay updated on your email activity.',
              style: TextStyle(color: Color(0xFFAEB4BF), fontSize: 15),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator(color: _gold)),
              )
            else if (_error != null)
              _stateCard(Icons.cloud_off_rounded, _error!)
            else if (_items.isEmpty)
              _stateCard(
                Icons.notifications_none_rounded,
                'No notifications yet. Email activity will appear here.',
              )
            else
              ..._items.map(_notificationCard),
          ],
        ),
      ),
    );
  }

  Widget _stateCard(IconData icon, String text) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _gold.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Icon(icon, color: _gold, size: 36),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFAEB4BF), fontSize: 15),
        ),
      ],
    ),
  );

  Widget _notificationCard(Map<String, dynamic> item) {
    final data = _presentation(item);
    final unread = item['readAt'] == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: unread ? const Color(0xFF101722) : _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unread
              ? data.color.withOpacity(0.45)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _timeLabel(item),
                  style: const TextStyle(
                    color: Color(0xFFAEB4BF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: data.color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
