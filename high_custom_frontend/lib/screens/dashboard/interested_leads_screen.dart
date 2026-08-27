import 'package:flutter/material.dart';

import '../../services/tracking_api.dart';

class InterestedLeadsScreen extends StatefulWidget {
  const InterestedLeadsScreen({super.key});

  @override
  State<InterestedLeadsScreen> createState() => _InterestedLeadsScreenState();
}

class _InterestedLeadsScreenState extends State<InterestedLeadsScreen> {
  static const _gold = Color(0xFFF2C45F);
  static const _background = Color(0xFF020507);
  List<Map<String, dynamic>> _details = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final result = await TrackingApi.getInterestDetails();
    if (!mounted) return;

    final rawDetails = result['details'];
    setState(() {
      _loading = false;
      _error = result['success'] == true
          ? null
          : result['message']?.toString() ?? 'Unable to load interested leads.';
      _details = rawDetails is List
          ? rawDetails
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : [];
    });
  }

  String _text(dynamic value) => value?.toString().trim() ?? '';

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(_text(value))?.toLocal();
    if (parsed == null) return '—';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} '
        '${two(parsed.hour)}:${two(parsed.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: RefreshIndicator(
        onRefresh: _load,
        color: _gold,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Interested Leads',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_details.length} contact detail submission${_details.length == 1 ? '' : 's'}',
              style: const TextStyle(color: Color(0xFFAEB4BF)),
            ),
            const SizedBox(height: 22),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator(color: _gold)),
              )
            else if (_error != null)
              _MessageCard(message: _error!, onRetry: _load)
            else if (_details.isEmpty)
              const _MessageCard(
                message:
                    'No interested lead has submitted contact details yet.',
              )
            else
              ..._details.map(_buildCard),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final lead = item['leadId'] is Map
        ? Map<String, dynamic>.from(item['leadId'] as Map)
        : <String, dynamic>{};
    final sequence = item['sequenceId'] is Map
        ? Map<String, dynamic>.from(item['sequenceId'] as Map)
        : <String, dynamic>{};
    final location = [
      item['city'],
      item['state'],
      item['country'],
    ].map(_text).where((part) => part.isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _text(item['name']).isEmpty
                      ? 'Unnamed lead'
                      : _text(item['name']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const _InterestedBadge(),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(Icons.phone_outlined, _text(item['mobileNumber'])),
          if (_text(lead['email']).isNotEmpty)
            _DetailRow(Icons.email_outlined, _text(lead['email'])),
          if (_text(item['companyName']).isNotEmpty)
            _DetailRow(Icons.business_outlined, _text(item['companyName'])),
          _DetailRow(Icons.location_on_outlined, location),
          if (_text(sequence['subject']).isNotEmpty)
            _DetailRow(
              Icons.mark_email_read_outlined,
              _text(sequence['subject']),
            ),
          _DetailRow(Icons.schedule_outlined, _date(item['submittedAt'])),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.value);
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFAEB4BF)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(color: Color(0xFFD7DAE0), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestedBadge extends StatelessWidget {
  const _InterestedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71).withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Interested',
        style: TextStyle(color: Color(0xFF57D68D), fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.onRetry});
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFAEB4BF)),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
