import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../models/user_model.dart';

class DashboardHeader extends StatelessWidget {
  // ============================================================
  // VARIABLES
  // ============================================================

  final bool isSidebarOpen;

  final VoidCallback onMenuPressed;

  final UserModel? user;

  final Function(String) onProfileMenuSelected;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const DashboardHeader({
    super.key,
    required this.isSidebarOpen,
    required this.onMenuPressed,
    required this.onProfileMenuSelected,
    this.user,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),

      decoration: BoxDecoration(
        color: AppColors.primary,

        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.10),
          ),
        ),
      ),

      child: Row(
        children: [
          // ==================================================
          // MENU BUTTON
          // ==================================================

          IconButton(
            onPressed: onMenuPressed,

            icon: Icon(
              isSidebarOpen
                  ? Icons.menu_open
                  : Icons.menu,

              color: Colors.black,

              size: 32,
            ),
          ),

          const Spacer(),

          // ==================================================
          // SETTINGS
          // ==================================================

          IconButton(
            onPressed: () {
              // TODO:
              // Add settings functionality here.
            },

            padding: EdgeInsets.zero,

            constraints: const BoxConstraints(
              minWidth: 42,
              minHeight: 42,
            ),

            tooltip: 'Settings',

            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.black,
              size: 27,
            ),
          ),

          const SizedBox(width: 6),

          // ==================================================
          // EMPLOYER CODE
          // ==================================================

          Container(
            height: 42,

            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),

            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),

              borderRadius: BorderRadius.circular(9),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                // ============================================
                // BUSINESS ICON
                // ============================================

                const Icon(
                  Icons.business_outlined,
                  color: Colors.black,
                  size: 18,
                ),

                const SizedBox(width: 5),

                // ============================================
                // EMPLOYER CODE
                // ============================================

                Text(
                  user?.employerCode ?? '---',

                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ==================================================
          // PROFILE DROPDOWN
          // ==================================================

          PopupMenuButton<String>(
            tooltip: 'Profile',

            offset: const Offset(
              0,
              52,
            ),

            elevation: 8,

            color: Colors.white,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            onSelected: onProfileMenuSelected,

            itemBuilder: (context) {
              return [
                // ==========================================
                // PROFILE
                // ==========================================

                const PopupMenuItem<String>(
                  value: 'Profile',

                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: Color(0xFF344054),
                        size: 20,
                      ),

                      SizedBox(width: 12),

                      Text(
                        'Profile',

                        style: TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // INTEGRATION
                // ==========================================

                const PopupMenuItem<String>(
                  value: 'Integration',

                  child: Row(
                    children: [
                      Icon(
                        Icons.integration_instructions_outlined,
                        color: Color(0xFF344054),
                        size: 20,
                      ),

                      SizedBox(width: 12),

                      Text(
                        'Integration',

                        style: TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // DIVIDER
                // ==========================================

                const PopupMenuDivider(),

                // ==========================================
                // LOGOUT
                // ==========================================

                const PopupMenuItem<String>(
                  value: 'Logout',

                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 20,
                      ),

                      SizedBox(width: 12),

                      Text(
                        'Logout',

                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },

            // ==================================================
            // PROFILE ICON
            // ==================================================

            child: const CircleAvatar(
              radius: 19,

              backgroundColor: Colors.black,

              child: Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),

          const SizedBox(width: 2),
        ],
      ),
    );
  }
}