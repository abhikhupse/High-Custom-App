import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../../constants/app_theme.dart';
import '../../../services/business_card_api.dart';

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
  bool _isLoadingCard = true;
  bool _isSavingCard = false;
  bool _isDeletingCard = false;
  bool _hasSavedCard = false;

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
    _loadBusinessCard();
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

  Future<void> _saveBusinessCard() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSavingCard) return;

    setState(() => _isSavingCard = true);
    final card = {
      'fullName': _fullNameController.text.trim(),
      'role': _roleController.text.trim(),
      'companyName': _companyController.text.trim(),
      'whatsapp': _whatsappController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      'email': _emailController.text.trim(),
      'qrLink': _qrLinkController.text.trim(),
      'address': _addressController.text.trim(),
    };
    final result = _hasSavedCard
        ? await BusinessCardApi.update(card: card)
        : await BusinessCardApi.create(card: card);

    if (!mounted) return;
    setState(() {
      _isSavingCard = false;
      if (result['success'] == true) _hasSavedCard = true;
    });
    _showMessage(
      result['message']?.toString() ??
          (result['success'] == true
              ? 'Business card saved successfully.'
              : 'Could not save the business card.'),
    );
  }

  Future<void> _loadBusinessCard() async {
    final result = await BusinessCardApi.fetch();
    if (!mounted) return;

    final card = result['businessCard'];
    if (result['success'] == true && card is Map) {
      _fullNameController.text = card['fullName']?.toString() ?? '';
      _roleController.text = card['role']?.toString() ?? '';
      _companyController.text = card['companyName']?.toString() ?? '';
      _whatsappController.text = card['whatsapp']?.toString() ?? '';
      _emailController.text = card['email']?.toString() ?? '';
      _qrLinkController.text = card['qrLink']?.toString() ?? '';
      _addressController.text = card['address']?.toString() ?? '';
      setState(() {
        _hasSavedCard = true;
        _isLoadingCard = false;
      });
      return;
    }

    setState(() {
      _hasSavedCard = false;
      _isLoadingCard = false;
    });
    if (result['statusCode'] != 404) {
      _showMessage(
        result['message']?.toString() ?? 'Could not load the business card.',
      );
    }
  }

  Future<void> _deleteBusinessCard() async {
    if (_isDeletingCard) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete business card?'),
        content: const Text(
          'This removes the saved business card from your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingCard = true);
    final result = await BusinessCardApi.delete();
    if (!mounted) return;
    setState(() {
      _isDeletingCard = false;
      if (result['success'] == true) _hasSavedCard = false;
    });
    _showMessage(
      result['message']?.toString() ?? 'Could not delete the business card.',
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

            if (_isLoadingCard) {
              return const Center(child: CircularProgressIndicator());
            }

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
                onPressed: _isSavingCard ? null : _saveBusinessCard,
                icon: _isSavingCard
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _hasSavedCard
                            ? Icons.save_rounded
                            : Icons.credit_card_rounded,
                      ),
                label: Text(
                  _hasSavedCard
                      ? 'Update Business Card'
                      : 'Create Business Card',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (_hasSavedCard) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isDeletingCard ? null : _deleteBusinessCard,
                  icon: _isDeletingCard
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete Saved Card'),
                ),
              ),
            ],
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

  String get _displayWhatsapp {
    final original = _value(whatsapp, 'WhatsApp');
    final digits = original.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+91 ${digits.substring(2, 7)} ${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return original;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: Color(0xFFFFFDF8)),
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(width: 1050, height: 600, child: _buildCardCanvas()),
      ),
    );
  }

  Widget _buildCardCanvas() {
    const navy = Color(0xFF06143D);

    return Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _CardShapePainter())),
        Positioned(
          left: 285,
          top: 22,
          child: Opacity(
            opacity: 0.038,
            child: Image.asset(
              'assets/images/business_card_watermark.png',
              width: 465,
              height: 465,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          left: 44,
          top: 32,
          width: 455,
          height: 165,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(navy, BlendMode.srcIn),
            child: Image.asset(
              'assets/images/business_card_wordmark.png',
              fit: BoxFit.fill,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        Positioned(
          right: 73,
          top: 52,
          child: Container(
            width: 204,
            height: 204,
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Column(
              children: [
                Expanded(
                  child: qrLink.trim().isEmpty
                      ? const Icon(
                          Icons.qr_code_2_rounded,
                          size: 180,
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
              ],
            ),
          ),
        ),
        const Positioned(
          right: 65,
          top: 267,
          width: 220,
          child: Text(
            'SCAN TO CONNECT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Positioned(
          left: 54,
          top: 214,
          width: 575,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _value(fullName, 'Full Name'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontSize: 47,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _displayRole.replaceAll(RegExp(r'^\(|\)$'), ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: navy,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      SimpleIcons.whatsapp,
                      color: Colors.white,
                      size: 33,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      _displayWhatsapp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 32,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 54,
          width: 590,
          bottom: 40,
          child: Column(
            children: [
              _contactRow(
                icon: Icons.location_on_rounded,
                text: _value(address, 'Business address'),
                height: 66,
                maxLines: 2,
              ),
              const SizedBox(height: 5),
              _contactRow(
                icon: Icons.mail_outline_rounded,
                text: _value(email, 'Email address'),
                height: 51,
              ),
              const SizedBox(height: 5),
              _contactRow(
                icon: Icons.language_rounded,
                text: _displayWebsite,
                height: 51,
                showDivider: false,
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
    bool showDivider = true,
  }) {
    const navy = Color(0xFF06143D);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 35)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              height: double.infinity,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: showDivider
                    ? const Border(
                        bottom: BorderSide(color: Color(0xFFB6B1D3), width: 2),
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 19),
                child: Text(
                  text,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: navy,
                    fontSize: maxLines == 1 ? 21 : 19,
                    height: 1.14,
                    fontWeight: FontWeight.w700,
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

class _CardShapePainter extends CustomPainter {
  const _CardShapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const navy = Color(0xFF06143D);
    const lavender = Color(0xFFC9C5E2);

    final navyPaint = Paint()..color = navy;
    final lavenderPaint = Paint()..color = lavender;
    final ivoryPaint = Paint()..color = const Color(0xFFFFFDF8);

    final topRight = Path()
      ..moveTo(624, 0)
      ..lineTo(944, 0)
      ..lineTo(1050, 106)
      ..lineTo(1050, 280)
      ..lineTo(893, 429)
      ..lineTo(727, 256)
      ..lineTo(764, 215)
      ..lineTo(734, 182)
      ..lineTo(763, 143)
      ..close();
    canvas.drawPath(topRight, navyPaint);

    final lowerNavy = Path()
      ..moveTo(1050, 397)
      ..lineTo(1050, 600)
      ..lineTo(868, 600)
      ..close();
    canvas.drawPath(lowerNavy, navyPaint);

    final diagonal = Path()
      ..moveTo(1050, 282)
      ..lineTo(1050, 397)
      ..lineTo(858, 600)
      ..lineTo(737, 600)
      ..close();
    canvas.drawPath(diagonal, lavenderPaint);

    final upperDiagonalCut = Path()
      ..moveTo(1050, 282)
      ..lineTo(1050, 291)
      ..lineTo(746, 600)
      ..lineTo(737, 600)
      ..close();
    canvas.drawPath(upperDiagonalCut, ivoryPaint);

    final lowerDiagonalCut = Path()
      ..moveTo(1050, 397)
      ..lineTo(1050, 407)
      ..lineTo(868, 600)
      ..lineTo(858, 600)
      ..close();
    canvas.drawPath(lowerDiagonalCut, ivoryPaint);

    final bottomLeft = Path()
      ..moveTo(0, 492)
      ..lineTo(0, 600)
      ..lineTo(104, 600)
      ..close();
    canvas.drawPath(bottomLeft, lavenderPaint);

    final bottomLeftCut = Path()
      ..moveTo(0, 504)
      ..lineTo(0, 516)
      ..lineTo(83, 600)
      ..lineTo(70, 600)
      ..close();
    canvas.drawPath(bottomLeftCut, ivoryPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
