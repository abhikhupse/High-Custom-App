import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CreateSequencePreview extends StatelessWidget {
  const CreateSequencePreview({
    super.key,
    required this.subjectController,
    required this.logoController,
    required this.heroImageController,
    required this.heroLinkController,
    required this.emailContentController,
    required this.whatsappController,
    required this.ctaTextController,
    required this.ctaUrlController,
    required this.attachmentNameController,
    required this.selectedLogoPosition,
    required this.selectedFont,
    required this.selectedTextColor,
    required this.selectedFontSize,
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
  });

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController subjectController;
  final TextEditingController logoController;
  final TextEditingController heroImageController;
  final TextEditingController heroLinkController;
  final TextEditingController emailContentController;
  final TextEditingController whatsappController;
  final TextEditingController ctaTextController;
  final TextEditingController ctaUrlController;
  final TextEditingController attachmentNameController;

  // ============================================================
  // EDITOR SETTINGS
  // ============================================================

  final String selectedLogoPosition;
  final String selectedFont;
  final String selectedTextColor;
  final String selectedFontSize;

  final bool isBold;
  final bool isItalic;
  final bool isUnderline;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF315BEF);

  static const Color textColor = Color(0xFF101828);

  static const Color secondaryTextColor = Color(0xFF667085);

  static const Color lightBorderColor = Color(0xFFE4E7EC);

  static const Color previewBackground = Color(0xFFF2F4F7);

  static const Color emailHeaderBackground = Color(0xFFF8FAFC);

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: lightBorderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // LIVE PREVIEW HEADER
          // ======================================================

          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.preview_outlined,
                  color: primaryColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Preview',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Preview your email on desktop and mobile.',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ======================================================
          // DESKTOP + MOBILE
          // ======================================================

          LayoutBuilder(
            builder: (context, constraints) {
              // ==================================================
              // TABLET / MOBILE WIDTH
              // ==================================================

              if (constraints.maxWidth < 850) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDesktopPreview(),

                    const SizedBox(height: 24),

                    _buildMobilePreview(),
                  ],
                );
              }

              // ==================================================
              // DESKTOP WIDTH
              // ==================================================

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDesktopPreview(),
                  ),

                  const SizedBox(width: 18),

                  SizedBox(
                    width: 285,
                    child: _buildMobilePreview(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP PREVIEW
  // ============================================================

  Widget _buildDesktopPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _previewTitle(
          Icons.desktop_windows_outlined,
          'Desktop Preview',
        ),

        const SizedBox(height: 9),

        Container(
          width: double.infinity,
          height: 530,
          decoration: BoxDecoration(
            color: previewBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: lightBorderColor,
            ),
          ),
          child: Column(
            children: [
              _buildDesktopBrowserChrome(),

              // ==================================================
              // EMAIL CLIENT HEADER
              // ==================================================

              _buildDesktopHeader(),

              // ==================================================
              // SCROLLABLE EMAIL
              // ==================================================

              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(10),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 680,
                        ),
                        child: _buildEmailTemplate(
                          isMobile: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DESKTOP EMAIL CLIENT HEADER
  // ============================================================

  Widget _buildDesktopBrowserChrome() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF20252B),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Row(
        children: [
          for (final color in const [Color(0xFFFF605C), Color(0xFFFFBD44), Color(0xFF00CA4E)])
            Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 21,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
              child: const Text('Email preview', style: TextStyle(color: Colors.white70, fontSize: 9)),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 14),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    final subject = subjectController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
        border: Border(
          bottom: BorderSide(
            color: lightBorderColor,
          ),
        ),
      ),
      child: Column(
        children: [
          // ======================================================
          // MAIL TOOLBAR
          // ======================================================

          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.email_outlined,
                  size: 15,
                  color: primaryColor,
                ),
              ),

              const SizedBox(width: 8),

              const Text(
                'Email Preview',
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              const Icon(
                Icons.star_border,
                size: 17,
                color: secondaryTextColor,
              ),

              const SizedBox(width: 10),

              const Icon(
                Icons.more_horiz,
                size: 18,
                color: secondaryTextColor,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ======================================================
          // SUBJECT
          // ======================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 36,
              ),

              const Text(
                'Subject',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  subject.isEmpty
                      ? 'Your email subject'
                      : subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE PREVIEW
  // ============================================================

  Widget _buildMobilePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _previewTitle(
          Icons.phone_android,
          'Mobile Preview',
        ),

        const SizedBox(height: 9),

        Center(
          child: Container(
            width: 292,
            height: 590,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(38),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12)),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(29),
                  child: Column(
                    children: [
                      _buildMobileStatusBar(),
                      Expanded(child: Container(color: Colors.white, child: _buildMobileEmailArea())),
                    ],
                  ),
                ),
                Positioned(top: 4, left: 81, right: 81, child: Container(height: 19, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18)))),
                Positioned(bottom: 8, left: 78, right: 78, child: Container(height: 4, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE STATUS BAR
  // ============================================================

  Widget _buildMobileStatusBar() {
    return Container(
      height: 36,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: const Row(
        children: [
          Text(
            '12:00',
            style: TextStyle(
              color: Colors.black,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),

          Spacer(),

          Icon(
            Icons.signal_cellular_alt,
            color: Colors.black,
            size: 10,
          ),

          SizedBox(width: 4),

          Icon(
            Icons.wifi,
            color: Colors.black,
            size: 10,
          ),

          SizedBox(width: 4),

          Icon(
            Icons.battery_full,
            color: Colors.black,
            size: 11,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE EMAIL AREA
  // ============================================================

  Widget _buildMobileEmailArea() {
    final subject = subjectController.text.trim();

    return Column(
      children: [
        // ========================================================
        // MOBILE EMAIL HEADER
        // ========================================================

        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: lightBorderColor))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textColor),
                  Spacer(),
                  Icon(Icons.archive_outlined, size: 17, color: textColor),
                  SizedBox(width: 15),
                  Icon(Icons.delete_outline_rounded, size: 18, color: textColor),
                  SizedBox(width: 15),
                  Icon(Icons.mail_outline_rounded, size: 18, color: textColor),
                  SizedBox(width: 12),
                  Icon(Icons.more_vert_rounded, size: 18, color: textColor),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      subject.isEmpty ? 'Exclusive Jewellery Collection for You ✨' : subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black, fontSize: 15, height: 1.15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 6, top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF1F3F4), borderRadius: BorderRadius.circular(5)),
                    child: const Text('Inbox', style: TextStyle(color: Color(0xFF4B5563), fontSize: 7)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: const Text('HC', style: TextStyle(color: Color(0xFFF2C45F), fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('High Custom Jewellers', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('to me  ⌄', style: TextStyle(color: secondaryTextColor, fontSize: 7)),
                    ]),
                  ),
                  const Text('9:41 AM', style: TextStyle(color: secondaryTextColor, fontSize: 7)),
                  const SizedBox(width: 5),
                  const Icon(Icons.more_horiz_rounded, color: secondaryTextColor, size: 16),
                ],
              ),
            ],
          ),
        ),

        // ========================================================
        // MOBILE EMAIL BODY SCROLLER
        // ========================================================

        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            thickness: 4,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                10,
                12,
                10,
                16,
              ),
              child: _buildEmailTemplate(
                isMobile: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PREVIEW TITLE
  // ============================================================

  Widget _previewTitle(
    IconData icon,
    String title,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: textColor,
        ),

        const SizedBox(width: 7),

        Text(
          title,
          style: const TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMAIL TEMPLATE
  // ============================================================

  Widget _buildEmailTemplate({
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: lightBorderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // LOGO
            // ====================================================

            if (_hasLogo())
              _buildLogoSection(
                isMobile: isMobile,
              ),

            // ====================================================
            // HERO IMAGE
            // ====================================================

            if (_hasHeroImage())
              _buildHeroSection(
                isMobile: isMobile,
              ),

            // ====================================================
            // EMAIL CONTENT
            // ====================================================

            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 20,
                isMobile ? 14 : 18,
                isMobile ? 12 : 20,
                10,
              ),
              child: _buildContent(
                isMobile: isMobile,
              ),
            ),

            // ====================================================
            // CTA
            // ====================================================

            if (ctaTextController.text.trim().isNotEmpty)
              _buildCtaButton(
                isMobile: isMobile,
              ),

            // ====================================================
            // WHATSAPP
            // ====================================================

            if (whatsappController.text.trim().isNotEmpty)
              _buildWhatsAppButton(
                isMobile: isMobile,
              ),

            if (attachmentNameController.text.trim().isNotEmpty)
              _buildAttachment(
                isMobile: isMobile,
              ),

          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMAIL BRAND HEADER
  // ============================================================

  Widget _buildEmailBrandHeader({
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 11 : 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: lightBorderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // ==================================================
          // BRAND ICON
          // ==================================================

          Container(
            width: isMobile ? 30 : 36,
            height: isMobile ? 30 : 36,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.mail_outline,
              color: primaryColor,
              size: isMobile ? 15 : 18,
            ),
          ),

          const SizedBox(width: 9),

          // ==================================================
          // BRAND NAME
          // ==================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Company',
                  style: TextStyle(
                    color: textColor,
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Email communication',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: isMobile ? 7 : 8.5,
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // MORE BUTTON
          // ==================================================

          Icon(
            Icons.more_horiz,
            color: secondaryTextColor,
            size: isMobile ? 16 : 18,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGO SECTION
  // ============================================================

  Widget _buildLogoSection({
    required bool isMobile,
  }) {
    Alignment alignment;

    switch (selectedLogoPosition) {
      case 'Left':
        alignment = Alignment.centerLeft;
        break;

      case 'Right':
        alignment = Alignment.centerRight;
        break;

      case 'Center':
      default:
        alignment = Alignment.center;
    }

    return Container(
      width: double.infinity,
      height: isMobile ? 70 : 90,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 8,
      ),
      child: Align(
        alignment: alignment,
        child: _buildActualImage(
          path: logoController.text.trim(),
          width: isMobile ? 105 : 170,
          height: isMobile ? 50 : 68,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // ============================================================
  // HERO IMAGE
  // ============================================================

  Widget _buildHeroSection({
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 18,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildActualImage(
          path: heroImageController.text.trim(),
          width: double.infinity,
          height: isMobile ? 90 : 140,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ============================================================
  // ACTUAL IMAGE
  // ============================================================

  Widget _buildActualImage({
    required String path,
    required double width,
    required double height,
    required BoxFit fit,
  }) {
    if (path.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            color: Color(0xFF98A2B3),
            size: 25,
          ),
        ),
      );
    }

    // ==========================================================
    // LOCAL FILE
    // ==========================================================

    // ==========================================================
    // NETWORK URL
    // ==========================================================

    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _imageErrorBox(
            width,
            height,
          );
        },
      );
    }

    if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, width: width, height: height, fit: fit);
      }
    }

    return _imageErrorBox(
      width,
      height,
    );
  }

  // ============================================================
  // IMAGE ERROR
  // ============================================================

  Widget _imageErrorBox(
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Color(0xFF98A2B3),
          size: 24,
        ),
      ),
    );
  }

  // ============================================================
  // EMAIL CONTENT
  // ============================================================

  Widget _buildContent({
    required bool isMobile,
  }) {
    final content = emailContentController.text.trim();

    final double fontSize = _getFontSize();

    return Text(
      content.isEmpty
          ? 'Your email content will appear here...'
          : content,
      style: TextStyle(
        color: _getPreviewColor(),
        fontSize: isMobile
            ? (fontSize > 16 ? 11 : 10)
            : (fontSize > 18 ? 13 : fontSize),
        height: 1.5,
        fontWeight: isBold
            ? FontWeight.bold
            : FontWeight.normal,
        fontStyle: isItalic
            ? FontStyle.italic
            : FontStyle.normal,
        decoration: isUnderline
            ? TextDecoration.underline
            : TextDecoration.none,
        fontFamily: _getFontFamily(),
      ),
    );
  }

  // ============================================================
  // CTA BUTTON
  // ============================================================

  Widget _buildCtaButton({
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 6,
      ),
      child: SizedBox(
        width: double.infinity,
        height: isMobile ? 32 : 38,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            ctaTextController.text.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 9 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WHATSAPP BUTTON
  // ============================================================

  Widget _buildWhatsAppButton({
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 5,
      ),
      child: SizedBox(
        width: double.infinity,
        height: isMobile ? 32 : 38,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(
            Icons.chat_outlined,
            size: isMobile ? 11 : 14,
          ),
          label: Text(
            'WhatsApp',
            style: TextStyle(
              fontSize: isMobile ? 9 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachment({
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_file,
            size: isMobile ? 14 : 17,
            color: primaryColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              attachmentNameController.text.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primaryColor,
                fontSize: isMobile ? 8 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter({
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: isMobile ? 9 : 11,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: lightBorderColor,
          ),
        ),
      ),
      child: Text(
        'You are receiving this email because you subscribed to our updates.',
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: secondaryTextColor,
          fontSize: isMobile ? 6.5 : 8,
          height: 1.3,
        ),
      ),
    );
  }

  // ============================================================
  // HAS LOGO
  // ============================================================

  bool _hasLogo() {
    return logoController.text.trim().isNotEmpty;
  }

  // ============================================================
  // HAS HERO
  // ============================================================

  bool _hasHeroImage() {
    return heroImageController.text.trim().isNotEmpty;
  }

  // ============================================================
  // TEXT COLOR
  // ============================================================

  Color _getPreviewColor() {
    switch (selectedTextColor) {
      case 'White':
        return Colors.white;

      case 'Gray':
        return const Color(0xFF667085);

      case 'Red':
        return Colors.red;

      case 'Blue':
        return Colors.blue;

      case 'Green':
        return Colors.green;

      case 'Gold':
        return const Color(0xFFD4AF37);

      case 'Black':
      default:
        return Colors.black;
    }
  }

  // ============================================================
  // FONT SIZE
  // ============================================================

  double _getFontSize() {
    switch (selectedFontSize) {
      case '12px':
        return 12;

      case '14px':
        return 14;

      case '16px':
        return 16;

      case '18px':
        return 18;

      case '20px':
        return 20;

      case '24px':
        return 24;

      case '28px':
        return 28;

      case '32px':
        return 32;

      default:
        return 16;
    }
  }

  // ============================================================
  // FONT FAMILY
  // ============================================================

  String _getFontFamily() {
    switch (selectedFont) {
      case 'Roboto':
        return 'Roboto';

      case 'Helvetica':
        return 'Helvetica';

      case 'Times New Roman':
        return 'Times New Roman';

      case 'Georgia':
        return 'Georgia';

      case 'Verdana':
        return 'Verdana';

      case 'Arial':
      default:
        return 'Arial';
    }
  }
}
