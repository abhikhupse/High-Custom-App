import 'package:flutter/material.dart';

import 'otp_verification_controller.dart';

class OtpVerificationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final OtpVerificationController controller;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onBackToLogin;

  const OtpVerificationForm({
    super.key,
    required this.formKey,
    required this.controller,
    required this.onVerify,
    required this.onResend,
    required this.onBackToLogin,
  });

  // ============================================================
  // COLORS
  // ============================================================

  static const Color background = Color(0xFF080D14);
  static const Color background2 = Color(0xFF030609);

  static const Color gold = Color(0xFFF2C45F);
  static const Color goldDark = Color(0xFFD9A93F);

  static const Color fieldColor = Color(0xD90B1017);
  static const Color fieldBorder = Color(0xFF555A64);

  static const Color white = Colors.white;
  static const Color mutedText = Color(0xFFAAAEB8);

  static const Color errorColor = Color(0xFFFF7676);

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
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontWeight: FontWeight.w600,
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
  // EMAIL VERIFICATION ICON
  // ============================================================

  Widget _buildVerificationIcon() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,

        color: gold.withOpacity(0.08),

        border: Border.all(
          color: gold.withOpacity(0.55),
          width: 1.3,
        ),

        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),

      child: const Icon(
        Icons.mark_email_read_outlined,
        color: gold,
        size: 31,
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVerificationIcon(),

        const SizedBox(height: 20),

        const Text(
          'Verify Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: white,
            fontSize: 27,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'We sent a 6-digit verification code to',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: mutedText,
            fontSize: 13,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 5),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
          ),
          child: Text(
            controller.email,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: gold,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // OTP BOX
  // ============================================================

  Widget _buildOtpBox(
    BuildContext context,
    int index,
  ) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    double boxWidth;
    double boxHeight;

    if (screenWidth < 350) {
      boxWidth = 39;
      boxHeight = 52;
    } else if (screenWidth < 390) {
      boxWidth = 43;
      boxHeight = 56;
    } else {
      boxWidth = 47;
      boxHeight = 59;
    }

    return SizedBox(
      width: boxWidth,
      height: boxHeight,

      child: TextField(
        controller:
            controller.otpControllers[index],

        focusNode:
            controller.focusNodes[index],

        keyboardType:
            TextInputType.number,

        textInputAction: index == 5
            ? TextInputAction.done
            : TextInputAction.next,

        textAlign:
            TextAlign.center,

        autofillHints:
            const [
          AutofillHints.oneTimeCode,
        ],

        // Keep this because your controller
        // handles pasted OTP values.
        maxLength: 6,

        scrollPadding:
            const EdgeInsets.only(
          bottom: 100,
        ),

        cursorColor:
            gold,

        style:
            TextStyle(
          color:
              white,

          fontSize:
              screenWidth < 360
                  ? 19
                  : 21,

          fontWeight:
              FontWeight.w700,
        ),

        onChanged:
            (value) {
          controller.onOtpChanged(
            value,
            index,
          );
        },

        onSubmitted:
            (_) {
          if (index == 5) {
            onVerify();
          }
        },

        decoration:
            InputDecoration(
          counterText: '',

          filled: true,

          fillColor:
              fieldColor,

          contentPadding:
              EdgeInsets.zero,

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),

            borderSide:
                const BorderSide(
              color:
                  fieldBorder,
              width:
                  1.2,
            ),
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),

            borderSide:
                const BorderSide(
              color:
                  fieldBorder,
              width:
                  1.2,
            ),
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),

            borderSide:
                const BorderSide(
              color:
                  gold,
              width:
                  1.6,
            ),
          ),

          errorBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),

            borderSide:
                const BorderSide(
              color:
                  errorColor,
              width:
                  1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OTP BOXES
  // ============================================================

  Widget _buildOtpBoxes(
    BuildContext context,
  ) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final spacing =
        screenWidth < 350
            ? 2.5
            : screenWidth < 390
                ? 3.0
                : 4.0;

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,

      children:
          List.generate(
        6,
        (index) {
          return Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal:
                  spacing,
            ),

            child:
                _buildOtpBox(
              context,
              index,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // OTP SECTION
  // ============================================================

  Widget _buildOtpSection(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.fromLTRB(
        14,
        20,
        14,
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xC5080D14,
        ),

        borderRadius:
            BorderRadius.circular(18),

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
                    .withOpacity(0.20),
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
          Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          const Text(
            'ENTER VERIFICATION CODE',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  mutedText,
              fontSize:
                  11,
              letterSpacing:
                  1.4,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height:
                16,
          ),

          _buildOtpBoxes(
            context,
          ),

          const SizedBox(
            height:
                9,
          ),

          AnimatedBuilder(
            animation:
                controller,

            builder:
                (
              context,
              child,
            ) {
              if (controller.otp.isEmpty ||
                  controller.otp.length == 6) {
                return const SizedBox(
                  height:
                      18,
                );
              }

              return SizedBox(
                height:
                    18,

                child:
                    Text(
                  controller
                          .validateOtp() ??
                      '',

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    color:
                        errorColor,
                    fontSize:
                        11,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VERIFY BUTTON
  // ============================================================

  Widget _buildVerifyButton() {
    return SizedBox(
      width:
          double.infinity,

      height:
          56,

      child:
          DecoratedBox(
        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(11),

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

          boxShadow:
              [
            BoxShadow(
              color:
                  gold.withOpacity(
                0.18,
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
            ElevatedButton(
          onPressed:
              controller.isLoading
                  ? null
                  : onVerify,

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.transparent,

            disabledBackgroundColor:
                Colors.transparent,

            shadowColor:
                Colors.transparent,

            elevation:
                0,

            foregroundColor:
                const Color(
              0xFF17120A,
            ),

            padding:
                EdgeInsets.zero,

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(11),
            ),
          ),

          child:
              controller.isLoading
                  ? const SizedBox(
                      width:
                          23,
                      height:
                          23,
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
                          MainAxisAlignment.center,

                      mainAxisSize:
                          MainAxisSize.min,

                      children: [
                        Icon(
                          Icons
                              .verified_outlined,
                          color:
                              Color(
                            0xFF17120A,
                          ),
                          size:
                              21,
                        ),

                        SizedBox(
                          width:
                              10,
                        ),

                        Text(
                          'Verify OTP',
                          style:
                              TextStyle(
                            color:
                                Color(
                              0xFF17120A,
                            ),
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        SizedBox(
                          width:
                              10,
                        ),

                        Icon(
                          Icons
                              .arrow_forward_rounded,
                          color:
                              Color(
                            0xFF17120A,
                          ),
                          size:
                              21,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // ============================================================
  // RESEND
  // ============================================================

  Widget _buildResend() {
    return AnimatedBuilder(
      animation:
          controller,

      builder:
          (
        context,
        child,
      ) {
        return Wrap(
          alignment:
              WrapAlignment.center,

          crossAxisAlignment:
              WrapCrossAlignment.center,

          children: [
            const Text(
              "Didn't receive the code? ",
              style:
                  TextStyle(
                color:
                    mutedText,
                fontSize:
                    13,
              ),
            ),

            TextButton(
              onPressed:
                  controller.isResending
                      ? null
                      : onResend,

              style:
                  TextButton.styleFrom(
                foregroundColor:
                    gold,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      4,
                  vertical:
                      6,
                ),
              ),

              child:
                  controller.isResending
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
                                gold,
                          ),
                        )
                      : const Text(
                          'Resend OTP',
                          style:
                              TextStyle(
                            color:
                                gold,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BACK TO LOGIN
  // ============================================================

  Widget _buildBackToLogin() {
    return TextButton.icon(
      onPressed:
          onBackToLogin,

      icon:
          const Icon(
        Icons.arrow_back_rounded,
        size:
            17,
      ),

      label:
          const Text(
        'Back to Login',
      ),

      style:
          TextButton.styleFrom(
        foregroundColor:
            mutedText,

        textStyle:
            const TextStyle(
          fontSize:
              13,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // BACKGROUND
  // SAME AS LOGIN / SIGNUP
  // ============================================================

  Widget _buildBackground() {
    return Positioned.fill(
      child:
          IgnorePointer(
        child:
            Stack(
          fit:
              StackFit.expand,

          children: [
            // ====================================================
            // BASE BACKGROUND
            // ====================================================

            const ColoredBox(
              color:
                  background2,
            ),

            // ====================================================
            // FIXED JEWELLERY IMAGE
            // ====================================================

            Center(
              child:
                  SizedBox(
                width:
                    double.infinity,

                height:
                    500,

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
                      'OTP JEWELLERY ERROR: $error',
                    );

                    return const SizedBox
                        .shrink();
                  },
                ),
              ),
            ),

            // ====================================================
            // VERTICAL DARK FADE
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

                  colors:
                      [
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

                    Colors
                        .transparent,
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

                  colors:
                      [
                    background2
                        .withOpacity(
                      0.30,
                    ),

                    Colors
                        .transparent,

                    Colors
                        .transparent,

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

            // ====================================================
            // GOLD GLOW
            // ====================================================

            Positioned(
              left:
                  -130,

              bottom:
                  100,

              child:
                  Container(
                width:
                    280,

                height:
                    280,

                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,

                  gradient:
                      RadialGradient(
                    colors:
                        [
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

    final horizontalPadding =
        screenWidth < 380
            ? 18.0
            : 24.0;

    return Stack(
      fit:
          StackFit.expand,

      children: [
        // ========================================================
        // FIXED BACKGROUND
        // ========================================================

        _buildBackground(),

        // ========================================================
        // PAGE
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
                // =================================================
                // SCROLLING AVAILABLE WHEN KEYBOARD IS OPEN
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
                  16,
                  horizontalPadding,
                  keyboardOpen
                      ? 30
                      : 20,
                ),

                child:
                    ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    minHeight:
                        keyboardOpen
                            ? 0
                            : constraints.maxHeight -
                                36,
                  ),

                  child:
                      Center(
                    child:
                        ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth:
                            560,
                      ),

                      child:
                          Form(
                        key:
                            formKey,

                        child:
                            Column(
                          mainAxisSize:
                              MainAxisSize.min,

                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,

                          children: [
                            // ======================================
                            // LOGO
                            // ======================================

                            _buildLogo(),

                            SizedBox(
                              height:
                                  keyboardOpen
                                      ? 14
                                      : 28,
                            ),

                            // ======================================
                            // TITLE
                            // ======================================

                            _buildTitle(),

                            SizedBox(
                              height:
                                  keyboardOpen
                                      ? 18
                                      : 30,
                            ),

                            // ======================================
                            // OTP
                            // ======================================

                            _buildOtpSection(
                              context,
                            ),

                            const SizedBox(
                              height:
                                  20,
                            ),

                            // ======================================
                            // VERIFY
                            // ======================================

                            _buildVerifyButton(),

                            const SizedBox(
                              height:
                                  18,
                            ),

                            // ======================================
                            // RESEND
                            // ======================================

                            _buildResend(),

                            const SizedBox(
                              height:
                                  2,
                            ),

                            // ======================================
                            // BACK
                            // ======================================

                            Center(
                              child:
                                  _buildBackToLogin(),
                            ),

                            const SizedBox(
                              height:
                                  10,
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