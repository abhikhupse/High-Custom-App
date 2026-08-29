import 'package:flutter/material.dart';

import '../../services/tracking_api.dart';
import '../../widgets/app_skeleton.dart';

// ============================================================
// TRACKING REPORT SCREEN
// ============================================================

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
  // ============================================================
  // COLORS
  // ============================================================

  static const Color background = Color(0xFF020507);

  static const Color cardColor = Color(0xFF071016);

  static const Color cardColor2 = Color(0xFF081118);

  static const Color borderColor = Color(0xFF1B2A35);

  static const Color white = Colors.white;

  static const Color mutedText = Color(0xFFA7AFBD);

  static const Color purple = Color(0xFF7C35FF);

  static const Color green = Color(0xFF00E676);

  static const Color orange = Color(0xFFFF9800);

  static const Color blue = Color(0xFF146CFF);

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;

  String? _error;

  Map<String, dynamic>? _statistics;

  List<dynamic> _deliveries = [];

  int _currentPage = 1;

  int _totalPages = 1;

  int _totalDeliveries = 0;

  static const int _pageSize = 20;

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  // ============================================================
  // DATE
  // ============================================================

  DateTime? _selectedDate;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadReport();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD REPORT
  // ============================================================

  Future<void> _loadReport({int? page}) async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final requestedPage = page ?? _currentPage;

      final response =
          await TrackingApi.getTrackingReport(
        page: requestedPage,
        limit: _pageSize,
      );

      if (!mounted) return;

      if (response['success'] != true) {
        throw Exception(
          response['message']?.toString() ??
              'Unable to load tracking report.',
        );
      }

      setState(() {
        _statistics =
            response['statistics']
                as Map<String, dynamic>?;

        _deliveries =
            response['deliveries']
                    as List<dynamic>? ??
                [];

        final pagination = response['pagination'];

        if (pagination is Map) {
          _currentPage =
              (pagination['page'] as num?)?.toInt() ?? requestedPage;
          _totalPages =
              (pagination['totalPages'] as num?)?.toInt() ?? 1;
          _totalDeliveries =
              (pagination['total'] as num?)?.toInt() ?? _deliveries.length;
        }

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
  // NUMBER
  // ============================================================

  int _number(String key) {
    final value = _statistics?[key];

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  // ============================================================
  // PERCENTAGE
  // ============================================================

  double _percentage(String key) {
    final value = _statistics?[key];

    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  // ============================================================
  // FILTERED DELIVERIES
  // ============================================================

  List<dynamic> get _filteredDeliveries {
    final query =
        _searchQuery.trim().toLowerCase();

    return _deliveries.where((delivery) {
      if (delivery is! Map) {
        return false;
      }

      final lead = delivery['leadId'];

      final sequence =
          delivery['sequenceId'];

      String firstName = '';
      String lastName = '';
      String email = '';
      String subject = '';

      if (lead is Map) {
        firstName =
            lead['firstName']
                ?.toString()
                .toLowerCase() ??
            '';

        lastName =
            lead['lastName']
                ?.toString()
                .toLowerCase() ??
            '';

        email =
            lead['email']
                ?.toString()
                .toLowerCase() ??
            '';
      }

      if (sequence is Map) {
        subject =
            sequence['subject']
                ?.toString()
                .toLowerCase() ??
            '';
      }

      // ========================================================
      // SEARCH
      // ========================================================

      if (query.isNotEmpty) {
        final searchable =
            '$firstName $lastName $email $subject';

        if (!searchable.contains(query)) {
          return false;
        }
      }

      // ========================================================
      // DATE FILTER
      // ========================================================

      if (_selectedDate != null) {
        final dateValue =
            delivery['sentAt'] ??
            delivery['createdAt'] ??
            delivery['updatedAt'];

        if (dateValue == null) {
          return false;
        }

        try {
          final date =
              DateTime.parse(
                dateValue.toString(),
              ).toLocal();

          if (date.year !=
                  _selectedDate!.year ||
              date.month !=
                  _selectedDate!.month ||
              date.day !=
                  _selectedDate!.day) {
            return false;
          }
        } catch (_) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: background,
      child: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const AppDashboardSkeleton();
    }

    if (_error != null) {
      return _buildError();
    }

    return RefreshIndicator(
      color: purple,
      backgroundColor: cardColor,
      onRefresh: _loadReport,
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final bool isMobile =
              constraints.maxWidth < 700;

          return ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              isMobile ? 14 : 24,
              isMobile ? 16 : 24,
              isMobile ? 14 : 24,
              35,
            ),
            children: [
              // =================================================
              // HEADER
              // =================================================

              _buildHeader(
                isMobile,
              ),

              const SizedBox(
                height: 22,
              ),

              // =================================================
              // STATISTICS
              // =================================================

              _buildStatistics(
                isMobile,
              ),

              const SizedBox(
                height: 22,
              ),

              // =================================================
              // EMAIL ACTIVITY
              // =================================================

              _buildEmailActivity(
                isMobile,
              ),

              const SizedBox(
                height: 18,
              ),

              // =================================================
              // EXPORT
              // =================================================

              _buildExportButton(),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ===============================================
              // ICON
              // ===============================================

              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                    colors: [
                      Color(
                        0xFF4438FF,
                      ),
                      Color(
                        0xFF9400FF,
                      ),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .trending_up_rounded,
                  color:
                      Colors.white,
                  size: 31,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      'Tracking Report',
                      style:
                          TextStyle(
                        color:
                            white,
                        fontSize:
                            23,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Email sequence performance analytics',
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          TextStyle(
                        color:
                            mutedText,
                        fontSize:
                            isMobile
                                ? 12
                                : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Align(
            alignment:
                Alignment.centerRight,
            child:
                _buildDateButton(),
          ),
        ],
      );
    }

    // ==========================================================
    // DESKTOP HEADER
    // ==========================================================

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration:
              BoxDecoration(
            gradient:
                const LinearGradient(
              colors: [
                Color(
                  0xFF4438FF,
                ),
                Color(
                  0xFF9400FF,
                ),
              ],
            ),
            borderRadius:
                BorderRadius.circular(
              15,
            ),
          ),
          child:
              const Icon(
            Icons
                .trending_up_rounded,
            color:
                Colors.white,
            size: 36,
          ),
        ),

        const SizedBox(
          width: 18,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                'Tracking Report',
                style:
                    TextStyle(
                  color:
                      white,
                  fontSize:
                      30,
                  fontWeight:
                      FontWeight
                          .w800,
                ),
              ),

              SizedBox(
                height: 4,
              ),

              Text(
                'Email sequence performance analytics',
                style:
                    TextStyle(
                  color:
                      mutedText,
                  fontSize:
                      15,
                ),
              ),
            ],
          ),
        ),

        _buildDateButton(),
      ],
    );
  }

  // ============================================================
  // DATE BUTTON
  // ============================================================

  Widget _buildDateButton() {
    return InkWell(
      onTap: _selectDate,
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child: Container(
        height: 52,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 17,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFF071016,
          ),
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          border:
              Border.all(
            color:
                borderColor,
          ),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .calendar_month_outlined,
              color:
                  Color(
                0xFFC3C9D4,
              ),
              size: 23,
            ),

            const SizedBox(
              width: 10,
            ),

            Text(
              _selectedDate ==
                      null
                  ? 'All Dates'
                  : _formatOnlyDate(
                      _selectedDate!,
                    ),
              style:
                  const TextStyle(
                color:
                    white,
                fontSize:
                    14,
                fontWeight:
                    FontWeight
                        .w600,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            const Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              color:
                  Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> _selectDate() async {
    final selected =
        await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now(),
      firstDate:
          DateTime(
        2020,
      ),
      lastDate:
          DateTime(
        2035,
      ),
      builder: (
        context,
        child,
      ) {
        return Theme(
          data:
              Theme.of(
            context,
          ).copyWith(
            colorScheme:
                const ColorScheme.dark(
              primary:
                  purple,
              surface:
                  cardColor,
            ),
            dialogTheme:
                const DialogThemeData(
              backgroundColor:
                  cardColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _selectedDate =
          selected;
    });
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics(
    bool isMobile,
  ) {
    final totalSent =
        _number(
      'totalSent',
    );

    final opened =
        _number(
      'totalOpened',
    );

    // ==========================================================
    // SENT BUT NOT OPENED
    // ==========================================================

    int sent =
        _number(
      'totalNotOpened',
    );

    if (sent == 0 &&
        totalSent >= opened) {
      sent =
          totalSent -
          opened;
    }

    final openRate =
        _percentage(
      'openRate',
    );

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final width =
            constraints.maxWidth;

        // ======================================================
        // MOBILE = 2 X 2
        // ======================================================

        if (isMobile) {
          final cardWidth =
              (width - 10) /
                  2;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statCard(
                width:
                    cardWidth,
                title:
                    'Total Sent',
                value:
                    totalSent
                        .toString(),
                subtitle:
                    'Emails sent',
                icon:
                    Icons
                        .send_rounded,
                iconColor:
                    purple,
                iconBackground:
                    const Color(
                  0xFF1D123D,
                ),
              ),

              _statCard(
                width:
                    cardWidth,
                title:
                    'Opened',
                value:
                    opened
                        .toString(),
                subtitle:
                    'Emails opened',
                icon:
                    Icons
                        .email_rounded,
                iconColor:
                    green,
                iconBackground:
                    const Color(
                  0xFF00331E,
                ),
              ),

              _statCard(
                width:
                    cardWidth,
                title:
                    'Sent',
                value:
                    sent
                        .toString(),
                subtitle:
                    'Emails sent',
                icon:
                    Icons
                        .send_rounded,
                iconColor:
                    blue,
                iconBackground:
                    const Color(
                  0xFF062453,
                ),
              ),

              _statCard(
                width:
                    cardWidth,
                title:
                    'Open Rate',
                value:
                    '${openRate.toStringAsFixed(1)}%',
                subtitle:
                    'Success rate',
                icon:
                    Icons
                        .bar_chart_rounded,
                iconColor:
                    blue,
                iconBackground:
                    const Color(
                  0xFF062453,
                ),
              ),
            ],
          );
        }

        // ======================================================
        // DESKTOP = 4 IN ONE ROW
        // ======================================================

        final cardWidth =
            (width - 36) /
                4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard(
              width:
                  cardWidth,
              title:
                  'Total Sent',
              value:
                  totalSent
                      .toString(),
              subtitle:
                  'Emails sent',
              icon:
                  Icons
                      .send_rounded,
              iconColor:
                  purple,
              iconBackground:
                  const Color(
                0xFF1D123D,
              ),
            ),

            _statCard(
              width:
                  cardWidth,
              title:
                  'Opened',
              value:
                  opened
                      .toString(),
              subtitle:
                  'Emails opened',
              icon:
                  Icons
                      .email_rounded,
              iconColor:
                  green,
              iconBackground:
                  const Color(
                0xFF00331E,
              ),
            ),

            _statCard(
              width:
                  cardWidth,
              title:
                  'Sent',
              value:
                  sent
                      .toString(),
              subtitle:
                  'Emails sent',
              icon:
                  Icons
                      .send_rounded,
              iconColor:
                  blue,
              iconBackground:
                  const Color(
                0xFF062453,
              ),
            ),

            _statCard(
              width:
                  cardWidth,
              title:
                  'Open Rate',
              value:
                  '${openRate.toStringAsFixed(1)}%',
              subtitle:
                  'Success rate',
              icon:
                  Icons
                      .bar_chart_rounded,
              iconColor:
                  blue,
              iconBackground:
                  const Color(
                0xFF062453,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        constraints:
            const BoxConstraints(
          minHeight: 132,
        ),
        padding:
            const EdgeInsets.all(
          14,
        ),
        decoration:
            BoxDecoration(
          color:
              cardColor,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          border:
              Border.all(
            color:
                borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration:
                      BoxDecoration(
                    color:
                        iconBackground,
                    borderRadius:
                        BorderRadius
                            .circular(
                      11,
                    ),
                  ),
                  child:
                      Icon(
                    icon,
                    color:
                        iconColor,
                    size: 24,
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      Text(
                    title,
                    maxLines: 2,
                    style:
                        const TextStyle(
                      color:
                          white,
                      fontSize:
                          13,
                      fontWeight:
                          FontWeight
                              .w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 13,
            ),

            Text(
              value,
              maxLines: 1,
              style:
                  const TextStyle(
                color:
                    white,
                fontSize:
                    27,
                fontWeight:
                    FontWeight
                        .w800,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              subtitle,
              style:
                  const TextStyle(
                color:
                    mutedText,
                fontSize:
                    11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMAIL ACTIVITY
  // ============================================================

  Widget _buildEmailActivity(
    bool isMobile,
  ) {
    final deliveries =
        _filteredDeliveries;

    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.all(
        isMobile ? 13 : 20,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF040B10,
        ),
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        border:
            Border.all(
          color:
              borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          // ====================================================
          // TITLE
          // ====================================================

          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF1D123D,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .email_outlined,
                  color:
                      purple,
                  size: 24,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Email Activity',
                      style:
                          TextStyle(
                        color:
                            white,
                        fontSize:
                            21,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Latest email tracking events',
                      style:
                          TextStyle(
                        color:
                            mutedText,
                        fontSize:
                            12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 17,
          ),

          // ====================================================
          // SEARCH
          // ====================================================

          _buildSearch(),

          const SizedBox(
            height: 18,
          ),

          // ====================================================
          // CARDS
          // ====================================================

          if (deliveries.isEmpty)
            _buildEmptyState()
          else
            ...deliveries.map(
              (delivery) =>
                  _buildDeliveryCard(
                delivery,
                isMobile,
              ),
            ),

          if (_totalPages > 1) ...[
            const SizedBox(height: 12),
            _buildPagination(),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.outlined(
          tooltip: 'Previous page',
          onPressed: _currentPage > 1
              ? () => _loadReport(page: _currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Page $_currentPage of $_totalPages • $_totalDeliveries records',
            style: const TextStyle(color: mutedText, fontSize: 13),
          ),
        ),
        IconButton.outlined(
          tooltip: 'Next page',
          onPressed: _currentPage < _totalPages
              ? () => _loadReport(page: _currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return TextField(
      controller:
          _searchController,
      onChanged: (
        value,
      ) {
        setState(() {
          _searchQuery =
              value;
        });
      },
      style:
          const TextStyle(
        color:
            white,
        fontSize:
            14,
      ),
      decoration:
          InputDecoration(
        hintText:
            'Search by name or email...',
        hintStyle:
            const TextStyle(
          color:
              mutedText,
          fontSize:
              14,
        ),
        prefixIcon:
            const Icon(
          Icons
              .search_rounded,
          color:
              Color(
            0xFFABB3C4,
          ),
        ),
        filled:
            true,
        fillColor:
            const Color(
          0xFF071016,
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 16,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            13,
          ),
          borderSide:
              const BorderSide(
            color:
                borderColor,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            13,
          ),
          borderSide:
              const BorderSide(
            color:
                borderColor,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            13,
          ),
          borderSide:
              const BorderSide(
            color:
                purple,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DELIVERY CARD
  // ============================================================

  Widget _buildDeliveryCard(
    dynamic delivery,
    bool isMobile,
  ) {
    final sequence =
        delivery['sequenceId'];

    final lead =
        delivery['leadId'];

    final openedAt =
        delivery['openedAt'];

    final sentAt =
        delivery['sentAt'] ??
        delivery['createdAt'];

    final response =
        delivery['response']?.toString() ?? '';

    final responseStatus =
        delivery['responseStatus']?.toString() ?? '';

    final respondedAt =
        delivery['respondedAt'];

    final firstName =
        lead is Map
            ? lead['firstName']
                    ?.toString() ??
                ''
            : '';

    final lastName =
        lead is Map
            ? lead['lastName']
                    ?.toString() ??
                ''
            : '';

    final email =
        lead is Map
            ? lead['email']
                    ?.toString() ??
                ''
            : '';

    final name =
        '$firstName $lastName'
            .trim();

    final step =
        sequence is Map
            ? sequence['step']
                    ?.toString() ??
                '-'
            : '-';

    final variant =
        sequence is Map
            ? sequence['variant']
                    ?.toString() ??
                '-'
            : '-';

    final subject =
        sequence is Map
            ? sequence['subject']
                    ?.toString() ??
                'No Subject'
            : 'No Subject';

    final bool opened =
        openedAt != null;

    final statusLabel = responseStatus.isNotEmpty
        ? responseStatus
        : response == 'interested'
        ? 'Interested'
        : response == 'notInterested'
            ? 'Not Interested'
            : opened
                ? 'Opened'
                : 'Sent';

    final eventDate =
        response.isNotEmpty
            ? (respondedAt ?? sentAt)
            : opened
            ? openedAt
            : sentAt;

    final displayName =
        name.isNotEmpty
            ? name
            : email.isNotEmpty
                ? email
                : 'Unknown Lead';

    final initial =
        displayName.isNotEmpty
            ? displayName[0]
                .toUpperCase()
            : '?';

    // ==========================================================
    // MOBILE CARD
    // ==========================================================

    if (isMobile) {
      return Container(
        width: double.infinity,
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),
        padding:
            const EdgeInsets.all(
          14,
        ),
        decoration:
            BoxDecoration(
          color:
              cardColor2,
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          border:
              Border.all(
            color:
                borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            // ==================================================
            // LEAD + STATUS
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                _buildAvatar(
                  initial,
                  email,
                ),

                const SizedBox(
                  width: 11,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              white,
                          fontSize:
                              15,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),

                      if (email
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          email,
                          maxLines:
                              1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                mutedText,
                            fontSize:
                                11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                _statusBadge(statusLabel),
              ],
            ),

            const SizedBox(
              height: 13,
            ),

            // ==================================================
            // STEP / VARIANT
            // ==================================================

            Row(
              children: [
                _stepBadge(
                  'Step $step',
                ),

                const SizedBox(
                  width: 7,
                ),

                _variantBadge(
                  'Variant $variant',
                ),

                const Spacer(),

                Text(
                  '$statusLabel ${_formatTime(eventDate)}',
                  style:
                      TextStyle(
                    color:
                        statusLabel == 'Interested'
                            ? green
                            : statusLabel == 'Not Interested'
                                ? const Color(0xFFFF5B66)
                                : opened
                                    ? green
                                    : orange,
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight
                            .w500,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 13,
            ),

            Container(
              width:
                  double.infinity,
              height: 1,
              color:
                  borderColor,
            ),

            const SizedBox(
              height: 13,
            ),

            // ==================================================
            // SUBJECT
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  '🚀',
                  style:
                      TextStyle(
                    fontSize:
                        17,
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        subject,
                        maxLines:
                            2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              white,
                          fontSize:
                              14,
                          height:
                              1.35,
                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        _formatDateOnly(
                          eventDate,
                        ),
                        style:
                            const TextStyle(
                          color:
                              mutedText,
                          fontSize:
                              11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // DESKTOP CARD
    // ==========================================================

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor2,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border:
            Border.all(
          color:
              borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          // ====================================================
          // LEAD
          // ====================================================

          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildAvatar(
                  initial,
                  email,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        displayName,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              white,
                          fontSize:
                              14,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        email,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              mutedText,
                          fontSize:
                              11,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Row(
                        children: [
                          _stepBadge(
                            'Step $step',
                          ),

                          const SizedBox(
                            width: 6,
                          ),

                          _variantBadge(
                            'Variant $variant',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 75,
            color:
                borderColor,
          ),

          const SizedBox(
            width: 20,
          ),

          // ====================================================
          // SUBJECT
          // ====================================================

          Expanded(
            flex: 4,
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  '🚀',
                  style:
                      TextStyle(
                    fontSize:
                        18,
                  ),
                ),

                const SizedBox(
                  width: 9,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        subject,
                        maxLines:
                            2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              white,
                          fontSize:
                              14,
                          height:
                              1.4,
                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        _formatDateOnly(
                          eventDate,
                        ),
                        style:
                            const TextStyle(
                          color:
                              mutedText,
                          fontSize:
                              11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 20,
          ),

          // ====================================================
          // STATUS
          // ====================================================

          SizedBox(
            width: 115,
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                _statusBadge(statusLabel),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  'at ${_formatTime(eventDate)}',
                  style:
                      const TextStyle(
                    color:
                        mutedText,
                    fontSize:
                        11,
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
  // AVATAR
  // ============================================================

  Widget _buildAvatar(
    String initial,
    String seed,
  ) {
    final colors = [
      const Color(
        0xFF5B16E8,
      ),
      const Color(
        0xFF0059FF,
      ),
      const Color(
        0xFFFF6500,
      ),
      const Color(
        0xFF16783D,
      ),
      const Color(
        0xFFE8223B,
      ),
      const Color(
        0xFF007C93,
      ),
      const Color(
        0xFFE89400,
      ),
    ];

    final index =
        seed.hashCode
            .abs() %
        colors.length;

    return Container(
      width: 45,
      height: 45,
      decoration:
          BoxDecoration(
        color:
            colors[index],
        shape:
            BoxShape.circle,
      ),
      alignment:
          Alignment.center,
      child: Text(
        initial,
        style:
            const TextStyle(
          color:
              Colors.white,
          fontSize:
              20,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // STEP BADGE
  // ============================================================

  Widget _stepBadge(
    String text,
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
            const Color(
          0xFF1B1033,
        ),
        borderRadius:
            BorderRadius.circular(
          7,
        ),
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          color:
              Color(
            0xFFB45CFF,
          ),
          fontSize:
              11,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // VARIANT BADGE
  // ============================================================

  Widget _variantBadge(
    String text,
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
            const Color(
          0xFF111820,
        ),
        borderRadius:
            BorderRadius.circular(
          7,
        ),
        border:
            Border.all(
          color:
              borderColor,
        ),
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          color:
              Color(
            0xFFC1C7D0,
          ),
          fontSize:
              11,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    String status,
  ) {
    final color = status == 'Interested'
        ? green
        : status == 'Not Interested'
            ? const Color(0xFFFF5B66)
            : status == 'Opened'
                ? green
                : orange;

    return Container(
      constraints:
          const BoxConstraints(
        minWidth: 70,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            status == 'Interested' || status == 'Opened'
                ? const Color(0xFF002F1C)
                : status == 'Not Interested'
                    ? const Color(0xFF3A1014)
                    : const Color(0xFF2D1B05),
        borderRadius:
            BorderRadius.circular(
          8,
        ),
        border:
            Border.all(
          color:
              color.withOpacity(
            0.20,
          ),
        ),
      ),
      child: Text(
        status,
        textAlign:
            TextAlign.center,
        style:
            TextStyle(
          color:
              color,
          fontSize:
              12,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // EXPORT BUTTON
  // ============================================================

  Widget _buildExportButton() {
    return Container(
      width:
          double.infinity,
      height: 55,
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.centerLeft,
          end:
              Alignment.centerRight,
          colors: [
            Color(
              0xFF1537E8,
            ),
            Color(
              0xFF6B17DC,
            ),
            Color(
              0xFFB408C5,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child:
          ElevatedButton.icon(
        onPressed:
            _exportReport,
        icon:
            const Icon(
          Icons
              .download_rounded,
          color:
              Colors.white,
          size: 21,
        ),
        label:
            const Text(
          'Export Report',
          style:
              TextStyle(
            color:
                Colors.white,
            fontSize:
                15,
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
          elevation:
              0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EXPORT
  // ============================================================

  void _exportReport() {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        behavior:
            SnackBarBehavior
                .floating,
        backgroundColor:
            Color(
          0xFF121820,
        ),
        content:
            Text(
          'Export functionality will be connected here.',
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 55,
        horizontal: 20,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor2,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border:
            Border.all(
          color:
              borderColor,
        ),
      ),
      child:
          const Column(
        children: [
          Icon(
            Icons
                .mail_outline_rounded,
            color:
                mutedText,
            size: 45,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'No email activity',
            style:
                TextStyle(
              color:
                  white,
              fontSize:
                  15,
              fontWeight:
                  FontWeight
                      .w700,
            ),
          ),

          SizedBox(
            height: 5,
          ),

          Text(
            'Tracking activity will appear here.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  mutedText,
              fontSize:
                  12,
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
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration:
                  BoxDecoration(
                color:
                    Colors.red
                        .withOpacity(
                  0.10,
                ),
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child:
                  const Icon(
                Icons
                    .error_outline_rounded,
                color:
                    Colors.redAccent,
                size: 35,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              _error!,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    mutedText,
                fontSize:
                    14,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton.icon(
              onPressed:
                  _loadReport,
              icon:
                  const Icon(
                Icons
                    .refresh_rounded,
              ),
              label:
                  const Text(
                'Retry',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    purple,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal:
                      22,
                  vertical:
                      13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE ONLY
  // ============================================================

  String _formatDateOnly(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

    try {
      final date =
          DateTime.parse(
        value.toString(),
      ).toLocal();

      return _formatOnlyDate(
        date,
      );
    } catch (_) {
      return '-';
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatOnlyDate(
    DateTime date,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }

  // ============================================================
  // TIME
  // ============================================================

  String _formatTime(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

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
              .padLeft(
                2,
                '0',
              );

      final period =
          date.hour >= 12
              ? 'PM'
              : 'AM';

      return '$hour:$minute $period';
    } catch (_) {
      return '-';
    }
  }
}
