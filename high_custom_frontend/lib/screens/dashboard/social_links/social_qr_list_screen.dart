import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:high_custom_frontend/services/social_links_api.dart';

class SocialQrListScreen extends StatefulWidget {
  const SocialQrListScreen({super.key});

  @override
  State<SocialQrListScreen> createState() => _SocialQrListScreenState();
}

class _SocialQrListScreenState extends State<SocialQrListScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _links = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final response = await SocialLinksApi.listQr();
    if (!mounted) return;
    if (response['success'] == true && response['data'] is List) {
      setState(() {
        _links = (response['data'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _loading = false;
      });
    } else {
      setState(() { _loading = false; _error = response['message']?.toString() ?? 'Unable to load QR codes.'; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF090A0C),
    appBar: AppBar(
      backgroundColor: const Color(0xFF101113),
      foregroundColor: Colors.white,
      title: const Text('Generated QR Codes'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFF2C45F)))
        : _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)))
            : _links.isEmpty
                ? const Center(child: Text('No QR codes generated yet.', style: TextStyle(color: Colors.white70)))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: .9,
                    ),
                    itemCount: _links.length,
                    itemBuilder: (_, index) => _card(_links[index]),
                  ),
  );

  Widget _card(Map<String, dynamic> link) {
    final rawQr = link['qrCode']?.toString() ?? '';
    final encoded = rawQr.contains(',') ? rawQr.split(',').last : rawQr;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF151619), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Expanded(child: rawQr.isEmpty ? const Icon(Icons.qr_code_2_rounded, color: Color(0xFFF2C45F), size: 100) : Image.memory(base64Decode(encoded))),
        Text(link['name']?.toString() ?? 'Link', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${link['linkClicks'] ?? 0} clicks · ${link['qrScans'] ?? 0} QR scans', style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ]),
    );
  }
}
