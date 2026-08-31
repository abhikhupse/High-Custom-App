import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../../constants/app_theme.dart';

class CreateBusinessCardScreen extends StatefulWidget {
  const CreateBusinessCardScreen({super.key});

  @override
  State<CreateBusinessCardScreen> createState() =>
      _CreateBusinessCardScreenState();
}

class _CreateBusinessCardScreenState extends State<CreateBusinessCardScreen> {
  static const _imageClipboard = MethodChannel('high_custom/image_clipboard');
  final _formKey = GlobalKey<FormState>();
  final _cardPreviewKey = GlobalKey();
  final _fullNameController = TextEditingController(text: 'Harish Patel');
  final _roleController = TextEditingController(text: 'Sales Executive');
  final _companyController = TextEditingController(
    text: 'High Custom Jewellers',
  );
  final _whatsappController = TextEditingController(text: '+91 84602 46233');
  final _emailController = TextEditingController(
    text: 'highcustom.sales04@gmail.com',
  );
  final _qrLinkController = TextEditingController(
    text: 'https://www.highcustomjewellens.com',
  );
  final _addressController = TextEditingController(
    text:
        'T01, Himson House, Opp. Ravji Holidays, Gundal Sheri Naka, Laldarwaja, Surat-395003.',
  );
  bool _isExporting = false;

