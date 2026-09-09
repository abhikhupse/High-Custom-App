import 'package:flutter/material.dart';

import '../../models/user_model.dart';

class DashboardHeader extends StatelessWidget {
  // ============================================================
  // VARIABLES
  // ============================================================

  final bool isSidebarOpen;

  final VoidCallback onMenuPressed;

  final VoidCallback onNotificationPressed;

  final UserModel? user;

  final Function(String) onProfileMenuSelected;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const DashboardHeader({
    super.key,
    required this.isSidebarOpen,
    required this.onMenuPressed,
    required this.onNotificationPressed,
    required this.onProfileMenuSelected,
    this.user,
  });

  // ============================================================
  // COLORS
  // ============================================================

  static const Color background = Color(0xFF030507);

  static const Color gold = Color(0xFFF2C45F);

  static const Color goldDark = Color(0xFFD9A93F);

  static const Color white = Colors.white;

  static const Color mutedText = Color(0xFFAEB4BF);

  // ============================================================
  // BRAND
  // ============================================================

  Widget _buildBrand({required bool compact}) {
    if (compact) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ======================================================
        // DIAMOND ICON
        // ======================================================
        const Icon(Icons.diamond_outlined, color: gold, size: 40),

        const SizedBox(width: 10),

        // ======================================================
        // BRAND TEXT
        // ======================================================
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HighCustomAI',
              style: TextStyle(
                color: gold,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),

            SizedBox(height: 2),

            Text(
              'BELIEVE IN PERFECTION',
              style: TextStyle(
                color: white,
                fontSize: 6.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // SETTINGS BUTTON
  // ============================================================

  Widget _buildSettingsButton({required bool compact}) {
    return InkWell(
      onTap: () {
        // Settings functionality can be added here.
      },

      borderRadius: BorderRadius.circular(12),

      child: Container(
        width: compact ? 42 : 50,

        height: compact ? 42 : 50,

        alignment: Alignment.center,

        child: Icon(
          Icons.settings_outlined,

          color: gold,

          size: compact ? 27 : 31,
        ),
      ),
    );
  }

  // ============================================================
  // EMPLOYER CODE
  // ============================================================

  Widget _buildEmployerCode({required bool compact}) {
    return Container(
      height: compact ? 42 : 50,

      constraints: BoxConstraints(maxWidth: compact ? 145 : 230),

      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 15),

      decoration: BoxDecoration(
        color: gold.withOpacity(0.06),

        borderRadius: BorderRadius.circular(11),

        border: Border.all(color: gold.withOpacity(0.65), width: 1),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(Icons.business_outlined, color: gold, size: compact ? 18 : 22),

          SizedBox(width: compact ? 6 : 9),

          Flexible(
            child: Text(
              user?.employerCode ?? '---',

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(
                color: gold,

                fontSize: compact ? 12 : 14,

                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE BUTTON
  // ============================================================

  Widget _buildProfileButton({
    required bool compact,
    bool mobileStyle = false,
  }) {
    final double buttonSize = compact ? 42 : 50;
    return PopupMenuButton<String>(
      tooltip: 'Profile',

      offset: const Offset(0, 55),

      elevation: 18,

      color: const Color(0xFF0B0E12),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),

        side: BorderSide(color: gold.withOpacity(0.35)),
      ),

      onSelected: onProfileMenuSelected,

      itemBuilder: (context) {
        return [
          // ====================================================
          // PROFILE
          // ====================================================
          const PopupMenuItem<String>(
            value: 'Profile',

            child: Row(
              children: [
                Icon(Icons.person_outline, color: gold, size: 20),

                SizedBox(width: 12),

                Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // INTEGRATION
          // ====================================================
          const PopupMenuItem<String>(
            value: 'Integration',

            child: Row(
              children: [
                Icon(
                  Icons.integration_instructions_outlined,
                  color: gold,
                  size: 20,
                ),

                SizedBox(width: 12),

                Text(
                  'Integration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // DIVIDER
          // ====================================================
          const PopupMenuDivider(),

          // ====================================================
          // LOGOUT
          // ====================================================
          const PopupMenuItem<String>(
            value: 'Logout',

            child: Row(
              children: [
                Icon(Icons.logout_rounded, color: Color(0xFFFF6464), size: 20),

                SizedBox(width: 12),

                Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFFF6464),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ];
      },

      // ========================================================
      // PROFILE CIRCLE
      // ========================================================
      child: Container(
        width: buttonSize,

        height: buttonSize,

        decoration: BoxDecoration(
          color: mobileStyle ? null : Colors.black,

          gradient: mobileStyle
              ? const LinearGradient(
                  colors: [Color(0xFF111720), Color(0xFF05070A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,

          shape: BoxShape.circle,

          border: Border.all(
            color: gold.withOpacity(mobileStyle ? 0.95 : 0.78),
            width: mobileStyle ? 1.35 : 1.2,
          ),

          boxShadow: [
            BoxShadow(
              color: gold.withOpacity(mobileStyle ? 0.12 : 0.08),
              blurRadius: mobileStyle ? 14 : 12,
            ),
          ],
        ),

        child: Icon(
          Icons.person_outline,

          color: Colors.white,

          size: mobileStyle ? 27 : (compact ? 21 : 24),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return InkWell(
      onTap: onNotificationPressed,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111720), Color(0xFF05070A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: gold.withOpacity(0.9), width: 1.15),
                boxShadow: [
                  BoxShadow(color: gold.withOpacity(0.12), blurRadius: 12),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: gold,
                size: 30,
              ),
            ),
            Positioned(
              top: -3,
              right: -6,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF52236),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    final bool compact = width < 620;

    return Container(
      width: double.infinity,

      height: compact ? 72 : 88,

      padding: compact
          ? const EdgeInsets.only(left: 14, right: 11)
          : const EdgeInsets.symmetric(horizontal: 22),

      decoration: BoxDecoration(
        gradient: compact
            ? const LinearGradient(
                colors: [Color(0xFF020406), Color(0xFF080C10)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: compact ? null : background,

        border: Border(bottom: BorderSide(color: gold.withOpacity(0.48))),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: compact
          ? Row(
              children: [
                InkWell(
                  onTap: onMenuPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(Icons.menu_rounded, color: gold, size: 36),
                  ),
                ),
                const Spacer(),
                _buildNotificationButton(context),
                const SizedBox(width: 13),
                _buildProfileButton(compact: false, mobileStyle: true),
              ],
            )
          : Row(
              children: [
                // ==================================================
                // MENU BUTTON
                // ==================================================
                InkWell(
                  onTap: onMenuPressed,

                  borderRadius: BorderRadius.circular(10),

                  child: SizedBox(
                    width: compact ? 46 : 52,

                    height: compact ? 46 : 52,

                    child: Icon(
                      isSidebarOpen
                          ? Icons.menu_open_rounded
                          : Icons.menu_rounded,

                      color: gold,

                      size: compact ? 30 : 35,
                    ),
                  ),
                ),

                // ==================================================
                // BRAND
                // ==================================================
                const SizedBox(width: 26),

                _buildBrand(compact: compact),

                const Spacer(),

                // ==================================================
                // SETTINGS
                // ==================================================
                _buildSettingsButton(compact: compact),

                SizedBox(width: compact ? 5 : 14),

                // ==================================================
                // EMPLOYER CODE
                // ==================================================
                _buildEmployerCode(compact: compact),

                SizedBox(width: compact ? 7 : 14),

                // ==================================================
                // PROFILE
                // ==================================================
                _buildProfileButton(compact: compact),
              ],
            ),
    );
  }
}
