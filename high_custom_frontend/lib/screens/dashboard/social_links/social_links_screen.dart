import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:high_custom_frontend/services/social_links_api.dart';

import 'create_business_card_screen.dart';
import 'social_qr_list_screen.dart';

// ============================================================
// SOCIAL LINKS SCREEN
// ============================================================

class SocialLinksScreen extends StatefulWidget {
  const SocialLinksScreen({super.key});

  @override
  State<SocialLinksScreen> createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends State<SocialLinksScreen> {
  final GlobalKey<FormState> _addLinkFormKey = GlobalKey<FormState>();
  final TextEditingController _platformNameController = TextEditingController();
  final TextEditingController _platformUrlController = TextEditingController();

  // ============================================================
  // COLORS
  // ============================================================

  static const Color pageBackground = Color(0xFF090A0C);
  static const Color surface = Color(0xFF101113);
  static const Color surface2 = Color(0xFF151619);
  static const Color borderColor = Color(0xFF292B2F);

  static const Color white = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFFECEDEF);
  static const Color mutedText = Color(0xFF9B9CA3);

  static const Color gold = Color(0xFFF2C45F);
  static const Color purple = Color(0xFFF2C45F);
  static const Color red = Color(0xFFFF5B66);

  // ============================================================
  // EXPANSION STATE
  // ============================================================

  bool socialExpanded = true;
  bool ecommerceExpanded = false;
  bool paymentExpanded = false;
  bool customExpanded = true;

  // ============================================================
  // Links are loaded from the signed-in admin's Render account.
  // ============================================================

  final List<Map<String, dynamic>> socialLinks = [];

  // ============================================================
  // Empty until an admin creates a link in the matching category.
  // ============================================================

  final List<Map<String, dynamic>> ecommerceLinks = [];

  // ============================================================
  // Payment links are also admin-managed.
  // ============================================================

  final List<Map<String, dynamic>> paymentLinks = [];

  final List<Map<String, dynamic>> customLinks = [];

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  @override
  void dispose() {
    _platformNameController.dispose();
    _platformUrlController.dispose();
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
            final bool isMobile = constraints.maxWidth < 800;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isMobile ? 14 : 28,
                isMobile ? 16 : 28,
                isMobile ? 14 : 28,
                35,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 950),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(isMobile),

                      const SizedBox(height: 16),

