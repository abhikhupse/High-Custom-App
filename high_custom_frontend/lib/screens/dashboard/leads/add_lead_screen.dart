import 'package:flutter/material.dart';

import '../../../services/leads_api.dart';
import '../../../services/sequence_api.dart';

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
  static const Color inputColor = Color(0xFF0D0F14);

  static const Color borderColor = Color(0xFF2D3037);

  static const Color gold = Color(0xFFF4C451);
  static const Color goldStrong = Color(0xFFFFC94F);
  static const Color goldDark = Color(0xFF987425);

  static const Color white = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFFECECEF);
  static const Color mutedText = Color(0xFF9699A2);
  static const Color hintText = Color(0xFF737784);

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
  bool trackingEnabled = true;
  bool isLoadingBusinessTypes = true;

  String selectedType = 'Email';
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

    final response = await SequenceApi.getSequences(
      page: 1,
      limit: 100,
    );

    if (!mounted) return;

    final values = <String>{};
    final data = response['data'];

    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;

        final value = item['businessType']?.toString().trim() ?? '';
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
                32,
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
                      _buildTopBar(
                        isMobile,
                      ),

                      SizedBox(
                        height:
                            isMobile
                                ? 20
                                : 24,
                      ),

                      _buildHeader(
                        isMobile,
                      ),

                      SizedBox(
                        height:
                            isMobile
                                ? 22
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
          onTap:
              isSaving
                  ? null
                  : () {
                      Navigator.pop(
                        context,
                      );
                    },
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          child: Container(
            width:
                isMobile ? 46 : 50,
            height:
                isMobile ? 46 : 50,
            decoration:
                BoxDecoration(
              color: surface,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              border:
                  Border.all(
                color: borderColor,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: lightText,
              size: 23,
            ),
          ),
        ),

        const Spacer(),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration:
              BoxDecoration(
            color:
                gold.withOpacity(
              0.08,
            ),
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border:
                Border.all(
              color:
                  gold.withOpacity(
                0.20,
              ),
            ),
          ),
          child: const Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                Icons
                    .person_add_alt_1_rounded,
                color: gold,
                size: 16,
              ),
              SizedBox(
                width: 6,
              ),
              Text(
                'New Lead',
                style:
                    TextStyle(
                  color: gold,
                  fontSize: 11,
                  fontWeight:
                      FontWeight
                          .w700,
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
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 58,
          decoration:
              BoxDecoration(
            color: gold,
            borderRadius:
                BorderRadius.circular(
              8,
            ),
          ),
        ),

        const SizedBox(
          width: 14,
        ),

        Container(
          width:
              isMobile ? 54 : 60,
          height:
              isMobile ? 54 : 60,
          decoration:
              BoxDecoration(
            color:
                gold.withOpacity(
              0.10,
            ),
            borderRadius:
                BorderRadius.circular(
              15,
            ),
          ),
          child: const Icon(
            Icons.person_add_alt_1_outlined,
            color: gold,
            size: 28,
          ),
        ),

        const SizedBox(
          width: 14,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Lead',
                style:
                    TextStyle(
                  color: white,
                  fontSize:
                      isMobile
                          ? 24
                          : 28,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                'Add a new lead to your database',
                style:
                    TextStyle(
                  color: mutedText,
                  fontSize:
                      isMobile
                          ? 12.5
                          : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORM CARD
  // ============================================================

  Widget _buildFormCard(
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? 16 : 22,
      ),
      decoration:
          BoxDecoration(
        color: surface,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: borderColor,
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
            hint: 'Email ID',
            icon:
                Icons.email_outlined,
            keyboardType:
                TextInputType.emailAddress,
          ),

          const SizedBox(
            height: 12,
          ),

          if (isMobile) ...[
            _buildInput(
              controller:
                  firstNameController,
              hint:
                  'First Name',
              icon:
                  Icons.person_outline,
            ),

            const SizedBox(
              height: 12,
            ),

            _buildInput(
              controller:
                  lastNameController,
              hint:
                  'Last Name',
              icon:
                  Icons.person_outline,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child:
                      _buildInput(
                    controller:
                        firstNameController,
                    hint:
                        'First Name',
                    icon:
                        Icons.person_outline,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      _buildInput(
                    controller:
                        lastNameController,
                    hint:
                        'Last Name',
                    icon:
                        Icons.person_outline,
                  ),
                ),
              ],
            ),

          const SizedBox(
            height: 12,
          ),

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

          _buildTypeDropdown(),

          const SizedBox(
            height: 12,
          ),

          _buildBusinessTypeDropdown(),

          const SizedBox(
            height: 14,
          ),

          _buildTrackingCard(),

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
          width: 4,
          height: 26,
          decoration:
              BoxDecoration(
            color: gold,
            borderRadius:
                BorderRadius.circular(
              8,
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        const Icon(
          Icons.auto_awesome_rounded,
          color: gold,
          size: 20,
        ),

        const SizedBox(
          width: 8,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Lead Information',
                style:
                    TextStyle(
                  color: white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight
                          .w700,
                ),
              ),

              SizedBox(
                height: 3,
              ),

              Text(
                'Enter the lead details below',
                style:
                    TextStyle(
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
    required TextEditingController
        controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        enabled: !isSaving,
        keyboardType:
            keyboardType,
        cursorColor: gold,
        style:
            const TextStyle(
          color: white,
          fontSize: 14,
          fontWeight:
              FontWeight.w500,
        ),
        decoration:
            InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(
            color: hintText,
            fontSize: 13,
          ),
          prefixIcon:
              Icon(
            icon,
            color:
                gold.withOpacity(
              0.9,
            ),
            size: 20,
          ),
          filled: true,
          fillColor: inputColor,
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 17,
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            borderSide:
                const BorderSide(
              color: borderColor,
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            borderSide:
                const BorderSide(
              color: gold,
              width: 1,
            ),
          ),
          disabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            borderSide:
                const BorderSide(
              color: borderColor,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TYPE DROPDOWN
  // ============================================================

  Widget _buildTypeDropdown() {
    return Container(
      height: 56,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration:
          BoxDecoration(
        color: inputColor,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child:
          DropdownButtonHideUnderline(
        child:
            DropdownButton<String>(
          value: selectedType,
          isExpanded: true,
          dropdownColor: surface2,
          icon:
              const Icon(
            Icons
                .keyboard_arrow_down_rounded,
            color: mutedText,
          ),
          style:
              const TextStyle(
            color: lightText,
            fontSize: 13,
            fontWeight:
                FontWeight.w500,
          ),
          items:
              const [
            DropdownMenuItem(
              value: 'Email',
              child: Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: gold,
                    size: 19,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Email',
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value:
                  'WhatsApp',
              child: Row(
                children: [
                  Icon(
                    Icons
                        .chat_bubble_outline_rounded,
                    color:
                        Color(
                      0xFF53CF7B,
                    ),
                    size: 19,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    'WhatsApp',
                  ),
                ],
              ),
            ),
          ],
          onChanged:
              isSaving
                  ? null
                  : (
                      value,
                    ) {
                      if (value ==
                          null) {
                        return;
                      }

                      setState(() {
                        selectedType =
                            value;
                      });
                    },
        ),
      ),
    );
  }

  // ============================================================
  // BUSINESS TYPE DROPDOWN
  // ============================================================

  Widget _buildBusinessTypeDropdown() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: inputColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedBusinessType,
          isExpanded: true,
          dropdownColor: surface2,
          icon: isLoadingBusinessTypes
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: gold,
                  ),
                )
              : const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: mutedText,
                ),
          hint: Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: gold,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLoadingBusinessTypes
                      ? 'Loading business types...'
                      : businessTypes.isEmpty
                          ? 'Create a sequence business type first'
                          : 'Select Business Type',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: hintText,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          style: const TextStyle(
            color: lightText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          items: businessTypes
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storefront_outlined,
                        color: gold,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          value,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: isSaving || isLoadingBusinessTypes || businessTypes.isEmpty
              ? null
              : (value) {
                  setState(() {
                    selectedBusinessType = value;
                  });
                },
        ),
      ),
    );
  }

  // ============================================================
  // TRACKING CARD
  // ============================================================

  Widget _buildTrackingCard() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration:
          BoxDecoration(
        color: inputColor,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color:
                  gold.withOpacity(
                0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
            child: const Icon(
              Icons
                  .track_changes_rounded,
              color: gold,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Tracking',
                  style:
                      TextStyle(
                    color: white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                SizedBox(
                  height: 3,
                ),

                Text(
                  'Track email opens and clicks',
                  style:
                      TextStyle(
                    color: mutedText,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: trackingEnabled,
            activeColor: gold,
            activeTrackColor:
                goldDark,
            inactiveThumbColor:
                mutedText,
            inactiveTrackColor:
                const Color(
              0xFF292C33,
            ),
            onChanged:
                isSaving
                    ? null
                    : (
                        value,
                      ) {
                        setState(
                          () {
                            trackingEnabled =
                                value;
                          },
                        );
                      },
          ),
        ],
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
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .stretch,
        children: [
          _buildSaveButton(),

          const SizedBox(
            height: 10,
          ),

          _buildCancelButton(),
        ],
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
                        .save_outlined,
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
            ? 'Create an active sequence with a Business Type first.'
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
        tracking: trackingEnabled,
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

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            const Color(
          0xFF20242E,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
      ),
    );
  }
}
