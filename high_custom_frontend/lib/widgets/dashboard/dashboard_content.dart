import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class DashboardContent extends StatefulWidget {
  final UserModel? user;

  const DashboardContent({
    super.key,
    this.user,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  DateTime? selectedDate;

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final DateTime today = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Colors.white,
              onSurface: Color(0xFF101828),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // ============================================================
  // DATE TEXT
  // ============================================================

  String _getDateText() {
    if (selectedDate == null) {
      return 'Today';
    }

    return '${selectedDate!.day.toString().padLeft(2, '0')}/'
        '${selectedDate!.month.toString().padLeft(2, '0')}/'
        '${selectedDate!.year}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardHeader(),

            const SizedBox(height: 22),

            // =====================================================
            // STATISTICS
            // =====================================================

            _buildStatistics(),

            const SizedBox(height: 20),

            // =====================================================
            // ANALYTICS
            // =====================================================

            _buildAnalytics(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD HEADER
  // ============================================================

  Widget _buildDashboardHeader() {
    final String welcomeText = widget.user == null
        ? "Welcome back! Here's what's happening."
        : "Welcome back, ${widget.user!.firstName}! Here's what's happening.";

    return LayoutBuilder(
      builder: (context, constraints) {
        // ========================================================
        // MOBILE
        // ========================================================

        if (constraints.maxWidth < 500) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 5),

              // IMPORTANT:
              // Do NOT use const here.
              Text(
                welcomeText,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 15),

              _buildDateButton(),
            ],
          );
        }

        // ========================================================
        // DESKTOP / TABLET
        // ========================================================

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // IMPORTANT:
                  // Do NOT use const here.
                  Text(
                    welcomeText,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 15),

            _buildDateButton(),
          ],
        );
      },
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        int columns;

        if (width >= 1300) {
          columns = 5;
        } else if (width >= 950) {
          columns = 4;
        } else if (width >= 650) {
          columns = 3;
        } else {
          columns = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 10,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: width < 650 ? 1.25 : 1.45,
          ),
          itemBuilder: (context, index) {
            return _buildStatCard(index);
          },
        );
      },
    );
  }

  // ============================================================
  // STAT CARD DATA
  // ============================================================

  Widget _buildStatCard(int index) {
    const cards = [
      DashboardStatCard(
        title: 'Total Mails',
        value: '0',
        subtitle: 'Total emails',
        icon: Icons.mail_outline,
        iconColor: Color(0xFF1677FF),
      ),
      DashboardStatCard(
        title: 'Total Leads',
        value: '0',
        subtitle: 'Total leads',
        icon: Icons.groups_outlined,
        iconColor: Color(0xFF9146FF),
      ),
      DashboardStatCard(
        title: 'Today Leads',
        value: '0',
        subtitle: 'Today leads',
        icon: Icons.people_alt_outlined,
        iconColor: Color(0xFF8D7777),
      ),
      DashboardStatCard(
        title: 'Pending',
        value: '0',
        subtitle: 'Pending emails',
        icon: Icons.access_time,
        iconColor: Color(0xFFFFB800),
      ),
      DashboardStatCard(
        title: 'Sent',
        value: '0',
        subtitle: 'Successfully sent',
        icon: Icons.send_outlined,
        iconColor: Color(0xFF15955E),
      ),
      DashboardStatCard(
        title: 'Seen',
        value: '0',
        subtitle: 'Opened emails',
        icon: Icons.visibility_outlined,
        iconColor: Color(0xFF7041C5),
      ),
      DashboardStatCard(
        title: 'Failed',
        value: '0',
        subtitle: 'Failed emails',
        icon: Icons.cancel_outlined,
        iconColor: Color(0xFFE72D3B),
      ),
      DashboardStatCard(
        title: 'Interested',
        value: '0',
        subtitle: 'Interested leads',
        icon: Icons.thumb_up_alt_outlined,
        iconColor: Color(0xFF1BC69B),
      ),
      DashboardStatCard(
        title: 'Not Interested',
        value: '0',
        subtitle: 'Not interested leads',
        icon: Icons.thumb_down_alt_outlined,
        iconColor: Color(0xFFFF7800),
      ),
      DashboardStatCard(
        title: 'QR Scans',
        value: '0',
        subtitle: 'Total QR code scans',
        icon: Icons.qr_code_2,
        iconColor: Color(0xFF10B8D8),
      ),
    ];

    return cards[index];
  }

  // ============================================================
  // ANALYTICS
  // ============================================================

  Widget _buildAnalytics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return const Column(
            children: [
              CampaignStatusCard(),

              SizedBox(height: 16),

              PlatformTrackingCard(),

              SizedBox(height: 16),

              QrAnalyticsCard(),
            ],
          );
        }

        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampaignStatusCard(),
            ),

            SizedBox(width: 16),

            Expanded(
              child: PlatformTrackingCard(),
            ),

            SizedBox(width: 16),

            Expanded(
              child: QrAnalyticsCard(),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DATE BUTTON
  // ============================================================

  Widget _buildDateButton() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFD0D5DD),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: Color(0xFF667085),
            ),

            const SizedBox(width: 8),

            Text(
              _getDateText(),
              style: const TextStyle(
                color: Color(0xFF344054),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Color(0xFF667085),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// DASHBOARD STAT CARD
// =================================================================

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ========================================================
          // TEXT
          // ========================================================

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ========================================================
          // ICON
          // ========================================================

          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// CAMPAIGN STATUS
// =================================================================

class CampaignStatusCard extends StatelessWidget {
  const CampaignStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AnalyticsCard(
      title: 'Campaign Status Overview',
      child: SizedBox(
        height: 230,
        child: _CampaignStatusContent(),
      ),
    );
  }
}

class _CampaignStatusContent extends StatelessWidget {
  const _CampaignStatusContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: CustomPaint(
            painter: EmptyDonutPainter(),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Mail',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    '0',
                    style: TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 18),

        const Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                color: Color(0xFFFFA800),
                title: 'Pending',
              ),
              _LegendItem(
                color: Color(0xFF19A974),
                title: 'Sent',
              ),
              _LegendItem(
                color: Color(0xFF7C4DFF),
                title: 'Seen',
              ),
              _LegendItem(
                color: Color(0xFFE73B45),
                title: 'Fail',
              ),
              _LegendItem(
                color: Color(0xFF11B5D6),
                title: 'Interested',
              ),
              _LegendItem(
                color: Color(0xFF667085),
                title: 'Not Interested',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =================================================================
// PLATFORM TRACKING
// =================================================================

class PlatformTrackingCard extends StatelessWidget {
  const PlatformTrackingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AnalyticsCard(
      title: 'Platform Click Tracking',
      child: SizedBox(
        height: 230,
        child: _PlatformTrackingContent(),
      ),
    );
  }
}

class _PlatformTrackingContent extends StatelessWidget {
  const _PlatformTrackingContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: CustomPaint(
            painter: EmptyDonutPainter(),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Clicks',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    '0',
                    style: TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 15),

        const Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                color: Color(0xFF20C978),
                title: 'WhatsApp',
              ),
              _LegendItem(
                color: Color(0xFFE83F55),
                title: 'Instagram',
              ),
              _LegendItem(
                color: Color(0xFF2877E8),
                title: 'Facebook Messenger',
              ),
              _LegendItem(
                color: Color(0xFF2299D5),
                title: 'Telegram',
              ),
              _LegendItem(
                color: Color(0xFF0A66C2),
                title: 'LinkedIn',
              ),
              _LegendItem(
                color: Colors.black,
                title: 'X (Twitter)',
              ),
              _LegendItem(
                color: Color(0xFF7C3AED),
                title: 'Threads',
              ),
              _LegendItem(
                color: Color(0xFF667085),
                title: 'Other',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =================================================================
// QR ANALYTICS
// =================================================================

class QrAnalyticsCard extends StatelessWidget {
  const QrAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      title: 'QR Button Click Analytics',
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF15955E),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Text(
          'Total: 0',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: const SizedBox(
        height: 230,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_2,
                size: 45,
                color: Color(0xFFD0D5DD),
              ),

              SizedBox(height: 10),

              Text(
                'No QR click data available',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// ANALYTICS CARD
// =================================================================

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _AnalyticsCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE4E7EC),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),

          child,
        ],
      ),
    );
  }
}

// =================================================================
// LEGEND ITEM
// =================================================================

class _LegendItem extends StatelessWidget {
  final Color color;
  final String title;

  const _LegendItem({
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 2.5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 6),

          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475467),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// EMPTY DONUT
// =================================================================

class EmptyDonutPainter extends CustomPainter {
  const EmptyDonutPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 10;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..color = const Color(0xFFE9EDF2);

    canvas.drawCircle(
      center,
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}