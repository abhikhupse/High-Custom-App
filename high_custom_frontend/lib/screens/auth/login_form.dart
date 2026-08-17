import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import 'login_controller.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final LoginController controller;
  final VoidCallback onSubmit;
  final VoidCallback? onSignup;
  final VoidCallback? onForgotPassword;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.controller,
    required this.onSubmit,
    this.onSignup,
    this.onForgotPassword,
  });

  Widget _fieldLabel(String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? prefix,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.35,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFBDBDBD),
              fontSize: 16,
            ),
            filled: true,
            fillColor: const Color(0xFF111419),
            prefixIcon: prefix,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xFF2C2C2C),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xFF2C2C2C),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isSmallScreen ? 16.0 : 22.0;

    final minBodyHeight =
        screenHeight - (isSmallScreen ? 40 : 80);

    return Stack(
      children: [
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
                minHeight: minBodyHeight,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 720,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF071112),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(190),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(120),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 22 : 48,
                        vertical: isSmallScreen ? 28 : 42,
                      ),
                      child: Form(
                        key: formKey,
                        autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'HIGH CUSTOM JEWELLERS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize:
                                    isSmallScreen ? 24 : 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'WELCOME BACK',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign in to continue to your account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(
                              height:
                                  isSmallScreen ? 34 : 42,
                            ),
                            _buildTextField(
                              label: 'Email Address',
                              hint: 'Email Address',
                              controller:
                                  controller.emailController,
                              keyboardType:
                                  TextInputType.emailAddress,
                              prefix: const Padding(
                                padding: EdgeInsets.only(
                                  left: 12,
                                  right: 6,
                                ),
                                child: Icon(
                                  Icons.email_outlined,
                                  color:
                                      AppColors.textSecondary,
                                ),
                              ),
                              validator:
                                  controller.validateEmail,
                            ),
                            const SizedBox(height: 22),
                            _buildTextField(
                              label: 'Password',
                              hint: '••••••••',
                              controller:
                                  controller.passwordController,
                              obscureText:
                                  controller.obscurePassword,
                              prefix: const Padding(
                                padding: EdgeInsets.only(
                                  left: 12,
                                  right: 6,
                                ),
                                child: Icon(
                                  Icons.lock_outline,
                                  color:
                                      AppColors.textSecondary,
                                ),
                              ),
                              suffixIcon: IconButton(
                                onPressed: controller
                                    .togglePasswordVisibility,
                                icon: Icon(
                                  controller.obscurePassword
                                      ? Icons
                                          .visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                  color:
                                      AppColors.textSecondary,
                                ),
                              ),
                              validator:
                                  controller.validatePassword,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment:
                                  Alignment.centerRight,
                              child: TextButton(
                                onPressed: onForgotPassword,
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color:
                                        AppColors.primary,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    controller.isLoading
                                        ? null
                                        : onSubmit,
                                style: ElevatedButton.styleFrom(
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                  backgroundColor:
                                      AppColors.primary,
                                  foregroundColor:
                                      Colors.black,
                                  elevation: 12,
                                ),
                                child: controller.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .center,
                                        children: [
                                          Icon(
                                            Icons
                                                .diamond_outlined,
                                            color: Colors.black,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'SIGN IN',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight:
                                                  FontWeight.w800,
                                              letterSpacing: 1.2,
                                              fontSize: 15,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Icon(
                                            Icons.arrow_forward,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: TextButton(
                                onPressed: onSignup,
                                child: RichText(
                                  text: const TextSpan(
                                    text:
                                        "Don't have an account? ",
                                    style: TextStyle(
                                      color: AppColors
                                          .textSecondary,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign Up',
                                        style: TextStyle(
                                          color:
                                              AppColors.primary,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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