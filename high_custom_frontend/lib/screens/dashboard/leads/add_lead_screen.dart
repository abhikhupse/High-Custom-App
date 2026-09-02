import 'package:flutter/material.dart';

import '../../../services/leads_api.dart';
import '../../../services/business_type_api.dart';
import '../../../widgets/app_feedback.dart';
import '../dashboard_screen.dart';

// ============================================================
// ADD LEAD SCREEN
// ============================================================

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color pageBackground = Color(0xFF090A0C);
  static const Color surface = Color(0xFF111216);
  static const Color surface2 = Color(0xFF15171B);

  static const Color borderColor = Color(0xFF2D3037);

  static const Color gold = Color(0xFFF4C451);
  static const Color goldStrong = Color(0xFFFFC94F);

  static const Color white = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFFECECEF);
  static const Color mutedText = Color(0xFF9699A2);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController firstNameController =
      TextEditingController();

  final TextEditingController lastNameController =
      TextEditingController();

  final TextEditingController companyController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool isSaving = false;
  bool isLoadingBusinessTypes = true;

  static const String selectedType = 'Email';
  String? selectedBusinessType;

  final List<String> businessTypes = [];

  @override
  void initState() {
    super.initState();
    _loadBusinessTypes();
  }

  Future<void> _loadBusinessTypes() async {
    setState(() {
      isLoadingBusinessTypes = true;
    });

    final response = await BusinessTypeApi.getBusinessTypes();

    if (!mounted) return;

    final values = <String>{};
    final data = response['data'];

    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;

        final value = item['name']?.toString().trim() ?? '';
        if (value.isNotEmpty) values.add(value);
      }
    }

    final sortedValues = values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    setState(() {
      businessTypes
        ..clear()
        ..addAll(sortedValues);

      if (selectedBusinessType != null &&
          !businessTypes.contains(selectedBusinessType)) {
        selectedBusinessType = null;
      }

      isLoadingBusinessTypes = false;
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    companyController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      bottomNavigationBar:
          MediaQuery.sizeOf(context).width < 700
              ? _buildMobileFooter()
              : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final isMobile =
                constraints.maxWidth < 700;

            return SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 28,
                isMobile ? 16 : 28,
                isMobile ? 16 : 28,
                isMobile ? 22 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 720,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      _buildTopBar(isMobile),

                      SizedBox(
                        height:
                            isMobile
                                ? 16
                                : 24,
                      ),

                      _buildHeader(
                        isMobile,
                      ),

                      SizedBox(
                        height:
                            isMobile
                                ? 16
                                : 26,
                      ),

                      _buildFormCard(
                        isMobile,
                      ),
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

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(
    bool isMobile,
  ) {
    return Row(
      children: [
        InkWell(
          onTap: isSaving
              ? null
              : () {
                  Navigator.pop(context);
                },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: isMobile ? 46 : 50,
            height: isMobile ? 46 : 50,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: gold,
              size: 23,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Lead',
                style: TextStyle(
                  color: white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: gold.withOpacity(0.45),
                  ),
                  color: gold.withOpacity(0.06),
                ),
                child: const Text(
                  '• Draft',
                  style: TextStyle(
                    color: gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
  // HEADER
  // ============================================================

  Widget _buildHeader(
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? 18 : 22,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF171711),
            Color(0xFF111216),
          ],
        ),
        border: Border.all(
          color: gold.withOpacity(0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New contact',
                  style: TextStyle(
                    color: white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Build your next connection',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: isMobile ? 12.5 : 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gold.withOpacity(0.12),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: gold,
              size: 31,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM CARD
  // ============================================================

  Widget _buildFormCard(
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.zero,
      decoration:
          BoxDecoration(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.18,
            ),
            blurRadius: 20,
            offset:
                const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),

          const SizedBox(
            height: 18,
          ),

          _buildInput(
            controller:
                emailController,
            hint: 'Email Address',
            icon:
                Icons.email_outlined,
            keyboardType:
                TextInputType.emailAddress,
            requiredField: true,
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInput(
                  controller: firstNameController,
                  hint: 'First Name',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  controller: lastNameController,
                  hint: 'Last Name',
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surface2,
                  border: Border.all(color: borderColor),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: gold,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Company',
                style: TextStyle(
                  color: white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildInput(
            controller:
                companyController,
            hint:
                'Company Name',
            icon:
                Icons.business_outlined,
          ),

          const SizedBox(
            height: 12,
          ),

          _buildBusinessTypeDropdown(),

          const SizedBox(
            height: 18,
          ),

          _buildActions(
            isMobile,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: surface2,
            border: Border.all(
              color: borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: gold,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact',
                style: TextStyle(
                  color: white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Add the lead’s contact details',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool requiredField = false,
  }) {
    final bool isCompactName =
        hint == 'First Name' || hint == 'Last Name';

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(
        horizontal: isCompactName ? 10 : 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: gold,
            size: isCompactName ? 19 : 22,
          ),
          SizedBox(width: isCompactName ? 8 : 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requiredField ? '$hint  •' : hint,
                  style: TextStyle(
                    color: lightText,
                    fontSize: isCompactName ? 11 : 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !isSaving,
                    keyboardType: keyboardType,
                    cursorColor: gold,
                    style: const TextStyle(
                      color: white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!requiredField) ...[
            SizedBox(width: isCompactName ? 5 : 8),
            Text(
              'Optional',
              style: TextStyle(
                color: mutedText,
                fontSize: isCompactName ? 9 : 10.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BUSINESS TYPE SELECTOR
  // ============================================================

  Future<void> _selectBusinessType() async {
    if (isSaving || isLoadingBusinessTypes || businessTypes.isEmpty) {
      return;
    }

    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.72),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.62,
            ),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF14161A),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF555962),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      color: gold,
                      size: 23,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Select Business Type',
                      style: TextStyle(
                        color: white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: businessTypes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = businessTypes[index];
                      final selected = item == selectedBusinessType;
                      return Material(
                        color: selected
                            ? gold.withOpacity(0.12)
                            : const Color(0xFF1A1C21),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => Navigator.pop(sheetContext, item),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? gold.withOpacity(0.55)
                                    : const Color(0xFF2D3037),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.business_outlined,
                                  color: gold,
                                  size: 19,
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: selected ? gold : lightText,
                                      fontSize: 14,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: gold,
                                    size: 20,
                                  ),
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
        );
      },
    );

    if (value != null && mounted) {
      setState(() {
        selectedBusinessType = value;
      });
    }
  }

  Widget _buildBusinessTypeDropdown() {
    final helper = isLoadingBusinessTypes
        ? 'Loading business types...'
        : businessTypes.isEmpty
            ? 'Add a Business Type from the Link page first'
            : selectedBusinessType ?? 'Select a business type';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectBusinessType,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selectedBusinessType == null
                  ? borderColor
                  : gold.withOpacity(0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: gold,
                size: 23,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Business Type  •',
                      style: TextStyle(
                        color: lightText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      helper,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selectedBusinessType == null
                            ? mutedText
                            : white,
                        fontSize: 13.5,
                        fontWeight: selectedBusinessType == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoadingBusinessTypes)
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: gold,
                  ),
                )
              else
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: mutedText,
                  size: 25,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDashboardSection(String menu) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          initialMenu: menu,
        ),
      ),
      (route) => false,
    );
  }

  Widget _buildMobileFooter() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070A0E),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: Row(
            children: [
              _buildFooterItem(
                label: 'Dashboard',
                icon: Icons.home_outlined,
                onTap: () => _openDashboardSection('Dashboard'),
              ),
              _buildFooterItem(
                label: 'Leads',
                icon: Icons.people_outline_rounded,
                onTap: () => _openDashboardSection('Leads'),
              ),
              _buildAddLeadFooterItem(),
              _buildFooterItem(
                label: 'Sequences',
                icon: Icons.account_tree_outlined,
                onTap: () => _openDashboardSection('Master'),
              ),
              _buildFooterItem(
                label: 'Settings',
                icon: Icons.settings_outlined,
                onTap: () => _openDashboardSection('Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: isSaving ? null : onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 25,
              color: const Color(0xFFAEB4BF),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFFAEB4BF),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddLeadFooterItem() {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD978), Color(0xFFD9A93F)],
                ),
                border: Border.all(
                  color: const Color(0xFFFFE6A6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 32,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Add Lead',
              style: TextStyle(
                color: gold,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions(
    bool isMobile,
  ) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gold.withOpacity(0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSaveButton(),
            const SizedBox(height: 4),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child:
              _buildCancelButton(),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          flex: 2,
          child:
              _buildSaveButton(),
        ),
      ],
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child:
          ElevatedButton.icon(
        onPressed:
            isSaving
                ? null
                : _saveLead,
        icon:
            isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(
                      strokeWidth:
                          2,
                      color:
                          Color(
                        0xFF171208,
                      ),
                    ),
                  )
                : const Icon(
                    Icons
                        .person_add_alt_1_rounded,
                    size: 19,
                  ),
        label:
            Text(
          isSaving
              ? 'Saving...'
              : 'Save Lead',
          style:
              const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              goldStrong,
          foregroundColor:
              const Color(
            0xFF191406,
          ),
          disabledBackgroundColor:
              const Color(
            0xFF967D3C,
          ),
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CANCEL BUTTON
  // ============================================================

  Widget _buildCancelButton() {
    return SizedBox(
      height: 50,
      child:
          OutlinedButton.icon(
        onPressed:
            isSaving
                ? null
                : () {
                    Navigator.pop(
                      context,
                    );
                  },
        icon:
            const Icon(
          Icons
              .arrow_back_rounded,
          size: 18,
        ),
        label:
            const Text(
          'Cancel',
          style:
              TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              lightText,
          side:
              const BorderSide(
            color: borderColor,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE LEAD
  // ============================================================

  Future<void> _saveLead() async {
    final String email =
        emailController.text.trim();

    final String firstName =
        firstNameController.text.trim();

    final String lastName =
        lastNameController.text.trim();

    final String company =
        companyController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        'Email is required.',
      );

      return;
    }

    final RegExp emailRegex =
        RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(
      email,
    )) {
      _showMessage(
        'Please enter a valid email address.',
      );

      return;
    }

    final businessType = selectedBusinessType?.trim() ?? '';

    if (businessType.isEmpty) {
      _showMessage(
        businessTypes.isEmpty
            ? 'Add a Business Type from the Link page first.'
            : 'Please select a Business Type.',
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final response =
          await LeadsApi.createLead(
        email: email,
        firstName: firstName,
        lastName: lastName,
        company: company,
        type: selectedType,
        businessType: businessType,
        tracking: true,
      );

      if (!mounted) {
        return;
      }

      if (response['success'] ==
          true) {
        _showMessage(
          response['message']
                  ?.toString() ??
              'Lead added successfully.',
        );

        Navigator.pop(
          context,
          true,
        );
      } else {
        _showMessage(
          response['message']
                  ?.toString() ??
              'Unable to add lead.',
        );
      }
    } catch (error) {
      debugPrint(
        'Add lead error: $error',
      );

      if (mounted) {
        _showMessage(
          'Unable to add lead. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    AppFeedback.show(context, message);
  }
}
