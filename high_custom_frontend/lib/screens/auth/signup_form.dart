import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'signup_controller.dart';

class SignupForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final SignupController controller;
  final VoidCallback onSubmit;
  final VoidCallback? onLogin;

  const SignupForm({
    super.key,
    required this.formKey,
    required this.controller,
    required this.onSubmit,
    this.onLogin,
  });

  @override
  State<SignupForm> createState() =>
      _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color background =
      Color(0xFF080D14);

  static const Color background2 =
      Color(0xFF030609);

  static const Color gold =
      Color(0xFFF2C45F);

  static const Color goldDark =
      Color(0xFFD9A93F);

  static const Color fieldColor =
      Color(0xD90B1017);

  static const Color fieldBorder =
      Color(0xFF555A64);

  static const Color white =
      Colors.white;

  static const Color mutedText =
      Color(0xFFAAAEB8);

  // ============================================================
  // STEP
  // ============================================================

  int _stepIndex = 0;

  bool get _isLoading =>
      widget.controller.isLoading;

  // ============================================================
  // NEXT STEP
  // ============================================================

  void _nextStep() {
    if (!widget.formKey.currentState!
        .validate()) {
      return;
    }

    FocusManager.instance.primaryFocus
        ?.unfocus();

    if (_stepIndex < 2) {
      setState(() {
        _stepIndex++;
      });
    } else {
      widget.onSubmit();
    }
  }

  // ============================================================
  // PREVIOUS STEP
  // ============================================================

  void _previousStep() {
    FocusManager.instance.primaryFocus
        ?.unfocus();

    if (_stepIndex > 0) {
      setState(() {
        _stepIndex--;
      });
    }
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.diamond_outlined,
          color: gold,
          size: 58,
        ),

        const SizedBox(height: 5),

        const Text(
          'HighCustomAI',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: gold,
            fontSize: 30,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 6),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 1,
              color: goldDark,
            ),

            const SizedBox(width: 9),

            const Text(
              'BELIEVE IN PERFECTION',
              style: TextStyle(
                color: white,
                fontSize: 8,
                fontWeight:
                    FontWeight.w600,
                letterSpacing: 2.2,
              ),
            ),

            const SizedBox(width: 9),

            Container(
              width: 32,
              height: 1,
              color: goldDark,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Create Your Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        SizedBox(height: 7),

        Text(
          'Start managing your leads with HighCustomAI',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: mutedText,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP INDICATOR
  // ============================================================

  Widget _buildStepIndicator() {
    const labels = [
      'Personal',
      'Contact',
      'Security',
    ];

    return Column(
      children: [
        Row(
          children: List.generate(
            labels.length,
            (index) {
              final active =
                  index <= _stepIndex;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration:
                            const Duration(
                          milliseconds: 250,
                        ),
                        height: 5,
                        decoration:
                            BoxDecoration(
                          color: active
                              ? gold
                              : const Color(
                                  0xFF333842,
                                ),
                          borderRadius:
                              BorderRadius
                                  .circular(20),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: gold
                                        .withOpacity(
                                      0.22,
                                    ),
                                    blurRadius:
                                        8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),

                    if (index !=
                        labels.length - 1)
                      const SizedBox(
                        width: 8,
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: List.generate(
            labels.length,
            (index) {
              final active =
                  index == _stepIndex;

              final completed =
                  index < _stepIndex;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment:
                          Alignment.center,
                      decoration:
                          BoxDecoration(
                        shape:
                            BoxShape.circle,
                        color: active ||
                                completed
                            ? gold
                            : const Color(
                                0xFF1B2028,
                              ),
                        border:
                            Border.all(
                          color: active ||
                                  completed
                              ? gold
                              : const Color(
                                  0xFF464C56,
                                ),
                        ),
                      ),
                      child: completed
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Color(
                                0xFF17120A,
                              ),
                            )
                          : Text(
                              '${index + 1}',
                              style:
                                  TextStyle(
                                color: active
                                    ? const Color(
                                        0xFF17120A,
                                      )
                                    : mutedText,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      labels[index],
                      style:
                          TextStyle(
                        color: active
                            ? gold
                            : mutedText,
                        fontSize: 11,
                        fontWeight:
                            active
                                ? FontWeight
                                    .w700
                                : FontWeight
                                    .w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController
        textController,
    required IconData prefixIcon,
    TextInputType keyboardType =
        TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    Widget? customPrefix,
    String? Function(String?)? validator,
    TextInputAction textInputAction =
        TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 9),

        TextFormField(
          controller: textController,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          textInputAction:
              textInputAction,

          scrollPadding:
              const EdgeInsets.only(
            bottom: 120,
          ),

          style: const TextStyle(
            color: white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),

          cursorColor: gold,

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: const TextStyle(
              color: mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),

            filled: true,
            fillColor: fieldColor,

            prefixIcon: customPrefix ??
                Icon(
                  prefixIcon,
                  color: gold,
                  size: 22,
                ),

            prefixIconConstraints:
                const BoxConstraints(
              minWidth: 54,
              minHeight: 56,
            ),

            suffixIcon: suffixIcon,

            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 17,
            ),

            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide:
                  const BorderSide(
                color: fieldBorder,
                width: 1.2,
              ),
            ),

            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide:
                  const BorderSide(
                color: fieldBorder,
                width: 1.2,
              ),
            ),

            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide:
                  const BorderSide(
                color: gold,
                width: 1.5,
              ),
            ),

            errorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide:
                  const BorderSide(
                color:
                    Color(0xFFFF7676),
                width: 1.2,
              ),
            ),

            focusedErrorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide:
                  const BorderSide(
                color:
                    Color(0xFFFF7676),
                width: 1.5,
              ),
            ),

            errorStyle:
                const TextStyle(
              color:
                  Color(0xFFFF8C8C),
              fontSize: 10,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PERSONAL STEP
  // ============================================================

  Widget _buildPersonalStep(
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        children: [
          _buildTextField(
            label: 'First Name',
            hint: 'Enter first name',
            textController:
                widget.controller
                    .firstNameController,
            prefixIcon:
                Icons.person_outline,
            validator: _stepIndex == 0
                ? widget.controller
                    .validateFirstName
                : (_) => null,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            label: 'Last Name',
            hint: 'Enter last name',
            textController:
                widget.controller
                    .lastNameController,
            prefixIcon:
                Icons.person_outline,
            validator: _stepIndex == 0
                ? widget.controller
                    .validateLastName
                : (_) => null,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            label: 'Employer Code',
            hint: 'Enter employer code',
            textController:
                widget.controller
                    .employerCodeController,
            prefixIcon:
                Icons.badge_outlined,
            validator: _stepIndex == 0
                ? widget.controller
                    .validateEmployerCode
                : (_) => null,
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'First Name',
                hint:
                    'Enter first name',
                textController:
                    widget.controller
                        .firstNameController,
                prefixIcon:
                    Icons.person_outline,
                validator:
                    _stepIndex == 0
                        ? widget.controller
                            .validateFirstName
                        : (_) => null,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _buildTextField(
                label: 'Last Name',
                hint:
                    'Enter last name',
                textController:
                    widget.controller
                        .lastNameController,
                prefixIcon:
                    Icons.person_outline,
                validator:
                    _stepIndex == 0
                        ? widget.controller
                            .validateLastName
                        : (_) => null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildTextField(
          label: 'Employer Code',
          hint: 'Enter employer code',
          textController:
              widget.controller
                  .employerCodeController,
          prefixIcon:
              Icons.badge_outlined,
          validator: _stepIndex == 0
              ? widget.controller
                  .validateEmployerCode
              : (_) => null,
        ),
      ],
    );
  }

  // ============================================================
  // CONTACT STEP
  // ============================================================

  Widget _buildContactStep() {
    return Column(
      children: [
        _buildTextField(
          label: 'Email Address',
          hint: 'Enter your email',
          textController:
              widget.controller
                  .emailController,
          keyboardType:
              TextInputType.emailAddress,
          prefixIcon:
              Icons.mail_outline_rounded,
          validator: _stepIndex == 1
              ? widget.controller
                  .validateEmail
              : (_) => null,
        ),

        const SizedBox(height: 16),

        _buildTextField(
          label: 'Phone Number',
          hint: '9876543210',
          textController:
              widget.controller
                  .phoneController,
          keyboardType:
              TextInputType.phone,
          prefixIcon:
              Icons.phone_outlined,

          customPrefix:
              const Padding(
            padding:
                EdgeInsets.only(
              left: 13,
              right: 7,
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  '🇮🇳',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),

                SizedBox(width: 7),

                Text(
                  '+91',
                  style: TextStyle(
                    color: gold,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          validator: _stepIndex == 1
              ? widget.controller
                  .validatePhone
              : (_) => null,
        ),
      ],
    );
  }

  // ============================================================
  // SECURITY STEP
  // ============================================================

  Widget _buildSecurityStep() {
    return Column(
      children: [
        _buildTextField(
          label: 'Password',
          hint: 'Enter your password',
          textController:
              widget.controller
                  .passwordController,
          prefixIcon:
              Icons.lock_outline_rounded,
          obscureText:
              widget.controller
                  .obscurePassword,

          suffixIcon:
              IconButton(
            onPressed:
                widget.controller
                    .togglePasswordVisibility,
            icon: Icon(
              widget.controller
                      .obscurePassword
                  ? Icons
                      .visibility_outlined
                  : Icons
                      .visibility_off_outlined,
              color: gold,
              size: 22,
            ),
          ),

          validator: _stepIndex == 2
              ? widget.controller
                  .validatePassword
              : (_) => null,
        ),

        const SizedBox(height: 16),

        _buildTextField(
          label: 'Confirm Password',
          hint: 'Confirm your password',
          textController:
              widget.controller
                  .confirmPasswordController,
          prefixIcon:
              Icons.lock_outline_rounded,
          obscureText:
              widget.controller
                  .obscureConfirmPassword,

          textInputAction:
              TextInputAction.done,

          suffixIcon:
              IconButton(
            onPressed:
                widget.controller
                    .toggleConfirmPasswordVisibility,
            icon: Icon(
              widget.controller
                      .obscureConfirmPassword
                  ? Icons
                      .visibility_outlined
                  : Icons
                      .visibility_off_outlined,
              color: gold,
              size: 22,
            ),
          ),

          validator: _stepIndex == 2
              ? widget.controller
                  .validateConfirmPassword
              : (_) => null,
        ),
      ],
    );
  }

  // ============================================================
  // CURRENT STEP
  // ============================================================

  Widget _buildCurrentStep(
    bool isMobile,
  ) {
    switch (_stepIndex) {
      case 0:
        return _buildPersonalStep(
          isMobile,
        );

      case 1:
        return _buildContactStep();

      case 2:
        return _buildSecurityStep();

      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // MAIN BUTTON
  // ============================================================

  Widget _buildMainButton() {
    final finalStep =
        _stepIndex == 2;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(11),

          gradient: _isLoading
              ? const LinearGradient(
                  colors: [
                    Color(0xFF9E833F),
                    Color(0xFF8A712F),
                  ],
                )
              : const LinearGradient(
                  begin:
                      Alignment.centerLeft,
                  end:
                      Alignment.centerRight,
                  colors: [
                    Color(0xFFFFD66F),
                    Color(0xFFE0A721),
                  ],
                ),

          boxShadow: [
            BoxShadow(
              color:
                  gold.withOpacity(0.18),
              blurRadius: 20,
              offset:
                  const Offset(0, 8),
            ),
          ],
        ),

        child: ElevatedButton(
          onPressed:
              _isLoading
                  ? null
                  : _nextStep,

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.transparent,
            disabledBackgroundColor:
                Colors.transparent,
            shadowColor:
                Colors.transparent,
            foregroundColor:
                const Color(
              0xFF17120A,
            ),
            elevation: 0,

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(11),
            ),
          ),

          child: _isLoading
              ? const SizedBox(
                  width: 23,
                  height: 23,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color:
                        Color(0xFF17120A),
                  ),
                )
              : Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      finalStep
                          ? Icons
                              .person_add_alt_1_outlined
                          : Icons
                              .arrow_forward_rounded,
                      color:
                          const Color(
                        0xFF17120A,
                      ),
                      size: 21,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Text(
                      finalStep
                          ? 'Create Account'
                          : 'Continue',
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF17120A,
                        ),
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // BACK BUTTON
  // ============================================================

  Widget _buildBackButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed:
            _isLoading
                ? null
                : _previousStep,

        icon: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
        ),

        label:
            const Text(
          'Back',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              gold,

          side:
              const BorderSide(
            color:
                fieldBorder,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN LINK
  // ============================================================

  Widget _buildLoginLink() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,

        text: TextSpan(
          text:
              'Already have an account? ',

          style:
              const TextStyle(
            color:
                mutedText,
            fontSize:
                13,
          ),

          children: [
            TextSpan(
              text:
                  'Login',

              style:
                  const TextStyle(
                color:
                    gold,
                fontWeight:
                    FontWeight.w700,
              ),

              recognizer:
                  TapGestureRecognizer()
                    ..onTap =
                        widget.onLogin,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BACKGROUND
  // SAME IDEA AS LOGIN SCREEN
  // ============================================================

  Widget _buildBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit:
              StackFit.expand,
          children: [
            // ====================================================
            // BASE
            // ====================================================

            const ColoredBox(
              color:
                  background2,
            ),

            // ====================================================
            // JEWELLERY PNG
            // FIXED IN MIDDLE
            // ====================================================

            Center(
              child:
                  SizedBox(
                width:
                    double.infinity,

                height:
                    520,

                child:
                    Image.asset(
                  'assets/images/login_jewellery.png',

                  fit:
                      BoxFit.cover,

                  alignment:
                      Alignment.center,

                  filterQuality:
                      FilterQuality.high,

                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    debugPrint(
                      'SIGNUP JEWELLERY ERROR: $error',
                    );

                    return const SizedBox
                        .shrink();
                  },
                ),
              ),
            ),

            // ====================================================
            // DARK OVERLAY
            // ====================================================

            DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.topCenter,
                  end:
                      Alignment.bottomCenter,
                  colors: [
                    const Color(
                      0xFF0C131D,
                    ),

                    const Color(
                      0xFF080D14,
                    ).withOpacity(
                      0.99,
                    ),

                    const Color(
                      0xFF080D14,
                    ).withOpacity(
                      0.96,
                    ),

                    const Color(
                      0xFF080D14,
                    ).withOpacity(
                      0.86,
                    ),

                    const Color(
                      0xFF030609,
                    ).withOpacity(
                      0.55,
                    ),

                    Colors
                        .transparent,
                  ],

                  stops:
                      const [
                    0.00,
                    0.25,
                    0.45,
                    0.62,
                    0.82,
                    1.00,
                  ],
                ),
              ),
            ),

            // ====================================================
            // SIDE FADE
            // ====================================================

            DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.centerLeft,
                  end:
                      Alignment.centerRight,
                  colors: [
                    background2
                        .withOpacity(
                      0.25,
                    ),
                    Colors
                        .transparent,
                    Colors
                        .transparent,
                    background2
                        .withOpacity(
                      0.25,
                    ),
                  ],
                  stops:
                      const [
                    0.0,
                    0.18,
                    0.82,
                    1.0,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final mediaQuery =
        MediaQuery.of(context);

    final screenWidth =
        mediaQuery.size.width;

    final keyboardOpen =
        mediaQuery.viewInsets.bottom > 0;

    final isMobile =
        screenWidth < 700;

    final horizontalPadding =
        isMobile ? 22.0 : 28.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ========================================================
        // FIXED BACKGROUND
        // ========================================================

        _buildBackground(),

        // ========================================================
        // CONTENT
        // ========================================================

        SafeArea(
          child:
              LayoutBuilder(
            builder:
                (
              context,
              constraints,
            ) {
              return SingleChildScrollView(
                physics:
                    keyboardOpen
                        ? const ClampingScrollPhysics()
                        : const BouncingScrollPhysics(),

                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,

                padding:
                    EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  keyboardOpen
                      ? 35
                      : 24,
                ),

                child:
                    ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    minHeight:
                        constraints.maxHeight -
                            42,
                  ),

                  child:
                      Center(
                    child:
                        ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth:
                            580,
                      ),

                      child:
                          Form(
                        key:
                            widget.formKey,

                        autovalidateMode:
                            AutovalidateMode
                                .onUserInteraction,

                        child:
                            Column(
                          mainAxisSize:
                              MainAxisSize
                                  .min,

                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .stretch,

                          children: [
                            // ======================================
                            // LOGO
                            // ======================================

                            _buildLogo(),

                            const SizedBox(
                              height:
                                  24,
                            ),

                            // ======================================
                            // TITLE
                            // ======================================

                            _buildTitle(),

                            const SizedBox(
                              height:
                                  24,
                            ),

                            // ======================================
                            // STEP INDICATOR
                            // ======================================

                            _buildStepIndicator(),

                            const SizedBox(
                              height:
                                  28,
                            ),

                            // ======================================
                            // CURRENT STEP
                            // ======================================

                            AnimatedSwitcher(
                              duration:
                                  const Duration(
                                milliseconds:
                                    220,
                              ),

                              transitionBuilder:
                                  (
                                child,
                                animation,
                              ) {
                                return FadeTransition(
                                  opacity:
                                      animation,

                                  child:
                                      SlideTransition(
                                    position:
                                        Tween<
                                            Offset>(
                                      begin:
                                          const Offset(
                                        0.05,
                                        0,
                                      ),
                                      end:
                                          Offset.zero,
                                    ).animate(
                                      animation,
                                    ),

                                    child:
                                        child,
                                  ),
                                );
                              },

                              child:
                                  Container(
                                key:
                                    ValueKey(
                                  _stepIndex,
                                ),

                                padding:
                                    const EdgeInsets
                                        .all(
                                  18,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xC5080D14,
                                  ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),

                                  border:
                                      Border.all(
                                    color:
                                        const Color(
                                      0xFF323943,
                                    ),
                                  ),

                                  boxShadow:
                                      [
                                    BoxShadow(
                                      color:
                                          Colors.black
                                              .withOpacity(
                                        0.20,
                                      ),
                                      blurRadius:
                                          20,
                                      offset:
                                          const Offset(
                                        0,
                                        8,
                                      ),
                                    ),
                                  ],
                                ),

                                child:
                                    _buildCurrentStep(
                                  isMobile,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height:
                                  22,
                            ),

                            // ======================================
                            // BUTTONS
                            // ======================================

                            if (_stepIndex >
                                0) ...[
                              _buildBackButton(),

                              const SizedBox(
                                height:
                                    10,
                              ),
                            ],

                            _buildMainButton(),

                            const SizedBox(
                              height:
                                  22,
                            ),

                            // ======================================
                            // LOGIN
                            // ======================================

                            _buildLoginLink(),

                            const SizedBox(
                              height:
                                  20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}