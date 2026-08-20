import 'package:flutter/material.dart';

import '../../../services/leads_api.dart';
import '../../../services/sequence_api.dart';

// ============================================================
// ADD LEAD SCREEN
// Theme matched with LeadsScreen
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

  static const Color pageBackground = Color(0xFFF4F6FA);

  static const Color panelColor = Color(0xFF5B5E66);

  static const Color tableColor = Color(0xFF0D101B);

  static const Color inputColor = Color(0xFF0D101B);

  static const Color gold = Color(0xFFF2C45F);

  static const Color goldDark = Color(0xFFD9A93F);

  static const Color white = Color(0xFFFFFFFF);

  static const Color lightText = Color(0xFFE8EAF0);

  static const Color mutedText = Color(0xFF9CA3AF);

  static const Color border = Color(0xFF777A82);

  static const Color blue = Color(0xFF315BEF);

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

  String selectedType = 'Email';

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
          builder: (context, constraints) {
            final bool isMobile =
                constraints.maxWidth < 850;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 14 : 28,
                isMobile ? 18 : 28,
                isMobile ? 14 : 28,
                35,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 900,
                  ),
                  child: _buildPageContent(
                    isMobile,
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
  // PAGE CONTENT
  // ============================================================

  Widget _buildPageContent(bool isMobile) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        _buildTopHeader(isMobile),

        const SizedBox(height: 16),

        _buildFormPanel(isMobile),
      ],
    );
  }

  // ============================================================
  // TOP HEADER
  // ============================================================

  Widget _buildTopHeader(bool isMobile) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(
        isMobile ? 16 : 18,
      ),

      decoration: BoxDecoration(
        color: panelColor,

        borderRadius:
            BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),

      child: Row(
        children: [
          // GOLD ACCENT LINE
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: gold,
              borderRadius:
                  BorderRadius.circular(4),
            ),
          ),

          const SizedBox(width: 12),

          // ICON
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.person_add_outlined,
              color: gold,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          // TITLE
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Lead',
                  style: TextStyle(
                    color: lightText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Add a new lead to your database',
                  style: TextStyle(
                    color: mutedText,
                    fontSize:
                        isMobile ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),

          // CLOSE BUTTON
          IconButton(
            tooltip: 'Close',

            onPressed: isSaving
                ? null
                : () {
                    Navigator.pop(context);
                  },

            icon: const Icon(
              Icons.close,
              color: lightText,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM PANEL
  // ============================================================

  Widget _buildFormPanel(bool isMobile) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(
        isMobile ? 15 : 18,
      ),

      decoration: BoxDecoration(
        color: panelColor,

        borderRadius:
            BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),

          const SizedBox(height: 16),

          _buildFormFields(isMobile),

          const SizedBox(height: 16),

          _buildTrackingSwitch(),

          const SizedBox(height: 18),

          _buildActions(isMobile),
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
          height: 18,
          decoration: BoxDecoration(
            color: gold,
            borderRadius:
                BorderRadius.circular(4),
          ),
        ),

        const SizedBox(width: 10),

        const Icon(
          Icons.auto_awesome,
          color: gold,
          size: 18,
        ),

        const SizedBox(width: 7),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Lead Information',
                style: TextStyle(
                  color: lightText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 3),

              Text(
                'Enter the details of the new lead.',
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
  // FORM FIELDS
  // ============================================================

  Widget _buildFormFields(bool isMobile) {
    return Column(
      children: [
        // EMAIL
        _darkInput(
          controller: emailController,
          hint: 'Email ID *',
          icon: Icons.email_outlined,
          keyboardType:
              TextInputType.emailAddress,
        ),

        const SizedBox(height: 10),

        // NAME
        if (isMobile)
          Column(
            children: [
              _darkInput(
                controller:
                    firstNameController,
                hint: 'First Name *',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 10),

              _darkInput(
                controller:
                    lastNameController,
                hint: 'Last Name *',
                icon: Icons.person_outline,
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _darkInput(
                  controller:
                      firstNameController,
                  hint: 'First Name *',
                  icon: Icons.person_outline,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _darkInput(
                  controller:
                      lastNameController,
                  hint: 'Last Name *',
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),

        const SizedBox(height: 10),

        // COMPANY
        _darkInput(
          controller: companyController,
          hint: 'Company Name *',
          icon: Icons.business_outlined,
        ),

        const SizedBox(height: 10),

        // BUSINESS TYPE
        _darkDropdown(
          value: selectedType,
          items: const [
            'Email',
            'WhatsApp',
          ],
          hint: 'Select Business Type',
          onChanged: isSaving
              ? null
              : (String? value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedType = value;
                  });
                },
        ),
      ],
    );
  }

  // ============================================================
  // DARK INPUT
  // ============================================================

  Widget _darkInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: 44,

      child: TextField(
        controller: controller,

        keyboardType: keyboardType,

        enabled: !isSaving,

        style: const TextStyle(
          color: white,
          fontSize: 12,
        ),

        cursorColor: gold,

        decoration: InputDecoration(
          hintText: hint,

          hintStyle: const TextStyle(
            color: Color(0xFF73798B),
            fontSize: 12,
          ),

          prefixIcon: Icon(
            icon,
            color: const Color(0xFF666D7F),
            size: 17,
          ),

          filled: true,

          fillColor: inputColor,

          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 10,
          ),

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: gold,
              width: 1,
            ),
          ),

          disabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DARK DROPDOWN
  //
  // IMPORTANT:
  // ValueChanged<String?>? fixes the Flutter error where
  // a nullable callback was being passed to DropdownButton.
  // ============================================================

  Widget _darkDropdown({
    required String value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      height: 44,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),

      decoration: BoxDecoration(
        color: inputColor,

        borderRadius:
            BorderRadius.circular(12),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,

          isExpanded: true,

          dropdownColor: tableColor,

          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: mutedText,
            size: 18,
          ),

          style: const TextStyle(
            color: white,
            fontSize: 12,
          ),

          borderRadius:
              BorderRadius.circular(12),

          items: items.map(
            (item) {
              final bool isWhatsApp =
                  item.toLowerCase() ==
                      'whatsapp';

              return DropdownMenuItem<String>(
                value: item,

                child: Row(
                  children: [
                    Icon(
                      isWhatsApp
                          ? Icons.chat_outlined
                          : Icons.email_outlined,

                      color: isWhatsApp
                          ? const Color(
                              0xFF65E49C,
                            )
                          : const Color(
                              0xFF9AAEFF,
                            ),

                      size: 15,
                    ),

                    const SizedBox(width: 8),

                    Text(item),
                  ],
                ),
              );
            },
          ).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }

  // ============================================================
  // TRACKING
  // ============================================================

  Widget _buildTrackingSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161A27),

        borderRadius:
            BorderRadius.circular(12),

        border: Border.all(
          color: const Color(0xFF292E3D),
        ),
      ),

      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 3,
        ),

        title: const Text(
          'Enable Tracking',
          style: TextStyle(
            color: white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),

        subtitle: const Text(
          'Track email opens and clicks',
          style: TextStyle(
            color: mutedText,
            fontSize: 11,
          ),
        ),

        value: trackingEnabled,

        activeColor: gold,

        activeTrackColor:
            goldDark.withOpacity(0.55),

        inactiveThumbColor:
            Color(0xFF777A82),

        inactiveTrackColor:
            Color(0xFF292E3D),

        onChanged: isSaving
            ? null
            : (value) {
                setState(() {
                  trackingEnabled =
                      value;
                });
              },
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActions(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _darkBackButton(),

          const SizedBox(height: 10),

          _goldSaveButton(
            expanded: true,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.end,
      children: [
        _darkBackButton(),

        const SizedBox(width: 10),

        _goldSaveButton(),
      ],
    );
  }

  // ============================================================
  // CANCEL BUTTON
  // ============================================================

  Widget _darkBackButton() {
    return SizedBox(
      height: 44,

      child: OutlinedButton.icon(
        onPressed: isSaving
            ? null
            : () {
                Navigator.pop(context);
              },

        icon: const Icon(
          Icons.arrow_back,
          size: 16,
        ),

        label: const Text(
          'Cancel',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),

        style:
            OutlinedButton.styleFrom(
          foregroundColor: lightText,

          side: const BorderSide(
            color: Color(0xFF858890),
          ),

          backgroundColor:
              Colors.transparent,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _goldSaveButton({
    bool expanded = false,
  }) {
    return SizedBox(
      height: 44,

      width: expanded
          ? double.infinity
          : null,

      child: ElevatedButton.icon(
        onPressed: isSaving
            ? null
            : _saveLead,

        icon: isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2D2610),
                ),
              )
            : const Icon(
                Icons.save_outlined,
                size: 17,
              ),

        label: Text(
          isSaving
              ? 'Saving...'
              : 'Save Lead',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor: gold,

          foregroundColor:
              const Color(0xFF2D2610),

          disabledBackgroundColor:
              const Color(0xFFB89B4C),

          elevation: 0,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
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

    // ==========================================================
    // EMAIL REQUIRED
    // ==========================================================

    if (email.isEmpty) {
      _showMessage(
        'Email is required.',
      );
      return;
    }

    // ==========================================================
    // EMAIL VALIDATION
    // ==========================================================

    final RegExp emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    // ==========================================================
    // START SAVING
    // ==========================================================

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
        tracking: trackingEnabled,
      );

      if (!mounted) {
        return;
      }

      if (response['success'] == true) {
        Map<String, dynamic>?
            sequenceResponse;

        // ======================================================
        // RUN EMAIL SEQUENCE
        // ======================================================

        if (trackingEnabled &&
            selectedType == 'Email') {
          sequenceResponse =
              await SequenceApi.runSequence();
        }

        if (!mounted) {
          return;
        }

        final bool sequenceFailed =
            sequenceResponse != null &&
                sequenceResponse['success'] !=
                    true;

        if (sequenceFailed) {
          _showMessage(
            'Lead added, but the sequence could not be run.',
          );
        } else {
          _showMessage(
            response['message']
                    ?.toString() ??
                'Lead added successfully.',
          );
        }

        // ======================================================
        // RETURN TO LEADS SCREEN
        //
        // true tells LeadsScreen that a lead
        // was successfully added.
        // ======================================================

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
    } catch (_) {
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

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            const Color(0xFF20242E),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10),
        ),
      ),
    );
  }
}