import 'package:flutter/material.dart';
import 'package:high_custom_frontend/services/auth_api.dart';

import 'tracking_report_screen.dart';
import 'interested_leads_screen.dart';
import 'integration_screen.dart';
import '../profile/profile_screen.dart';
import 'master/master_list_screen.dart';
import 'leads/leads_screen.dart';
import 'leads/add_lead_screen.dart';
import 'social_links/social_links_screen.dart';
import 'link/link_screen.dart';
import '../privacy/privacy_policy_screen.dart';
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
    this.initialMenu = 'Dashboard',
  });

  final String initialMenu;

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color background =
      Color(0xFF020507);

  static const Color sidebarBackground =
      Color(0xFF07090C);

  static const Color gold =
      Color(0xFFF2C45F);

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

  late String selectedMenu;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    selectedMenu = widget.initialMenu;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (mounted) {
          dashboardController.fetchUserDetails();
        }
      },
    );
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

  void _handleProfileMenu(
    String menu,
  ) {
    switch (menu) {
      case 'Profile':
        setState(() {
          selectedMenu = 'Profile';
          isSidebarOpen = false;
        });

        break;

      case 'Integration':
        setState(() {
          selectedMenu = 'Integration';
          isSidebarOpen = false;
        });

        break;

      case 'Logout':
        _showLogoutDialog();

        break;
    }
  }

  // ============================================================
  // SIDEBAR MENU
  // ============================================================

  void _handleSidebarMenu(
    String menu,
  ) {
    setState(() {
      selectedMenu = menu;
      isSidebarOpen = false;
    });
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              const Color(
            0xFF0B0E12,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            side:
                BorderSide(
              color:
                  gold.withOpacity(
                0.35,
              ),
            ),
          ),
          title:
              const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: gold,
              ),

              SizedBox(
                width: 12,
              ),

              Text(
                'Logout',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      20,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
          content:
              const Text(
            'Are you sure you want to logout?',
            style:
                TextStyle(
              color:
                  Color(
                0xFFAEB4BF,
              ),
              fontSize:
                  15,
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text(
                'Cancel',
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFFAEB4BF,
                  ),
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            ElevatedButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                );

                _logout();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    gold,
                foregroundColor:
                    Colors.black,
                elevation:
                    0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    9,
                  ),
                ),
              ),
              child:
                  const Text(
                'Logout',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w700,
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
          builder:
              (_) =>
                  const LoginScreen(),
        ),
        (route) => false,
      );

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            const Color(
          0xFF35191C,
        ),
        content:
            Text(
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
  Widget build(
    BuildContext context,
  ) {
    final screenWidth =
        MediaQuery.sizeOf(
      context,
    ).width;

    final bool isMobile =
        screenWidth < 800;

    return AnimatedBuilder(
      animation:
          dashboardController,
      builder: (
        context,
        _,
      ) {
        return Scaffold(
          backgroundColor:
              background,
          resizeToAvoidBottomInset:
              true,
          bottomNavigationBar:
              isMobile
                  ? _buildMobileFooter()
                  : null,
          body:
              SafeArea(
            child:
                Column(
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                DashboardHeader(
                  isSidebarOpen:
                      isSidebarOpen,
                  user:
                      dashboardController.user,
                  onMenuPressed:
                      () {
                    setState(
                      () {
                        isSidebarOpen =
                            !isSidebarOpen;
                      },
                    );
                  },
                  onProfileMenuSelected:
                      _handleProfileMenu,
                ),

                // ==================================================
                // BODY
                // ==================================================

                Expanded(
                  child:
                      Stack(
                    children: [
                      // ============================================
                      // CONTENT
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
                        Positioned.fill(
                          child:
                              GestureDetector(
                            onTap:
                                () {
                              setState(
                                () {
                                  isSidebarOpen =
                                      false;
                                },
                              );
                            },
                            child:
                                Container(
                              color:
                                  Colors.black.withOpacity(
                                0.75,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 285,
                          child:
                              Material(
                            elevation:
                                20,
                            color:
                                sidebarBackground,
                            child:
                                DashboardSidebar(
                              isOpen:
                                  true,
                              selectedMenu:
                                  selectedMenu,
                              onMenuSelected:
                                  _handleSidebarMenu,
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
                                    ? 270
                                    : 0,
                            child:
                                ClipRect(
                              child:
                                  SizedBox(
                                width:
                                    270,
                                child:
                                    isSidebarOpen
                                        ? Material(
                                            elevation:
                                                20,
                                            color:
                                                sidebarBackground,
                                            child:
                                                DashboardSidebar(
                                              isOpen:
                                                  true,
                                              selectedMenu:
                                                  selectedMenu,
                                              onMenuSelected:
                                                  _handleSidebarMenu,
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
  // MOBILE FOOTER
  // ============================================================

  Widget _buildMobileFooter() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070A0E),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: Row(
            children: [
              _buildFooterItem(
                label: 'Dashboard',
                icon: Icons.home_outlined,
                selected: selectedMenu == 'Dashboard',
                onTap: () => _handleSidebarMenu('Dashboard'),
              ),
              _buildFooterItem(
                label: 'Leads',
                icon: Icons.people_outline_rounded,
                selected: selectedMenu == 'Leads',
                onTap: () => _handleSidebarMenu('Leads'),
              ),
              _buildAddLeadFooterItem(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddLeadScreen(),
                    ),
                  );
                },
              ),
              _buildFooterItem(
                label: 'Sequences',
                icon: Icons.account_tree_outlined,
                selected: selectedMenu == 'Master',
                onTap: () => _handleSidebarMenu('Master'),
              ),
              _buildFooterItem(
                label: 'Settings',
                icon: Icons.settings_outlined,
                selected: selectedMenu == 'Profile',
                onTap: () => _handleSidebarMenu('Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddLeadFooterItem({
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Transform.translate(
          offset: const Offset(0, -7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD978),
                      Color(0xFFD9A93F),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFE6A6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 32,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Add Lead',
                maxLines: 1,
                style: TextStyle(
                  color: Color(0xFFF3F4F6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterItem({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              const Positioned(
                top: 0,
                child: SizedBox(
                  width: 48,
                  child: Divider(
                    height: 2,
                    thickness: 2,
                    color: gold,
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: selected
                      ? gold
                      : const Color(0xFFAEB4BF),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected
                        ? gold
                        : const Color(0xFFAEB4BF),
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

      case 'Interested Leads':
        return const InterestedLeadsScreen();

      // ========================================================
      // SOCIAL LINKS
      // ========================================================

      case 'Social Links':
        return const SocialLinksScreen();

      // ========================================================
      // LINK
      //
      // AUTOMATIONS -> LINK
      // ========================================================

      case 'Link':
        return const LinkScreen();

      // ========================================================
      // TRACKING REPORT
      // ========================================================

      case 'Tracking Report':
        return const TrackingReportScreen();

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
        return const PrivacyPolicyScreen();

      // ========================================================
      // CAMPAIGNS
      // ========================================================

      case 'Campaigns':
        return _buildOtherContent(
          title:
              'Campaigns',
          icon:
              Icons.campaign_outlined,
        );

      // ========================================================
      // TEMPLATES
      // ========================================================

      case 'Templates':
        return _buildOtherContent(
          title:
              'Templates',
          icon:
              Icons.description_outlined,
        );

      // ========================================================
      // TERMS
      // ========================================================

      case 'Terms & Conditions':
        return _buildOtherContent(
          title:
              'Terms & Conditions',
          icon:
              Icons.description_outlined,
        );

      // ========================================================
      // LANDING PAGE
      // ========================================================

      case 'Landing Page':
        return _buildOtherContent(
          title:
              'Landing Page',
          icon:
              Icons.web_outlined,
        );

      // ========================================================
      // CONTACT
      // ========================================================

      case 'Contact Us':
        return _buildOtherContent(
          title:
              'Contact Us',
          icon:
              Icons.contact_mail_outlined,
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
      width:
          double.infinity,
      height:
          double.infinity,
      color:
          background,
      child:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width:
                      50,
                  height:
                      50,
                  decoration:
                      BoxDecoration(
                    color:
                        gold.withOpacity(
                      0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                    border:
                        Border.all(
                      color:
                          gold.withOpacity(
                        0.35,
                      ),
                    ),
                  ),
                  child:
                      Icon(
                    icon,
                    color:
                        gold,
                  ),
                ),

                const SizedBox(
                  width:
                      14,
                ),

                Expanded(
                  child:
                      Text(
                    title,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          28,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height:
                  24,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                24,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xD90A0D11,
                ),
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                border:
                    Border.all(
                  color:
                      gold.withOpacity(
                    0.35,
                  ),
                ),
              ),
              child:
                  Text(
                'This section is ready for the $title module.',
                style:
                    const TextStyle(
                  color:
                      Color(
                    0xFFB8BDC6,
                  ),
                  fontSize:
                      15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
