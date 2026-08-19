import 'package:flutter/material.dart';

import '../../services/tracking_api.dart';

class TrackingReportScreen extends StatefulWidget {
  const TrackingReportScreen({
    super.key,
  });

  @override
  State<TrackingReportScreen> createState() =>
      _TrackingReportScreenState();
}

class _TrackingReportScreenState
    extends State<TrackingReportScreen> {
  bool _loading = true;

  String? _error;

  Map<String, dynamic>? _statistics;

  List<dynamic> _deliveries = [];

  @override
  void initState() {
    super.initState();

    _loadReport();
  }

  // ============================================================
  // LOAD REPORT
  // ============================================================

  Future<void> _loadReport() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response =
          await TrackingApi.getTrackingReport();

      if (!mounted) return;

      setState(() {
        _statistics =
            response['statistics']
                as Map<String, dynamic>?;

        _deliveries =
            response['deliveries']
                    as List<dynamic>? ??
                [];

        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int _number(String key) {
    final value = _statistics?[key];

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  double _percentage(String key) {
    final value = _statistics?[key];

    if (value is num) {
      return value.toDouble();
    }

    return 0;
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
      child: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        22,
        24,
        18,
      ),
      color: const Color(0xFFF5F7FA),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: const [
                Text(
                  'Tracking Report',
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Track sequence email opens and delivery performance.',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _loading ? null : _loadReport,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF101828),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          24,
          0,
          24,
          30,
        ),
        children: [
          _buildStatistics(),

          const SizedBox(height: 28),

          _buildDeliveryHeader(),

          const SizedBox(height: 14),

          if (_deliveries.isEmpty)
            _buildEmptyState()
          else
            ..._deliveries.map(
              _buildDeliveryCard,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final width = constraints.maxWidth;

        double cardWidth;

        if (width >= 1100) {
          cardWidth =
              (width - 48) / 4;
        } else if (width >= 650) {
          cardWidth =
              (width - 16) / 2;
        } else {
          cardWidth = width;
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _statCard(
              width: cardWidth,
              title: 'Total Sent',
              value: _number(
                'totalSent',
              ),
              icon: Icons.send_outlined,
            ),

            _statCard(
              width: cardWidth,
              title: 'Opened',
              value: _number(
                'totalOpened',
              ),
              icon:
                  Icons.mark_email_read_outlined,
            ),

            _statCard(
              width: cardWidth,
              title: 'Not Opened',
              value: _number(
                'totalNotOpened',
              ),
              icon:
                  Icons.mark_email_unread_outlined,
            ),

            _statCard(
              width: cardWidth,
              title: 'Open Rate',
              value:
                  '${_percentage('openRate').toStringAsFixed(1)}%',
              icon: Icons.bar_chart_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required double width,
    required String title,
    required dynamic value,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE4E7EC),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(
                0.03,
              ),
              blurRadius: 12,
              offset:
                  const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFD4AF37)
                        .withOpacity(0.12),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color:
                    const Color(0xFFD4AF37),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color:
                          Color(0xFF667085),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    value.toString(),
                    style: const TextStyle(
                      color:
                          Color(0xFF101828),
                      fontSize: 24,
                      fontWeight:
                          FontWeight.w800,
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

  // ============================================================
  // DELIVERY HEADER
  // ============================================================

  Widget _buildDeliveryHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Sequence Deliveries',
            style: TextStyle(
              color: Color(0xFF101828),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        Text(
          '${_deliveries.length} records',
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DELIVERY CARD
  // ============================================================

  Widget _buildDeliveryCard(
    dynamic delivery,
  ) {
    final sequence =
        delivery['sequenceId'];

    final lead =
        delivery['leadId'];

    final openedAt =
        delivery['openedAt'];

    final openedCount =
        delivery['openedCount'] ?? 0;

    final status =
        delivery['status']
            ?.toString() ??
        '';

    final email =
        lead is Map
            ? lead['email']?.toString()
            : null;

    final firstName =
        lead is Map
            ? lead['firstName']?.toString()
            : null;

    final lastName =
        lead is Map
            ? lead['lastName']?.toString()
            : null;

    final leadName = [
      firstName,
      lastName,
    ]
        .where(
          (value) =>
              value != null &&
              value.trim().isNotEmpty,
        )
        .join(' ');

    final sequenceStep =
        sequence is Map
            ? sequence['step']
            : null;

    final variant =
        sequence is Map
            ? sequence['variant']
            : null;

    final subject =
        sequence is Map
            ? sequence['subject']
            : null;

    final isOpened =
        openedAt != null;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              const Color(0xFFE4E7EC),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.025,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  leadName.isNotEmpty
                      ? leadName
                      : email ??
                          'Unknown Lead',
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF101828),
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              _statusBadge(
                isOpened,
              ),
            ],
          ),

          if (email != null) ...[
            const SizedBox(height: 5),

            Text(
              email,
              style:
                  const TextStyle(
                color:
                    Color(0xFF667085),
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 14),

          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _infoItem(
                'Step',
                sequenceStep
                        ?.toString() ??
                    '-',
              ),

              _infoItem(
                'Variant',
                variant
                        ?.toString() ??
                    '-',
              ),

              _infoItem(
                'Opens',
                openedCount
                    .toString(),
              ),

              _infoItem(
                'Status',
                status.isEmpty
                    ? '-'
                    : status,
              ),
            ],
          ),

          if (subject != null) ...[
            const SizedBox(height: 14),

            Text(
              subject.toString(),
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color:
                    Color(0xFF344054),
                fontSize: 14,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ],

          if (openedAt != null) ...[
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color:
                      Colors.green,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  'First opened: ${_formatDate(openedAt)}',
                  style:
                      const TextStyle(
                    color:
                        Colors.green,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusBadge(
    bool opened,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            opened
                ? Colors.green
                    .withOpacity(0.10)
                : Colors.orange
                    .withOpacity(0.10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            opened
                ? Icons.check_circle
                : Icons.schedule,
            size: 15,
            color:
                opened
                    ? Colors.green
                    : Colors.orange,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            opened
                ? 'Opened'
                : 'Pending',
            style:
                TextStyle(
              color:
                  opened
                      ? Colors.green
                      : Colors.orange,
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO
  // ============================================================

  Widget _infoItem(
    String title,
    String value,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Text(
          '$title: ',
          style:
              const TextStyle(
            color:
                Color(0xFF98A2B3),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style:
              const TextStyle(
            color:
                Color(0xFF344054),
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 70,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              const Color(0xFFE4E7EC),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            color:
                Color(0xFF98A2B3),
            size: 52,
          ),

          SizedBox(height: 14),

          Text(
            'No tracking data yet',
            style: TextStyle(
              color:
                  Color(0xFF344054),
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Send a sequence email and open it to see tracking data here.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Color(0xFF667085),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 50,
            ),

            const SizedBox(height: 14),

            Text(
              _error!,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Color(0xFF344054),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed:
                  _loadReport,
              child:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
    dynamic value,
  ) {
    try {
      final date =
          DateTime.parse(
        value.toString(),
      ).toLocal();

      final hour =
          date.hour == 0
              ? 12
              : date.hour > 12
                  ? date.hour - 12
                  : date.hour;

      final minute =
          date.minute
              .toString()
              .padLeft(2, '0');

      final period =
          date.hour >= 12
              ? 'PM'
              : 'AM';

      return '${date.day}/${date.month}/${date.year} '
          '$hour:$minute $period';
    } catch (_) {
      return value.toString();
    }
  }
}