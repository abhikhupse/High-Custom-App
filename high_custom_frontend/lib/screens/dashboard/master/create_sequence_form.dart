import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/sequence_api.dart';
import 'create_sequence_preview.dart';

// ============================================================
// CREATE SEQUENCE FORM
// ============================================================

class CreateSequenceForm extends StatefulWidget {
  const CreateSequenceForm({
    super.key,
  });

  @override
  State<CreateSequenceForm> createState() =>
      _CreateSequenceFormState();
}

// ============================================================
// STATE
// ============================================================

class _CreateSequenceFormState extends State<CreateSequenceForm> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color background = Color(0xFF020507);

  static const Color cardColor = Color(0xFF0A0D11);

  static const Color cardColor2 = Color(0xFF0E1116);

  static const Color fieldBackground = Color(0xFF070A0E);

  static const Color borderColor = Color(0xFF282D35);

  static const Color softBorder = Color(0xFF1C2027);

  static const Color white = Colors.white;

  static const Color textColor = Color(0xFFF3F4F6);

  static const Color secondaryTextColor = Color(0xFF9298A3);

  static const Color hintColor = Color(0xFF636A76);

  static const Color purple = Color(0xFF7657EA);

  static const Color purpleLight = Color(0xFF9D62F4);

  static const Color gold = Color(0xFFF2C45F);

  static const Color green = Color(0xFF25D366);

  static const Color red = Color(0xFFFF5B66);

  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ============================================================
  // CURRENT STEP
  // ============================================================

  int currentStep = 0;

  final List<String> stepTitles = const [
    'Basic Info',
    'Email Content',
    'Action Links',
    'Review',
  ];

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
  // BUSINESS TYPE
  // ============================================================

  String selectedBusinessType = '';

  final List<String> businessTypes = [];

  // ============================================================
  // SELECTIONS
  // ============================================================

  String selectedLogoPosition = 'Center';

  String selectedFont = 'Arial';

  String selectedFontSize = '16px';

  String selectedTextColor = 'Black';

  String selectedStatus = 'draft';

  // ============================================================
  // EDITOR
  // ============================================================

  bool isBold = false;

  bool isItalic = false;

  bool isUnderline = false;

  // ============================================================
  // TRACKING
  // ============================================================

  bool trackingEnabled = true;

  // ============================================================
  // SCHEDULE
  // ============================================================

  DateTime? scheduledDateTime;

  // ============================================================
  // LOADING
  // ============================================================

  bool isLoading = false;

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
    return Container(
      color: background,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepper(),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 220,
                ),
                child: SingleChildScrollView(
                  key: ValueKey<int>(
                    currentStep,
                  ),
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    16,
                    14,
                    32,
                  ),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT STEP
  // ============================================================

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return _buildBasicStep();

      case 1:
        return _buildEmailStep();

      case 2:
        return _buildActionStep();

      case 3:
        return _buildReviewStep();

      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // STEPPER
  // ============================================================

  Widget _buildStepper() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        16,
        14,
        14,
      ),
      decoration: const BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(
            color: softBorder,
          ),
        ),
      ),
      child: Row(
        children: List.generate(
          stepTitles.length,
          (index) {
            final bool completed =
                index < currentStep;

            final bool active =
                index == currentStep;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: completed
                              ? () {
                                  setState(() {
                                    currentStep = index;
                                  });
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 200,
                            ),
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: completed
                                  ? green
                                  : active
                                      ? gold
                                      : fieldBackground,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: completed
                                    ? green
                                    : active
                                        ? gold
                                        : borderColor,
                              ),
                            ),
                            child: completed
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.black,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: active
                                          ? Colors.black
                                          : secondaryTextColor,
                                      fontWeight:
                                          FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          stepTitles[index],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active
                                ? gold
                                : completed
                                    ? textColor
                                    : secondaryTextColor,
                            fontSize: 9.5,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (index !=
                      stepTitles.length - 1)
                    Container(
                      width: 16,
                      height: 1,
                      margin: const EdgeInsets.only(
                        bottom: 22,
                      ),
                      color: completed
                          ? green
                          : borderColor,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // STEP 1
  // ============================================================

  Widget _buildBasicStep() {
    return Column(
      children: [
        _stepHeader(
          icon: Icons.description_outlined,
          title: 'Basic Information',
          subtitle:
              'Set up your sequence details.',
        ),

        const SizedBox(height: 16),

        // ========================================================
        // SEQUENCE DETAILS
        // ========================================================

        _buildCard(
          title: 'Sequence Details',
          subtitle:
              'Configure the main campaign information.',
          icon: Icons.tune_rounded,
          child: Column(
            children: [
              // =================================================
              // STEP + GAP
              // =================================================

              LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  if (constraints.maxWidth < 330) {
                    return Column(
                      children: [
                        _buildTextField(
                          controller: stepController,
                          label: 'Step',
                          hint: '1',
                          keyboardType:
                              TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly,
                          ],
                        ),

                        const SizedBox(height: 14),

                        _buildTextField(
                          controller:
                              gapDaysController,
                          label: 'Gap Days',
                          hint: '0',
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
                              stepController,
                          label: 'Step',
                          hint: '1',
                          keyboardType:
                              TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly,
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _buildTextField(
                          controller:
                              gapDaysController,
                          label: 'Gap Days',
                          hint: '0',
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

              const SizedBox(height: 16),

              // =================================================
              // VARIANT
              // =================================================

              _buildTextField(
                controller:
                    variantController,
                label: 'Variant',
                hint: 'Example: A',
                textCapitalization:
                    TextCapitalization.characters,
              ),

              const SizedBox(height: 16),

              // =================================================
              // BUSINESS TYPE
              // =================================================

              _buildBusinessTypeSelector(),

              const SizedBox(height: 16),

              // =================================================
              // SUBJECT
              // =================================================

              _buildTextField(
                controller:
                    subjectController,
                label: 'Email Subject',
                hint:
                    'Enter your email subject',
                prefixIcon:
                    Icons.subject_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ========================================================
        // BRAND
        // ========================================================

        _buildCard(
          title: 'Brand Identity',
          subtitle:
              'Upload your company logo or banner.',
          icon: Icons.business_outlined,
          child: Column(
            children: [
              _buildFilePicker(
                label:
                    'Company Logo / Banner',
                value:
                    logoController.text,
                emptyText:
                    'Upload logo or banner',
                icon:
                    Icons.cloud_upload_outlined,
                onTap:
                    _pickLogoFile,
              ),

              const SizedBox(height: 16),

              _buildDropdown(
                label: 'Logo Position',
                value:
                    selectedLogoPosition,
                items: const [
                  'Left',
                  'Center',
                  'Right',
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedLogoPosition =
                        value;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ========================================================
        // HERO
        // ========================================================

        _buildCard(
          title: 'Hero Image',
          subtitle:
              'Add your campaign promotional image.',
          icon: Icons.image_outlined,
          child: Column(
            children: [
              _goldInfoBox(
                title:
                    'Recommended Size',
                text:
                    '1200 × 400 px • Maximum 2 MB',
              ),

              const SizedBox(height: 14),

              _buildFilePicker(
                label:
                    'Hero Image',
                value:
                    heroImageController.text,
                emptyText:
                    'Upload hero image',
                icon:
                    Icons.add_photo_alternate_outlined,
                onTap:
                    _pickHeroImage,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller:
                    heroLinkController,
                label:
                    'Hero Image Link',
                hint:
                    'https://example.com',
                keyboardType:
                    TextInputType.url,
                prefixIcon:
                    Icons.link_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        _navigationButtons(
          nextTitle: 'Continue',
          nextIcon:
              Icons.arrow_forward_rounded,
          onNext:
              _nextStep,
        ),
      ],
    );
  }

  // ============================================================
  // BUSINESS TYPE SELECTOR
  // ============================================================

  Widget _buildBusinessTypeSelector() {
    final bool hasType =
        selectedBusinessType.trim().isNotEmpty;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Type',
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        InkWell(
          onTap: isLoading
              ? null
              : _showBusinessTypeSelector,
          borderRadius:
              BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: fieldBackground,
              borderRadius:
                  BorderRadius.circular(10),
              border: Border.all(
                color: hasType
                    ? gold
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
                        gold.withOpacity(0.09),
                    borderRadius:
                        BorderRadius.circular(9),
                  ),
                  child: Icon(
                    hasType
                        ? Icons.storefront_outlined
                        : Icons.add_business_outlined,
                    color: gold,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasType
                            ? selectedBusinessType
                            : 'Add Business Type',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasType
                              ? textColor
                              : gold,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        hasType
                            ? 'Business category for this sequence'
                            : 'Create your own business category',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color:
                              secondaryTextColor,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons
                      .keyboard_arrow_down_rounded,
                  color:
                      secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUSINESS TYPE SHEET
  // ============================================================

  Future<void> _showBusinessTypeSelector() async {
    String draftBusinessType = '';
    String? validationMessage;

    final String? selected =
        await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            sheetSetState,
          ) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(
                  sheetContext,
                ).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(
                            sheetContext,
                          ).size.height *
                          0.82,
                ),
                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFF0B0E13),
                  borderRadius:
                      BorderRadius.vertical(
                    top:
                        Radius.circular(22),
                  ),
                ),
                child:
                    SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    20,
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // =========================================
                      // HANDLE
                      // =========================================

                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration:
                              BoxDecoration(
                            color:
                                borderColor,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // =========================================
                      // HEADER
                      // =========================================

                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration:
                                BoxDecoration(
                              color:
                                  gold.withOpacity(
                                0.09,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .storefront_outlined,
                              color: gold,
                              size: 20,
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          const Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Business Type',
                                  style:
                                      TextStyle(
                                    color:
                                        textColor,
                                    fontSize:
                                        17,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),

                                SizedBox(
                                  height: 2,
                                ),

                                Text(
                                  'Choose an existing type or add your own.',
                                  style:
                                      TextStyle(
                                    color:
                                        secondaryTextColor,
                                    fontSize:
                                        10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // =========================================
                      // EXISTING TYPES
                      // =========================================

                      if (businessTypes
                          .isNotEmpty) ...[
                        const Text(
                          'Saved Business Types',
                          style:
                              TextStyle(
                            color:
                                textColor,
                            fontSize:
                                11,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),

                        const SizedBox(
                          height: 9,
                        ),

                        ...businessTypes.map(
                          (type) {
                            final bool
                                isSelected =
                                selectedBusinessType ==
                                    type;

                            return Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                bottom:
                                    8,
                              ),
                              child:
                                  InkWell(
                                onTap:
                                    () {
                                  Navigator.of(
                                    sheetContext,
                                  ).pop(
                                    type,
                                  );
                                },
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  11,
                                ),
                                child:
                                    Container(
                                  width:
                                      double.infinity,
                                  padding:
                                      const EdgeInsets
                                          .all(
                                    11,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        isSelected
                                            ? gold.withOpacity(
                                                0.08,
                                              )
                                            : fieldBackground,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      11,
                                    ),
                                    border:
                                        Border.all(
                                      color:
                                          isSelected
                                              ? gold
                                              : borderColor,
                                    ),
                                  ),
                                  child:
                                      Row(
                                    children: [
                                      Container(
                                        width:
                                            38,
                                        height:
                                            38,
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              gold.withOpacity(
                                            0.09,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(
                                            9,
                                          ),
                                        ),
                                        child:
                                            const Icon(
                                          Icons
                                              .storefront_outlined,
                                          color:
                                              gold,
                                          size:
                                              18,
                                        ),
                                      ),

                                      const SizedBox(
                                        width:
                                            10,
                                      ),

                                      Expanded(
                                        child:
                                            Text(
                                          type,
                                          maxLines:
                                              1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style:
                                              const TextStyle(
                                            color:
                                                textColor,
                                            fontSize:
                                                12,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                      ),

                                      if (isSelected)
                                        const Icon(
                                          Icons
                                              .check_circle_rounded,
                                          color:
                                              gold,
                                          size:
                                              19,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Divider(
                          color:
                              softBorder,
                          height: 1,
                        ),

                        const SizedBox(
                          height: 16,
                        ),
                      ],

                      // =========================================
                      // EMPTY STATE
                      // =========================================

                      if (businessTypes.isEmpty)
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                14,
                            vertical:
                                18,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                fieldBackground,
                            borderRadius:
                                BorderRadius.circular(
                              11,
                            ),
                            border:
                                Border.all(
                              color:
                                  borderColor,
                            ),
                          ),
                          child:
                              const Column(
                            children: [
                              Icon(
                                Icons
                                    .storefront_outlined,
                                color:
                                    secondaryTextColor,
                                size:
                                    27,
                              ),

                              SizedBox(
                                height:
                                    7,
                              ),

                              Text(
                                'No Business Type Added',
                                style:
                                    TextStyle(
                                  color:
                                      textColor,
                                  fontSize:
                                      12,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),

                              SizedBox(
                                height:
                                    3,
                              ),

                              Text(
                                'Add your first business type below.',
                                textAlign:
                                    TextAlign.center,
                                style:
                                    TextStyle(
                                  color:
                                      secondaryTextColor,
                                  fontSize:
                                      9.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (businessTypes
                          .isEmpty)
                        const SizedBox(
                          height: 16,
                        ),

                      // =========================================
                      // ADD TYPE
                      // =========================================

                      const Text(
                        'Add Business Type',
                        style:
                            TextStyle(
                          color:
                              textColor,
                          fontSize:
                              11,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      TextField(
                        textCapitalization:
                            TextCapitalization
                                .words,
                        cursorColor:
                            gold,
                        style:
                            const TextStyle(
                          color:
                              textColor,
                          fontSize:
                              12,
                        ),
                        onChanged: (value) {
                          draftBusinessType =
                              value;

                          if (validationMessage !=
                              null) {
                            sheetSetState(
                              () {
                                validationMessage =
                                    null;
                              },
                            );
                          }
                        },
                        decoration:
                            InputDecoration(
                          hintText:
                              'Example: B2B',
                          hintStyle:
                              const TextStyle(
                            color:
                                hintColor,
                            fontSize:
                                10.5,
                          ),
                          prefixIcon:
                              const Icon(
                            Icons
                                .add_business_outlined,
                            color:
                                secondaryTextColor,
                            size:
                                18,
                          ),
                          filled:
                              true,
                          fillColor:
                              fieldBackground,
                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                12,
                            vertical:
                                12,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  borderColor,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  borderColor,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  gold,
                            ),
                          ),
                          errorText:
                              validationMessage,
                          errorStyle:
                              const TextStyle(
                            color:
                                red,
                            fontSize:
                                9.5,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 11,
                      ),

                      // =========================================
                      // ADD BUTTON
                      // =========================================

                      SizedBox(
                        width:
                            double.infinity,
                        height:
                            46,
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              () {
                            final String
                                value =
                                draftBusinessType
                                    .trim();

                            if (value.isEmpty) {
                              sheetSetState(
                                () {
                                  validationMessage =
                                      'Please enter a business type';
                                },
                              );

                              return;
                            }

                            if (value.length <
                                2) {
                              sheetSetState(
                                () {
                                  validationMessage =
                                      'Business type is too short';
                                },
                              );

                              return;
                            }

                            final int
                                existingIndex =
                                businessTypes
                                    .indexWhere(
                              (
                                element,
                              ) =>
                                  element
                                      .toLowerCase() ==
                                  value
                                      .toLowerCase(),
                            );

                            String
                                finalValue;

                            if (existingIndex != -1) {
                              finalValue =
                                  businessTypes[
                                      existingIndex];
                            } else {
                              finalValue =
                                  value;
                            }

                            Navigator.of(
                              sheetContext,
                            ).pop(
                              finalValue,
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .add_rounded,
                            size:
                                18,
                          ),
                          label:
                              const Text(
                            'Add & Select Business Type',
                            style:
                                TextStyle(
                              fontSize:
                                  11.5,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                gold,
                            foregroundColor:
                                Colors.black,
                            elevation:
                                0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (selected != null &&
        selected.trim().isNotEmpty) {
      setState(() {
        final bool alreadyExists =
            businessTypes.any(
          (type) =>
              type.toLowerCase() ==
              selected.toLowerCase(),
        );

        if (!alreadyExists) {
          businessTypes.add(selected);
        }

        selectedBusinessType =
            selected;
      });
    }
  }

  // ============================================================
  // STEP 2
  // ============================================================

  Widget _buildEmailStep() {
    return Column(
      children: [
        _stepHeader(
          icon: Icons.email_outlined,
          title: 'Email Content',
          subtitle:
              'Create and style your campaign email.',
        ),

        const SizedBox(height: 16),

        // ========================================================
        // EDITOR SETTINGS
        // ========================================================

        _buildCard(
          title: 'Editor Settings',
          subtitle:
              'Choose font and text formatting.',
          icon:
              Icons.text_fields_rounded,
          child: Column(
            children: [
              _buildDropdown(
                label: 'Font',
                value:
                    selectedFont,
                items: const [
                  'Arial',
                  'Roboto',
                  'Helvetica',
                  'Times New Roman',
                  'Georgia',
                  'Verdana',
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedFont =
                        value;
                  });
                },
              ),

              const SizedBox(height: 14),

              // =================================================
              // MOBILE SAFE DROPDOWNS
              // =================================================

              LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  if (constraints.maxWidth <
                      320) {
                    return Column(
                      children: [
                        _buildDropdown(
                          label:
                              'Font Size',
                          value:
                              selectedFontSize,
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
                          onChanged:
                              (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setState(
                              () {
                                selectedFontSize =
                                    value;
                              },
                            );
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _buildDropdown(
                          label:
                              'Text Color',
                          value:
                              selectedTextColor,
                          items: const [
                            'Black',
                            'White',
                            'Gray',
                            'Red',
                            'Blue',
                            'Green',
                            'Gold',
                          ],
                          onChanged:
                              (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setState(
                              () {
                                selectedTextColor =
                                    value;
                              },
                            );
                          },
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child:
                            _buildDropdown(
                          label:
                              'Font Size',
                          value:
                              selectedFontSize,
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
                          onChanged:
                              (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setState(
                              () {
                                selectedFontSize =
                                    value;
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child:
                            _buildDropdown(
                          label:
                              'Text Color',
                          value:
                              selectedTextColor,
                          items: const [
                            'Black',
                            'White',
                            'Gray',
                            'Red',
                            'Blue',
                            'Green',
                            'Gold',
                          ],
                          onChanged:
                              (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setState(
                              () {
                                selectedTextColor =
                                    value;
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ========================================================
        // MESSAGE
        // ========================================================

        _buildCard(
          title: 'Message',
          subtitle:
              'Write your email message.',
          icon:
              Icons.edit_note_rounded,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildEditorToolbar(),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      fieldBackground,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color:
                        borderColor,
                  ),
                ),
                child:
                    TextFormField(
                  controller:
                      contentController,
                  minLines:
                      10,
                  maxLines:
                      16,
                  keyboardType:
                      TextInputType.multiline,
                  textCapitalization:
                      TextCapitalization
                          .sentences,
                  cursorColor:
                      gold,
                  style:
                      TextStyle(
                    color:
                        _selectedEditorColor(),
                    fontSize:
                        _selectedEditorSize(),
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
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Write your email content here...',
                    hintStyle:
                        TextStyle(
                      color:
                          hintColor,
                      fontSize:
                          12,
                    ),
                    border:
                        InputBorder.none,
                    contentPadding:
                        EdgeInsets.all(
                      14,
                    ),
                  ),
                  onChanged:
                      (_) {
                    setState(() {});
                  },
                ),
              ),

              const SizedBox(height: 11),

              const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 15,
                    color: gold,
                  ),

                  SizedBox(width: 7),

                  Expanded(
                    child: Text(
                      'Variables: {{firstName}}, {{lastName}}, {{email}}',
                      style:
                          TextStyle(
                        color:
                            secondaryTextColor,
                        fontSize:
                            10.5,
                        height:
                            1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ========================================================
        // ATTACHMENT
        // ========================================================

        _buildCard(
          title: 'Attachment',
          subtitle:
              'Attach a file to your email.',
          icon:
              Icons.attach_file_rounded,
          child: Column(
            children: [
              _buildFilePicker(
                label:
                    'Attachment File',
                value:
                    attachmentNameController
                        .text,
                emptyText:
                    'Upload attachment',
                icon:
                    Icons.upload_file_outlined,
                onTap:
                    _pickAttachmentFile,
              ),

              if (attachmentNameController
                  .text
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 12,
                ),

                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        fieldBackground,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                    border:
                        Border.all(
                      color:
                          borderColor,
                    ),
                  ),
                  child:
                      Row(
                    children: [
                      const Icon(
                        Icons
                            .description_outlined,
                        color:
                            gold,
                        size:
                            19,
                      ),

                      const SizedBox(
                        width: 9,
                      ),

                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              attachmentNameController
                                  .text,
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    textColor,
                                fontSize:
                                    11.5,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  2,
                            ),

                            Text(
                              attachmentMimeController
                                      .text
                                      .trim()
                                      .isEmpty
                                  ? 'Attachment'
                                  : attachmentMimeController
                                      .text,
                              style:
                                  const TextStyle(
                                color:
                                    secondaryTextColor,
                                fontSize:
                                    9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 18),

        _navigationButtons(
          backTitle: 'Back',
          nextTitle: 'Continue',
          nextIcon:
              Icons.arrow_forward_rounded,
          onBack:
              _previousStep,
          onNext:
              _nextStep,
        ),
      ],
    );
  }

  // ============================================================
  // STEP 3
  // ============================================================

  Widget _buildActionStep() {
    return Column(
      children: [
        _stepHeader(
          icon:
              Icons.ads_click_rounded,
          title:
              'Action Links',
          subtitle:
              'Add CTA buttons and campaign actions.',
        ),

        const SizedBox(height: 16),

        // ========================================================
        // PRIMARY CTA
        // ========================================================

        _buildCard(
          title:
              'Primary CTA',
          subtitle:
              'Add your main campaign button.',
          icon:
              Icons.touch_app_outlined,
          child:
              Column(
            children: [
              _buildTextField(
                controller:
                    ctaTextController,
                label:
                    'Button Text',
                hint:
                    'Example: Shop Now',
                prefixIcon:
                    Icons.ads_click_outlined,
              ),

              const SizedBox(
                height: 16,
              ),

              _buildTextField(
                controller:
                    ctaUrlController,
                label:
                    'Button URL',
                hint:
                    'https://example.com',
                keyboardType:
                    TextInputType.url,
                prefixIcon:
                    Icons.link_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ========================================================
        // WHATSAPP LINK
        // ========================================================

        _buildCard(
          title:
              'WhatsApp',
          subtitle:
              'Add a WhatsApp communication link.',
          icon:
              Icons.chat_outlined,
          child:
              _buildTextField(
            controller:
                whatsappController,
            label:
                'WhatsApp Link',
            hint:
                'https://wa.me/919999999999',
            keyboardType:
                TextInputType.url,
            prefixIcon:
                Icons.chat_bubble_outline,
          ),
        ),

        const SizedBox(height: 14),

        // ========================================================
        // CAMPAIGN SETTINGS
        // ========================================================

        _buildCard(
          title:
              'Campaign Settings',
          subtitle:
              'Configure status, tracking and scheduling.',
          icon:
              Icons.settings_outlined,
          child:
              Column(
            children: [
              _buildDropdown(
                label:
                    'Status',
                value:
                    selectedStatus,
                items: const [
                  'draft',
                  'scheduled',
                  'active',
                  'paused',
                ],
                onChanged:
                    (value) {
                  if (value ==
                      null) {
                    return;
                  }

                  setState(() {
                    selectedStatus =
                        value;
                  });
                },
              ),

              const SizedBox(
                height: 14,
              ),

              _buildTrackingSwitch(),

              const SizedBox(
                height: 14,
              ),

              _buildSchedulePicker(),

              if (scheduledDateTime !=
                  null) ...[
                const SizedBox(
                  height: 6,
                ),

                Align(
                  alignment:
                      Alignment.centerRight,
                  child:
                      TextButton.icon(
                    onPressed:
                        () {
                      setState(() {
                        scheduledDateTime =
                            null;
                      });
                    },
                    icon:
                        const Icon(
                      Icons.close,
                      color:
                          red,
                      size:
                          15,
                    ),
                    label:
                        const Text(
                      'Clear Schedule',
                      style:
                          TextStyle(
                        color:
                            red,
                        fontSize:
                            11,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 18),

        _navigationButtons(
          backTitle:
              'Back',
          nextTitle:
              'Review Sequence',
          nextIcon:
              Icons.arrow_forward_rounded,
          onBack:
              _previousStep,
          onNext:
              _nextStep,
        ),
      ],
    );
  }

  // ============================================================
  // STEP 4
  // ============================================================

  Widget _buildReviewStep() {
    return Column(
      children: [
        _stepHeader(
          icon:
              Icons.fact_check_outlined,
          title:
              'Review & Publish',
          subtitle:
              'Review your sequence before publishing.',
        ),

        const SizedBox(height: 16),

        // ========================================================
        // OVERVIEW
        // ========================================================

        _reviewCard(
          icon:
              Icons.description_outlined,
          iconColor:
              gold,
          title:
              'Sequence Overview',
          editStep:
              0,
          child:
              Column(
            children: [
              _responsiveReviewRow(
                first:
                    _overviewItem(
                  icon:
                      Icons.layers_outlined,
                  title:
                      'Step',
                  value:
                      stepController.text.trim().isEmpty
                          ? '-'
                          : stepController.text.trim(),
                ),
                second:
                    _overviewItem(
                  icon:
                      Icons.schedule_outlined,
                  title:
                      'Gap Days',
                  value:
                      '${gapDaysController.text.trim().isEmpty ? '0' : gapDaysController.text.trim()} Days',
                ),
              ),

              const Divider(
                color:
                    softBorder,
                height:
                    28,
              ),

              _responsiveReviewRow(
                first:
                    _overviewItem(
                  icon:
                      Icons.alt_route_outlined,
                  title:
                      'Variant',
                  value:
                      variantController.text.trim().isEmpty
                          ? '-'
                          : variantController.text.trim(),
                ),
                second:
                    _overviewItem(
                  icon:
                      Icons.storefront_outlined,
                  title:
                      'Business Type',
                  value:
                      selectedBusinessType.trim().isEmpty
                          ? '-'
                          : selectedBusinessType,
                ),
              ),

              const Divider(
                color:
                    softBorder,
                height:
                    28,
              ),

              _responsiveReviewRow(
                first:
                    _overviewItem(
                  icon:
                      Icons.circle,
                  iconColor:
                      _statusColor(),
                  title:
                      'Status',
                  value:
                      _capitalize(
                    selectedStatus,
                  ),
                  valueColor:
                      _statusColor(),
                ),
                second:
                    _overviewItem(
                  icon:
                      Icons.calendar_month_outlined,
                  title:
                      'Schedule',
                  value:
                      scheduledDateTime == null
                          ? 'Not scheduled'
                          : _formatDateTime(
                              scheduledDateTime!,
                            ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ========================================================
        // EMAIL CONTENT
        // ========================================================

        _reviewCard(
          icon:
              Icons.email_outlined,
          iconColor:
              purpleLight,
          title:
              'Email Content',
          editStep:
              1,
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Subject',
                style:
                    TextStyle(
                  color:
                      secondaryTextColor,
                  fontSize:
                      10.5,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                subjectController.text
                        .trim()
                        .isEmpty
                    ? 'No subject'
                    : subjectController.text
                        .trim(),
                style:
                    const TextStyle(
                  color:
                      textColor,
                  fontSize:
                      13.5,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const Divider(
                color:
                    softBorder,
                height:
                    28,
              ),

              const Text(
                'Message',
                style:
                    TextStyle(
                  color:
                      secondaryTextColor,
                  fontSize:
                      10.5,
                ),
              ),

              const SizedBox(
                height: 7,
              ),

              Text(
                contentController.text
                        .trim()
                        .isEmpty
                    ? 'No email content'
                    : contentController.text
                        .trim(),
                maxLines:
                    7,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color:
                      textColor,
                  fontSize:
                      12,
                  height:
                      1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ========================================================
        // ACTION LINKS
        // ========================================================

        _reviewCard(
          icon:
              Icons.link_rounded,
          iconColor:
              purpleLight,
          title:
              'Action Links',
          editStep:
              2,
          child:
              Column(
            children: [
              _reviewLinkRow(
                label:
                    'Primary CTA',
                title:
                    ctaTextController.text.trim().isEmpty
                        ? 'Not configured'
                        : ctaTextController.text.trim(),
                url:
                    ctaUrlController.text.trim().isEmpty
                        ? '-'
                        : ctaUrlController.text.trim(),
              ),

              const Divider(
                color:
                    softBorder,
                height:
                    28,
              ),

              _reviewLinkRow(
                label:
                    'WhatsApp',
                title:
                    whatsappController.text.trim().isEmpty
                        ? 'Not configured'
                        : 'WhatsApp Link',
                url:
                    whatsappController.text.trim().isEmpty
                        ? '-'
                        : whatsappController.text.trim(),
              ),

              const Divider(
                color:
                    softBorder,
                height:
                    28,
              ),

              Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color:
                        gold,
                    size:
                        20,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  const Expanded(
                    child:
                        Text(
                      'Tracking',
                      style:
                          TextStyle(
                        color:
                            textColor,
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),

                  Icon(
                    trackingEnabled
                        ? Icons.check_circle_rounded
                        : Icons.cancel_outlined,
                    color:
                        trackingEnabled
                            ? green
                            : secondaryTextColor,
                    size:
                        18,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Flexible(
                    child:
                        Text(
                      trackingEnabled
                          ? 'Enabled'
                          : 'Disabled',
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          TextStyle(
                        color:
                            trackingEnabled
                                ? green
                                : secondaryTextColor,
                        fontSize:
                            10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ========================================================
        // EMAIL PREVIEW
        // ========================================================

        _buildReviewPreviewCard(),

        const SizedBox(height: 14),

        _goldInfoBox(
          title:
              'Ready to Publish',
          text:
              'Review your campaign carefully. Once published, the sequence will be available for your automated email workflow.',
        ),

        const SizedBox(height: 18),

        _navigationButtons(
          backTitle:
              'Back',
          nextTitle:
              'Publish Sequence',
          nextIcon:
              Icons.send_rounded,
          onBack:
              _previousStep,
          onNext:
              isLoading
                  ? null
                  : _createSequence,
        ),
      ],
    );
  }

  // ============================================================
  // RESPONSIVE REVIEW ROW
  // ============================================================

  Widget _responsiveReviewRow({
    required Widget first,
    required Widget second,
  }) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        if (constraints.maxWidth <
            300) {
          return Column(
            children: [
              first,
              const SizedBox(height: 16),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: first,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: second,
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // REVIEW PREVIEW
  // ============================================================

  Widget _buildReviewPreviewCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(16),
        border:
            Border.all(
          color:
              borderColor,
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:
                    42,
                height:
                    42,
                decoration:
                    BoxDecoration(
                  color:
                      gold.withOpacity(
                    0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  border:
                      Border.all(
                    color:
                        gold.withOpacity(
                      0.22,
                    ),
                  ),
                ),
                child:
                    const Icon(
                  Icons.visibility_outlined,
                  color:
                      gold,
                  size:
                      20,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Preview',
                      style:
                          TextStyle(
                        color:
                            textColor,
                        fontSize:
                            15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      'Preview your final email.',
                      style:
                          TextStyle(
                        color:
                            secondaryTextColor,
                        fontSize:
                            10,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed:
                    _showEmailPreview,
                icon:
                    const Icon(
                  Icons.open_in_full_rounded,
                  color:
                      gold,
                  size:
                      19,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Divider(
            height:
                1,
            color:
                softBorder,
          ),

          const SizedBox(height: 14),

          Container(
            width:
                double.infinity,
            clipBehavior:
                Clip.antiAlias,
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                // ===============================================
                // SUBJECT
                // ===============================================

                Container(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xFFF8FAFC),
                    border:
                        Border(
                      bottom:
                          BorderSide(
                        color:
                            Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EMAIL PREVIEW',
                        style:
                            TextStyle(
                          color:
                              Color(0xFF7C8491),
                          fontSize:
                              8,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        subjectController.text
                                .trim()
                                .isEmpty
                            ? 'Your email subject'
                            : subjectController.text
                                .trim(),
                        maxLines:
                            2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Color(0xFF111827),
                          fontSize:
                              12,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                // ===============================================
                // BODY
                // ===============================================

                Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        contentController.text
                                .trim()
                                .isEmpty
                            ? 'Your email content will appear here.'
                            : contentController.text
                                .trim(),
                        maxLines:
                            8,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            TextStyle(
                          color:
                              _previewTextColor(),
                          fontSize:
                              _previewFontSize(),
                          height:
                              1.5,
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
                      ),

                      if (ctaTextController
                          .text
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 18,
                        ),

                        Center(
                          child:
                              Container(
                            constraints:
                                const BoxConstraints(
                              maxWidth:
                                  220,
                            ),
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal:
                                  22,
                              vertical:
                                  10,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  gold,
                              borderRadius:
                                  BorderRadius.circular(
                                7,
                              ),
                            ),
                            child:
                                Text(
                              ctaTextController.text
                                  .trim(),
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow.ellipsis,
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.black,
                                fontSize:
                                    10.5,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (whatsappController
                          .text
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(
                          height:
                              16,
                        ),

                        const Center(
                          child:
                              Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_outlined,
                                color:
                                    Color(0xFF168447),
                                size:
                                    15,
                              ),

                              SizedBox(width: 5),

                              Text(
                                'Contact on WhatsApp',
                                style:
                                    TextStyle(
                                  color:
                                      Color(0xFF168447),
                                  fontSize:
                                      9.5,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width:
                double.infinity,
            height:
                44,
            child:
                OutlinedButton.icon(
              onPressed:
                  _showEmailPreview,
              icon:
                  const Icon(
                Icons.visibility_outlined,
                size:
                    17,
              ),
              label:
                  const Text(
                'Open Full Email Preview',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    gold,
                side:
                    const BorderSide(
                  color:
                      borderColor,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    9,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FULL EMAIL PREVIEW
  // ============================================================

  void _showEmailPreview() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled:
          true,
      useSafeArea:
          true,
      backgroundColor:
          Colors.transparent,
      builder:
          (sheetContext) {
        return Container(
          height:
              MediaQuery.of(sheetContext)
                      .size
                      .height *
                  0.92,
          decoration:
              const BoxDecoration(
            color:
                background,
            borderRadius:
                BorderRadius.vertical(
              top:
                  Radius.circular(
                22,
              ),
            ),
          ),
          child:
              Column(
            children: [
              const SizedBox(
                height: 9,
              ),

              Container(
                width:
                    40,
                height:
                    4,
                decoration:
                    BoxDecoration(
                  color:
                      borderColor,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  12,
                  8,
                  10,
                ),
                child:
                    Row(
                  children: [
                    const Expanded(
                      child:
                          Text(
                        'Email Preview',
                        style:
                            TextStyle(
                          color:
                              textColor,
                          fontSize:
                              17,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed:
                          () {
                        Navigator.of(
                          sheetContext,
                        ).pop();
                      },
                      icon:
                          const Icon(
                        Icons.close_rounded,
                        color:
                            secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(
                height:
                    1,
                color:
                    softBorder,
              ),

              Expanded(
                child:
                    SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  child:
                      CreateSequencePreview(
                    subjectController:
                        subjectController,
                    logoController:
                        logoController,
                    heroImageController:
                        heroImageController,
                    heroLinkController:
                        heroLinkController,
                    emailContentController:
                        contentController,
                    whatsappController:
                        whatsappController,
                    ctaTextController:
                        ctaTextController,
                    ctaUrlController:
                        ctaUrlController,
                    selectedLogoPosition:
                        selectedLogoPosition,
                    selectedFont:
                        selectedFont,
                    selectedTextColor:
                        selectedTextColor,
                    selectedFontSize:
                        selectedFontSize,
                    isBold:
                        isBold,
                    isItalic:
                        isItalic,
                    isUnderline:
                        isUnderline,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // STEP HEADER
  // ============================================================

  Widget _stepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              borderColor,
        ),
      ),
      child:
          Row(
        children: [
          Container(
            width:
                46,
            height:
                46,
            decoration:
                BoxDecoration(
              color:
                  gold.withOpacity(
                0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              border:
                  Border.all(
                color:
                    gold.withOpacity(
                  0.22,
                ),
              ),
            ),
            child:
                Icon(
              icon,
              color:
                  gold,
              size:
                  22,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        textColor,
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize:
                        10.5,
                    height:
                        1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              borderColor,
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:
                    39,
                height:
                    39,
                decoration:
                    BoxDecoration(
                  color:
                      purple.withOpacity(
                    0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  color:
                      purpleLight,
                  size:
                      19,
                ),
              ),

              const SizedBox(
                width:
                    10,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            textColor,
                        fontSize:
                            14,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height:
                          2,
                    ),

                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color:
                            secondaryTextColor,
                        fontSize:
                            9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                17,
          ),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // REVIEW CARD
  // ============================================================

  Widget _reviewCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int editStep,
    required Widget child,
  }) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              borderColor,
        ),
      ),
      child:
          Column(
        children: [
          Row(
            children: [
              Container(
                width:
                    38,
                height:
                    38,
                decoration:
                    BoxDecoration(
                  color:
                      iconColor.withOpacity(
                    0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    9,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  color:
                      iconColor,
                  size:
                      19,
                ),
              ),

              const SizedBox(
                width:
                    10,
              ),

              Expanded(
                child:
                    Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        textColor,
                    fontSize:
                        14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              TextButton.icon(
                onPressed:
                    () {
                  setState(() {
                    currentStep =
                        editStep;
                  });
                },
                icon:
                    const Icon(
                  Icons.edit_outlined,
                  color:
                      gold,
                  size:
                      14,
                ),
                label:
                    const Text(
                  'Edit',
                  style:
                      TextStyle(
                    color:
                        gold,
                    fontSize:
                        10,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Divider(
            height:
                1,
            color:
                softBorder,
          ),

          const SizedBox(height: 15),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // OVERVIEW ITEM
  // ============================================================

  Widget _overviewItem({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color:
              iconColor ??
                  secondaryTextColor,
          size:
              17,
        ),

        const SizedBox(
          width:
              8,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  color:
                      secondaryTextColor,
                  fontSize:
                      9.5,
                ),
              ),

              const SizedBox(
                height:
                    3,
              ),

              Text(
                value,
                maxLines:
                    2,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    TextStyle(
                  color:
                      valueColor ??
                          textColor,
                  fontSize:
                      11.5,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REVIEW LINK
  // ============================================================

  Widget _reviewLinkRow({
    required String label,
    required String title,
    required String url,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.link_rounded,
          color:
              gold,
          size:
              18,
        ),

        const SizedBox(
          width:
              9,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(
                  color:
                      secondaryTextColor,
                  fontSize:
                      9.5,
                ),
              ),

              const SizedBox(
                height:
                    3,
              ),

              Text(
                title,
                style:
                    const TextStyle(
                  color:
                      textColor,
                  fontSize:
                      11.5,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              if (url !=
                  '-') ...[
                const SizedBox(
                  height:
                      3,
                ),

                Text(
                  url,
                  maxLines:
                      2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        gold,
                    fontSize:
                        9.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GOLD INFO BOX
  // ============================================================

  Widget _goldInfoBox({
    required String title,
    required String text,
  }) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        13,
      ),
      decoration:
          BoxDecoration(
        color:
            gold.withOpacity(
          0.07,
        ),
        borderRadius:
            BorderRadius.circular(
          11,
        ),
        border:
            Border.all(
          color:
              gold.withOpacity(
            0.25,
          ),
        ),
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color:
                gold,
            size:
                18,
          ),

          const SizedBox(
            width:
                9,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        gold,
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height:
                      3,
                ),

                Text(
                  text,
                  style:
                      const TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize:
                        9.5,
                    height:
                        1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    IconData? prefixIcon,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color:
                textColor,
            fontSize:
                11,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height:
              7,
        ),

        TextFormField(
          controller:
              controller,
          keyboardType:
              keyboardType,
          inputFormatters:
              inputFormatters,
          textCapitalization:
              textCapitalization,
          cursorColor:
              gold,
          style:
              const TextStyle(
            color:
                textColor,
            fontSize:
                12.5,
          ),
          onChanged:
              (_) {
            setState(() {});
          },
          decoration:
              InputDecoration(
            hintText:
                hint,
            hintStyle:
                const TextStyle(
              color:
                  hintColor,
              fontSize:
                  11,
            ),
            prefixIcon:
                prefixIcon == null
                    ? null
                    : Icon(
                        prefixIcon,
                        color:
                            secondaryTextColor,
                        size:
                            17,
                      ),
            filled:
                true,
            fillColor:
                fieldBackground,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal:
                  12,
              vertical:
                  13,
            ),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              borderSide:
                  const BorderSide(
                color:
                    borderColor,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              borderSide:
                  const BorderSide(
                color:
                    borderColor,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              borderSide:
                  const BorderSide(
                color:
                    gold,
                width:
                    1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DROPDOWN
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
          style:
              const TextStyle(
            color:
                textColor,
            fontSize:
                11,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height:
              7,
        ),

        DropdownButtonFormField<String>(
          value:
              value,
          isExpanded:
              true,
          dropdownColor:
              cardColor2,
          icon:
              const Icon(
            Icons.keyboard_arrow_down_rounded,
            color:
                secondaryTextColor,
          ),
          items:
              items.map(
            (item) {
              return DropdownMenuItem<String>(
                value:
                    item,
                child:
                    Text(
                  item,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        textColor,
                    fontSize:
                        11,
                  ),
                ),
              );
            },
          ).toList(),
          onChanged:
              onChanged,
          decoration:
              InputDecoration(
            filled:
                true,
            fillColor:
                fieldBackground,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal:
                  10,
              vertical:
                  5,
            ),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              borderSide:
                  const BorderSide(
                color:
                    borderColor,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              borderSide:
                  const BorderSide(
                color:
                    borderColor,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              borderSide:
                  const BorderSide(
                color:
                    gold,
              ),
            ),
          ),
        ),
      ],
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

    final String displayName =
        hasFile
            ? value
                .split('\\')
                .last
                .split('/')
                .last
            : emptyText;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color:
                textColor,
            fontSize:
                11,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height:
              7,
        ),

        InkWell(
          onTap:
              onTap,
          borderRadius:
              BorderRadius.circular(
            10,
          ),
          child:
              Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(
              11,
            ),
            decoration:
                BoxDecoration(
              color:
                  fieldBackground,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              border:
                  Border.all(
                color:
                    hasFile
                        ? gold
                        : borderColor,
              ),
            ),
            child:
                Row(
              children: [
                Container(
                  width:
                      38,
                  height:
                      38,
                  decoration:
                      BoxDecoration(
                    color:
                        gold.withOpacity(
                      0.09,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      9,
                    ),
                  ),
                  child:
                      Icon(
                    icon,
                    color:
                        gold,
                    size:
                        18,
                  ),
                ),

                const SizedBox(
                  width:
                      10,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            TextStyle(
                          color:
                              hasFile
                                  ? textColor
                                  : secondaryTextColor,
                          fontSize:
                              11,
                          fontWeight:
                              hasFile
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                        ),
                      ),

                      const SizedBox(
                        height:
                            2,
                      ),

                      const Text(
                        'Tap to browse',
                        style:
                            TextStyle(
                          color:
                              hintColor,
                          fontSize:
                              9,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.upload_rounded,
                  color:
                      secondaryTextColor,
                  size:
                      17,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EDITOR TOOLBAR
  // ============================================================

  Widget _buildEditorToolbar() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            5,
        vertical:
            5,
      ),
      decoration:
          BoxDecoration(
        color:
            fieldBackground,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        border:
            Border.all(
          color:
              borderColor,
        ),
      ),
      child:
          Row(
        children: [
          _toolbarButton(
            icon:
                Icons.format_bold,
            active:
                isBold,
            onPressed:
                () {
              setState(() {
                isBold =
                    !isBold;
              });
            },
          ),

          _toolbarButton(
            icon:
                Icons.format_italic,
            active:
                isItalic,
            onPressed:
                () {
              setState(() {
                isItalic =
                    !isItalic;
              });
            },
          ),

          _toolbarButton(
            icon:
                Icons.format_underlined,
            active:
                isUnderline,
            onPressed:
                () {
              setState(() {
                isUnderline =
                    !isUnderline;
              });
            },
          ),

          const Spacer(),

          InkWell(
            onTap:
                () {
              contentController.clear();

              setState(() {});
            },
            borderRadius:
                BorderRadius.circular(
              7,
            ),
            child:
                const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal:
                    7,
                vertical:
                    8,
              ),
              child:
                  Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline,
                    color:
                        red,
                    size:
                        15,
                  ),

                  SizedBox(
                    width:
                        4,
                  ),

                  Text(
                    'Clear',
                    style:
                        TextStyle(
                      color:
                          red,
                      fontSize:
                          10,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required bool active,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        right:
            4,
      ),
      decoration:
          BoxDecoration(
        color:
            active
                ? gold.withOpacity(
                    0.12,
                  )
                : Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          7,
        ),
      ),
      child:
          IconButton(
        constraints:
            const BoxConstraints(
          minWidth:
              34,
          minHeight:
              34,
        ),
        padding:
            EdgeInsets.zero,
        onPressed:
            onPressed,
        icon:
            Icon(
          icon,
          color:
              active
                  ? gold
                  : secondaryTextColor,
          size:
              18,
        ),
      ),
    );
  }

  // ============================================================
  // TRACKING
  // ============================================================

  Widget _buildTrackingSwitch() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            11,
        vertical:
            8,
      ),
      decoration:
          BoxDecoration(
        color:
            fieldBackground,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        border:
            Border.all(
          color:
              borderColor,
        ),
      ),
      child:
          Row(
        children: [
          Container(
            width:
                38,
            height:
                38,
            decoration:
                BoxDecoration(
              color:
                  gold.withOpacity(
                0.09,
              ),
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),
            child:
                const Icon(
              Icons.analytics_outlined,
              color:
                  gold,
              size:
                  18,
            ),
          ),

          const SizedBox(
            width:
                9,
          ),

          const Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Tracking',
                  style:
                      TextStyle(
                    color:
                        textColor,
                    fontSize:
                        11.5,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                SizedBox(
                  height:
                      2,
                ),

                Text(
                  'Track email opens',
                  style:
                      TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize:
                        9,
                  ),
                ),
              ],
            ),
          ),

          Switch.adaptive(
            value:
                trackingEnabled,
            activeColor:
                gold,
            activeTrackColor:
                gold.withOpacity(
              0.28,
            ),
            onChanged:
                (value) {
              setState(() {
                trackingEnabled =
                    value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCHEDULE
  // ============================================================

  Widget _buildSchedulePicker() {
    return InkWell(
      onTap:
          _selectDateTime,
      borderRadius:
          BorderRadius.circular(
        10,
      ),
      child:
          Container(
        width:
            double.infinity,
        padding:
            const EdgeInsets.all(
          11,
        ),
        decoration:
            BoxDecoration(
          color:
              fieldBackground,
          borderRadius:
              BorderRadius.circular(
            10,
          ),
          border:
              Border.all(
            color:
                borderColor,
          ),
        ),
        child:
            Row(
          children: [
            Container(
              width:
                  38,
              height:
                  38,
              decoration:
                  BoxDecoration(
                color:
                    gold.withOpacity(
                  0.09,
                ),
                borderRadius:
                    BorderRadius.circular(
                  9,
                ),
              ),
              child:
                  const Icon(
                Icons.calendar_month_outlined,
                color:
                    gold,
                size:
                    18,
              ),
            ),

            const SizedBox(
              width:
                  9,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scheduled Date & Time',
                    style:
                        TextStyle(
                      color:
                          secondaryTextColor,
                      fontSize:
                          9,
                    ),
                  ),

                  const SizedBox(
                    height:
                        3,
                  ),

                  Text(
                    scheduledDateTime ==
                            null
                        ? 'Select date and time'
                        : _formatDateTime(
                            scheduledDateTime!,
                          ),
                    maxLines:
                        2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        TextStyle(
                      color:
                          scheduledDateTime ==
                                  null
                              ? hintColor
                              : textColor,
                      fontSize:
                          11,
                      fontWeight:
                          scheduledDateTime ==
                                  null
                              ? FontWeight.w400
                              : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color:
                  secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION BUTTONS
  // ============================================================

  Widget _navigationButtons({
    String? backTitle,
    required String nextTitle,
    required IconData nextIcon,
    VoidCallback? onBack,
    VoidCallback? onNext,
  }) {
    return Row(
      children: [
        if (onBack != null) ...[
          Expanded(
            child:
                SizedBox(
              height:
                  48,
              child:
                  OutlinedButton.icon(
                onPressed:
                    onBack,
                icon:
                    const Icon(
                  Icons.arrow_back_rounded,
                  size:
                      17,
                ),
                label:
                    Text(
                  backTitle ??
                      'Back',
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      textColor,
                  backgroundColor:
                      cardColor,
                  side:
                      const BorderSide(
                    color:
                        borderColor,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width:
                10,
          ),
        ],

        Expanded(
          child:
              Container(
            height:
                48,
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xFFF0BA4F),
                  Color(0xFFD99A25),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
            child:
                ElevatedButton.icon(
              onPressed:
                  onNext,
              icon:
                  isLoading &&
                          currentStep ==
                              3
                      ? const SizedBox(
                          width:
                              16,
                          height:
                              16,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                Colors.black,
                          ),
                        )
                      : Icon(
                          nextIcon,
                          size:
                              17,
                        ),
              label:
                  Text(
                isLoading &&
                        currentStep ==
                            3
                    ? 'Publishing...'
                    : nextTitle,
                maxLines:
                    1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  fontSize:
                      11,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.transparent,
                disabledBackgroundColor:
                    Colors.transparent,
                shadowColor:
                    Colors.transparent,
                foregroundColor:
                    Colors.black,
                disabledForegroundColor:
                    Colors.black54,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      8,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NEXT STEP
  // ============================================================

  void _nextStep() {
    FocusScope.of(context).unfocus();

    if (currentStep == 0) {
      if (!_validateBasicStep()) {
        return;
      }
    }

    if (currentStep == 1) {
      if (contentController.text
          .trim()
          .isEmpty) {
        _showMessage(
          'Please enter email content.',
          isError:
              true,
        );

        return;
      }
    }

    if (currentStep < 3) {
      setState(() {
        currentStep++;
      });
    }
  }

  // ============================================================
  // PREVIOUS STEP
  // ============================================================

  void _previousStep() {
    FocusScope.of(context).unfocus();

    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  // ============================================================
  // VALIDATE BASIC
  // ============================================================

  bool _validateBasicStep() {
    final int? step =
        int.tryParse(
      stepController.text.trim(),
    );

    final int? gap =
        int.tryParse(
      gapDaysController.text.trim(),
    );

    if (step == null ||
        step <= 0) {
      _showMessage(
        'Please enter a valid step.',
        isError:
            true,
      );

      return false;
    }

    if (gap == null ||
        gap < 0) {
      _showMessage(
        'Please enter valid gap days.',
        isError:
            true,
      );

      return false;
    }

    if (variantController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Variant is required.',
        isError:
            true,
      );

      return false;
    }

    if (selectedBusinessType
        .trim()
        .isEmpty) {
      _showMessage(
        'Please add and select a business type.',
        isError:
            true,
      );

      return false;
    }

    if (subjectController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Email subject is required.',
        isError:
            true,
      );

      return false;
    }

    return true;
  }

  // ============================================================
  // PICK LOGO
  // ============================================================

  Future<void> _pickLogoFile() async {
    final result =
        await FilePicker.platform.pickFiles(
      type:
          FileType.image,
      allowMultiple:
          false,
    );

    if (result == null ||
        result.files.isEmpty) {
      return;
    }

    final file =
        result.files.first;

    if (!mounted) {
      return;
    }

    setState(() {
      logoController.text =
          file.path ??
              file.name;
    });
  }

  // ============================================================
  // PICK HERO
  // ============================================================

  Future<void> _pickHeroImage() async {
    final result =
        await FilePicker.platform.pickFiles(
      type:
          FileType.image,
      allowMultiple:
          false,
    );

    if (result == null ||
        result.files.isEmpty) {
      return;
    }

    final file =
        result.files.first;

    if (file.size >
        2 * 1024 * 1024) {
      _showMessage(
        'Hero image must be less than 2 MB.',
        isError:
            true,
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      heroImageController.text =
          file.path ??
              file.name;
    });
  }

  // ============================================================
  // PICK ATTACHMENT
  // ============================================================

  Future<void> _pickAttachmentFile() async {
    final result =
        await FilePicker.platform.pickFiles(
      type:
          FileType.any,
      allowMultiple:
          false,
    );

    if (result == null ||
        result.files.isEmpty) {
      return;
    }

    final file =
        result.files.first;

    if (!mounted) {
      return;
    }

    setState(() {
      attachmentNameController.text =
          file.name;

      attachmentUrlController.text =
          file.path ??
              '';

      attachmentMimeController.text =
          _getMimeType(
        file.extension,
      );

      attachmentSizeController.text =
          file.size.toString();
    });
  }

  // ============================================================
  // MIME
  // ============================================================

  String _getMimeType(
    String? extension,
  ) {
    switch (extension
        ?.toLowerCase()) {
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
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      case 'xls':
        return 'application/vnd.ms-excel';

      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      default:
        return 'application/octet-stream';
    }
  }

  // ============================================================
  // SELECT DATE TIME
  // ============================================================

  Future<void> _selectDateTime() async {
    final now =
        DateTime.now();

    final selectedDate =
        await showDatePicker(
      context:
          context,
      initialDate:
          scheduledDateTime ??
              now,
      firstDate:
          DateTime(
        now.year,
        now.month,
        now.day,
      ),
      lastDate:
          DateTime(
        now.year + 5,
      ),
      builder:
          (
        context,
        child,
      ) {
        return Theme(
          data:
              Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.dark(
              primary:
                  gold,
              surface:
                  cardColor2,
              onSurface:
                  white,
            ),
          ),
          child:
              child!,
        );
      },
    );

    if (selectedDate == null ||
        !mounted) {
      return;
    }

    final selectedTime =
        await showTimePicker(
      context:
          context,
      initialTime:
          scheduledDateTime != null
              ? TimeOfDay.fromDateTime(
                  scheduledDateTime!,
                )
              : TimeOfDay.now(),
      builder:
          (
        context,
        child,
      ) {
        return Theme(
          data:
              Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.dark(
              primary:
                  gold,
              surface:
                  cardColor2,
              onSurface:
                  white,
            ),
          ),
          child:
              child!,
        );
      },
    );

    if (selectedTime == null ||
        !mounted) {
      return;
    }

    final DateTime newDate =
        DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (newDate.isBefore(
      DateTime.now(),
    )) {
      _showMessage(
        'Please select a future date and time.',
        isError:
            true,
      );

      return;
    }

    setState(() {
      scheduledDateTime =
          newDate;
    });
  }

  // ============================================================
  // CREATE SEQUENCE
  // ============================================================

  Future<void> _createSequence() async {
    FocusScope.of(context).unfocus();

    if (!_validateBasicStep()) {
      setState(() {
        currentStep = 0;
      });

      return;
    }

    if (contentController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Email content is required.',
        isError:
            true,
      );

      setState(() {
        currentStep = 1;
      });

      return;
    }

    final int? step =
        int.tryParse(
      stepController.text.trim(),
    );

    final int? gapDays =
        int.tryParse(
      gapDaysController.text.trim(),
    );

    if (step == null ||
        gapDays == null) {
      return;
    }

    setState(() {
      isLoading =
          true;
    });

    try {
      final result =
          await SequenceApi.createSequence(
        step:
            step,

        gapDays:
            gapDays,

        variant:
            variantController.text.trim(),

        businessType:
            selectedBusinessType.trim(),

        subject:
            subjectController.text.trim(),

        logoUrl:
            logoController.text.trim().isEmpty
                ? null
                : logoController.text.trim(),

        logoPosition:
            selectedLogoPosition,

        heroImageUrl:
            heroImageController.text.trim().isEmpty
                ? null
                : heroImageController.text.trim(),

        heroImageLink:
            heroLinkController.text.trim().isEmpty
                ? null
                : heroLinkController.text.trim(),

        content:
            contentController.text,

        font:
            selectedFont,

        fontSize:
            selectedFontSize,

        textColor:
            selectedTextColor,

        bold:
            isBold,

        italic:
            isItalic,

        underline:
            isUnderline,

        attachmentName:
            attachmentNameController.text.trim().isEmpty
                ? null
                : attachmentNameController.text.trim(),

        attachmentUrl:
            attachmentUrlController.text.trim().isEmpty
                ? null
                : attachmentUrlController.text.trim(),

        attachmentMimeType:
            attachmentMimeController.text.trim().isEmpty
                ? null
                : attachmentMimeController.text.trim(),

        attachmentSize:
            int.tryParse(
                  attachmentSizeController.text.trim(),
                ) ??
                0,

        whatsapp:
            whatsappController.text.trim().isEmpty
                ? null
                : whatsappController.text.trim(),

        trackingEnabled:
            trackingEnabled,

        status:
            selectedStatus,

        scheduledAt:
            scheduledDateTime
                ?.toIso8601String(),
      );

      if (!mounted) {
        return;
      }

      if (result['success'] ==
          true) {
        _showMessage(
          result['message']
                  ?.toString() ??
              'Sequence created successfully.',
        );

        await Future.delayed(
          const Duration(
            milliseconds:
                450,
          ),
        );

        if (!mounted) {
          return;
        }

        Navigator.pop(
          context,
          true,
        );
      } else {
        _showMessage(
          result['message']
                  ?.toString() ??
              'Unable to create sequence.',
          isError:
              true,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Something went wrong: $e',
        isError:
            true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading =
              false;
        });
      }
    }
  }

  // ============================================================
  // EDITOR COLOR
  // ============================================================

  Color _selectedEditorColor() {
    switch (selectedTextColor) {
      case 'White':
        return Colors.white;

      case 'Gray':
        return const Color(
          0xFF9CA3AF,
        );

      case 'Red':
        return Colors.redAccent;

      case 'Blue':
        return Colors.blueAccent;

      case 'Green':
        return Colors.greenAccent;

      case 'Gold':
        return gold;

      case 'Black':
      default:
        return Colors.white;
    }
  }

  // ============================================================
  // PREVIEW COLOR
  // ============================================================

  Color _previewTextColor() {
    switch (selectedTextColor) {
      case 'White':
        return const Color(
          0xFF111827,
        );

      case 'Gray':
        return const Color(
          0xFF667085,
        );

      case 'Red':
        return Colors.red;

      case 'Blue':
        return Colors.blue;

      case 'Green':
        return const Color(
          0xFF188847,
        );

      case 'Gold':
        return const Color(
          0xFFB8860B,
        );

      case 'Black':
      default:
        return Colors.black;
    }
  }

  // ============================================================
  // EDITOR SIZE
  // ============================================================

  double _selectedEditorSize() {
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
  // PREVIEW SIZE
  // ============================================================

  double _previewFontSize() {
    final size =
        _selectedEditorSize();

    if (size >= 24) {
      return 14;
    }

    if (size >= 18) {
      return 13;
    }

    return 12;
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor() {
    switch (selectedStatus) {
      case 'active':
        return green;

      case 'scheduled':
        return gold;

      case 'paused':
        return Colors.orangeAccent;

      default:
        return secondaryTextColor;
    }
  }

  // ============================================================
  // CAPITALIZE
  // ============================================================

  String _capitalize(
    String value,
  ) {
    if (value.isEmpty) {
      return value;
    }

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDateTime(
    DateTime dateTime,
  ) {
    final day =
        dateTime.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        dateTime.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final hour =
        dateTime.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minute =
        dateTime.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$day/$month/${dateTime.year} $hour:$minute';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(
          message,
          style:
              const TextStyle(
            color:
                white,
            fontSize:
                11.5,
          ),
        ),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            isError
                ? const Color(
                    0xFF38171C,
                  )
                : const Color(
                    0xFF12301F,
                  ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            11,
          ),
        ),
      ),
    );
  }
}
