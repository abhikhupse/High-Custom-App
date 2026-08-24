import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// SOCIAL LINKS SCREEN
// ============================================================

class SocialLinksScreen extends StatefulWidget {
  const SocialLinksScreen({
    super.key,
  });

  @override
  State<SocialLinksScreen> createState() =>
      _SocialLinksScreenState();
}

class _SocialLinksScreenState extends State<SocialLinksScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color pageBackground = Color(0xFF090A0C);
  static const Color surface = Color(0xFF101216);
  static const Color surface2 = Color(0xFF15171C);
  static const Color borderColor = Color(0xFF2C3038);

  static const Color white = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFFECEDEF);
  static const Color mutedText = Color(0xFF969AA5);

  static const Color gold = Color(0xFFF2C45F);
  static const Color purple = Color(0xFF7957E8);
  static const Color blue = Color(0xFF1677FF);
  static const Color red = Color(0xFFFF5B66);

  // ============================================================
  // EXPANSION STATE
  // ============================================================

  bool socialExpanded = true;
  bool ecommerceExpanded = false;
  bool paymentExpanded = false;

  // ============================================================
  // SOCIAL MEDIA LINKS - 5 DUMMY DATA
  // ============================================================

  final List<Map<String, dynamic>> socialLinks = [
    {
      'name': 'Instagram',
      'url': 'https://instagram.com/highcustom',
      'selected': false,
      'platform': 'instagram',
    },
    {
      'name': 'Facebook',
      'url': 'https://facebook.com/highcustom',
      'selected': false,
      'platform': 'facebook',
    },
    {
      'name': 'WhatsApp',
      'url': 'https://wa.me/919876543210',
      'selected': false,
      'platform': 'whatsapp',
    },
    {
      'name': 'YouTube',
      'url': 'https://youtube.com/@highcustom',
      'selected': false,
      'platform': 'youtube',
    },
    {
      'name': 'LinkedIn',
      'url': 'https://linkedin.com/company/highcustom',
      'selected': false,
      'platform': 'linkedin',
    },
  ];

  // ============================================================
  // E-COMMERCE LINKS - 5 DUMMY DATA
  // ============================================================

  final List<Map<String, dynamic>> ecommerceLinks = [
    {
      'name': 'Amazon',
      'url': 'https://amazon.in/highcustom',
      'selected': false,
      'platform': 'amazon',
    },
    {
      'name': 'Flipkart',
      'url': 'https://flipkart.com/highcustom',
      'selected': false,
      'platform': 'flipkart',
    },
    {
      'name': 'Meesho',
      'url': 'https://meesho.com/highcustom',
      'selected': false,
      'platform': 'meesho',
    },
    {
      'name': 'Myntra',
      'url': 'https://myntra.com/highcustom',
      'selected': false,
      'platform': 'myntra',
    },
    {
      'name': 'Website Store',
      'url': 'https://highcustomai.com/shop',
      'selected': false,
      'platform': 'website',
    },
  ];

  // ============================================================
  // PAYMENT GATEWAYS - 5 DUMMY DATA
  // ============================================================

  final List<Map<String, dynamic>> paymentLinks = [
    {
      'name': 'Google Pay',
      'url': 'https://pay.google.com/highcustom',
      'selected': false,
      'platform': 'googlepay',
    },
    {
      'name': 'PhonePe',
      'url': 'https://phonepe.com/highcustom',
      'selected': false,
      'platform': 'phonepe',
    },
    {
      'name': 'Paytm',
      'url': 'https://paytm.com/highcustom',
      'selected': false,
      'platform': 'paytm',
    },
    {
      'name': 'PayPal',
      'url': 'https://paypal.me/highcustom',
      'selected': false,
      'platform': 'paypal',
    },
    {
      'name': 'Razorpay',
      'url': 'https://razorpay.me/@highcustom',
      'selected': false,
      'platform': 'razorpay',
    },
  ];

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final bool isMobile =
                constraints.maxWidth < 800;

            return SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isMobile ? 14 : 28,
                isMobile ? 16 : 28,
                isMobile ? 14 : 28,
                35,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 950,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(
                        isMobile,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      _buildLinksCard(
                        isMobile,
                      ),
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

  Widget _buildHeaderCard(
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? 16 : 22,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                _buildBusinessTitle(),

                const SizedBox(
                  height: 18,
                ),

                _blueActionButton(
                  icon: Icons.qr_code_2_rounded,
                  label: 'VIEW ALL QR',
                  onTap: () {
                    _showMessage(
                      'View All QR',
                    );
                  },
                ),

                const SizedBox(
                  height: 10,
                ),

                _outlineActionButton(
                  icon: Icons.badge_outlined,
                  label: 'BUSINESS CARD',
                  onTap: () {
                    _showMessage(
                      'Business Card',
                    );
                  },
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildBusinessTitle(),
                ),

                _blueActionButton(
                  icon: Icons.qr_code_2_rounded,
                  label: 'VIEW ALL QR',
                  onTap: () {
                    _showMessage(
                      'View All QR',
                    );
                  },
                ),

                const SizedBox(
                  width: 10,
                ),

                _outlineActionButton(
                  icon: Icons.badge_outlined,
                  label: 'BUSINESS CARD',
                  onTap: () {
                    _showMessage(
                      'Business Card',
                    );
                  },
                ),
              ],
            ),
    );
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
              colors: [
                Color(0xFF5864E8),
                Color(0xFF9B4CC7),
              ],
            ),
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          child: const Icon(
            Icons.qr_code_rounded,
            color: white,
            size: 30,
          ),
        ),

        const SizedBox(
          width: 14,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Digital Business Card',
                softWrap: true,
                style: TextStyle(
                  color: white,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w800,
                  height: 1.15,
                ),
              ),

              SizedBox(
                height: 6,
              ),

              Text(
                'Smart Social Links Manager',
                style: TextStyle(
                  color: mutedText,
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
  // LINKS CARD
  // ============================================================

  Widget _buildLinksCard(
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? 14 : 22,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          // ======================================================
          // GENERATE QR
          // ======================================================

          _purpleActionButton(
            icon: Icons.qr_code_2_rounded,
            label: 'Generate QR Code',
            onTap: () {
              final selected =
                  _getSelectedLinks();

              if (selected.isEmpty) {
                _showMessage(
                  'Please select at least one link.',
                );

                return;
              }

              _showMessage(
                '${selected.length} links selected.',
              );
            },
          ),

          const SizedBox(
            height: 18,
          ),

          // ======================================================
          // SOCIAL
          // ======================================================

          _buildExpandableSection(
            title: 'Social Media Links',
            subtitle:
                '${socialLinks.length} links',
            icon: Icons.share_rounded,
            expanded: socialExpanded,
            children: socialLinks,
            onTap: () {
              setState(() {
                socialExpanded =
                    !socialExpanded;
              });
            },
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // E-COMMERCE
          // ======================================================

          _buildExpandableSection(
            title: 'E-commerce Links',
            subtitle:
                '${ecommerceLinks.length} links',
            icon:
                Icons.shopping_cart_outlined,
            expanded:
                ecommerceExpanded,
            children:
                ecommerceLinks,
            onTap: () {
              setState(() {
                ecommerceExpanded =
                    !ecommerceExpanded;
              });
            },
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // PAYMENT
          // ======================================================

          _buildExpandableSection(
            title: 'Payment Gateways',
            subtitle:
                '${paymentLinks.length} links',
            icon:
                Icons.credit_card_rounded,
            expanded:
                paymentExpanded,
            children:
                paymentLinks,
            onTap: () {
              setState(() {
                paymentExpanded =
                    !paymentExpanded;
              });
            },
          ),
        ],
      ),
    );
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
    required List<Map<String, dynamic>>
        children,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(
          0xFF111318,
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
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
                      child: Icon(
                        icon,
                        color:
                            const Color(
                          0xFF8179FF,
                        ),
                        size: 19,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: lightText,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

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
                      duration:
                          const Duration(
                        milliseconds: 180,
                      ),
                      turns:
                          expanded ? 0.5 : 0,
                      child: const Icon(
                        Icons
                            .keyboard_arrow_down_rounded,
                        color: lightText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (expanded) ...[
            Container(
              height: 1,
              color: borderColor,
            ),

            ...List.generate(
              children.length,
              (index) {
                return _buildSavedLink(
                  source: children,
                  index: index,
                  showBottomBorder:
                      index !=
                          children.length -
                              1,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SAVED LINK
  // ============================================================

  Widget _buildSavedLink({
    required List<Map<String, dynamic>>
        source,
    required int index,
    required bool showBottomBorder,
  }) {
    final Map<String, dynamic> link =
        source[index];

    final String name =
        link['name']?.toString() ?? '';

    final String url =
        link['url']?.toString() ?? '';

    final String platform =
        link['platform']?.toString() ?? '';

    final bool checked =
        link['selected'] == true;

    return InkWell(
      onTap: () {
        // ========================================================
        // ROW TAP ALSO TOGGLES CHECKBOX
        // ========================================================

        setState(() {
          source[index]['selected'] =
              !checked;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: checked
              ? purple.withOpacity(
                  0.07,
                )
              : Colors.transparent,
          border: showBottomBorder
              ? const Border(
                  bottom: BorderSide(
                    color: borderColor,
                  ),
                )
              : null,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 9,
        ),
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
                  materialTapTargetSize:
                      MaterialTapTargetSize
                          .padded,
                  side:
                      const BorderSide(
                    color:
                        Color(
                      0xFF727987,
                    ),
                    width: 1.5,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      5,
                    ),
                  ),
                  onChanged: (value) {
                    // ============================================
                    // FIXED TICK / UNTICK
                    // ============================================

                    setState(() {
                      source[index]
                              ['selected'] =
                          value ?? false;
                    });
                  },
                ),
              ),
            ),

            // ====================================================
            // PLATFORM LOGO
            // ====================================================

            _buildPlatformLogo(
              platform,
            ),

            const SizedBox(
              width: 11,
            ),

            // ====================================================
            // NAME + URL
            // ====================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: lightText,
                      fontSize: 13.5,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    url,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: mutedText,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // COPY
            // ====================================================

            IconButton(
              tooltip: 'Copy Link',
              onPressed: () {
                _copyLink(
                  url,
                );
              },
              icon: const Icon(
                Icons.content_copy_rounded,
                color:
                    Color(
                  0xFF9CA2AF,
                ),
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
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                side:
                    const BorderSide(
                  color: borderColor,
                ),
              ),
              icon: const Icon(
                Icons.more_vert_rounded,
                color: lightText,
                size: 21,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(
                    source: source,
                    index: index,
                  );
                }

                if (value == 'delete') {
                  _showDeleteDialog(
                    source: source,
                    index: index,
                  );
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: gold,
                          size: 18,
                        ),

                        SizedBox(
                          width: 11,
                        ),

                        Text(
                          'Edit',
                          style: TextStyle(
                            color: lightText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .delete_outline_rounded,
                          color: red,
                          size: 18,
                        ),

                        SizedBox(
                          width: 11,
                        ),

                        Text(
                          'Delete',
                          style: TextStyle(
                            color: red,
                            fontSize: 13,
                          ),
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

  Widget _buildPlatformLogo(
    String platform,
  ) {
    IconData icon =
        Icons.link_rounded;

    Color iconColor =
        purple;

    Color background =
        purple.withOpacity(
      0.12,
    );

    switch (platform.toLowerCase()) {
      // ========================================================
      // SOCIAL MEDIA
      // ========================================================

      case 'instagram':
        icon =
            Icons.camera_alt_rounded;
        iconColor =
            const Color(
          0xFFE1306C,
        );
        background =
            const Color(
          0xFFE1306C,
        ).withOpacity(
          0.12,
        );
        break;

      case 'facebook':
        icon =
            Icons.facebook_rounded;
        iconColor =
            const Color(
          0xFF1877F2,
        );
        background =
            const Color(
          0xFF1877F2,
        ).withOpacity(
          0.12,
        );
        break;

      case 'whatsapp':
        icon =
            Icons.chat_rounded;
        iconColor =
            const Color(
          0xFF25D366,
        );
        background =
            const Color(
          0xFF25D366,
        ).withOpacity(
          0.12,
        );
        break;

      case 'youtube':
        icon =
            Icons.play_circle_fill_rounded;
        iconColor =
            const Color(
          0xFFFF0000,
        );
        background =
            const Color(
          0xFFFF0000,
        ).withOpacity(
          0.12,
        );
        break;

      case 'linkedin':
        icon =
            Icons.business_center_rounded;
        iconColor =
            const Color(
          0xFF0A66C2,
        );
        background =
            const Color(
          0xFF0A66C2,
        ).withOpacity(
          0.12,
        );
        break;

      // ========================================================
      // E-COMMERCE
      // ========================================================

      case 'amazon':
        icon =
            Icons.shopping_bag_rounded;
        iconColor =
            const Color(
          0xFFFF9900,
        );
        background =
            const Color(
          0xFFFF9900,
        ).withOpacity(
          0.12,
        );
        break;

      case 'flipkart':
        icon =
            Icons.shopping_cart_rounded;
        iconColor =
            const Color(
          0xFFFFD814,
        );
        background =
            const Color(
          0xFFFFD814,
        ).withOpacity(
          0.10,
        );
        break;

      case 'meesho':
        icon =
            Icons.storefront_rounded;
        iconColor =
            const Color(
          0xFFF43397,
        );
        background =
            const Color(
          0xFFF43397,
        ).withOpacity(
          0.12,
        );
        break;

      case 'myntra':
        icon =
            Icons.local_mall_rounded;
        iconColor =
            const Color(
          0xFFFF3F6C,
        );
        background =
            const Color(
          0xFFFF3F6C,
        ).withOpacity(
          0.12,
        );
        break;

      case 'website':
        icon =
            Icons.language_rounded;
        iconColor =
            const Color(
          0xFF65A6FF,
        );
        background =
            const Color(
          0xFF65A6FF,
        ).withOpacity(
          0.12,
        );
        break;

      // ========================================================
      // PAYMENT
      // ========================================================

      case 'googlepay':
        icon =
            Icons.account_balance_wallet_rounded;
        iconColor =
            const Color(
          0xFF4285F4,
        );
        background =
            const Color(
          0xFF4285F4,
        ).withOpacity(
          0.12,
        );
        break;

      case 'phonepe':
        icon =
            Icons.account_balance_wallet_rounded;
        iconColor =
            const Color(
          0xFF6739B7,
        );
        background =
            const Color(
          0xFF6739B7,
        ).withOpacity(
          0.14,
        );
        break;

      case 'paytm':
        icon =
            Icons.payments_rounded;
        iconColor =
            const Color(
          0xFF00BAF2,
        );
        background =
            const Color(
          0xFF00BAF2,
        ).withOpacity(
          0.12,
        );
        break;

      case 'paypal':
        icon =
            Icons.payments_rounded;
        iconColor =
            const Color(
          0xFF0070BA,
        );
        background =
            const Color(
          0xFF0070BA,
        ).withOpacity(
          0.14,
        );
        break;

      case 'razorpay':
        icon =
            Icons.credit_card_rounded;
        iconColor =
            const Color(
          0xFF528FF0,
        );
        background =
            const Color(
          0xFF528FF0,
        ).withOpacity(
          0.12,
        );
        break;
    }

    return Container(
      width: 41,
      height: 41,
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(
          11,
        ),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 20,
      ),
    );
  }

  // ============================================================
  // SELECTED LINKS
  // ============================================================

  List<Map<String, dynamic>>
      _getSelectedLinks() {
    return [
      ...socialLinks.where(
        (link) =>
            link['selected'] == true,
      ),
      ...ecommerceLinks.where(
        (link) =>
            link['selected'] == true,
      ),
      ...paymentLinks.where(
        (link) =>
            link['selected'] == true,
      ),
    ];
  }

  // ============================================================
  // COPY LINK
  // ============================================================

  Future<void> _copyLink(
    String url,
  ) async {
    await Clipboard.setData(
      ClipboardData(
        text: url,
      ),
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      'Link copied successfully.',
    );
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _showEditDialog({
    required List<Map<String, dynamic>>
        source,
    required int index,
  }) async {
    final TextEditingController
        nameController =
        TextEditingController(
      text:
          source[index]['name']
                  ?.toString() ??
              '',
    );

    final TextEditingController
        urlController =
        TextEditingController(
      text:
          source[index]['url']
                  ?.toString() ??
              '',
    );

    await showDialog(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          backgroundColor: surface2,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            side: const BorderSide(
              color: borderColor,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: gold,
              ),

              SizedBox(
                width: 10,
              ),

              Text(
                'Edit Link',
                style: TextStyle(
                  color: white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                _dialogInput(
                  controller:
                      nameController,
                  hint: 'Link Name',
                  icon:
                      Icons.apps_rounded,
                ),

                const SizedBox(
                  height: 12,
                ),

                _dialogInput(
                  controller:
                      urlController,
                  hint: 'Link URL',
                  icon:
                      Icons.link_rounded,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: mutedText,
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed: () {
                final String name =
                    nameController.text
                        .trim();

                final String url =
                    urlController.text
                        .trim();

                if (name.isEmpty ||
                    url.isEmpty) {
                  _showMessage(
                    'Please complete both fields.',
                  );

                  return;
                }

                setState(() {
                  source[index]['name'] =
                      name;

                  source[index]['url'] =
                      url;
                });

                Navigator.pop(
                  dialogContext,
                );

                _showMessage(
                  'Link updated successfully.',
                );
              },
              icon: const Icon(
                Icons.save_outlined,
                size: 17,
              ),
              label: const Text(
                'Save',
              ),
              style:
                  ElevatedButton.styleFrom(
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
    required TextEditingController
        controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      cursorColor: purple,
      style: const TextStyle(
        color: white,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: mutedText,
        ),
        prefixIcon: Icon(
          icon,
          color: mutedText,
          size: 19,
        ),
        filled: true,
        fillColor: pageBackground,
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            11,
          ),
          borderSide:
              const BorderSide(
            color: borderColor,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            11,
          ),
          borderSide:
              const BorderSide(
            color: purple,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _showDeleteDialog({
    required List<Map<String, dynamic>>
        source,
    required int index,
  }) async {
    final String name =
        source[index]['name']
                ?.toString() ??
            'this link';

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          backgroundColor: surface2,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            side: const BorderSide(
              color: borderColor,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons
                    .delete_outline_rounded,
                color: red,
              ),

              SizedBox(
                width: 10,
              ),

              Text(
                'Delete Link',
                style: TextStyle(
                  color: white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete $name?',
            style: const TextStyle(
              color: mutedText,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: mutedText,
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon: const Icon(
                Icons.delete_outline,
                size: 17,
              ),
              label: const Text(
                'Delete',
              ),
              style:
                  ElevatedButton.styleFrom(
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

    setState(() {
      source.removeAt(
        index,
      );
    });

    _showMessage(
      'Link deleted successfully.',
    );
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
        icon: Icon(
          icon,
          size: 18,
        ),
        label: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
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
        icon: Icon(
          icon,
          size: 18,
        ),
        label: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        style:
            OutlinedButton.styleFrom(
          foregroundColor: lightText,
          side: const BorderSide(
            color: borderColor,
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
            colors: [
              Color(
                0xFF625BE1,
              ),
              Color(
                0xFF9149B4,
              ),
            ],
          ),
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
        child:
            ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(
            icon,
            size: 18,
          ),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.transparent,
            shadowColor:
                Colors.transparent,
            foregroundColor: white,
            elevation: 0,
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

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            const Color(
          0xFF20242E,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}