import 'dart:convert';

import 'package:file_saver/file_saver.dart';
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
  String? _downloadingQrId;

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
      setState(() {
        _loading = false;
        _error = response['message']?.toString() ?? 'Unable to load QR codes.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF090A0C),
    appBar: AppBar(
      backgroundColor: const Color(0xFF101113),
      foregroundColor: Colors.white,
      title: const Text('My QR Codes'),
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ],
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFF2C45F)),
          )
        : _error != null
        ? Center(
            child: Text(_error!, style: const TextStyle(color: Colors.white70)),
          )
        : _links.isEmpty
        ? const Center(
            child: Text(
              'No QR codes generated yet.',
              style: TextStyle(color: Colors.white70),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            itemCount: _links.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, index) {
              if (index == 0) {
                return Text(
                  '${_links.length} active QR code${_links.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white60, fontSize: 15),
                );
              }
              return _card(_links[index - 1]);
            },
          ),
  );

  Widget _card(Map<String, dynamic> link) {
    final rawQr = link['qrCode']?.toString() ?? '';
    final encoded = rawQr.contains(',') ? rawQr.split(',').last : rawQr;
    final isFixedCard = link['fixedCard'] == true;
    final trackingTarget =
        link['trackingTarget']?.toString() ??
        link['qrTarget']?.toString().replaceFirst('source=qr', 'source=link') ??
        '';
    return Container(
      constraints: const BoxConstraints(minHeight: 176),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151619),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                    ? const Icon(
                        Icons.qr_code_2_rounded,
                        color: Color(0xFF090A0C),
                        size: 90,
                      )
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
                        if (!isFixedCard)
                          PopupMenuButton<String>(
                            color: const Color(0xFF202226),
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Color(0xFFF2C45F),
                            ),
                            onSelected: (value) {
                              if (value == 'edit') _editTitle(link);
                              if (value == 'delete') _deleteQr(link);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isFixedCard)
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'One QR for every saved link',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Updates automatically',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _metric(
                              'Scans',
                              link['qrScans'] ?? 0,
                              Icons.qr_code_scanner_rounded,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 35,
                            color: const Color(0xFF4A4131),
                          ),
                          Expanded(
                            child: _metric(
                              'Clicks',
                              link['linkClicks'] ?? 0,
                              Icons.ads_click_rounded,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _copyLinkRow(trackingTarget),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed:
                rawQr.isEmpty || _downloadingQrId == link['_id']?.toString()
                ? null
                : () => _downloadQr(link, encoded),
            icon: _downloadingQrId == link['_id']?.toString()
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: Text(
              _downloadingQrId == link['_id']?.toString()
                  ? 'Downloading...'
                  : 'Download QR',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              foregroundColor: const Color(0xFFF2C45F),
              side: const BorderSide(color: Color(0xFFF2C45F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyLinkRow(String link) => Container(
    height: 42,
    padding: const EdgeInsets.only(left: 11, right: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF0B0D10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Row(
      children: [
        const Icon(Icons.link_rounded, size: 16, color: Color(0xFFF2C45F)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            link,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
        IconButton(
          tooltip: 'Copy link',
          icon: const Icon(
            Icons.copy_rounded,
            size: 18,
            color: Color(0xFFF2C45F),
          ),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: link));
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('QR link copied.')));
            }
          },
        ),
      ],
    ),
  );

  Widget _metric(String label, dynamic value, IconData icon) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: const Color(0xFFF2C45F)),
      const SizedBox(height: 3),
      Text(
        value.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ],
  );

  Future<void> _downloadQr(Map<String, dynamic> link, String encodedQr) async {
    final id = link['_id']?.toString() ?? '';
    if (id.isEmpty || _downloadingQrId != null) return;

    setState(() => _downloadingQrId = id);
    try {
      final title =
          (link['qrTitle']?.toString().isNotEmpty == true
                  ? link['qrTitle'].toString()
                  : link['name']?.toString() ?? 'high-custom-qr')
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
              .replaceAll(RegExp(r'^-+|-+$'), '');
      await FileSaver.instance.saveFile(
        name: '${title.isEmpty ? 'high-custom' : title}-qr',
        bytes: base64Decode(encodedQr),
        fileExtension: 'png',
        mimeType: MimeType.png,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code downloaded as PNG.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not download this QR code.')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingQrId = null);
    }
  }

  Future<void> _editTitle(Map<String, dynamic> link) async {
    final controller = TextEditingController(
      text: link['qrTitle']?.toString().isNotEmpty == true
          ? link['qrTitle'].toString()
          : link['name']?.toString() ?? '',
    );
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151619),
        title: const Text(
          'Edit QR Title',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'QR title',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty) return;
    final response = await SocialLinksApi.update(
      link['_id'].toString(),
      qrTitle: title,
    );
    if (response['success'] == true) await _load();
  }

  Future<void> _deleteQr(Map<String, dynamic> link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151619),
        title: const Text(
          'Delete QR Code?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'The link will stay saved. Only its QR code will be removed.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6975),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final response = await SocialLinksApi.deleteQr(link['_id'].toString());
    if (response['success'] == true) await _load();
  }
}
