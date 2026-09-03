import 'package:flutter/material.dart';
import 'package:high_custom_frontend/widgets/app_feedback.dart';
import 'package:high_custom_frontend/services/business_type_api.dart';

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

  static const Color gold = Color(0xFFF2C45F);
  static const Color goldDark = Color(0xFFD9A93F);

  // ============================================================
  // STATE
  // ============================================================

  String? selectedActionLink;
  String? selectedBusinessType;
  bool isLoadingBusinessTypes = true;

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

  final List<String> businessTypes = [];
  final Map<String, String> businessTypeIds = {};

  @override
  void initState() {
    super.initState();
    _loadBusinessTypes();
  }

  Future<void> _loadBusinessTypes() async {
    final response = await BusinessTypeApi.getBusinessTypes();
    if (!mounted) return;

    final values = <String>[];
    final ids = <String, String>{};
    final data = response['data'];
    if (data is List) {
      for (final item in data) {
        if (item is Map && item['name'] != null) {
          final name = item['name'].toString().trim();
          final id = item['_id']?.toString().trim() ?? '';
          if (name.isNotEmpty) {
            values.add(name);
            if (id.isNotEmpty) ids[name] = id;
          }
        }
      }
    }

    setState(() {
      businessTypes
        ..clear()
        ..addAll(values);
      businessTypeIds
        ..clear()
        ..addAll(ids);
      isLoadingBusinessTypes = false;
    });
  }

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
            color: gold.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: gold.withOpacity(0.35),
            ),
          ),
          child: const Icon(
            Icons.link_rounded,
            color: gold,
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
          color: gold.withOpacity(0.10),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.layers_rounded,
              color: gold,
              size: 20,
            ),

            SizedBox(width: 9),

            Text(
              'Business Branding',
              style: TextStyle(
                color: gold,
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
          color: gold,
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
          color: gold,
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
                  color: gold,
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
            color: gold,
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
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            value: selectedBusinessType,
            hint: isLoadingBusinessTypes
                ? 'Loading Business Types...'
                : businessTypes.isEmpty
                    ? 'No Business Type Added'
                    : 'Select Business Type',
            items: businessTypes,
            manageBusinessTypes: true,
            onChanged: (value) {
              setState(() {
                selectedBusinessType = value;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 58,
          child: ElevatedButton.icon(
            onPressed: _showAddBusinessTypeDialog,
            icon: const Icon(Icons.add_business_rounded, size: 19),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: const Color(0xFF171208),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddBusinessTypeDialog() async {
    String draftBusinessType = '';
    bool isSavingType = false;

    final created = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: gold.withOpacity(0.35)),
          ),
          title: const Text(
            'Add Business Type',
            style: TextStyle(color: white, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            autofocus: true,
            enabled: !isSavingType,
            onChanged: (value) {
              draftBusinessType = value;
            },
            cursorColor: gold,
            style: const TextStyle(color: white),
            decoration: InputDecoration(
              hintText: 'Enter business type',
              hintStyle: const TextStyle(color: mutedText),
              filled: true,
              fillColor: inputColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: gold),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSavingType
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSavingType
                  ? null
                  : () async {
                      final name = draftBusinessType.trim();
                      if (name.length < 2) {
                        _showMessage('Please enter a valid business type.');
                        return;
                      }
                      setDialogState(() => isSavingType = true);
                      final response =
                          await BusinessTypeApi.createBusinessType(name);
                      if (!dialogContext.mounted) return;
                      if (response['success'] == true) {
                        Navigator.pop(dialogContext, name);
                      } else {
                        setDialogState(() => isSavingType = false);
                        _showMessage(
                          response['message']?.toString() ??
                              'Unable to add business type.',
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: const Color(0xFF171208),
              ),
              child: Text(isSavingType ? 'Adding...' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (created != null && mounted) {
      await _loadBusinessTypes();
      if (!mounted) return;
      setState(() => selectedBusinessType = created);
    }
  }

  Future<void> _editBusinessType(String currentName, String id) async {
    final controller = TextEditingController(text: currentName);
    final updatedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: gold.withOpacity(0.35)),
        ),
        title: const Text(
          'Edit Business Type',
          style: TextStyle(color: white, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          cursorColor: gold,
          style: const TextStyle(color: white),
          decoration: InputDecoration(
            hintText: 'Enter business type',
            hintStyle: const TextStyle(color: mutedText),
            filled: true,
            fillColor: inputColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: gold),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.length >= 2) Navigator.pop(dialogContext, value);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: const Color(0xFF171208),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updatedName == null || updatedName == currentName || !mounted) return;

    final response = await BusinessTypeApi.updateBusinessType(id, updatedName);
    if (!mounted) return;
    if (response['success'] == true) {
      if (selectedBusinessType == currentName) {
        selectedBusinessType = updatedName;
      }
      await _loadBusinessTypes();
      _showMessage('Business type updated.');
    } else {
      _showMessage(response['message']?.toString() ?? 'Unable to update business type.');
    }
  }

  Future<void> _deleteBusinessType(String name, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF71333C)),
        ),
        title: const Text(
          'Delete Business Type?',
          style: TextStyle(color: white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete “$name” from your business-type list?',
          style: const TextStyle(color: mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB83E4D),
              foregroundColor: white,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final response = await BusinessTypeApi.deleteBusinessType(id);
    if (!mounted) return;
    if (response['success'] == true) {
      if (selectedBusinessType == name) selectedBusinessType = null;
      await _loadBusinessTypes();
      _showMessage('Business type deleted.');
    } else {
      _showMessage(
        response['message']?.toString() ?? 'Unable to delete business type.',
        type: response['statusCode'] == 409 ? AppFeedbackType.error : null,
      );
    }
  }

  // ============================================================
  // COMMON DROPDOWN
  // ============================================================

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool manageBusinessTypes = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: items.isEmpty
            ? null
            : () async {
                final selected = await _showSelectionSheet(
                  title: hint,
                  value: value,
                  items: items,
                  manageBusinessTypes: manageBusinessTypes,
                );
                if (selected != null) onChanged(selected);
              },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            color: inputColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value == null
                  ? borderColor
                  : gold.withOpacity(0.55),
            ),
          ),
          child: Row(
            children: [
              Icon(
                value == null
                    ? Icons.tune_rounded
                    : Icons.check_circle_outline_rounded,
                color: gold,
                size: 20,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  value ?? hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: value == null ? mutedText : white,
                    fontSize: 14,
                    fontWeight:
                        value == null ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: gold,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showSelectionSheet({
    required String title,
    required String? value,
    required List<String> items,
    bool manageBusinessTypes = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (sheetContext) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.65,
          ),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          decoration: BoxDecoration(
            color: const Color(0xFF111419),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(26),
            ),
            border: Border(
              top: BorderSide(
                color: gold.withOpacity(0.38),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF555A64),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.list_alt_rounded,
                      color: gold,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: mutedText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final isSelected = item == value;
                    return Material(
                      color: isSelected
                          ? gold.withOpacity(0.12)
                          : const Color(0xFF181B20),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => Navigator.pop(sheetContext, item),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 54),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? gold.withOpacity(0.58)
                                  : borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: gold.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.business_outlined,
                                  color: gold,
                                  size: 17,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: isSelected ? gold : white,
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: gold,
                                  size: 21,
                                ),
                              if (manageBusinessTypes) ...[
                                const SizedBox(width: 5),
                                IconButton(
                                  tooltip: 'Edit $item',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    final id = businessTypeIds[item];
                                    if (id == null) return;
                                    Navigator.pop(sheetContext);
                                    Future<void>.delayed(Duration.zero, () {
                                      if (mounted) _editBusinessType(item, id);
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: gold,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete $item',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    final id = businessTypeIds[item];
                                    if (id == null) return;
                                    Navigator.pop(sheetContext);
                                    Future<void>.delayed(Duration.zero, () {
                                      if (mounted) _deleteBusinessType(item, id);
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFFF7180),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
              Color(0xFFFFD978),
              goldDark,
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
            foregroundColor: Color(0xFF171208),
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

  void _showMessage(String message, {AppFeedbackType? type}) {
    if (!mounted) {
      return;
    }

    AppFeedback.show(context, message, type: type);
  }
}
