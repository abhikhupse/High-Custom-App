import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../constants/colors.dart';
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
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  int _stepIndex = 0;

  bool get _isLoading => widget.controller.isLoading;

  void _nextStep() {
    if (!widget.formKey.currentState!.validate()) {
      return;
    }

    if (_stepIndex < 2) {
      setState(() {
        _stepIndex += 1;
      });
    } else {
      widget.onSubmit();
    }
  }

  void _previousStep() {
    if (_stepIndex > 0) {
      setState(() {
        _stepIndex -= 1;
      });
    }
  }

  List<Widget> _stepFields(bool isNarrow) {
    Widget personalFields() {
      if (isNarrow) {
        return Column(
          children: [
            _buildTextField(
              label: 'First Name',
              hint: 'First Name',
              controller: widget.controller.firstNameController,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12, right: 6),
                child: Icon(Icons.person_outline, color: AppColors.textSecondary),
              ),
              validator: _stepIndex == 0 ? widget.controller.validateFirstName : (_) => null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Last Name',
              hint: 'Last Name',
              controller: widget.controller.lastNameController,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12, right: 6),
                child: Icon(Icons.person_outline, color: AppColors.textSecondary),
              ),
              validator: _stepIndex == 0 ? widget.controller.validateLastName : (_) => null,
            ),
            const SizedBox(height: 18),
            _buildTextField(
              label: 'Employer Code',
              hint: 'Employer Code',
              controller: widget.controller.employerCodeController,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12, right: 6),
                child: Icon(Icons.badge_outlined, color: AppColors.textSecondary),
              ),
              validator: _stepIndex == 0 ? widget.controller.validateEmployerCode : (_) => null,
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
                  hint: 'First Name',
                  controller: widget.controller.firstNameController,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 6),
                    child: Icon(Icons.person_outline, color: AppColors.textSecondary),
                  ),
                  validator: _stepIndex == 0 ? widget.controller.validateFirstName : (_) => null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Last Name',
                  hint: 'Last Name',
                  controller: widget.controller.lastNameController,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 6),
                    child: Icon(Icons.person_outline, color: AppColors.textSecondary),
                  ),
                  validator: _stepIndex == 0 ? widget.controller.validateLastName : (_) => null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildTextField(
            label: 'Employer Code',
            hint: 'Employer Code',
            controller: widget.controller.employerCodeController,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12, right: 6),
              child: Icon(Icons.badge_outlined, color: AppColors.textSecondary),
            ),
            validator: _stepIndex == 0 ? widget.controller.validateEmployerCode : (_) => null,
          ),
        ],
      );
    }

    return [
      personalFields(),
      Column(
        children: [
          _buildTextField(
            label: 'Email Address',
            hint: 'Email Address',
            controller: widget.controller.emailController,
            keyboardType: TextInputType.emailAddress,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12, right: 6),
              child: Icon(Icons.email_outlined, color: AppColors.textSecondary),
            ),
            validator: _stepIndex == 1 ? widget.controller.validateEmail : (_) => null,
          ),
          const SizedBox(height: 18),
          _buildTextField(
            label: 'Phone Number',
            hint: '98765 43210',
            controller: widget.controller.phoneController,
            keyboardType: TextInputType.phone,
            borderColor: AppColors.primary,
            fillColor: const Color(0xFF091012),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 16, right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇮🇳', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text('+91', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            validator: _stepIndex == 1 ? widget.controller.validatePhone : (_) => null,
          ),
        ],
      ),
      Column(
        children: [
          _buildTextField(
            label: 'Password',
            hint: '••••••••',
            controller: widget.controller.passwordController,
            obscureText: widget.controller.obscurePassword,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12, right: 6),
              child: Icon(Icons.lock_outline, color: AppColors.textSecondary),
            ),
            suffixIcon: IconButton(
              onPressed: widget.controller.togglePasswordVisibility,
              icon: Icon(
                widget.controller.obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
            ),
            validator: _stepIndex == 2 ? widget.controller.validatePassword : (_) => null,
          ),
          const SizedBox(height: 18),
          _buildTextField(
            label: 'Confirm Password',
            hint: 'Confirm password',
            controller: widget.controller.confirmPasswordController,
            obscureText: widget.controller.obscureConfirmPassword,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12, right: 6),
              child: Icon(Icons.lock_outline, color: AppColors.textSecondary),
            ),
            suffixIcon: IconButton(
              onPressed: widget.controller.toggleConfirmPasswordVisibility,
              icon: Icon(
                widget.controller.obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
            ),
            validator: _stepIndex == 2 ? widget.controller.validateConfirmPassword : (_) => null,
          ),
        ],
      ),
    ];
  }

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
    Color borderColor = const Color(0xFF2C2C2C),
    Color fillColor = const Color(0xFF111419),
    Widget? suffixIcon,
    Widget? prefix,
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
          style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.35),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 16),
            filled: true,
            fillColor: fillColor,
            prefixIcon: prefix,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final labels = ['Personal', 'Contact', 'Security'];
    return Column(
      children: [
        Row(
          children: List.generate(labels.length, (index) {
            final active = index == _stepIndex;
            return Expanded(
              child: Container(
                height: 10,
                margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : const Color(0xFF20262B),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Row(
          children: labels.map((label) {
            final isActive = labels.indexOf(label) == _stepIndex;
            return Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepSection(bool isNarrow) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: isNarrow ? 280 : 320),
        child: _stepFields(isNarrow)[_stepIndex],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isSmallScreen ? 16.0 : 22.0;
    final contentSpacing = isSmallScreen ? 20.0 : 28.0;
    final minBodyHeight = screenHeight - (isSmallScreen ? 40 : 80);

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
                colors: [AppColors.primary.withAlpha(46), Colors.transparent],
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
                colors: [AppColors.primary.withAlpha(36), Colors.transparent],
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minBodyHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF071112),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(color: AppColors.primary.withAlpha(190), width: 1.4),
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
                          horizontal: isSmallScreen ? 22 : 28,
                          vertical: isSmallScreen ? 26 : 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'HIGH CUSTOM JEWELLERS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: isSmallScreen ? 24 : 28,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildStepIndicator(),
                                ],
                              ),
                            ),
                            SizedBox(height: contentSpacing),
                            Form(
                              key: widget.formKey,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildStepSection(isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 24 : 30),
                                  if (isSmallScreen)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (_stepIndex > 0)
                                          SizedBox(
                                            height: 56,
                                            child: TextButton(
                                              onPressed: _previousStep,
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppColors.primary,
                                                textStyle: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              child: const Text('Back'),
                                            ),
                                          ),
                                        if (_stepIndex > 0) const SizedBox(height: 12),
                                        SizedBox(
                                          height: 56,
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : _nextStep,
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 18),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.black,
                                              elevation: 12,
                                              shadowColor: AppColors.primary.withAlpha(80),
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.black,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.diamond_outlined, color: Colors.black),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        _stepIndex < 2 ? 'NEXT' : 'CREATE ACCOUNT',
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.w800,
                                                          letterSpacing: 1.2,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Icon(Icons.arrow_forward, color: Colors.black),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      children: [
                                        if (_stepIndex > 0)
                                          Expanded(
                                            child: TextButton(
                                              onPressed: _previousStep,
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppColors.primary,
                                                textStyle: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              child: const Text('Back'),
                                            ),
                                          )
                                        else
                                          const Expanded(child: SizedBox()),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: SizedBox(
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _nextStep,
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 18),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: Colors.black,
                                                elevation: 12,
                                                shadowColor: AppColors.primary.withAlpha(80),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        color: Colors.black,
                                                      ),
                                                    )
                                                  : Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.diamond_outlined, color: Colors.black),
                                                        const SizedBox(width: 12),
                                                        Text(
                                                          _stepIndex < 2 ? 'NEXT' : 'CREATE ACCOUNT',
                                                          style: const TextStyle(
                                                            color: Colors.black,
                                                            fontWeight: FontWeight.w800,
                                                            letterSpacing: 1.2,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        const Icon(Icons.arrow_forward, color: Colors.black),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  SizedBox(height: isSmallScreen ? 18 : 24),
                                  Center(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Already have access? ',
                                        style: const TextStyle(color: AppColors.textSecondary),
                                        children: [
                                          TextSpan(
                                            text: 'Log In',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = widget.onLogin,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
