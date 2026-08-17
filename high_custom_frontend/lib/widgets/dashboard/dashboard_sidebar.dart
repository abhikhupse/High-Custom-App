import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class DashboardSidebar extends StatelessWidget {
  final bool isOpen;
  final String selectedMenu;
  final Function(String) onMenuSelected;

  const DashboardSidebar({
    super.key,
    required this.isOpen,
    required this.selectedMenu,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,

      // ==================================================
      // FULLY CLOSE SIDEBAR
      // ==================================================

      width: isOpen ? 250 : 0,

      child: isOpen
          ? Container(
              width: 250,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    // ==================================================
                    // MAIN MENU
                    // ==================================================

                    _menuItem(
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard',
                    ),

                    _menuItem(
                      icon: Icons.campaign_outlined,
                      title: 'Campaigns',
                    ),

                    _menuItem(
                      icon: Icons.description_outlined,
                      title: 'Templates',
                    ),

                    _menuItem(
                      icon: Icons.link_outlined,
                      title: 'Social Links',
                    ),

                    // ==================================================
                    // MAIL AUTOMATIONS
                    // ==================================================

                    _mailAutomationMenu(),

                    // ==================================================
                    // LEADS
                    // ==================================================

                    _menuItem(
                      icon: Icons.people_outline,
                      title: 'Leads',
                    ),

                    const SizedBox(height: 15),

                    Divider(
                      color: Colors.grey.shade800,
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // OTHER MENU
                    // ==================================================

                    _menuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                    ),

                    _menuItem(
                      icon: Icons.web_outlined,
                      title: 'Landing Page',
                    ),

                    _menuItem(
                      icon: Icons.article_outlined,
                      title: 'Terms & Conditions',
                    ),

                    _menuItem(
                      icon: Icons.contact_mail_outlined,
                      title: 'Contact Us',
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ============================================================
  // NORMAL MENU ITEM
  // ============================================================

  Widget _menuItem({
    required IconData icon,
    required String title,
  }) {
    final bool isSelected = selectedMenu == title;

    return InkWell(
      onTap: () {
        onMenuSelected(title);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        margin: const EdgeInsets.only(
          bottom: 5,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Icon
            Icon(
              icon,
              size: 21,
              color: isSelected
                  ? AppColors.primary
                  : Colors.grey.shade400,
            ),

            const SizedBox(width: 13),

            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  fontSize: 14,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          ],
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
        selectedMenu == 'Master' ||
        selectedMenu == 'Tracking Report';

    return Column(
      children: [
        // ==================================================
        // MAIL AUTOMATIONS TITLE
        // ==================================================

        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 21,
                color: hasSelectedChild
                    ? AppColors.primary
                    : Colors.grey.shade400,
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Text(
                  'Mail Automations',
                  style: TextStyle(
                    color: hasSelectedChild
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),

        // ==================================================
        // SUB MENU
        // ==================================================

        _subMenuItem(
          title: 'Link',
        ),

        _subMenuItem(
          title: 'Master',
        ),

        _subMenuItem(
          title: 'Tracking Report',
        ),
      ],
    );
  }

  // ============================================================
  // SUB MENU ITEM
  // ============================================================

  Widget _subMenuItem({
    required String title,
  }) {
    final bool isSelected = selectedMenu == title;

    return InkWell(
      onTap: () {
        onMenuSelected(title);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        margin: const EdgeInsets.only(
          left: 30,
          bottom: 3,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Small bullet
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey.shade600,
              ),
            ),

            const SizedBox(width: 10),

            // Sub menu title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade400,
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}