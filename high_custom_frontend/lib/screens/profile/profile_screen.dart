import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:high_custom_frontend/widgets/app_feedback.dart';

import '../../services/profile_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController
      _firstNameController =
      TextEditingController();

  final TextEditingController
      _lastNameController =
      TextEditingController();

  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _phoneController =
      TextEditingController();

  final TextEditingController
      _employerCodeController =
      TextEditingController();

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Uint8List? _profileImageBytes;

  String? _profileImageName;

  String? _profileImageUrl;

  // ============================================================
  // ACCOUNT
  // ============================================================

  bool _isEmailVerified = false;

  // ============================================================
  // LOADING
  // ============================================================

  bool _isLoading = true;

  bool _isSaving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employerCodeController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    final result =
        await ProfileApi.getProfile();

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      final dynamic userData =
          result['user'];

      if (userData is Map) {
        _firstNameController.text =
            userData['firstName']
                    ?.toString() ??
                '';

        _lastNameController.text =
            userData['lastName']
                    ?.toString() ??
                '';

        _emailController.text =
            userData['email']
                    ?.toString() ??
                '';

        _phoneController.text =
            userData['phone']
                    ?.toString() ??
                '';

        _employerCodeController.text =
            userData['employerCode']
                    ?.toString() ??
                '';

        _isEmailVerified =
            userData['isEmailVerified'] ==
                true;

        _profileImageUrl =
            ProfileApi.getImageUrl(
          userData['profileImage'],
        );
      }

      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });

      _showMessage(
        result['message'] ??
            'Unable to load profile.',
      );
    }
  }

  // ============================================================
  // PICK PROFILE IMAGE
  // ============================================================

  Future<void> _pickProfileImage() async {
    try {
      final FilePickerResult? result =
          await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'webp',
        ],
        allowMultiple: false,
        withData: true,
      );

      if (result == null) {
        return;
      }

      final PlatformFile file =
          result.files.first;

      // ========================================================
      // CHECK BYTES
      // ========================================================

      if (file.bytes == null) {
        _showMessage(
          'Unable to read the selected image.',
        );
        return;
      }

      // ========================================================
      // CHECK EXTENSION
      // ========================================================

      final String extension =
          (file.extension ?? '')
              .toLowerCase();

      const allowedExtensions = [
        'jpg',
        'jpeg',
        'png',
        'webp',
      ];

      if (!allowedExtensions
          .contains(extension)) {
        _showMessage(
          'Only JPG, JPEG, PNG or WEBP images are allowed.',
        );
        return;
      }

      // ========================================================
      // SET IMAGE
      // ========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _profileImageBytes =
            file.bytes;

        _profileImageName =
            file.name;
      });

      _showMessage(
        'Profile image selected successfully.',
      );
    } catch (error) {
      debugPrint(
        'PROFILE IMAGE ERROR: $error',
      );

      _showMessage(
        'Unable to select profile image.',
      );
    }
  }

  // ============================================================
  // REMOVE SELECTED IMAGE
  // ============================================================

  void _removeProfileImage() {
    if (_profileImageBytes == null) {
      return;
    }

    setState(() {
      _profileImageBytes = null;
      _profileImageName = null;
    });

    _showMessage(
      'Selected image removed.',
    );
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (_isSaving) {
      return;
    }

    // ========================================================
    // VALIDATION
    // ========================================================

    if (_firstNameController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'First name is required.',
      );
      return;
    }

    if (_lastNameController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Last name is required.',
      );
      return;
    }

    if (_emailController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Email address is required.',
      );
      return;
    }

    if (_phoneController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Phone number is required.',
      );
      return;
    }

    // ========================================================
    // START LOADING
    // ========================================================

    setState(() {
      _isSaving = true;
    });

    // ========================================================
    // UPDATE API
    // ========================================================

    final result =
        await ProfileApi.updateProfile(
      firstName:
          _firstNameController.text,
      lastName:
          _lastNameController.text,
      email:
          _emailController.text,
      phone:
          _phoneController.text,
      profileImageBytes:
          _profileImageBytes,
      profileImageName:
          _profileImageName,
    );

    if (!mounted) {
      return;
    }

    // ========================================================
    // SUCCESS
    // ========================================================

    if (result['success'] == true) {
      final dynamic user =
          result['user'];

      if (user is Map) {
        _profileImageUrl =
            ProfileApi.getImageUrl(
          user['profileImage'],
        );

        _isEmailVerified =
            user['isEmailVerified'] ==
                true;
      }

      setState(() {
        _isSaving = false;
        _profileImageBytes = null;
        _profileImageName = null;
      });

      _showMessage(
        'Profile updated successfully.',
      );

      return;
    }

    // ========================================================
    // ERROR
    // ========================================================

    setState(() {
      _isSaving = false;
    });

    _showMessage(
      result['message'] ??
          'Profile update failed.',
    );
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

    AppFeedback.show(context, message);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final double screenWidth =
        MediaQuery.of(context).size.width;

    final bool isMobile =
        screenWidth < 700;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color:
          const Color(0xFFF5F7FA),
      child: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  EdgeInsets.symmetric(
                horizontal:
                    isMobile ? 20 : 32,
                vertical:
                    isMobile ? 24 : 30,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(
                    isMobile: isMobile,
                  ),

                  SizedBox(
                    height:
                        isMobile ? 24 : 32,
                  ),

                  _buildProfileImageCard(
                    isMobile: isMobile,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  _buildPersonalInformationCard(
                    isMobile: isMobile,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  _buildAccountInformationCard(
                    isMobile: isMobile,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  _buildSaveButton(
                    isMobile: isMobile,
                  ),

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildPageHeader({
    required bool isMobile,
  }) {
    return Row(
      children: [
        Container(
          width:
              isMobile ? 54 : 60,
          height:
              isMobile ? 54 : 60,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFEFF4FF),
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.person_outline_rounded,
            color:
                const Color(0xFF315BEF),
            size:
                isMobile ? 27 : 30,
          ),
        ),

        const SizedBox(
          width: 15,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  color:
                      const Color(0xFF101828),
                  fontSize:
                      isMobile ? 26 : 30,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                'Manage your personal information and account details.',
                style: TextStyle(
                  color:
                      const Color(0xFF667085),
                  fontSize:
                      isMobile ? 13 : 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROFILE IMAGE CARD
  // ============================================================

  Widget _buildProfileImageCard({
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.all(
        isMobile ? 20 : 28,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE4E7EC),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.035,
            ),
            blurRadius: 15,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: isMobile
          ? _buildMobileProfileImageSection()
          : _buildDesktopProfileImageSection(),
    );
  }

  // ============================================================
  // DESKTOP IMAGE
  // ============================================================

  Widget _buildDesktopProfileImageSection() {
    return Row(
      children: [
        _buildProfileImage(),

        const SizedBox(
          width: 25,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile Photo',
                style: TextStyle(
                  color:
                      Color(0xFF101828),
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 7,
              ),

              const Text(
                'Upload a profile image that represents you.',
                style: TextStyle(
                  color:
                      Color(0xFF667085),
                  fontSize: 14,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Row(
                children: [
                  _buildImageButton(),

                  if (_profileImageBytes !=
                      null) ...[
                    const SizedBox(
                      width: 10,
                    ),
                    _buildRemoveImageButton(),
                  ],
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                'Supported: JPG, JPEG, PNG and WEBP.',
                style: TextStyle(
                  color:
                      Color(0xFF98A2B3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE IMAGE
  // ============================================================

  Widget _buildMobileProfileImageSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        _buildProfileImage(),

        const SizedBox(
          height: 18,
        ),

        const Text(
          'Profile Photo',
          style: TextStyle(
            color:
                Color(0xFF101828),
            fontSize: 18,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        const Text(
          'Upload a profile image that represents you.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color:
                Color(0xFF667085),
            fontSize: 14,
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        Wrap(
          alignment:
              WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildImageButton(),

            if (_profileImageBytes !=
                null)
              _buildRemoveImageButton(),
          ],
        ),

        const SizedBox(
          height: 10,
        ),

        const Text(
          'Supported: JPG, JPEG, PNG and WEBP.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color:
                Color(0xFF98A2B3),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _buildProfileImage() {
    Widget image;

    if (_profileImageBytes != null) {
      image = Image.memory(
        _profileImageBytes!,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
      );
    } else if (_profileImageUrl != null) {
      image = Image.network(
        _profileImageUrl!,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
        errorBuilder:
            (
          context,
          error,
          stackTrace,
        ) {
          return _defaultProfileIcon();
        },
        loadingBuilder:
            (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress ==
              null) {
            return child;
          }

          return const Center(
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        },
      );
    } else {
      image =
          _defaultProfileIcon();
    }

    return Stack(
      clipBehavior:
          Clip.none,
      children: [
        Container(
          width: 118,
          height: 118,
          padding:
              const EdgeInsets.all(4),
          decoration:
              BoxDecoration(
            shape:
                BoxShape.circle,
            gradient:
                const LinearGradient(
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
              colors: [
                Color(0xFF315BEF),
                Color(0xFF6D8BFF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF315BEF,
                ).withOpacity(0.18),
                blurRadius: 20,
                offset:
                    const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            padding:
                const EdgeInsets.all(3),
            decoration:
                const BoxDecoration(
              shape:
                  BoxShape.circle,
              color:
                  Colors.white,
            ),
            child: ClipOval(
              child: image,
            ),
          ),
        ),

        Positioned(
          right: -2,
          bottom: 2,
          child:
              GestureDetector(
            onTap:
                _pickProfileImage,
            child: Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFF315BEF),
                shape:
                    BoxShape.circle,
                border:
                    Border.all(
                  color:
                      Colors.white,
                  width: 3,
                ),
              ),
              child:
                  const Icon(
                Icons
                    .camera_alt_rounded,
                color:
                    Colors.white,
                size: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DEFAULT IMAGE
  // ============================================================

  Widget _defaultProfileIcon() {
    return Container(
      width: 104,
      height: 104,
      color:
          const Color(0xFFF2F4F7),
      child: const Icon(
        Icons.person_rounded,
        size: 58,
        color:
            Color(0xFF98A2B3),
      ),
    );
  }

  // ============================================================
  // IMAGE BUTTON
  // ============================================================

  Widget _buildImageButton() {
    return ElevatedButton.icon(
      onPressed:
          _pickProfileImage,
      icon: const Icon(
        Icons.upload_rounded,
        size: 18,
      ),
      label: const Text(
        'Change Photo',
      ),
      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            const Color(0xFF315BEF),
        foregroundColor:
            Colors.white,
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(9),
        ),
      ),
    );
  }

  // ============================================================
  // REMOVE BUTTON
  // ============================================================

  Widget _buildRemoveImageButton() {
    return OutlinedButton.icon(
      onPressed:
          _removeProfileImage,
      icon: const Icon(
        Icons.delete_outline_rounded,
        size: 18,
      ),
      label: const Text(
        'Remove',
      ),
      style:
          OutlinedButton.styleFrom(
        foregroundColor:
            const Color(0xFFD92D20),
        side:
            const BorderSide(
          color:
              Color(0xFFF04438),
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(9),
        ),
      ),
    );
  }

  // ============================================================
  // PERSONAL INFORMATION
  // ============================================================

  Widget _buildPersonalInformationCard({
    required bool isMobile,
  }) {
    return _buildSectionCard(
      title:
          'Personal Information',
      subtitle:
          'Update your personal information and contact details.',
      icon:
          Icons.person_outline_rounded,
      child: isMobile
          ? Column(
              children: [
                _buildTextField(
                  label:
                      'First Name',
                  controller:
                      _firstNameController,
                  icon:
                      Icons.person_outline,
                ),
                const SizedBox(
                  height: 16,
                ),
                _buildTextField(
                  label:
                      'Last Name',
                  controller:
                      _lastNameController,
                  icon:
                      Icons.person_outline,
                ),
                const SizedBox(
                  height: 16,
                ),
                _buildTextField(
                  label:
                      'Email Address',
                  controller:
                      _emailController,
                  icon:
                      Icons.email_outlined,
                  keyboardType:
                      TextInputType.emailAddress,
                ),
                const SizedBox(
                  height: 16,
                ),
                _buildTextField(
                  label:
                      'Phone Number',
                  controller:
                      _phoneController,
                  icon:
                      Icons.phone_outlined,
                  keyboardType:
                      TextInputType.phone,
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          _buildTextField(
                        label:
                            'First Name',
                        controller:
                            _firstNameController,
                        icon:
                            Icons.person_outline,
                      ),
                    ),
                    const SizedBox(
                      width: 18,
                    ),
                    Expanded(
                      child:
                          _buildTextField(
                        label:
                            'Last Name',
                        controller:
                            _lastNameController,
                        icon:
                            Icons.person_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 18,
                ),
                Row(
                  children: [
                    Expanded(
                      child:
                          _buildTextField(
                        label:
                            'Email Address',
                        controller:
                            _emailController,
                        icon:
                            Icons.email_outlined,
                        keyboardType:
                            TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(
                      width: 18,
                    ),
                    Expanded(
                      child:
                          _buildTextField(
                        label:
                            'Phone Number',
                        controller:
                            _phoneController,
                        icon:
                            Icons.phone_outlined,
                        keyboardType:
                            TextInputType.phone,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  // ============================================================
  // ACCOUNT INFORMATION
  // ============================================================

  Widget _buildAccountInformationCard({
    required bool isMobile,
  }) {
    return _buildSectionCard(
      title:
          'Account Information',
      subtitle:
          'Information related to your application account.',
      icon:
          Icons.manage_accounts_outlined,
      child: isMobile
          ? Column(
              children: [
                _buildTextField(
                  label:
                      'Employer Code',
                  controller:
                      _employerCodeController,
                  icon:
                      Icons.badge_outlined,
                  readOnly: true,
                ),
                const SizedBox(
                  height: 16,
                ),
                _buildReadOnlyField(
                  label:
                      'Account Status',
                  value:
                      'Active',
                  icon:
                      Icons.verified_outlined,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child:
                      _buildTextField(
                    label:
                        'Employer Code',
                    controller:
                        _employerCodeController,
                    icon:
                        Icons.badge_outlined,
                    readOnly: true,
                  ),
                ),
                const SizedBox(
                  width: 18,
                ),
                Expanded(
                  child:
                      _buildReadOnlyField(
                    label:
                        'Account Status',
                    value:
                        'Active',
                    icon:
                        Icons.verified_outlined,
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE4E7EC),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.035,
            ),
            blurRadius: 15,
            offset:
                const Offset(0, 5),
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
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFEFF4FF),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(0xFF315BEF),
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF101828),
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF667085),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
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
                Color(0xFF344054),
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        TextField(
          controller:
              controller,
          keyboardType:
              keyboardType,
          readOnly:
              readOnly,
          style:
              const TextStyle(
            color:
                Color(0xFF101828),
            fontSize: 14,
          ),
          decoration:
              InputDecoration(
            prefixIcon:
                Icon(
              icon,
              color:
                  const Color(0xFF98A2B3),
              size: 20,
            ),
            filled:
                true,
            fillColor:
                readOnly
                    ? const Color(
                        0xFFF2F4F7,
                      )
                    : const Color(
                        0xFFF9FAFB,
                      ),
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 14,
              vertical: 14,
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
                    Color(0xFFD0D5DD),
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
                    Color(0xFFD0D5DD),
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
                    Color(0xFF315BEF),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // READ ONLY FIELD
  // ============================================================

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
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
                Color(0xFF344054),
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        TextField(
          readOnly: true,
          controller:
              TextEditingController(
            text: value,
          ),
          style:
              const TextStyle(
            color:
                Color(0xFF027A48),
            fontSize: 14,
            fontWeight:
                FontWeight.w600,
          ),
          decoration:
              InputDecoration(
            prefixIcon:
                Icon(
              icon,
              color:
                  const Color(0xFF12B76A),
              size: 20,
            ),
            suffixIcon:
                Container(
              margin:
                  const EdgeInsets.all(
                10,
              ),
              width: 8,
              height: 8,
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFF12B76A),
                shape:
                    BoxShape.circle,
              ),
            ),
            filled:
                true,
            fillColor:
                const Color(0xFFECFDF3),
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 14,
              vertical: 14,
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
                    Color(0xFFA6F4C5),
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
                    Color(0xFFA6F4C5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton({
    required bool isMobile,
  }) {
    return Align(
      alignment:
          isMobile
              ? Alignment.center
              : Alignment.centerRight,
      child: SizedBox(
        height: 48,
        child:
            ElevatedButton.icon(
          onPressed:
              _isSaving
                  ? null
                  : _saveProfile,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        Colors.white,
                  ),
                )
              : const Icon(
                  Icons.check_rounded,
                  size: 19,
                ),
          label: Text(
            _isSaving
                ? 'Saving...'
                : 'Save Changes',
          ),
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF315BEF),
            foregroundColor:
                Colors.white,
            disabledBackgroundColor:
                const Color(
              0xFF8FA7F5,
            ),
            elevation: 0,
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 24,
            ),
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
    );
  }
}
