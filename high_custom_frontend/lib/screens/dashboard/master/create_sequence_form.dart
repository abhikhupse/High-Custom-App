import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/sequence_api.dart';
import 'create_sequence_preview.dart';

class CreateSequenceForm extends StatefulWidget {
  const CreateSequenceForm({
    super.key,
  });

  @override
  State<CreateSequenceForm> createState() =>
      _CreateSequenceFormState();
}

class _SequenceTypeOption {
  final String value;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _SequenceTypeOption({
    required this.value,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}

class _CreateSequenceFormState extends State<CreateSequenceForm> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF315BEF);
  static const Color backgroundColor = Color(0xFFF6F8FC);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF101828);
  static const Color secondaryTextColor = Color(0xFF667085);
  static const Color borderColor = Color(0xFFD0D5DD);
  static const Color lightBorderColor = Color(0xFFE4E7EC);
  static const Color fieldBackground = Color(0xFFF9FAFB);

  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController stepController =
      TextEditingController();

  final TextEditingController gapDaysController =
      TextEditingController();

  final TextEditingController variantController =
      TextEditingController();

  final TextEditingController subjectController =
      TextEditingController();

  final TextEditingController logoController =
      TextEditingController();

  final TextEditingController heroImageController =
      TextEditingController();

  final TextEditingController heroLinkController =
      TextEditingController();

  final TextEditingController contentController =
      TextEditingController();

  final TextEditingController whatsappController =
      TextEditingController();

  final TextEditingController ctaTextController =
      TextEditingController();

  final TextEditingController ctaUrlController =
      TextEditingController();

  final TextEditingController attachmentNameController =
      TextEditingController();

  final TextEditingController attachmentUrlController =
      TextEditingController();

  final TextEditingController attachmentMimeController =
      TextEditingController();

  final TextEditingController attachmentSizeController =
      TextEditingController();

  // ============================================================
  // DROPDOWNS
  // ============================================================

  String selectedType = 'Email';

  String selectedLogoPosition = 'Center';

  String selectedFont = 'Arial';

  String selectedFontSize = '16px';

  String selectedTextColor = 'Black';

  String selectedStatus = 'draft';

  // ============================================================
  // TEXT FORMATTING
  // ============================================================

  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;

  // ============================================================
  // TRACKING
  // ============================================================

  bool trackingEnabled = true;

  // ============================================================
  // SCHEDULING
  // ============================================================

  DateTime? scheduledDateTime;

  // ============================================================
  // LOADING
  // ============================================================

  bool isLoading = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    stepController.clear();
    gapDaysController.clear();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    stepController.dispose();
    gapDaysController.dispose();
    variantController.dispose();
    subjectController.dispose();
    logoController.dispose();
    heroImageController.dispose();
    heroLinkController.dispose();
    contentController.dispose();
    whatsappController.dispose();
    ctaTextController.dispose();
    ctaUrlController.dispose();
    attachmentNameController.dispose();
    attachmentUrlController.dispose();
    attachmentMimeController.dispose();
    attachmentSizeController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return _buildMobileLayout();
          }

          return _buildDesktopLayout();
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP LAYOUT
  // ============================================================

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),

          const SizedBox(height: 24),

          _buildBasicInformationCard(),

          const SizedBox(height: 20),

          _buildBrandIdentityCard(),

          const SizedBox(height: 20),

          _buildHeroImageCard(),

          const SizedBox(height: 20),

          _buildEmailContentCard(),

          const SizedBox(height: 20),

          _buildAttachmentCard(),

          const SizedBox(height: 20),

          _buildActionLinksCard(),

          const SizedBox(height: 20),

          _buildSchedulingCard(),

          const SizedBox(height: 20),

          _buildPreviewCard(),

          const SizedBox(height: 30),

          _buildBottomButtons(),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE LAYOUT
  // ============================================================

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),

          const SizedBox(height: 20),

          _buildBasicInformationCard(),

          const SizedBox(height: 20),

          _buildBrandIdentityCard(),

          const SizedBox(height: 20),

          _buildHeroImageCard(),

          const SizedBox(height: 20),

          _buildEmailContentCard(),

          const SizedBox(height: 20),

          _buildAttachmentCard(),

          const SizedBox(height: 20),

          _buildActionLinksCard(),

          const SizedBox(height: 20),

          _buildSchedulingCard(),

          const SizedBox(height: 20),

          _buildPreviewCard(),

          const SizedBox(height: 30),

          _buildBottomButtons(),
        ],
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Email Sequence',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Create and configure your marketing sequence.',
          style: TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 1. BASIC INFORMATION
  // ============================================================

  Widget _buildBasicInformationCard() {
    return _buildCard(
      title: 'Basic Information',
      icon: Icons.info_outline,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildTextField(
                      controller: stepController,
                      label: 'Step',
                      hint: 'Example 1',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Step is required';
                        }

                        final step =
                            int.tryParse(value.trim());

                        if (step == null || step <= 0) {
                          return 'Step Should bot be 0. Enter a valid step';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    _buildTextField(
                      controller: gapDaysController,
                      label: 'Gap Days',
                      hint: 'Example 0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Gap days is required';
                        }

                        final days =
                            int.tryParse(value.trim());

                        if (days == null) {
                          return 'Enter valid days';
                        }

                        return null;
                      },
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: stepController,
                      label: 'Step',
                      hint: 'Enter step number',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Step is required';
                        }

                        final step =
                            int.tryParse(value.trim());

                        if (step == null || step <= 0) {
                          return 'Enter a valid step';
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: gapDaysController,
                      label: 'Gap Days',
                      hint: 'Enter gap days',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Gap days is required';
                        }

                        final days =
                            int.tryParse(value.trim());

                        if (days == null || days < 0) {
                          return 'Enter valid days';
                        }

                        return null;
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildTextField(
                      controller: variantController,
                      label: 'Variant',
                      hint: 'Example: A',
                      textCapitalization:
                          TextCapitalization.characters,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Variant is required';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    _buildTypeSelector(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: variantController,
                      label: 'Variant',
                      hint: 'Example: A',
                      textCapitalization:
                          TextCapitalization.characters,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Variant is required';
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTypeSelector(),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          _buildTextField(
            controller: subjectController,
            label: 'Email Subject',
            hint: 'Enter your email subject',
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Email subject is required';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2. BRAND IDENTITY
  // ============================================================

  Widget _buildBrandIdentityCard() {
    return _buildCard(
      title: 'Brand Identity',
      icon: Icons.business_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendation(
            title: 'Recommended Company Logo / Banner',
            icon: Icons.lightbulb_outline,
            children: const [
              _RecommendationRow(
                label: 'Banner',
                value: '500 × 200 px or 800 × 300 px',
              ),
              _RecommendationRow(
                label: 'Logo',
                value: '300 × 300 px or 450 × 120 px',
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildFilePicker(
            label: 'Company Logo / Banner',
            value: logoController.text,
            emptyText: 'Upload company logo or banner',
            icon: Icons.cloud_upload_outlined,
            onTap: _pickLogoFile,
          ),

          const SizedBox(height: 18),

          _buildDropdown(
            label: 'Logo Position',
            value: selectedLogoPosition,
            items: const [
              'Left',
              'Center',
              'Right',
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedLogoPosition = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. HERO IMAGE
  // ============================================================

  Widget _buildHeroImageCard() {
    return _buildCard(
      title: 'Hero Image',
      icon: Icons.image_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendation(
            title: 'Recommended Hero Image',
            icon: Icons.photo_size_select_large_outlined,
            children: const [
              _RecommendationRow(
                label: 'Size',
                value: '1200 × 400 px',
              ),
              _RecommendationRow(
                label: 'Maximum',
                value: '2 MB',
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildFilePicker(
            label: 'Hero Image',
            value: heroImageController.text,
            emptyText: 'Upload hero image',
            icon: Icons.add_photo_alternate_outlined,
            onTap: _pickHeroImage,
          ),

          const SizedBox(height: 18),

          _buildTextField(
            controller: heroLinkController,
            label: 'Hero Image Link',
            hint: 'https://example.com',
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 4. EMAIL CONTENT
  // ============================================================

  Widget _buildEmailContentCard() {
    return _buildCard(
      title: 'Email Content',
      icon: Icons.email_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editor Settings',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          _buildEditorSettings(),

          const SizedBox(height: 18),

          _buildEditorToolbar(),

          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: TextFormField(
              controller: contentController,
              minLines: 12,
              maxLines: 22,
              keyboardType: TextInputType.multiline,
              textCapitalization:
                  TextCapitalization.sentences,
              style: TextStyle(
                color: _getSelectedTextColor(),
                fontSize: _getFontSize(),
                fontWeight:
                    isBold
                        ? FontWeight.bold
                        : FontWeight.normal,
                fontStyle:
                    isItalic
                        ? FontStyle.italic
                        : FontStyle.normal,
                decoration:
                    isUnderline
                        ? TextDecoration.underline
                        : TextDecoration.none,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Write your email content here...',
                hintStyle: TextStyle(
                  color: Color(0xFF98A2B3),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onChanged: (_) {
                setState(() {});
              },
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Email content is required';
                }

                return null;
              },
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'You can use variables such as {{firstName}}, {{lastName}}, {{email}}.',
            style: TextStyle(
              fontSize: 12,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDITOR SETTINGS
  // FIXED MOBILE OVERFLOW
  // ============================================================

  Widget _buildEditorSettings() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // MOBILE
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildDropdown(
                label: 'Font',
                value: selectedFont,
                items: const [
                  'Arial',
                  'Roboto',
                  'Helvetica',
                  'Times New Roman',
                  'Georgia',
                  'Verdana',
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedFont = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              _buildDropdown(
                label: 'Font Size',
                value: selectedFontSize,
                items: const [
                  '12px',
                  '14px',
                  '16px',
                  '18px',
                  '20px',
                  '24px',
                  '28px',
                  '32px',
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedFontSize = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              _buildDropdown(
                label: 'Text Color',
                value: selectedTextColor,
                items: const [
                  'Black',
                  'White',
                  'Gray',
                  'Red',
                  'Blue',
                  'Green',
                  'Gold',
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedTextColor = value;
                  });
                },
              ),
            ],
          );
        }

        // DESKTOP / TABLET
        return Column(
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Font',
                    value: selectedFont,
                    items: const [
                      'Arial',
                      'Roboto',
                      'Helvetica',
                      'Times New Roman',
                      'Georgia',
                      'Verdana',
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedFont = value;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: _buildDropdown(
                    label: 'Font Size',
                    value: selectedFontSize,
                    items: const [
                      '12px',
                      '14px',
                      '16px',
                      '18px',
                      '20px',
                      '24px',
                      '28px',
                      '32px',
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedFontSize = value;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Text Color',
              value: selectedTextColor,
              items: const [
                'Black',
                'White',
                'Gray',
                'Red',
                'Blue',
                'Green',
                'Gold',
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedTextColor = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EDITOR TOOLBAR
  // ============================================================

  Widget _buildEditorToolbar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: lightBorderColor,
        ),
      ),
      child: Row(
        children: [
          _toolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Bold',
            active: isBold,
            onPressed: () {
              setState(() {
                isBold = !isBold;
              });
            },
          ),

          _toolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Italic',
            active: isItalic,
            onPressed: () {
              setState(() {
                isItalic = !isItalic;
              });
            },
          ),

          _toolbarButton(
            icon: Icons.format_underlined,
            tooltip: 'Underline',
            active: isUnderline,
            onPressed: () {
              setState(() {
                isUnderline = !isUnderline;
              });
            },
          ),

          const Spacer(),

          TextButton.icon(
            onPressed: () {
              contentController.clear();

              setState(() {});
            },
            icon: const Icon(
              Icons.delete_outline,
              size: 17,
            ),
            label: const Text(
              'Clear',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: active
              ? primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 19,
            color:
                active
                    ? primaryColor
                    : textColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 5. ATTACHMENT
  // ============================================================

  Widget _buildAttachmentCard() {
    return _buildCard(
      title: 'Attachment',
      icon: Icons.attach_file,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilePicker(
            label: 'Attachment File',
            value: attachmentNameController.text,
            emptyText: 'Upload attachment',
            icon: Icons.upload_file_outlined,
            onTap: _pickAttachmentFile,
          ),

          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildTextField(
                      controller:
                          attachmentMimeController,
                      label: 'MIME Type',
                      hint: 'application/pdf',
                    ),

                    const SizedBox(height: 18),

                    _buildTextField(
                      controller:
                          attachmentSizeController,
                      label: 'File Size',
                      hint: 'Size in bytes',
                      keyboardType:
                          TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller:
                          attachmentMimeController,
                      label: 'MIME Type',
                      hint: 'application/pdf',
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: _buildTextField(
                      controller:
                          attachmentSizeController,
                      label: 'File Size',
                      hint: 'Size in bytes',
                      keyboardType:
                          TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                      ],
                    ),
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
  // 6. ACTION LINK / CTA
  // ============================================================

  Widget _buildActionLinksCard() {
    return _buildCard(
      title: 'Action Link / CTA Button',
      icon: Icons.ads_click_outlined,
      child: Column(
        children: [
          _buildTextField(
            controller: ctaTextController,
            label: 'CTA Button Text',
            hint: 'Example: Shop Now',
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: ctaUrlController,
            label: 'CTA Button URL',
            hint: 'https://example.com',
            keyboardType: TextInputType.url,
          ),

          const SizedBox(height: 18),

          _buildTextField(
            controller: whatsappController,
            label: 'WhatsApp Link',
            hint: 'https://wa.me/919999999999',
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 7. SCHEDULING
  // FIXED TRACKING OVERFLOW
  // ============================================================

  Widget _buildSchedulingCard() {
    return _buildCard(
      title: 'Scheduling',
      icon: Icons.schedule_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile =
              constraints.maxWidth < 600;

          return Column(
            children: [
              if (isMobile)
                Column(
                  children: [
                    _buildDropdown(
                      label: 'Status',
                      value: selectedStatus,
                      items: const [
                        'draft',
                        'scheduled',
                        'active',
                        'paused',
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildTrackingSwitch(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Status',
                        value: selectedStatus,
                        items: const [
                          'draft',
                          'scheduled',
                          'active',
                          'paused',
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: _buildTrackingSwitch(),
                    ),
                  ],
                ),

              const SizedBox(height: 18),

              InkWell(
                onTap: _selectDateTime,
                borderRadius:
                    BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: fieldBackground,
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                      color: borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color:
                              primaryColor
                                  .withOpacity(0.10),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scheduled Date & Time',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    secondaryTextColor,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              scheduledDateTime == null
                                  ? 'Select date and time'
                                  : _formatDateTime(
                                      scheduledDateTime!,
                                    ),
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    scheduledDateTime ==
                                            null
                                        ? secondaryTextColor
                                        : textColor,
                                fontWeight:
                                    scheduledDateTime ==
                                            null
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right,
                        color: secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),

              if (scheduledDateTime != null)
                Align(
                  alignment:
                      Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        scheduledDateTime = null;
                      });
                    },
                    child: const Text(
                      'Clear Schedule',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // TRACKING SWITCH
  // ============================================================

  Widget _buildTrackingSwitch() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 72,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: fieldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: primaryColor,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'Enable Tracking',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 6),

          Switch.adaptive(
            value: trackingEnabled,
            activeColor: primaryColor,
            onChanged: (value) {
              setState(() {
                trackingEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 8. LIVE PREVIEW
  // ============================================================

  Widget _buildPreviewCard() {
    return CreateSequencePreview(
      subjectController: subjectController,
      logoController: logoController,
      heroImageController: heroImageController,
      heroLinkController: heroLinkController,
      emailContentController: contentController,
      whatsappController: whatsappController,
      ctaTextController: ctaTextController,
      ctaUrlController: ctaUrlController,
      selectedLogoPosition: selectedLogoPosition,
      selectedFont: selectedFont,
      selectedTextColor: selectedTextColor,
      selectedFontSize: selectedFontSize,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
    );
  }

  // ============================================================
  // BOTTOM BUTTONS
  // ============================================================

  Widget _buildBottomButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed:
                    isLoading ? null : _cancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: const BorderSide(
                    color: borderColor,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
                child: const Text('Cancel'),
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed:
                    isLoading
                        ? null
                        : _createSequence,
                icon: isLoading
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check,
                        size: 18,
                      ),
                label: Text(
                  isLoading
                      ? 'Creating...'
                      : 'Create Sequence',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment:
              MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed:
                  isLoading ? null : _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: const BorderSide(
                  color: borderColor,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              child: const Text('Cancel'),
            ),

            const SizedBox(width: 12),

            ElevatedButton.icon(
              onPressed:
                  isLoading
                      ? null
                      : _createSequence,
              icon: isLoading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.check,
                      size: 18,
                    ),
              label: Text(
                isLoading
                    ? 'Creating...'
                    : 'Create Sequence',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: lightBorderColor,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      primaryColor.withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // RECOMMENDATION BOX
  // ============================================================

  Widget _buildRecommendation({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD6E0FF),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: primaryColor,
                size: 19,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // FILE PICKER UI
  // ============================================================

  Widget _buildFilePicker({
    required String label,
    required String value,
    required String emptyText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool hasFile =
        value.trim().isNotEmpty;

    String displayName = emptyText;

    if (hasFile) {
      displayName =
          value.split('\\').last.split('/').last;
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: fieldBackground,
              borderRadius:
                  BorderRadius.circular(10),
              border: Border.all(
                color:
                    hasFile
                        ? primaryColor
                        : borderColor,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        primaryColor.withOpacity(
                      0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          hasFile
                              ? textColor
                              : secondaryTextColor,
                      fontSize: 13,
                      fontWeight:
                          hasFile
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.upload_outlined,
                  color: secondaryTextColor,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization:
              textCapitalization,
          validator: validator,
          onChanged: (_) {
            setState(() {});
          },
          style: const TextStyle(
            color: textColor,
            fontSize: 14,
          ),
          cursorColor: primaryColor,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF98A2B3),
              fontSize: 13,
            ),
            filled: true,
            fillColor: fieldBackground,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            focusedErrorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // IMPROVED TYPE SELECTOR
  // ============================================================

  Widget _buildTypeSelector() {
    final option = _typeOption(selectedType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        InkWell(
          onTap: isLoading ? null : _showTypeSelector,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: fieldBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: option.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    option.icon,
                    color: option.iconColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        option.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _SequenceTypeOption _typeOption(String value) {
    switch (value) {
      case 'WhatsApp':
        return const _SequenceTypeOption(
          value: 'WhatsApp',
          title: 'WhatsApp',
          description: 'Send WhatsApp campaign messages',
          icon: Icons.chat_outlined,
          iconColor: Color(0xFF039855),
          backgroundColor: Color(0xFFECFDF3),
        );
      case 'SMS':
        return const _SequenceTypeOption(
          value: 'SMS',
          title: 'SMS',
          description: 'Send short text messages',
          icon: Icons.sms_outlined,
          iconColor: Color(0xFF7A5AF8),
          backgroundColor: Color(0xFFF4F3FF),
        );
      case 'Email':
      default:
        return const _SequenceTypeOption(
          value: 'Email',
          title: 'Email',
          description: 'Send email campaign messages',
          icon: Icons.email_outlined,
          iconColor: primaryColor,
          backgroundColor: Color(0xFFEFF4FF),
        );
    }
  }

  Future<void> _showTypeSelector() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Select Type',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Choose how this sequence will communicate with leads.',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                ...['Email', 'WhatsApp', 'SMS'].map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildTypeOptionTile(
                      option: _typeOption(type),
                      selected: selectedType == type,
                      onTap: () => Navigator.pop(sheetContext, type),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        selectedType = selected;
      });
    }
  }

  Widget _buildTypeOptionTile({
    required _SequenceTypeOption option,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5F8FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primaryColor : lightBorderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: option.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                option.icon,
                color: option.iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.description,
                    style: const TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? primaryColor : Colors.transparent,
                border: Border.all(
                  color: selected ? primaryColor : const Color(0xFFD0D5DD),
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 15,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // FIXED: isExpanded prevents dropdown text overflow
  // ============================================================

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: secondaryTextColor,
          ),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldBackground,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 5,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: primaryColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEXT COLOR
  // ============================================================

  Color _getSelectedTextColor() {
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
  // LOGO PICKER
  // ============================================================

  Future<void> _pickLogoFile() async {
    final result =
        await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null ||
        result.files.isEmpty) {
      return;
    }

    final file = result.files.first;

    if (!mounted) return;

    setState(() {
      logoController.text =
          file.path ?? file.name;
    });
  }

  // ============================================================
  // HERO PICKER
  // ============================================================

  Future<void> _pickHeroImage() async {
    final result =
        await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null ||
        result.files.isEmpty) {
      return;
    }

    final file = result.files.first;

    if (!mounted) return;

    if (file.size > 2 * 1024 * 1024) {
      _showMessage(
        'Hero image must be less than 2 MB.',
        isError: true,
      );
      return;
    }

    setState(() {
      heroImageController.text =
          file.path ?? file.name;
    });
  }

  // ============================================================
  // ATTACHMENT PICKER
  // ============================================================

  Future<void> _pickAttachmentFile() async {
    final result =
        await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null ||
        result.files.isEmpty) {
      return;
    }

    final file = result.files.first;

    if (!mounted) return;

    final String mimeType =
        _getMimeType(file.extension);

    setState(() {
      attachmentNameController.text =
          file.name;

      attachmentUrlController.text =
          file.path ?? '';

      attachmentMimeController.text =
          mimeType;

      attachmentSizeController.text =
          file.size.toString();
    });
  }

  String _getMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';

      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'gif':
        return 'image/gif';

      case 'doc':
        return 'application/msword';

      case 'docx':
        return
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      case 'xls':
        return 'application/vnd.ms-excel';

      case 'xlsx':
        return
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      default:
        return 'application/octet-stream';
    }
  }

  // ============================================================
  // DATE TIME
  // ============================================================

  Future<void> _selectDateTime() async {
    final now = DateTime.now();

    final selectedDate =
        await showDatePicker(
      context: context,
      initialDate:
          scheduledDateTime ?? now,
      firstDate: now,
      lastDate: DateTime(
        now.year + 5,
      ),
    );

    if (selectedDate == null ||
        !mounted) {
      return;
    }

    final selectedTime =
        await showTimePicker(
      context: context,
      initialTime:
          scheduledDateTime != null
              ? TimeOfDay.fromDateTime(
                  scheduledDateTime!,
                )
              : TimeOfDay.now(),
    );

    if (selectedTime == null ||
        !mounted) {
      return;
    }

    setState(() {
      scheduledDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  String _formatDateTime(
      DateTime dateTime) {
    final day =
        dateTime.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        dateTime.month.toString().padLeft(
              2,
              '0',
            );

    final hour =
        dateTime.hour.toString().padLeft(
              2,
              '0',
            );

    final minute =
        dateTime.minute.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/${dateTime.year} '
        '$hour:$minute';
  }

  // ============================================================
  // CREATE SEQUENCE
  // ============================================================

  Future<void> _createSequence() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final step =
        int.tryParse(
      stepController.text.trim(),
    );

    final gapDays =
        int.tryParse(
      gapDaysController.text.trim(),
    );

    if (step == null ||
        gapDays == null) {
      _showMessage(
        'Please enter valid step and gap days.',
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result =
          await SequenceApi.createSequence(
        step: step,
        gapDays: gapDays,
        variant:
            variantController.text.trim(),
        type: selectedType,
        subject:
            subjectController.text.trim(),

        logoUrl:
            logoController.text
                    .trim()
                    .isEmpty
                ? null
                : logoController.text.trim(),

        logoPosition:
            selectedLogoPosition,

        heroImageUrl:
            heroImageController.text
                    .trim()
                    .isEmpty
                ? null
                : heroImageController.text
                    .trim(),

        heroImageLink:
            heroLinkController.text
                    .trim()
                    .isEmpty
                ? null
                : heroLinkController.text
                    .trim(),

        content:
            contentController.text,

        font: selectedFont,

        fontSize:
            selectedFontSize,

        textColor:
            selectedTextColor,

        bold: isBold,

        italic: isItalic,

        underline: isUnderline,

        attachmentName:
            attachmentNameController.text
                    .trim()
                    .isEmpty
                ? null
                : attachmentNameController.text
                    .trim(),

        attachmentUrl:
            attachmentUrlController.text
                    .trim()
                    .isEmpty
                ? null
                : attachmentUrlController.text
                    .trim(),

        attachmentMimeType:
            attachmentMimeController.text
                    .trim()
                    .isEmpty
                ? null
                : attachmentMimeController.text
                    .trim(),

        attachmentSize:
            int.tryParse(
              attachmentSizeController.text
                  .trim(),
            ) ??
            0,

        whatsapp:
            whatsappController.text
                    .trim()
                    .isEmpty
                ? null
                : whatsappController.text
                    .trim(),

        trackingEnabled:
            trackingEnabled,

        status:
            selectedStatus,

        scheduledAt:
            scheduledDateTime
                ?.toIso8601String(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showMessage(
          result['message'] ??
              'Sequence created successfully.',
        );

        await Future.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );

        if (!mounted) return;

        Navigator.pop(
          context,
          result,
        );
      } else {
        if (result['sessionExpired'] ==
            true) {
          _showMessage(
            'Session expired. Please login again.',
            isError: true,
          );
          return;
        }

        _showMessage(
          result['message'] ??
              'Unable to create sequence.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE DRAFT
  // ============================================================

  Future<void> _saveDraft() async {
    setState(() {
      selectedStatus = 'draft';
    });

    await _createSequence();
  }

  // ============================================================
  // CANCEL
  // ============================================================

  void _cancel() {
    if (isLoading) return;

    Navigator.pop(context);
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Colors.red
                : Colors.green,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}

// ================================================================
// RECOMMENDATION ROW
// ================================================================

class _RecommendationRow
    extends StatelessWidget {
  const _RecommendationRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            '📌 ',
            style: TextStyle(
              fontSize: 12,
            ),
          ),

          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}