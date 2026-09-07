import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      title: const Text('My QR Codes'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFF2C45F)))
        : _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)))
            : _links.isEmpty
                ? const Center(child: Text('No QR codes generated yet.', style: TextStyle(color: Colors.white70)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    itemCount: _links.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return Text(
                          '${_links.length} active QR code${_links.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 15,
                          ),
                        );
                      }
                      return _card(_links[index - 1]);
                    },
                  ),
  );

  Widget _card(Map<String, dynamic> link) {
    final rawQr = link['qrCode']?.toString() ?? '';
    final encoded = rawQr.contains(',') ? rawQr.split(',').last : rawQr;
    return Container(
      constraints: const BoxConstraints(minHeight: 176),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151619),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: Row(
        children: [
          Container(
            width: 122,
            height: 122,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: rawQr.isEmpty
                ? const Icon(Icons.qr_code_2_rounded,
                    color: Color(0xFF090A0C), size: 90)
                : Image.memory(base64Decode(encoded), fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        link['qrTitle']?.toString().isNotEmpty == true
                            ? link['qrTitle'].toString()
                            : link['name']?.toString() ?? 'Untitled QR',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      color: const Color(0xFF202226),
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Color(0xFFF2C45F)),
                      onSelected: (value) {
                        if (value == 'edit') _editTitle(link);
                        if (value == 'delete') _deleteQr(link);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(
                        text: link['trackingTarget']?.toString() ??
                            link['qrTarget']
                                ?.toString()
                                .replaceFirst('source=qr', 'source=link') ??
                            ''));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('QR link copied.')));
                    }
                  },
                  child: Text(
                    link['trackingTarget']?.toString() ??
                        link['qrTarget']
                            ?.toString()
                            .replaceFirst('source=qr', 'source=link') ??
                        '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF303238), height: 18),
                Row(
                  children: [
                    Expanded(child: _metric('Scans', link['qrScans'] ?? 0,
                        Icons.qr_code_scanner_rounded)),
                    Container(width: 1, height: 35, color: const Color(0xFF4A4131)),
                    Expanded(child: _metric('Clicks', link['linkClicks'] ?? 0,
                        Icons.ads_click_rounded)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, dynamic value, IconData icon) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: const Color(0xFFF2C45F)),
      const SizedBox(height: 3),
      Text(value.toString(), style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ],
  );

  Future<void> _editTitle(Map<String, dynamic> link) async {
    final controller = TextEditingController(text: link['qrTitle']?.toString().isNotEmpty == true ? link['qrTitle'].toString() : link['name']?.toString() ?? '');
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151619),
        title: const Text('Edit QR Title', style: TextStyle(color: Colors.white)),
        content: TextField(controller: controller, autofocus: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'QR title', hintStyle: TextStyle(color: Colors.white54))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty) return;
    final response = await SocialLinksApi.update(link['_id'].toString(), qrTitle: title);
    if (response['success'] == true) await _load();
  }

  Future<void> _deleteQr(Map<String, dynamic> link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151619),
        title: const Text('Delete QR Code?', style: TextStyle(color: Colors.white)),
        content: const Text('The link will stay saved. Only its QR code will be removed.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6975)), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final response = await SocialLinksApi.deleteQr(link['_id'].toString());
    if (response['success'] == true) await _load();
  }
}
