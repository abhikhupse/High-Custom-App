import 'package:flutter/material.dart';
import 'package:high_custom_frontend/services/auth_api.dart';

import 'integration_screen.dart';
import '../profile/profile_screen.dart';
import 'master/master_list_screen.dart';
import 'leads/leads_screen.dart';

import '../auth/login_screen.dart';

import '../../controllers/dashboard_controller.dart';

import '../../widgets/dashboard/dashboard_header.dart';
import '../../widgets/dashboard/dashboard_sidebar.dart';
import '../../widgets/dashboard/dashboard_content.dart';

// ============================================================
// DASHBOARD SCREEN
// ============================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
  });

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final DashboardController dashboardController =
      DashboardController();

  // ============================================================
  // SIDEBAR
  // ============================================================

  bool isSidebarOpen = false;

  // ============================================================
  // SELECTED MENU
  // ============================================================

  String selectedMenu = 'Dashboard';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (mounted) {
        dashboardController
            .fetchUserDetails();
      }
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    dashboardController.dispose();

    super.dispose();
  }

  // ============================================================
  // PROFILE MENU
  // ============================================================

  void _handleProfileMenu(String menu) {
    switch (menu) {
      // ========================================================
      // PROFILE
      // ========================================================

      case 'Profile':
        setState(() {
          selectedMenu = 'Profile';
          isSidebarOpen = false;
        });
        break;

      // ========================================================
      // INTEGRATION
      // ========================================================

      case 'Integration':
        setState(() {
          selectedMenu = 'Integration';
          isSidebarOpen = false;
        });
        break;

      // ========================================================
      // LOGOUT
      // ========================================================

      case 'Logout':
        _showLogoutDialog();
        break;
    }
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF101828),
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 15,
              color:
                  Color(0xFF667085),
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
                  color:
                      Color(0xFF667085),
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _logout();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final result =
        await AuthApi.logout();

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
        (route) => false,
      );

      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xFF241414),
        content: Text(
          result['message']
                  ?.toString() ??
              'Logout failed. Please try again.',
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final bool isMobile =
        screenWidth < 800;

    return AnimatedBuilder(
      animation:
          dashboardController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor:
              const Color(0xFFF5F7FA),

          resizeToAvoidBottomInset:
              true,

          body: SafeArea(
            child: Column(
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                DashboardHeader(
                  isSidebarOpen:
                      isSidebarOpen,

                  user:
                      dashboardController.user,

                  onMenuPressed: () {
                    setState(() {
                      isSidebarOpen =
                          !isSidebarOpen;
                    });
                  },

                  onProfileMenuSelected:
                      _handleProfileMenu,
                ),

                // ==================================================
                // BODY
                // ==================================================

                Expanded(
                  child: Stack(
                    children: [
                      // ============================================
                      // MAIN CONTENT
                      // ============================================

                      Positioned.fill(
                        child:
                            _buildSelectedContent(),
                      ),

                      // ============================================
                      // MOBILE SIDEBAR
                      // ============================================

                      if (isMobile &&
                          isSidebarOpen) ...[
                        // ------------------------------------------
                        // BACKGROUND OVERLAY
                        // ------------------------------------------

                        Positioned.fill(
                          child:
                              GestureDetector(
                            onTap: () {
                              setState(() {
                                isSidebarOpen =
                                    false;
                              });
                            },
                            child:
                                Container(
                              color: Colors
                                  .black
                                  .withOpacity(
                                0.45,
                              ),
                            ),
                          ),
                        ),

                        // ------------------------------------------
                        // MOBILE SIDEBAR
                        // ------------------------------------------

                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 285,
                          child:
                              Material(
                            elevation: 12,
                            color:
                                const Color(
                              0xFF111111,
                            ),
                            child:
                                DashboardSidebar(
                              isOpen:
                                  true,

                              selectedMenu:
                                  selectedMenu,

                              onMenuSelected:
                                  (menu) {
                                setState(() {
                                  selectedMenu =
                                      menu;

                                  isSidebarOpen =
                                      false;
                                });
                              },
                            ),
                          ),
                        ),
                      ],

                      // ============================================
                      // DESKTOP SIDEBAR
                      // ============================================

                      if (!isMobile)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child:
                              AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds:
                                  250,
                            ),

                            curve:
                                Curves.easeInOut,

                            width:
                                isSidebarOpen
                                    ? 250
                                    : 0,

                            child:
                                ClipRect(
                              child:
                                  SizedBox(
                                width: 250,

                                child:
                                    isSidebarOpen
                                        ? Material(
                                            color:
                                                const Color(
                                              0xFF111111,
                                            ),

                                            elevation:
                                                8,

                                            child:
                                                DashboardSidebar(
                                              isOpen:
                                                  true,

                                              selectedMenu:
                                                  selectedMenu,

                                              onMenuSelected:
                                                  (menu) {
                                                setState(() {
                                                  selectedMenu =
                                                      menu;

                                                  isSidebarOpen =
                                                      false;
                                                });
                                              },
                                            ),
                                          )
                                        : null,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SELECTED CONTENT
  // ============================================================

  Widget _buildSelectedContent() {
    switch (selectedMenu) {
      // ========================================================
      // DASHBOARD
      // ========================================================

      case 'Dashboard':
        return DashboardContent(
          user:
              dashboardController.user,
        );

      // ========================================================
      // MASTER
      // ========================================================

      case 'Master':
        return const MasterListScreen();

      // ========================================================
      // LEADS
      // ========================================================

      case 'Leads':
        return const LeadsScreen();

      // ========================================================
      // LINK
      // ========================================================

      case 'Link':
        return _buildOtherContent(
          title: 'Link',
          icon: Icons.link,
        );

      // ========================================================
      // TRACKING REPORT
      // ========================================================

      case 'Tracking Report':
        return _buildOtherContent(
          title: 'Tracking Report',
          icon:
              Icons.analytics_outlined,
        );

      // ========================================================
      // SOCIAL LINKS
      // ========================================================

      case 'Social Links':
        return _buildOtherContent(
          title: 'Social Links',
          icon:
              Icons.share_outlined,
        );

      // ========================================================
      // PROFILE
      // ========================================================

      case 'Profile':
        return const ProfileScreen();

      // ========================================================
      // INTEGRATION
      // ========================================================

      case 'Integration':
        return const IntegrationScreen();

      // ========================================================
      // PRIVACY POLICY
      // ========================================================

      case 'Privacy Policy':
        return _buildOtherContent(
          title: 'Privacy Policy',
          icon:
              Icons.shield_outlined,
        );

      // ========================================================
      // TERMS & CONDITIONS
      // ========================================================

      case 'Terms & Conditions':
        return _buildOtherContent(
          title: 'Terms & Conditions',
          icon:
              Icons.description_outlined,
        );

      // ========================================================
      // LANDING PAGE
      // ========================================================

      case 'Landing Page':
        return _buildOtherContent(
          title: 'Landing Page',
          icon:
              Icons.home_outlined,
        );

      // ========================================================
      // DEFAULT
      // ========================================================

      default:
        return DashboardContent(
          user:
              dashboardController.user,
        );
    }
  }

  // ============================================================
  // OTHER CONTENT
  // ============================================================

  Widget _buildOtherContent({
    required String title,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color:
          const Color(0xFFF5F7FA),
      child:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // TITLE
            // ==================================================

            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFEFF4FF,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color:
                        const Color(
                      0xFF315BEF,
                    ),
                    size: 25,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Text(
                    title,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF101828),
                      fontSize: 28,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 25,
            ),

            // ==================================================
            // CONTENT CARD
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(24),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                      0.04,
                    ),
                    blurRadius: 15,
                    offset:
                        const Offset(
                      0,
                      5,
                    ),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title Content',
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF101828),
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    'This section is ready for the $title module.',
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF667085),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}