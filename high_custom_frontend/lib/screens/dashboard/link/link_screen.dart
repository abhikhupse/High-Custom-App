import 'package:flutter/material.dart';
import 'package:high_custom_frontend/widgets/app_feedback.dart';

// ============================================================
// LINK SCREEN
// ============================================================

class LinkScreen extends StatefulWidget {
  const LinkScreen({super.key});

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color background = Color(0xFF020507);
  static const Color cardColor = Color(0xFF0B0F14);
  static const Color inputColor = Color(0xFF0A0D12);
  static const Color borderColor = Color(0xFF292F39);

  static const Color white = Colors.white;
  static const Color mutedText = Color(0xFF969CA8);

  static const Color purple = Color(0xFF8055F5);
  static const Color blue = Color(0xFF4A57E8);

  // ============================================================
  // STATE
  // ============================================================

  String? selectedActionLink;
  String? selectedBusinessType;

  String selectedLinksText = 'No links selected';

  // ============================================================
  // DATA
  // ============================================================

  final List<String> actionLinks = [
    'Instagram',
    'Facebook',
    'LinkedIn',
    'Website',
    'WhatsApp',
  ];

  final List<String> businessTypes = [
    'Jewellery',
    'Retail',
    'E-commerce',
    'Services',
    'Other',
  ];

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 800;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 28,
              isMobile ? 20 : 30,
              isMobile ? 16 : 28,
              40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 850,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPageHeader(isMobile),

                    const SizedBox(height: 22),

                    _buildMainCard(isMobile),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader(bool isMobile) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: purple.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: purple.withOpacity(0.35),
            ),
          ),
          child: const Icon(
            Icons.link_rounded,
            color: purple,
            size: 25,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Links',
                style: TextStyle(
                  color: white,
                  fontSize: isMobile ? 23 : 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Manage your business branding & links',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MAIN CARD
  // ============================================================

  Widget _buildMainCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? 20 : 30,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBrandingBadge(),

          const SizedBox(height: 25),

          Text(
            'Business Links',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: white,
              fontSize: isMobile ? 27 : 32,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Upload your company image and manage all business\nsocial links professionally.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFC4C7CE),
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 30),

          _buildCompanyLogoCard(),

          const SizedBox(height: 28),

          _buildSectionLabel(
            'WhatsApp Link',
          ),

          const SizedBox(height: 10),

          _buildWhatsAppField(),

          const SizedBox(height: 25),

          _buildSectionLabel(
            'Selected Action Links',
          ),

          const SizedBox(height: 12),

          Text(
            selectedLinksText,
            style: const TextStyle(
              color: mutedText,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 26),

          _buildSectionLabel(
            'Select Action Links',
          ),

          const SizedBox(height: 10),

          _buildActionLinkDropdown(),

          const SizedBox(height: 26),

          _buildSectionLabel(
            'Business Type',
          ),

          const SizedBox(height: 10),

          _buildBusinessTypeDropdown(),

          const SizedBox(height: 30),

          _buildSaveButton(),
        ],
      ),
    );
  }

  // ============================================================
  // BRANDING BADGE
  // ============================================================

  Widget _buildBrandingBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: purple.withOpacity(0.10),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.layers_rounded,
              color: purple,
              size: 20,
            ),

            SizedBox(width: 9),

            Text(
              'Business Branding',
              style: TextStyle(
                color: purple,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMPANY LOGO
  // ============================================================

  Widget _buildCompanyLogoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: purple,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Company Logo',
            style: TextStyle(
              color: white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Recommended Company Logo / Banner',
            style: TextStyle(
              color: mutedText,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 13),

          _buildRecommendation(
            'Banner: 500 × 200 px or 800 × 300 px',
          ),

          const SizedBox(height: 9),

          _buildRecommendation(
            'Logo: 300 × 300 px or 450 × 120 px',
          ),

          const SizedBox(height: 20),

          _buildChooseFile(),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.push_pin_rounded,
          color: purple,
          size: 19,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: mutedText,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CHOOSE FILE
  // ============================================================

  Widget _buildChooseFile() {
    return InkWell(
      onTap: () {
        _showMessage(
          'File picker will be connected here.',
        );
      },
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: inputColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: const Text(
                'Choose File',
                style: TextStyle(
                  color: purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Container(
              width: 1,
              height: double.infinity,
              color: borderColor,
            ),

            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child: Text(
                  'No file chosen',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION LABEL
  // ============================================================

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ============================================================
  // WHATSAPP
  // ============================================================

  Widget _buildWhatsAppField() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: inputColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 16),

          Icon(
            Icons.chat_rounded,
            color: Color(0xFF58C84A),
            size: 25,
          ),

          SizedBox(width: 14),

          Expanded(
            child: Text(
              'https://wa.me/918530480563?text=Hi+Abhishek...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFE3E5E9),
                fontSize: 13,
              ),
            ),
          ),

          SizedBox(width: 16),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION LINKS DROPDOWN
  // ============================================================

  Widget _buildActionLinkDropdown() {
    return _buildDropdown(
      value: selectedActionLink,
      hint: 'Select Links',
      items: actionLinks,
      onChanged: (value) {
        setState(() {
          selectedActionLink = value;

          if (value != null) {
            selectedLinksText = value;
          }
        });
      },
    );
  }

  // ============================================================
  // BUSINESS TYPE DROPDOWN
  // ============================================================

  Widget _buildBusinessTypeDropdown() {
    return _buildDropdown(
      value: selectedBusinessType,
      hint: 'Select Business Type',
      items: businessTypes,
      onChanged: (value) {
        setState(() {
          selectedBusinessType = value;
        });
      },
    );
  }

  // ============================================================
  // COMMON DROPDOWN
  // ============================================================

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
      ),
      decoration: BoxDecoration(
        color: inputColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              color: mutedText,
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          dropdownColor: const Color(0xFF11151B),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFB5BAC4),
          ),
          style: const TextStyle(
            color: white,
            fontSize: 14,
          ),
          borderRadius: BorderRadius.circular(14),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF4655E9),
              Color(0xFF8D39B9),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ElevatedButton.icon(
          onPressed: _saveBusinessDetails,
          icon: const Icon(
            Icons.save_rounded,
            size: 21,
          ),
          label: const Text(
            'Save Business Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _saveBusinessDetails() {
    _showMessage(
      'Business details saved successfully.',
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    AppFeedback.show(context, message);
  }
}