  List<TextEditingController> get _controllers => [
    _fullNameController,
    _roleController,
    _companyController,
    _whatsappController,
    _emailController,
    _qrLinkController,
    _addressController,
  ];

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_refreshPreview);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..removeListener(_refreshPreview)
        ..dispose();
    }
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  String? _validateEmail(String? value) {
    final requiredError = _required(value, 'Email');
    if (requiredError != null) return requiredError;
    final email = value!.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validateLink(String? value) {
    final requiredError = _required(value, 'QR link');
    if (requiredError != null) return requiredError;
    final uri = Uri.tryParse(value!.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Enter a complete link, such as https://example.com.';
    }
    return null;
  }

  void _createCard() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Digital business card created.')),
    );
  }

  Future<Uint8List> _captureCard() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _cardPreviewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Business card preview is not ready.');
    }

    final pixelRatio = 1050 / boundary.size.width;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) {
      throw StateError('Business card image could not be made.');
    }
    return data.buffer.asUint8List();
  }

  String get _cardFileName {
    final name = _fullNameController.text.trim().toLowerCase();
    final safeName = name
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return '${safeName.isEmpty ? 'business-card' : safeName}-business-card';
  }

  Future<void> _downloadCard() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureCard();
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _imageClipboard.invokeMethod<void>('savePng', {
          'bytes': bytes,
          'name': '$_cardFileName.png',
        });
        if (mounted) {
          _showMessage('Saved in Downloads/High Custom.');
        }
      } else {
        await FileSaver.instance.saveFile(
          name: _cardFileName,
          bytes: bytes,
          fileExtension: 'png',
          mimeType: MimeType.png,
        );
        if (mounted) {
          _showMessage('Business card downloaded as PNG.');
        }
      }
    } catch (_) {
      if (mounted) _showMessage('Could not download the business card.');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _copyCard() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureCard();
      await _imageClipboard.invokeMethod<void>('copyPng', bytes);
      if (mounted) _showMessage('Business card copied as an image.');
    } catch (_) {
      if (mounted) {
        _showMessage('Image copying is not supported on this device.');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Create Digital Business Card',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1050;

            return SingleChildScrollView(
              padding: EdgeInsets.all(wide ? 28 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: _buildForm()),
                            const SizedBox(width: 24),
                            Expanded(flex: 7, child: _buildPreviewPanel()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildPreviewPanel(),
                            const SizedBox(height: 20),
                            _buildForm(),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Business card details',
              style: TextStyle(
                color: AppTheme.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'All fields are required and update the preview instantly.',
              style: TextStyle(color: AppTheme.mutedText, fontSize: 13),
            ),
            const SizedBox(height: 22),
            _field(
              controller: _fullNameController,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
            ),
            _field(
              controller: _roleController,
              label: 'Role / Designation',
              icon: Icons.badge_outlined,
            ),
            _field(
              controller: _companyController,
              label: 'Company Name',
              icon: Icons.business_outlined,
            ),
            _field(
              controller: _whatsappController,
              label: 'WhatsApp',
              icon: Icons.chat_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()-]')),
              ],
            ),
            _field(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            _field(
              controller: _qrLinkController,
              label: 'QR Link',
              hint: 'https://example.com',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              validator: _validateLink,
            ),
            _field(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _createCard,
                icon: const Icon(Icons.credit_card_rounded),
                label: const Text(
                  'Create Business Card',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator ?? (value) => _required(value, label),
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        decoration: InputDecoration(
          labelText: '$label *',
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.gold),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Live Preview',
                  style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '1050 × 600 px',
                style: TextStyle(color: AppTheme.gold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RepaintBoundary(
            key: _cardPreviewKey,
            child: AspectRatio(
              aspectRatio: 1050 / 600,
              child: _BusinessCardPreview(
                fullName: _fullNameController.text,
                role: _roleController.text,
                company: _companyController.text,
                whatsapp: _whatsappController.text,
                email: _emailController.text,
                qrLink: _qrLinkController.text,
                address: _addressController.text,
              ),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final copyButton = _cardActionButton(
                outlined: true,
                onPressed: _isExporting ? null : _copyCard,
                icon: Icons.copy_rounded,
                label: 'Copy Card',
              );
              final downloadButton = _cardActionButton(
                onPressed: _isExporting ? null : _downloadCard,
                icon: Icons.download_rounded,
                label: 'Download Card',
                loading: _isExporting,
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    downloadButton,
                    const SizedBox(height: 10),
                    copyButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: copyButton),
                  const SizedBox(width: 12),
                  Expanded(child: downloadButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _cardActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool outlined = false,
    bool loading = false,
  }) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 19,
            height: 19,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: 21),
        const SizedBox(width: 9),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );

    if (outlined) {
      return SizedBox(
        height: 52,
        child: OutlinedButton(onPressed: onPressed, child: content),
      );
    }
    return SizedBox(
      height: 52,
      child: ElevatedButton(onPressed: onPressed, child: content),
    );
  }
}

class _BusinessCardPreview extends StatelessWidget {
  const _BusinessCardPreview({
    required this.fullName,
    required this.role,
    required this.company,
    required this.whatsapp,
    required this.email,
    required this.qrLink,
    required this.address,
  });

  final String fullName;
  final String role;
  final String company;
  final String whatsapp;
  final String email;
  final String qrLink;
  final String address;

  String _value(String value, String fallback) =>
      value.trim().isEmpty ? fallback : value.trim();

  String get _displayRole {
    final value = _value(role, 'Role / Designation');
    return value.startsWith('(') && value.endsWith(')') ? value : '($value)';
  }

  String get _displayWebsite {
    var value = _value(qrLink, 'www.highcustomjewellens.com');
    value = value.replaceFirst(RegExp(r'^https?://'), '');
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        border: Border.all(color: const Color(0xFFD8D5E5)),
      ),
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(width: 1050, height: 600, child: _buildCardCanvas()),
      ),
    );
  }

  Widget _buildCardCanvas() {
    const navy = Color(0xFF06143D);
    const lavender = Color(0xFFD6D3EA);

    return Stack(
      children: [
        const Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(width: 42, child: ColoredBox(color: lavender)),
        ),
        const Positioned(
          right: 0,
          top: 0,
          child: SizedBox(
            width: 58,
            height: 292,
            child: ColoredBox(color: lavender),
          ),
        ),
        const Positioned(
          right: 0,
          top: 79,
          child: SizedBox(
            width: 58,
            height: 10,
            child: ColoredBox(color: Color(0xFFFFFDF8)),
          ),
        ),
        const Positioned(
          right: 0,
          top: 171,
          child: SizedBox(
            width: 58,
            height: 10,
            child: ColoredBox(color: Color(0xFFFFFDF8)),
          ),
        ),
        const Positioned(
          right: 0,
          top: 268,
          child: SizedBox(
            width: 58,
            height: 10,
            child: ColoredBox(color: Color(0xFFFFFDF8)),
          ),
        ),
        const Positioned(
          right: 0,
          top: 278,
          child: SizedBox(
            width: 58,
            height: 11,
            child: ColoredBox(color: navy),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Opacity(
              opacity: 0.055,
              child: Image.asset(
                'assets/images/business_card_watermark.png',
                width: 520,
                height: 520,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          left: 50,
          top: 45,
          width: 435,
          height: 150,
          child: Image.asset(
            'assets/images/business_card_wordmark.png',
            fit: BoxFit.fill,
            alignment: Alignment.centerLeft,
          ),
        ),
        Positioned(
          right: 82,
          top: 56,
          child: Container(
            width: 228,
            height: 228,
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: qrLink.trim().isEmpty
                ? const Icon(
                    Icons.qr_code_2_rounded,
                    size: 190,
                    color: Colors.black,
                  )
                : QrImageView(
                    data: qrLink.trim(),
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),
        Positioned(
          left: 82,
          top: 226,
          width: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _value(fullName, 'Full Name'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontSize: 46,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _displayRole,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(SimpleIcons.whatsapp, color: navy, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _value(whatsapp, 'WhatsApp'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 35,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 55,
          right: 82,
          bottom: 20,
          child: Column(
            children: [
              _contactRow(
                icon: Icons.location_on,
                text: _value(address, 'Business address'),
                height: 66,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              _contactRow(
                icon: Icons.mail_outline_rounded,
                text: _value(email, 'Email address'),
                height: 58,
              ),
              const SizedBox(height: 8),
              _contactRow(
                icon: Icons.language_rounded,
                text: _displayWebsite,
                height: 58,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String text,
    required double height,
    int maxLines = 1,
  }) {
    const navy = Color(0xFF06143D);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: ColoredBox(
              color: navy,
              child: Center(child: Icon(icon, color: Colors.white, size: 40)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ColoredBox(
              color: const Color(0xCCD4D1E8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: navy,
                      fontSize: maxLines == 1 ? 22 : 20,
                      height: 1.14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
