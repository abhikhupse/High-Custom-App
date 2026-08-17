import 'package:flutter/material.dart';

import '../../constants/colors.dart';
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

  Widget _buildOtpBox(
    BuildContext context,
    int index,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive OTP box size.
    final boxWidth = screenWidth < 360 ? 42.0 : 48.0;
    final boxHeight = screenWidth < 360 ? 54.0 : 58.0;

    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: TextField(
        controller: controller.otpControllers[index],
        focusNode: controller.focusNodes[index],
        keyboardType: TextInputType.number,
        textInputAction: index == 5
            ? TextInputAction.done
            : TextInputAction.next,
        textAlign: TextAlign.center,

        // Important for OTP autofill.
        autofillHints: const [
          AutofillHints.oneTimeCode,
        ],

        // We handle multiple characters ourselves so
        // pasted OTP can be distributed across boxes.
        maxLength: 6,

        style: TextStyle(
          color: Colors.white,
          fontSize: screenWidth < 360 ? 20 : 22,
          fontWeight: FontWeight.w700,
        ),

        onChanged: (value) {
          controller.onOtpChanged(
            value,
            index,
          );
        },

        onSubmitted: (_) {
          if (index == 5) {
            onVerify();
          }
        },

        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFF111419),
          contentPadding: EdgeInsets.zero,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF2C2C2C),
              width: 1.2,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF2C2C2C),
              width: 1.2,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.8,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBoxes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final spacing = screenWidth < 360 ? 3.0 : 4.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        6,
        (index) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing,
            ),
            child: _buildOtpBox(
              context,
              index,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isSmallScreen = screenWidth < 600;

    final horizontalPadding =
        isSmallScreen ? 16.0 : 22.0;

    return Stack(
      children: [
        // Top glow.
        Positioned(
          top: -120,
          left: -100,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withAlpha(46),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom glow.
        Positioned(
          bottom: -120,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withAlpha(36),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - 48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 620,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen
                          ? 22
                          : 48,
                      vertical: isSmallScreen
                          ? 30
                          : 42,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF071112),
                      borderRadius:
                          BorderRadius.circular(36),
                      border: Border.all(
                        color:
                            AppColors.primary.withAlpha(
                          190,
                        ),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withAlpha(120),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Email icon.
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  AppColors.primary.withAlpha(
                                20,
                              ),
                              border: Border.all(
                                color:
                                    AppColors.primary.withAlpha(
                                  120,
                                ),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons
                                  .mark_email_read_outlined,
                              color: AppColors.primary,
                              size: 34,
                            ),
                          ),

                          const SizedBox(height: 22),

                          const Text(
                            'VERIFY YOUR EMAIL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'We have sent a 6-digit verification code to',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Email.
                          Text(
                            controller.email,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 32),

                          const Text(
                            'ENTER VERIFICATION CODE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  AppColors.textSecondary,
                              fontSize: 12,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // OTP boxes.
                          _buildOtpBoxes(context),

                          const SizedBox(height: 12),

                          // Validation message.
                          AnimatedBuilder(
                            animation: controller,
                            builder: (
                              context,
                              child,
                            ) {
                              if (controller.otp.isEmpty ||
                                  controller
                                          .otp.length ==
                                      6) {
                                return const SizedBox(
                                  height: 20,
                                );
                              }

                              return SizedBox(
                                height: 20,
                                child: Text(
                                  controller
                                          .validateOtp() ??
                                      '',
                                  textAlign:
                                      TextAlign.center,
                                  style:
                                      const TextStyle(
                                    color:
                                        AppColors.error,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // Verify button.
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: AnimatedBuilder(
                              animation: controller,
                              builder: (
                                context,
                                child,
                              ) {
                                return ElevatedButton(
                                  onPressed:
                                      controller.isLoading
                                          ? null
                                          : onVerify,
                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        30,
                                      ),
                                    ),
                                    backgroundColor:
                                        AppColors.primary,
                                    foregroundColor:
                                        Colors.black,
                                    elevation: 12,
                                  ),
                                  child: controller
                                          .isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2.5,
                                            color:
                                                Colors.black,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .verified_outlined,
                                              color:
                                                  Colors.black,
                                            ),
                                            SizedBox(
                                              width: 12,
                                            ),
                                            Text(
                                              'VERIFY OTP',
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors
                                                        .black,
                                                fontWeight:
                                                    FontWeight
                                                        .w800,
                                                letterSpacing:
                                                    1.2,
                                                fontSize:
                                                    15,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 12,
                                            ),
                                            Icon(
                                              Icons
                                                  .arrow_forward,
                                              color:
                                                  Colors.black,
                                            ),
                                          ],
                                        ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Resend.
                          AnimatedBuilder(
                            animation: controller,
                            builder: (
                              context,
                              child,
                            ) {
                              return Wrap(
                                alignment:
                                    WrapAlignment.center,
                                crossAxisAlignment:
                                    WrapCrossAlignment
                                        .center,
                                children: [
                                  const Text(
                                    "Didn't receive the code? ",
                                    style: TextStyle(
                                      color: AppColors
                                          .textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        controller
                                                .isResending
                                            ? null
                                            : onResend,
                                    style:
                                        TextButton.styleFrom(
                                      foregroundColor:
                                          AppColors
                                              .primary,
                                    ),
                                    child: controller
                                            .isResending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth:
                                                  2,
                                              color:
                                                  AppColors
                                                      .primary,
                                            ),
                                          )
                                        : const Text(
                                            'Resend OTP',
                                            style:
                                                TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .w700,
                                            ),
                                          ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 8),

                          TextButton.icon(
                            onPressed:
                                onBackToLogin,
                            icon: const Icon(
                              Icons.arrow_back,
                              size: 18,
                            ),
                            label: const Text(
                              'Back to Login',
                            ),
                            style:
                                TextButton.styleFrom(
                              foregroundColor:
                                  AppColors
                                      .textSecondary,
                            ),
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}