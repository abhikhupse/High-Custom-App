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
                      childAspectRatio: .65,
                    ),
                    itemCount: _links.length,
                    itemBuilder: (_, index) => _card(_links[index]),
                  ),
  );

  Widget _card(Map<String, dynamic> link) {
    final rawQr = link['qrCode']?.toString() ?? '';
    final encoded = rawQr.contains(',') ? rawQr.split(',').last : rawQr;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF151619),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2C45F).withValues(alpha: .38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090A0C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF2C45F).withValues(alpha: .8),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              const Positioned(top: 25, left: 25, child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFF2C45F), size: 15)),
              const Positioned(top: 40, right: 29, child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFF2C45F), size: 11)),
              const Positioned(bottom: 28, left: 30, child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFF2C45F), size: 10)),
              if (rawQr.isEmpty)
                const Icon(Icons.qr_code_2_rounded, color: Color(0xFFF2C45F), size: 100)
              else
                Container(
                  width: 164,
                  height: 164,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Image.memory(base64Decode(encoded)),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
          child: Column(children: [
            Text(link['qrTitle']?.toString().isNotEmpty == true ? link['qrTitle'].toString() : link['name']?.toString() ?? 'Untitled QR', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _editTitle(link), icon: const Icon(Icons.edit_outlined, size: 15), label: const Text('Edit'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF2C45F), side: const BorderSide(color: Color(0xFFF2C45F))))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () => _deleteQr(link), icon: const Icon(Icons.delete_outline_rounded, size: 15), label: const Text('Delete'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF6975), side: const BorderSide(color: Color(0xFFFF6975))))),
            ]),
            const SizedBox(height: 9),
            InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: link['qrTarget']?.toString() ?? ''));
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR link copied.')));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF090A0C), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.link_rounded, color: Colors.white60, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(link['qrTarget']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 10))),
                ]),
              ),
            ),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: _stat(Icons.qr_code_scanner_rounded, '${link['qrScans'] ?? 0} Scans')),
              const SizedBox(width: 8),
              Expanded(child: _stat(Icons.ads_click_rounded, '${link['linkClicks'] ?? 0} Clicks')),
            ]),
          ]),
        ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: BoxDecoration(color: const Color(0xFF20242E), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 13, color: const Color(0xFFF2C45F)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ]),
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