                      _buildLinksCard(isMobile),
                    ],
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
  // HEADER
  // ============================================================

  Widget _buildHeaderCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBusinessTitle(),

                const SizedBox(height: 18),

                _blueActionButton(
                  icon: Icons.qr_code_2_rounded,
                  label: 'VIEW ALL QR',
                  onTap: _openQrList,
                ),

                const SizedBox(height: 10),

                _outlineActionButton(
                  icon: Icons.badge_outlined,
                  label: 'BUSINESS CARD',
                  onTap: _openBusinessCard,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildBusinessTitle()),

                _blueActionButton(
                  icon: Icons.qr_code_2_rounded,
                  label: 'VIEW ALL QR',
                  onTap: _openQrList,
                ),

                const SizedBox(width: 10),

                _outlineActionButton(
                  icon: Icons.badge_outlined,
                  label: 'BUSINESS CARD',
                  onTap: _openBusinessCard,
                ),
              ],
            ),
    );
  }

  void _openBusinessCard() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateBusinessCardScreen()));
  }

  // ============================================================
  // BUSINESS TITLE
  // ============================================================

  Widget _buildBusinessTitle() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF2C45F), Color(0xFFD9A93F)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.qr_code_rounded,
            color: Color(0xFF090A0C),
            size: 30,
          ),
        ),

        const SizedBox(width: 14),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Digital Business Card',
                softWrap: true,
                style: TextStyle(
                  color: white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),

              SizedBox(height: 6),

              Text(
                'Smart Social Links Manager',
                style: TextStyle(color: mutedText, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LINKS CARD
  // ============================================================

  Widget _buildLinksCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _outlineActionButton(
            icon: Icons.save_outlined,
            label: 'SAVE LINKS',
            onTap: _saveLinks,
          ),

          const SizedBox(height: 10),

          // ======================================================
          // GENERATE QR
          // ======================================================
          _purpleActionButton(
            icon: Icons.qr_code_2_rounded,
            label: 'Generate QR Code',
            onTap: _generateQrCodes,
          ),

          const SizedBox(height: 18),

          // ======================================================
          // SOCIAL
          // ======================================================
          _buildExpandableSection(
            title: 'Social Media Links',
            subtitle: '${socialLinks.length} links',
            icon: Icons.share_rounded,
            expanded: socialExpanded,
            children: socialLinks,
            emptyMessage: 'No social media links added yet.',
            onTap: () {
              setState(() {
                socialExpanded = !socialExpanded;
              });
            },
          ),

          const SizedBox(height: 12),

          // ======================================================
          // E-COMMERCE
          // ======================================================
          _buildExpandableSection(
            title: 'E-commerce Links',
            subtitle: '${ecommerceLinks.length} links',
            icon: Icons.shopping_cart_outlined,
            expanded: ecommerceExpanded,
            children: ecommerceLinks,
            emptyMessage: 'No e-commerce links added yet.',
            onTap: () {
              setState(() {
                ecommerceExpanded = !ecommerceExpanded;
              });
            },
          ),

          const SizedBox(height: 12),

          // ======================================================
          // PAYMENT
          // ======================================================
          _buildExpandableSection(
            title: 'Payment Gateways',
            subtitle: '${paymentLinks.length} links',
            icon: Icons.credit_card_rounded,
            expanded: paymentExpanded,
            children: paymentLinks,
            emptyMessage: 'No payment links added yet.',
            onTap: () {
              setState(() {
                paymentExpanded = !paymentExpanded;
              });
            },
          ),

          const SizedBox(height: 12),

          _buildExpandableSection(
            title: 'Custom Links',
            subtitle: '${customLinks.length} links',
            icon: Icons.add_link_rounded,
            expanded: customExpanded,
            children: customLinks,
            emptyMessage: 'Your custom links will appear here.',
            onTap: () {
              setState(() {
                customExpanded = !customExpanded;
              });
            },
          ),

          const SizedBox(height: 18),

          _buildAddLinkForm(isMobile),
        ],
      ),
    );
  }

  Widget _buildAddLinkForm(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Form(
        key: _addLinkFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.add_link_rounded, color: gold, size: 21),
                SizedBox(width: 10),
                Text(
                  'Add a New Link',
                  style: TextStyle(
                    color: lightText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isMobile) ...[
              _addLinkInput(
                controller: _platformNameController,
                label: 'Platform Name',
                hint: 'Example: Pinterest',
                icon: Icons.apps_rounded,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a platform name.'
                    : null,
              ),
              const SizedBox(height: 12),
              _addLinkInput(
                controller: _platformUrlController,
                label: 'Platform URL',
                hint: 'https://example.com/your-page',
                icon: Icons.link_rounded,
                keyboardType: TextInputType.url,
                validator: _validatePlatformUrl,
                onFieldSubmitted: (_) => _addNewLink(),
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _addLinkInput(
                      controller: _platformNameController,
                      label: 'Platform Name',
                      hint: 'Example: Pinterest',
                      icon: Icons.apps_rounded,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a platform name.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _addLinkInput(
                      controller: _platformUrlController,
                      label: 'Platform URL',
                      hint: 'https://example.com/your-page',
                      icon: Icons.link_rounded,
                      keyboardType: TextInputType.url,
                      validator: _validatePlatformUrl,
                      onFieldSubmitted: (_) => _addNewLink(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _addNewLink,
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('Add Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: pageBackground,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addLinkInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      cursorColor: gold,
      style: const TextStyle(color: white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: mutedText),
        hintStyle: const TextStyle(color: Color(0xFF676970)),
        prefixIcon: Icon(icon, color: mutedText, size: 19),
        filled: true,
        fillColor: pageBackground,
        errorStyle: const TextStyle(color: red),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: gold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: red),
        ),
      ),
    );
  }

  String? _validatePlatformUrl(String? value) {
    final String url = value?.trim() ?? '';
    if (url.isEmpty) {
      return 'Enter a platform URL.';
    }

    final Uri? parsedUrl = Uri.tryParse(url);
    if (parsedUrl == null ||
        !parsedUrl.hasScheme ||
        (parsedUrl.scheme != 'http' && parsedUrl.scheme != 'https') ||
        parsedUrl.host.isEmpty) {
      return 'Enter a valid URL starting with http:// or https://.';
    }

    return null;
  }

  Future<void> _addNewLink() async {
    if (_addLinkFormKey.currentState?.validate() != true) {
      return;
    }

    final String name = _platformNameController.text.trim();
    final String url = _platformUrlController.text.trim();

    final response = await SocialLinksApi.create(
      name: name,
      url: url,
      platform: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''),
    );
    if (!mounted) return;
    if (response['success'] != true || response['data'] is! Map) {
      _showMessage(response['message']?.toString() ?? 'Could not add link.');
      return;
    }

    setState(() {
      customLinks.insert(0, Map<String, dynamic>.from(response['data'] as Map));
      customExpanded = true;
    });

    _platformNameController.clear();
    _platformUrlController.clear();
    _addLinkFormKey.currentState?.reset();
    FocusScope.of(context).unfocus();
    _showMessage('$name link added successfully.');
  }

  Future<void> _saveLinks() async {
    final allLinks = [
      ...socialLinks,
      ...ecommerceLinks,
      ...paymentLinks,
      ...customLinks,
    ];
    final responses = await Future.wait(allLinks.map((link) => SocialLinksApi.update(
          link['_id'].toString(),
          selected: link['selected'] == true,
        )));
    if (!mounted) return;
    if (responses.every((response) => response['success'] == true)) {
      _showMessage('${_getSelectedLinks().length} selected links saved.');
    } else {
      _showMessage('Some selected links could not be saved.');
    }
  }

  Future<void> _loadLinks() async {
    final response = await SocialLinksApi.list();
    if (!mounted || response['success'] != true || response['data'] is! List) return;
    final links = (response['data'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    setState(() {
      socialLinks
        ..clear()
        ..addAll(links.where((link) => link['category'] == 'social'));
      ecommerceLinks
        ..clear()
        ..addAll(links.where((link) => link['category'] == 'ecommerce'));
      paymentLinks
        ..clear()
        ..addAll(links.where((link) => link['category'] == 'payment'));
      customLinks
        ..clear()
        ..addAll(links.where((link) => link['category'] == 'custom'));
    });
  }

  Future<void> _generateQrCodes() async {
    final selected = _getSelectedLinks();
    if (selected.isEmpty) {
      _showMessage('Please select at least one link.');
      return;
    }
    final response = await SocialLinksApi.generateQr(
      selected.map((link) => link['_id'].toString()).toList(),
    );
    if (!mounted) return;
    if (response['success'] == true) {
      await _loadLinks();
      if (mounted) _showMessage('${selected.length} QR code(s) generated.');
    } else {
      _showMessage(response['message']?.toString() ?? 'Could not generate QR codes.');
    }
  }

  void _openQrList() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocialQrListScreen()));
  }

  // ============================================================
  // EXPANDABLE SECTION
  // ============================================================

  Widget _buildExpandableSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool expanded,
    required VoidCallback onTap,
    required List<Map<String, dynamic>> children,
    String? emptyMessage,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: purple.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: gold, size: 19),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: lightText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: mutedText,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    AnimatedRotation(
                      duration: const Duration(milliseconds: 180),
                      turns: expanded ? 0.5 : 0,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: lightText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (expanded) ...[
            Container(height: 1, color: borderColor),

            if (children.isEmpty && emptyMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Text(
                  emptyMessage,
                  style: const TextStyle(color: mutedText, fontSize: 12),
                ),
              ),

            ...List.generate(children.length, (index) {
              return _buildSavedLink(
                source: children,
                index: index,
                showBottomBorder: index != children.length - 1,
              );
            }),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SAVED LINK
  // ============================================================

  Widget _buildSavedLink({
    required List<Map<String, dynamic>> source,
    required int index,
    required bool showBottomBorder,
  }) {
    final Map<String, dynamic> link = source[index];

    final String name = link['name']?.toString() ?? '';

    final String url = link['url']?.toString() ?? '';

    final String platform = link['platform']?.toString() ?? '';

    final bool checked = link['selected'] == true;

    return InkWell(
      onTap: () {
        // ========================================================
        // ROW TAP ALSO TOGGLES CHECKBOX
        // ========================================================

        setState(() {
          source[index]['selected'] = !checked;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: checked ? purple.withOpacity(0.07) : Colors.transparent,
          border: showBottomBorder
              ? const Border(bottom: BorderSide(color: borderColor))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        child: Row(
          children: [
            // ====================================================
            // CHECKBOX
            // ====================================================
            SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Checkbox(
                  value: checked,
                  activeColor: purple,
                  checkColor: white,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  side: const BorderSide(color: Color(0xFF727987), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (value) {
                    // ============================================
                    // FIXED TICK / UNTICK
                    // ============================================

                    setState(() {
                      source[index]['selected'] = value ?? false;
                    });
                  },
                ),
              ),
            ),

            // ====================================================
            // PLATFORM LOGO
            // ====================================================
            _buildPlatformLogo(platform),

            const SizedBox(width: 11),

            // ====================================================
            // NAME + URL
            // ====================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: lightText,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: mutedText, fontSize: 10.5),
                  ),
                ],
              ),
            ),

            // ====================================================
            // COPY
            // ====================================================
            IconButton(
              tooltip: 'Copy Link',
              onPressed: () async {
                _copyLink(url);
              },
              icon: const Icon(
                Icons.content_copy_rounded,
                color: Color(0xFF9CA2AF),
                size: 18,
              ),
            ),

            // ====================================================
            // THREE DOTS
            // ====================================================
            PopupMenuButton<String>(
              tooltip: 'Options',
              color: surface2,
              elevation: 14,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: borderColor),
              ),
              icon: const Icon(
                Icons.more_vert_rounded,
                color: lightText,
                size: 21,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(source: source, index: index);
                }

                if (value == 'delete') {
                  _showDeleteDialog(source: source, index: index);
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: gold, size: 18),

                        SizedBox(width: 11),

                        Text(
                          'Edit',
                          style: TextStyle(color: lightText, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: red,
                          size: 18,
                        ),

                        SizedBox(width: 11),

                        Text(
                          'Delete',
                          style: TextStyle(color: red, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PLATFORM LOGO
  // ============================================================

  Widget _buildPlatformLogo(String platform) {
    IconData icon = Icons.link_rounded;

    Color iconColor = purple;

    Color background = purple.withOpacity(0.12);

    switch (platform.toLowerCase()) {
      // ========================================================
      // SOCIAL MEDIA
      // ========================================================

      case 'instagram':
        icon = Icons.camera_alt_rounded;
        iconColor = const Color(0xFFE1306C);
        background = const Color(0xFFE1306C).withOpacity(0.12);
        break;

      case 'facebook':
        icon = Icons.facebook_rounded;
        iconColor = const Color(0xFF1877F2);
        background = const Color(0xFF1877F2).withOpacity(0.12);
        break;

      case 'whatsapp':
        icon = Icons.chat_rounded;
        iconColor = const Color(0xFF25D366);
        background = const Color(0xFF25D366).withOpacity(0.12);
        break;

      case 'youtube':
        icon = Icons.play_circle_fill_rounded;
        iconColor = const Color(0xFFFF0000);
        background = const Color(0xFFFF0000).withOpacity(0.12);
        break;

      case 'linkedin':
        icon = Icons.business_center_rounded;
        iconColor = const Color(0xFF0A66C2);
        background = const Color(0xFF0A66C2).withOpacity(0.12);
        break;

      // ========================================================
      // E-COMMERCE
      // ========================================================

      case 'amazon':
        icon = Icons.shopping_bag_rounded;
        iconColor = const Color(0xFFFF9900);
        background = const Color(0xFFFF9900).withOpacity(0.12);
        break;

      case 'flipkart':
        icon = Icons.shopping_cart_rounded;
        iconColor = const Color(0xFFFFD814);
        background = const Color(0xFFFFD814).withOpacity(0.10);
        break;

      case 'meesho':
        icon = Icons.storefront_rounded;
        iconColor = const Color(0xFFF43397);
        background = const Color(0xFFF43397).withOpacity(0.12);
        break;

      case 'myntra':
        icon = Icons.local_mall_rounded;
        iconColor = const Color(0xFFFF3F6C);
        background = const Color(0xFFFF3F6C).withOpacity(0.12);
        break;

      case 'website':
        icon = Icons.language_rounded;
        iconColor = const Color(0xFF65A6FF);
        background = const Color(0xFF65A6FF).withOpacity(0.12);
        break;

      // ========================================================
      // PAYMENT
      // ========================================================

      case 'googlepay':
        icon = Icons.account_balance_wallet_rounded;
        iconColor = const Color(0xFF4285F4);
        background = const Color(0xFF4285F4).withOpacity(0.12);
        break;

      case 'phonepe':
        icon = Icons.account_balance_wallet_rounded;
        iconColor = const Color(0xFF6739B7);
        background = const Color(0xFF6739B7).withOpacity(0.14);
        break;

      case 'paytm':
        icon = Icons.payments_rounded;
        iconColor = const Color(0xFF00BAF2);
        background = const Color(0xFF00BAF2).withOpacity(0.12);
        break;

      case 'paypal':
        icon = Icons.payments_rounded;
        iconColor = const Color(0xFF0070BA);
        background = const Color(0xFF0070BA).withOpacity(0.14);
        break;

      case 'razorpay':
        icon = Icons.credit_card_rounded;
        iconColor = const Color(0xFF528FF0);
        background = const Color(0xFF528FF0).withOpacity(0.12);
        break;
    }

    return Container(
      width: 41,
      height: 41,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  // ============================================================
  // SELECTED LINKS
  // ============================================================

  List<Map<String, dynamic>> _getSelectedLinks() {
    return [
      ...socialLinks.where((link) => link['selected'] == true),
      ...ecommerceLinks.where((link) => link['selected'] == true),
      ...paymentLinks.where((link) => link['selected'] == true),
      ...customLinks.where((link) => link['selected'] == true),
    ];
  }

  // ============================================================
  // COPY LINK
  // ============================================================

  Future<void> _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));

    if (!mounted) {
      return;
    }

    _showMessage('Link copied successfully.');
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _showEditDialog({
    required List<Map<String, dynamic>> source,
    required int index,
  }) async {
    final TextEditingController nameController = TextEditingController(
      text: source[index]['name']?.toString() ?? '',
    );

    final TextEditingController urlController = TextEditingController(
      text: source[index]['url']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surface2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: borderColor),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_outlined, color: gold),

              SizedBox(width: 10),

              Text(
                'Edit Link',
                style: TextStyle(
                  color: white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogInput(
                  controller: nameController,
                  hint: 'Link Name',
                  icon: Icons.apps_rounded,
                ),

                const SizedBox(height: 12),

                _dialogInput(
                  controller: urlController,
                  hint: 'Link URL',
                  icon: Icons.link_rounded,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel', style: TextStyle(color: mutedText)),
            ),

            ElevatedButton.icon(
              onPressed: () async {
                final String name = nameController.text.trim();

                final String url = urlController.text.trim();

                if (name.isEmpty || url.isEmpty) {
                  _showMessage('Please complete both fields.');

                  return;
                }

                final response = await SocialLinksApi.update(
                  source[index]['_id'].toString(),
                  name: name,
                  url: url,
                );
                if (response['success'] != true) {
                  _showMessage(response['message']?.toString() ?? 'Could not update link.');
                  return;
                }
                if (!dialogContext.mounted) return;
                setState(() {
                  source[index]
                    ..['name'] = name
                    ..['url'] = url;
                });
                Navigator.pop(dialogContext);
                _showMessage('Link updated successfully.');
              },
              icon: const Icon(Icons.save_outlined, size: 17),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: white,
              ),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    urlController.dispose();
  }

  // ============================================================
  // DIALOG INPUT
  // ============================================================

  Widget _dialogInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      cursorColor: purple,
      style: const TextStyle(color: white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: mutedText),
        prefixIcon: Icon(icon, color: mutedText, size: 19),
        filled: true,
        fillColor: pageBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: purple),
        ),
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _showDeleteDialog({
    required List<Map<String, dynamic>> source,
    required int index,
  }) async {
    final String name = source[index]['name']?.toString() ?? 'this link';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surface2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: borderColor),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: red),

              SizedBox(width: 10),

              Text(
                'Delete Link',
                style: TextStyle(
                  color: white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete $name?',
            style: const TextStyle(color: mutedText, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel', style: TextStyle(color: mutedText)),
            ),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete_outline, size: 17),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: white,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (index >= source.length) {
      return;
    }

    final response = await SocialLinksApi.delete(source[index]['_id'].toString());
    if (!mounted) return;
    if (response['success'] == true) {
      setState(() => source.removeAt(index));
      _showMessage('Link deleted successfully.');
    } else {
      _showMessage(response['message']?.toString() ?? 'Could not delete link.');
    }
  }

  // ============================================================
  // BUTTONS
  // ============================================================

  Widget _blueActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: pageBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _outlineActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: lightText,
          side: const BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _purpleActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF2C45F), Color(0xFFD9A93F)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: pageBackground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF20242E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          message,
          style: const TextStyle(color: white, fontSize: 12),
        ),
      ),
    );
  }
}
