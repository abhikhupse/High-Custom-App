import 'package:flutter/material.dart';

// ============================================================
// DASHBOARD SIDEBAR
// ============================================================

class DashboardSidebar extends StatelessWidget {
  // ============================================================
  // VARIABLES
  // ============================================================

  final bool isOpen;

  final String selectedMenu;

  final Function(String) onMenuSelected;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const DashboardSidebar({
    super.key,
    required this.isOpen,
    required this.selectedMenu,
    required this.onMenuSelected,
  });

  // ============================================================
  // COLORS
  // ============================================================

  static const Color background =
      Color(0xFF050709);

  static const Color cardBackground =
      Color(0xFF0B0E12);

  static const Color gold =
      Color(0xFFF2C45F);

  static const Color goldDark =
      Color(0xFFD9A93F);

  static const Color white =
      Colors.white;

  static const Color mutedText =
      Color(0xFFA8ADB6);

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 250,
      ),

      curve: Curves.easeInOut,

      width: isOpen ? 250 : 0,

      decoration: BoxDecoration(
        color: background,

        border: Border(
          right: BorderSide(
            color: gold.withOpacity(
              0.22,
            ),
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.50,
            ),

            blurRadius: 20,

            offset: const Offset(
              5,
              0,
            ),
          ),
        ],
      ),

      child: !isOpen
          ? const SizedBox.shrink()
          : SafeArea(
              top: false,

              child: Column(
                children: [
                  // ==================================================
                  // SIDEBAR HEADER
                  // ==================================================

                  _buildSidebarHeader(),

                  // ==================================================
                  // DIVIDER
                  // ==================================================

                  Container(
                    height: 1,

                    margin: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),

                    color: gold.withOpacity(
                      0.18,
                    ),
                  ),

                  // ==================================================
                  // MENU
                  // ==================================================

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        10,
                        16,
                        10,
                        24,
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,

                        children: [
                          // ==========================================
                          // MAIN LABEL
                          // ==========================================

                          _sectionLabel(
                            'MAIN MENU',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          // ==========================================
                          // DASHBOARD
                          // ==========================================

                          _menuItem(
                            icon:
                                Icons.dashboard_outlined,

                            title:
                                'Dashboard',
                          ),

                          // ==========================================
                          // TEMPLATES
                          // ==========================================

                          // _menuItem(
                          //   icon: Icons.description_outlined,
                          //   title: 'Templates',
                          // ),

                          // ==========================================
                          // LEADS
                          // ==========================================

                          _menuItem(
                            icon:
                                Icons.people_outline_rounded,

                            title:
                                'Leads',
                          ),

                          _menuItem(
                            icon:
                                Icons.person_search_outlined,

                            title:
                                'Interested Leads',
                          ),

                          // ==========================================
                          // MASTER
                          // ==========================================

                          _mailAutomationMenu(),

                          const SizedBox(
                            height: 18,
                          ),

                          // ==========================================
                          // DIVIDER
                          // ==========================================

                          Container(
                            height: 1,

                            margin:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),

                            color: gold.withOpacity(
                              0.15,
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          // ==========================================
                          // OTHER LABEL
                          // ==========================================

                          _sectionLabel(
                            'OTHER',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          // ==========================================
                          // PRIVACY POLICY
                          // ==========================================

                          _menuItem(
                            icon:
                                Icons.privacy_tip_outlined,

                            title:
                                'Privacy Policy',
                          ),

                          // ==========================================
                          // LANDING PAGE
                          // ==========================================

                          _menuItem(
                            icon:
                                Icons.web_outlined,

                            title:
                                'Landing Page',
                          ),

                          // ==========================================
                          // TERMS
                          // ==========================================

                          _menuItem(
                            icon:
                                Icons.article_outlined,

                            title:
                                'Terms & Conditions',
                          ),

                          // ==========================================
                          // CONTACT
                          // ==========================================

                          _menuItem(
                            icon:
                                Icons.contact_mail_outlined,

                            title:
                                'Contact Us',
                          ),
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
  // SIDEBAR HEADER
  // ============================================================

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        18,
      ),

      child: Row(
        children: [
          // ======================================================
          // LOGO
          // ======================================================

          Container(
            width: 45,

            height: 45,

            decoration: BoxDecoration(
              color: gold.withOpacity(
                0.07,
              ),

              borderRadius: BorderRadius.circular(
                11,
              ),

              border: Border.all(
                color: gold.withOpacity(
                  0.35,
                ),
              ),
            ),

            child: const Icon(
              Icons.diamond_outlined,

              color: gold,

              size: 28,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          // ======================================================
          // BRAND
          // ======================================================

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'HighCustomAI',

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    color: gold,

                    fontSize: 18,

                    fontWeight:
                        FontWeight.w600,

                    letterSpacing:
                        0.3,
                  ),
                ),

                SizedBox(
                  height: 3,
                ),

                Text(
                  'BELIEVE IN PERFECTION',

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    color: mutedText,

                    fontSize: 6.5,

                    fontWeight:
                        FontWeight.w600,

                    letterSpacing:
                        1.5,
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
  // SECTION LABEL
  // ============================================================

  Widget _sectionLabel(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),

      child: Text(
        title,

        style: TextStyle(
          color: gold.withOpacity(
            0.55,
          ),

          fontSize: 10,

          fontWeight:
              FontWeight.w700,

          letterSpacing:
              1.4,
        ),
      ),
    );
  }

  // ============================================================
  // NORMAL MENU ITEM
  // ============================================================

  Widget _menuItem({
    required IconData icon,
    required String title,
  }) {
    final bool isSelected =
        selectedMenu == title;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 5,
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: () {
            onMenuSelected(
              title,
            );
          },

          borderRadius:
              BorderRadius.circular(
            11,
          ),

          splashColor:
              gold.withOpacity(
            0.08,
          ),

          highlightColor:
              gold.withOpacity(
            0.04,
          ),

          child: AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 180,
            ),

            height: 48,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 13,
            ),

            decoration:
                BoxDecoration(
              color: isSelected
                  ? gold.withOpacity(
                      0.09,
                    )
                  : Colors.transparent,

              borderRadius:
                  BorderRadius.circular(
                11,
              ),

              border:
                  Border.all(
                color: isSelected
                    ? gold.withOpacity(
                        0.48,
                      )
                    : Colors.transparent,
              ),

              boxShadow:
                  isSelected
                      ? [
                          BoxShadow(
                            color:
                                gold.withOpacity(
                              0.05,
                            ),

                            blurRadius:
                                14,
                          ),
                        ]
                      : null,
            ),

            child: Row(
              children: [
                // ================================================
                // ICON BOX
                // ================================================

                Container(
                  width: 31,

                  height: 31,

                  alignment:
                      Alignment.center,

                  decoration:
                      BoxDecoration(
                    color: isSelected
                        ? gold.withOpacity(
                            0.12,
                          )
                        : Colors.transparent,

                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),

                  child: Icon(
                    icon,

                    size: 20,

                    color: isSelected
                        ? gold
                        : mutedText,
                  ),
                ),

                const SizedBox(
                  width: 11,
                ),

                // ================================================
                // TITLE
                // ================================================

                Expanded(
                  child: Text(
                    title,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        TextStyle(
                      color: isSelected
                          ? gold
                          : const Color(
                              0xFFD0D3D9,
                            ),

                      fontSize: 14,

                      fontWeight:
                          isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                    ),
                  ),
                ),

                // ================================================
                // SELECTED INDICATOR
                // ================================================

                if (isSelected)
                  Container(
                    width: 4,

                    height: 18,

                    decoration:
                        BoxDecoration(
                      color: gold,

                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color:
                              gold.withOpacity(
                            0.35,
                          ),

                          blurRadius:
                              7,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAIL AUTOMATIONS
  // ============================================================

  Widget _mailAutomationMenu() {
    final bool hasSelectedChild =
        selectedMenu == 'Link' ||
            selectedMenu == 'Social Links' ||
            selectedMenu == 'Master' ||
            selectedMenu ==
                'Tracking Report';
    bool isExpanded = true;

    return StatefulBuilder(
      builder: (context, setMenuState) => Container(
      margin: const EdgeInsets.only(
        bottom: 5,
      ),

      decoration: BoxDecoration(
        color: hasSelectedChild
            ? gold.withOpacity(
                0.035,
              )
            : Colors.transparent,

        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),

      child: Column(
        children: [
          // ====================================================
          // TITLE
          // ====================================================

          InkWell(
            onTap: () {
              setMenuState(() {
                isExpanded = !isExpanded;
              });
            },

            borderRadius:
                BorderRadius.circular(
              12,
            ),

            child: Container(
              height: 48,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 13,
              ),

              child: Row(
                children: [
                // ==============================================
                // ICON
                // ==============================================

                Container(
                  width: 31,

                  height: 31,

                  alignment:
                      Alignment.center,

                  child: Icon(
                    Icons.auto_awesome_outlined,

                    size: 20,

                    color: hasSelectedChild
                        ? gold
                        : mutedText,
                  ),
                ),

                const SizedBox(
                  width: 11,
                ),

                // ==============================================
                // TITLE
                // ==============================================

                Expanded(
                  child: Text(
                    'Master',

                    style:
                        TextStyle(
                      color: hasSelectedChild
                          ? gold
                          : const Color(
                              0xFFD0D3D9,
                            ),

                      fontSize: 14,

                      fontWeight:
                          hasSelectedChild
                              ? FontWeight.w700
                              : FontWeight.w500,
                    ),
                  ),
                ),

                // ==============================================
                // ARROW
                // ==============================================

                AnimatedRotation(
                  turns: isExpanded ? 0 : -0.25,

                  duration: const Duration(
                    milliseconds: 180,
                  ),

                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,

                    color: hasSelectedChild
                        ? gold
                        : mutedText,

                    size: 21,
                  ),
                ),
                ],
              ),
            ),
          ),

          // ====================================================
          // SUB MENU
          // ====================================================

          if (isExpanded) Padding(
            padding: const EdgeInsets.only(
              left: 28,
              bottom: 5,
            ),

            child: Column(
              children: [
                _subMenuItem(
                  title: 'Link',
                ),

                _subMenuItem(
                  title: 'Social Links',
                ),

                _subMenuItem(
                  title: 'Sequences',
                  menuValue: 'Master',
                ),

                _subMenuItem(
                  title:
                      'Tracking Report',
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ============================================================
  // SUB MENU ITEM
  // ============================================================

  Widget _subMenuItem({
    required String title,
    String? menuValue,
  }) {
    final String selectedValue = menuValue ?? title;
    final bool isSelected =
        selectedMenu == selectedValue;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 3,
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: () {
            onMenuSelected(
              selectedValue,
            );
          },

          borderRadius:
              BorderRadius.circular(
            9,
          ),

          child: AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 180,
            ),

            height: 39,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 11,
            ),

            decoration:
                BoxDecoration(
              color: isSelected
                  ? gold.withOpacity(
                      0.09,
                    )
                  : Colors.transparent,

              borderRadius:
                  BorderRadius.circular(
                9,
              ),

              border:
                  Border.all(
                color: isSelected
                    ? gold.withOpacity(
                        0.30,
                      )
                    : Colors.transparent,
              ),
            ),

            child: Row(
              children: [
                // ================================================
                // BULLET
                // ================================================

                Container(
                  width: 6,

                  height: 6,

                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,

                    color: isSelected
                        ? gold
                        : const Color(
                            0xFF666B75,
                          ),

                    boxShadow:
                        isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      gold.withOpacity(
                                    0.40,
                                  ),

                                  blurRadius:
                                      6,
                                ),
                              ]
                            : null,
                  ),
                ),

                const SizedBox(
                  width: 11,
                ),

                // ================================================
                // TITLE
                // ================================================

                Expanded(
                  child: Text(
                    title,

                    style:
                        TextStyle(
                      color: isSelected
                          ? gold
                          : mutedText,

                      fontSize: 13,

                      fontWeight:
                          isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
