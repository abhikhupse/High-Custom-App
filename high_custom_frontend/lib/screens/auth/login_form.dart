import 'package:flutter/material.dart';

import 'login_controller.dart';

class LoginForm extends StatelessWidget {
  // ============================================================
  // VARIABLES
  // ============================================================

  final GlobalKey<FormState> formKey;

  final LoginController controller;

  final VoidCallback onSubmit;

  final VoidCallback? onSignup;

  final VoidCallback? onForgotPassword;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const LoginForm({
    super.key,
    required this.formKey,
    required this.controller,
    required this.onSubmit,
    this.onSignup,
    this.onForgotPassword,
  });

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
  // INPUT FIELD
  // ============================================================

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController textController,
    required IconData prefixIcon,
    TextInputType keyboardType =
        TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputAction textInputAction =
        TextInputAction.next,
    VoidCallback? onFieldSubmitted,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // ======================================================
        // LABEL
        // ======================================================

        Text(
          label,
          style: const TextStyle(
            color: white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(
          height: 11,
        ),

        // ======================================================
        // TEXT FIELD
        // ======================================================

        TextFormField(
          controller: textController,

          keyboardType: keyboardType,

          obscureText: obscureText,

          validator: validator,

          textInputAction:
              textInputAction,

          // Prevent smart formatting problems.
          autocorrect: false,

          enableSuggestions:
              !obscureText,

          // ====================================================
          // KEYBOARD SCROLL
          // ====================================================

          scrollPadding:
              const EdgeInsets.only(
            bottom: 140,
          ),

          // ====================================================
          // SUBMIT FROM KEYBOARD
          // ====================================================

          onFieldSubmitted: (_) {
            if (onFieldSubmitted !=
                null) {
              onFieldSubmitted();
            }
          },

          // ====================================================
          // TEXT STYLE
          // ====================================================

          style: const TextStyle(
            color: white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),

          cursorColor: gold,

          // ====================================================
          // DECORATION
          // ====================================================

          decoration:
              InputDecoration(
            hintText: hint,

            hintStyle:
                const TextStyle(
              color: mutedText,
              fontSize: 15,
              fontWeight:
                  FontWeight.w400,
            ),

            filled: true,

            fillColor: fieldColor,

            // ================================================
            // PREFIX ICON
            // ================================================

            prefixIcon: Icon(
              prefixIcon,
              color: gold,
              size: 23,
            ),

            prefixIconConstraints:
                const BoxConstraints(
              minWidth: 55,
              minHeight: 58,
            ),

            // ================================================
            // SUFFIX ICON
            // ================================================

            suffixIcon:
                suffixIcon,

            // ================================================
            // PADDING
            // ================================================

            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 19,
            ),

            // ================================================
            // NORMAL BORDER
            // ================================================

            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color: fieldBorder,
                width: 1.2,
              ),
            ),

            // ================================================
            // ENABLED BORDER
            // ================================================

            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color: fieldBorder,
                width: 1.2,
              ),
            ),

            // ================================================
            // FOCUSED BORDER
            // ================================================

            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color: gold,
                width: 1.5,
              ),
            ),

            // ================================================
            // ERROR BORDER
            // ================================================

            errorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(0xFFFF7676),
                width: 1.2,
              ),
            ),

            // ================================================
            // FOCUSED ERROR BORDER
            // ================================================

            focusedErrorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(0xFFFF7676),
                width: 1.5,
              ),
            ),

            // ================================================
            // ERROR STYLE
            // ================================================

            errorStyle:
                const TextStyle(
              color:
                  Color(0xFFFF8C8C),
              fontSize: 12,
              height: 1.3,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Column(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        // ======================================================
        // DIAMOND
        // ======================================================

        const Icon(
          Icons.diamond_outlined,
          color: gold,
          size: 62,
        ),

        const SizedBox(
          height: 6,
        ),

        // ======================================================
        // NAME
        // ======================================================

        const Text(
          'HighCustomAI',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color: gold,
            fontSize: 32,
            fontWeight:
                FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        // ======================================================
        // TAG LINE
        // ======================================================

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 35,
              height: 1,
              color: goldDark,
            ),

            const SizedBox(
              width: 10,
            ),

            const Text(
              'BELIEVE IN PERFECTION',
              style: TextStyle(
                color: white,
                fontSize: 9,
                fontWeight:
                    FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Container(
              width: 35,
              height: 1,
              color: goldDark,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // MARKETING TEXT
  // ============================================================

  Widget _buildMarketingText() {
    return const Column(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Text(
          'Smart Leads.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color: white,
            fontSize: 31,
            fontWeight:
                FontWeight.w700,
            height: 1.15,
          ),
        ),

        SizedBox(
          height: 5,
        ),

        Text(
          'Real Growth.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color: gold,
            fontSize: 31,
            fontWeight:
                FontWeight.w700,
            height: 1.15,
          ),
        ),

        SizedBox(
          height: 18,
        ),

        Text(
          'Manage, track & convert your leads\n'
          'efficiently with HighCustomAI Lead\n'
          'Management System.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color: mutedText,
            fontSize: 14,
            height: 1.55,
            fontWeight:
                FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOGIN BUTTON
  // ============================================================

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,

      child: DecoratedBox(
        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(
            11,
          ),

          // ====================================================
          // BUTTON GRADIENT
          // ====================================================

          gradient:
              controller.isLoading
                  ? const LinearGradient(
                      colors: [
                        Color(
                          0xFF9E833F,
                        ),
                        Color(
                          0xFF8A712F,
                        ),
                      ],
                    )
                  : const LinearGradient(
                      begin:
                          Alignment.centerLeft,
                      end:
                          Alignment.centerRight,
                      colors: [
                        Color(
                          0xFFFFD66F,
                        ),
                        Color(
                          0xFFE0A721,
                        ),
                      ],
                    ),

          boxShadow: [
            BoxShadow(
              color:
                  gold.withOpacity(
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

        child: ElevatedButton(
          // ====================================================
          // LOGIN CLICK
          // ====================================================

          onPressed:
              controller.isLoading
                  ? null
                  : () {
                      debugPrint(
                        'LOGIN BUTTON PRESSED FROM LOGIN FORM',
                      );

                      onSubmit();
                    },

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

            padding:
                EdgeInsets.zero,

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
          ),

          // ====================================================
          // BUTTON CONTENT
          // ====================================================

          child:
              controller.isLoading
                  ? const SizedBox(
                      width: 23,
                      height: 23,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2.4,
                        color:
                            Color(
                          0xFF17120A,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      mainAxisSize:
                          MainAxisSize
                              .min,
                      children: [
                        Text(
                          'Login',
                          style:
                              TextStyle(
                            color:
                                Color(
                              0xFF17120A,
                            ),
                            fontSize:
                                17,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),

                        SizedBox(
                          width: 13,
                        ),

                        Icon(
                          Icons
                              .login_rounded,
                          color:
                              Color(
                            0xFF17120A,
                          ),
                          size: 22,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // ============================================================
  // SIGN UP
  // ============================================================

  Widget _buildSignup() {
    return Center(
      child: Wrap(
        alignment:
            WrapAlignment.center,

        crossAxisAlignment:
            WrapCrossAlignment.center,

        children: [
          const Text(
            "Don't have an account? ",
            style: TextStyle(
              color: mutedText,
              fontSize: 14,
              fontWeight:
                  FontWeight.w400,
            ),
          ),

          InkWell(
            onTap: onSignup,

            borderRadius:
                BorderRadius.circular(
              6,
            ),

            child:
                const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 2,
              ),

              child: Text(
                'Sign Up',
                style:
                    TextStyle(
                  color: gold,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BACKGROUND
  // ============================================================

  Widget _buildBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ==================================================
            // BASE
            // ==================================================

            const ColoredBox(
              color: background2,
            ),

            // ==================================================
            // JEWELLERY IMAGE
            // ==================================================

            Center(
              child: SizedBox(
                width:
                    double.infinity,
                height: 500,

                child:
                    Image.asset(
                  'assets/images/login_jewellery.png',

                  fit:
                      BoxFit.cover,

                  alignment:
                      Alignment.center,

                  filterQuality:
                      FilterQuality.high,

                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    debugPrint(
                      'LOGIN JEWELLERY ERROR: $error',
                    );

                    return const SizedBox
                        .shrink();
                  },
                ),
              ),
            ),

            // ==================================================
            // VERTICAL FADE
            // ==================================================

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
                      0.84,
                    ),

                    const Color(
                      0xFF030609,
                    ).withOpacity(
                      0.48,
                    ),

                    Colors.transparent,
                  ],

                  stops:
                      const [
                    0.00,
                    0.24,
                    0.43,
                    0.60,
                    0.80,
                    1.00,
                  ],
                ),
              ),
            ),

            // ==================================================
            // SIDE FADE
            // ==================================================

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
                      0.30,
                    ),

                    Colors.transparent,

                    Colors.transparent,

                    background2
                        .withOpacity(
                      0.30,
                    ),
                  ],

                  stops:
                      const [
                    0.00,
                    0.18,
                    0.82,
                    1.00,
                  ],
                ),
              ),
            ),

            // ==================================================
            // GOLD GLOW
            // ==================================================

            Positioned(
              left: -130,
              bottom: 100,

              child:
                  Container(
                width: 280,
                height: 280,

                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,

                  gradient:
                      RadialGradient(
                    colors: [
                      gold.withOpacity(
                        0.06,
                      ),
                      Colors.transparent,
                    ],
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
  // LOGIN CONTENT
  // ============================================================

  Widget _buildContent({
    required double screenHeight,
    required bool keyboardOpen,
  }) {
    final bool shortScreen =
        screenHeight < 800;

    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 560,
        ),

        // ======================================================
        // IMPORTANT
        //
        // ALL TextFormFields MUST BE INSIDE THIS FORM.
        // LoginScreen's _formKey points to this Form.
        // ======================================================

        child: Form(
          key: formKey,

          autovalidateMode:
              AutovalidateMode.disabled,

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              // =================================================
              // LOGO
              // =================================================

              _buildLogo(),

              SizedBox(
                height:
                    keyboardOpen
                        ? 14
                        : shortScreen
                            ? 18
                            : 30,
              ),

              // =================================================
              // MARKETING
              // =================================================

              _buildMarketingText(),

              SizedBox(
                height:
                    keyboardOpen
                        ? 18
                        : shortScreen
                            ? 20
                            : 30,
              ),

              // =================================================
              // EMAIL
              // =================================================

              _buildTextField(
                label:
                    'Email',

                hint:
                    'Enter your email',

                textController:
                    controller
                        .emailController,

                keyboardType:
                    TextInputType
                        .emailAddress,

                prefixIcon:
                    Icons
                        .mail_outline_rounded,

                validator:
                    controller
                        .validateEmail,

                textInputAction:
                    TextInputAction
                        .next,
              ),

              SizedBox(
                height:
                    keyboardOpen
                        ? 12
                        : shortScreen
                            ? 14
                            : 20,
              ),

              // =================================================
              // PASSWORD
              // =================================================

              _buildTextField(
                label:
                    'Password',

                hint:
                    'Enter your password',

                textController:
                    controller
                        .passwordController,

                prefixIcon:
                    Icons
                        .lock_outline_rounded,

                obscureText:
                    controller
                        .obscurePassword,

                validator:
                    controller
                        .validatePassword,

                textInputAction:
                    TextInputAction.done,

                onFieldSubmitted:
                    onSubmit,

                suffixIcon:
                    IconButton(
                  onPressed:
                      controller
                          .togglePasswordVisibility,

                  icon: Icon(
                    controller
                            .obscurePassword
                        ? Icons
                            .visibility_outlined
                        : Icons
                            .visibility_off_outlined,

                    color: gold,

                    size: 23,
                  ),
                ),
              ),

              // =================================================
              // FORGOT PASSWORD
              // =================================================

              Align(
                alignment:
                    Alignment.centerRight,

                child:
                    TextButton(
                  onPressed:
                      onForgotPassword,

                  style:
                      TextButton.styleFrom(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 9,
                    ),
                  ),

                  child:
                      const Text(
                    'Forgot Password?',

                    style:
                        TextStyle(
                      color: gold,
                      fontSize: 14,
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              // =================================================
              // LOGIN
              // =================================================

              _buildLoginButton(),

              SizedBox(
                height:
                    keyboardOpen
                        ? 12
                        : shortScreen
                            ? 12
                            : 20,
              ),

              // =================================================
              // SIGN UP
              // =================================================

              _buildSignup(),

              const SizedBox(
                height: 10,
              ),
            ],
          ),
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
    final MediaQueryData mediaQuery =
        MediaQuery.of(context);

    final double screenWidth =
        mediaQuery.size.width;

    final double availableHeight =
        mediaQuery.size.height;

    final bool keyboardOpen =
        mediaQuery.viewInsets.bottom > 0;

    final double horizontalPadding =
        screenWidth < 380
            ? 20.0
            : 24.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ======================================================
        // BACKGROUND
        // ======================================================

        _buildBackground(),

        // ======================================================
        // LOGIN FORM
        // ======================================================

        SafeArea(
          child: LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              final double topPadding =
                  keyboardOpen
                      ? 16.0
                      : 10.0;

              final double bottomPadding =
                  keyboardOpen
                      ? 30.0
                      : 20.0;

              return SingleChildScrollView(
                // =================================================
                // SCROLL WHEN KEYBOARD IS OPEN
                // =================================================

                physics:
                    keyboardOpen
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),

                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,

                padding:
                    EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  bottomPadding,
                ),

                child:
                    ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    minHeight:
                        keyboardOpen
                            ? 0
                            : constraints
                                    .maxHeight -
                                topPadding -
                                bottomPadding,
                  ),

                  child:
                      keyboardOpen
                          ? _buildContent(
                              screenHeight:
                                  availableHeight,
                              keyboardOpen:
                                  true,
                            )
                          : Center(
                              child:
                                  _buildContent(
                                screenHeight:
                                    availableHeight,
                                keyboardOpen:
                                    false,
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