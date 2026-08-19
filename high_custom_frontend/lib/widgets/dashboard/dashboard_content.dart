import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/sequence_api.dart';

class DashboardContent extends StatefulWidget {
  final UserModel? user;

  const DashboardContent({
    super.key,
    this.user,
  });

  @override
  State<DashboardContent> createState() =>
      _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  // ============================================================
  // DATE FILTER
  // ============================================================

  bool todayOnly = false;

  DateTime? fromDate;

  DateTime? toDate;

  // ============================================================
  // TRACKING SUMMARY
  // ============================================================

  Map<String, dynamic> _trackingSummary = {
    'totalMails': 0,
    'sent': 0,
    'failed': 0,
    'opened': 0,
    'clicked': 0,
    'pending': 0,
    'interested': 0,
    'notInterested': 0,
    'totalLeads': 0,
    'todayLeads': 0,
    'qrScans': 0,
  };

  bool _isLoadingSummary = true;

  bool _isRefreshing = false;

  String? _summaryError;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadTrackingSummary();
  }

  // ============================================================
  // LOAD TRACKING SUMMARY
  // ============================================================

  Future<void> _loadTrackingSummary({
    bool showLoading = true,
  }) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() {
        _isLoadingSummary = true;
        _summaryError = null;
      });
    } else {
      setState(() {
        _isRefreshing = true;
        _summaryError = null;
      });
    }

    try {
      final result = await SequenceApi.getTrackingSummary(
        startDate: fromDate,
        endDate: toDate,
      );

      if (!mounted) return;

      // ==========================================================
      // API ERROR
      // ==========================================================

      if (result['success'] == false) {
        setState(() {
          _summaryError =
              result['message']?.toString() ??
                  'Unable to load dashboard data.';
        });

        return;
      }

      // ==========================================================
      // GET DATA
      //
      // Supports:
      //
      // {
      //   success: true,
      //   data: {...}
      // }
      //
      // OR
      //
      // {
      //   success: true,
      //   totalMails: 10
      // }
      // ==========================================================

      dynamic rawData = result['data'];

      if (rawData is! Map) {
        rawData = result;
      }

      if (rawData is Map) {
        final Map data = Map.from(rawData);

        setState(() {
          _trackingSummary = {
            'totalMails': _toInt(
              data['totalMails'],
            ),

            'sent': _toInt(
              data['sent'],
            ),

            'failed': _toInt(
              data['failed'],
            ),

            'opened': _toInt(
              data['opened'],
            ),

            'clicked': _toInt(
              data['clicked'],
            ),

            'pending': _toInt(
              data['pending'],
            ),

            'interested': _toInt(
              data['interested'],
            ),

            'notInterested': _toInt(
              data['notInterested'],
            ),

            'totalLeads': _toInt(
              data['totalLeads'],
            ),

            'todayLeads': _toInt(
              data['todayLeads'],
            ),

            'qrScans': _toInt(
              data['qrScans'],
            ),
          };

          _summaryError = null;
        });
      } else {
        setState(() {
          _summaryError =
              'Invalid dashboard data received from server.';
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _summaryError =
            'Unable to load dashboard statistics.';
      });

      debugPrint(
        'Dashboard summary error: $error',
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoadingSummary = false;
        _isRefreshing = false;
      });
    }
  }

  // ============================================================
  // SAFE INT
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  // ============================================================
  // NUMERIC VALUE
  // ============================================================

  int _numericValue(String key) {
    return _toInt(
      _trackingSummary[key],
    );
  }

  // ============================================================
  // COUNT LABEL
  // ============================================================

  String _countLabel(String key) {
    if (_isLoadingSummary) {
      return '...';
    }

    return _numericValue(key).toString();
  }

  // ============================================================
  // ACTIVE DATE FILTER
  // ============================================================

  bool get _hasActiveDateFilter {
    return todayOnly ||
        fromDate != null ||
        toDate != null;
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // DATE TEXT
  // ============================================================

  String _getDateText() {
    if (todayOnly) {
      return 'Today';
    }

    if (fromDate != null &&
        toDate != null) {
      return '${_formatDateLabel(fromDate!)} - '
          '${_formatDateLabel(toDate!)}';
    }

    if (fromDate != null) {
      return 'From ${_formatDateLabel(fromDate!)}';
    }

    if (toDate != null) {
      return 'Until ${_formatDateLabel(toDate!)}';
    }

    return 'Today';
  }

  // ============================================================
  // SHOW DATE FILTER
  // ============================================================

  Future<void> _showDateFilter() async {
    DateTime? tempFromDate = fromDate;

    DateTime? tempToDate = toDate;

    bool tempTodayOnly = todayOnly;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return Dialog(
              backgroundColor: Colors.transparent,

              insetPadding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),

              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 520,
                ),

                child: Container(
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),
                  ),

                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      // ==================================================
                      // HEADER
                      // ==================================================

                      Container(
                        padding:
                            const EdgeInsets.all(20),

                        decoration:
                            const BoxDecoration(
                          color:
                              Color(0xFF101828),

                          borderRadius:
                              BorderRadius.only(
                            topLeft:
                                Radius.circular(18),
                            topRight:
                                Radius.circular(18),
                          ),
                        ),

                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,

                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFF315BEF,
                                ).withOpacity(0.18),

                                borderRadius:
                                    BorderRadius.circular(
                                  10,
                                ),
                              ),

                              child:
                                  const Icon(
                                Icons
                                    .calendar_month_outlined,

                                color:
                                    Color(0xFF7C9AFF),
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filter Dashboard',

                                    style:
                                        TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize:
                                          18,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),

                                  SizedBox(
                                    height: 3,
                                  ),

                                  Text(
                                    'Select a date range to filter stats',

                                    style:
                                        TextStyle(
                                      color:
                                          Color(0xFF98A2B3),
                                      fontSize:
                                          12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              onPressed:
                                  () =>
                                      Navigator.pop(
                                dialogContext,
                              ),

                              icon:
                                  const Icon(
                                Icons.close,
                                color:
                                    Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // BODY
                      // ==================================================

                      Padding(
                        padding:
                            const EdgeInsets.all(20),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            const Text(
                              'Date Range',

                              style:
                                  TextStyle(
                                color:
                                    Color(0xFF101828),
                                fontSize:
                                    14,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child:
                                      _dateBox(
                                    label:
                                        'From Date',

                                    date:
                                        tempFromDate,

                                    onTap:
                                        () async {
                                      final date =
                                          await _pickSingleDate(
                                        context,
                                        tempFromDate ??
                                            DateTime.now(),
                                      );

                                      if (date !=
                                          null) {
                                        setDialogState(
                                          () {
                                            tempFromDate =
                                                date;

                                            tempTodayOnly =
                                                false;

                                            if (tempToDate !=
                                                    null &&
                                                tempToDate!
                                                    .isBefore(
                                                  date,
                                                )) {
                                              tempToDate =
                                                  date;
                                            }
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child:
                                      _dateBox(
                                    label:
                                        'To Date',

                                    date:
                                        tempToDate,

                                    onTap:
                                        () async {
                                      final date =
                                          await _pickSingleDate(
                                        context,
                                        tempToDate ??
                                            tempFromDate ??
                                            DateTime.now(),
                                      );

                                      if (date !=
                                          null) {
                                        if (tempFromDate !=
                                                null &&
                                            date.isBefore(
                                              tempFromDate!,
                                            )) {
                                          ScaffoldMessenger
                                                  .of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text(
                                                'To Date cannot be before From Date.',
                                              ),
                                            ),
                                          );

                                          return;
                                        }

                                        setDialogState(
                                          () {
                                            tempToDate =
                                                date;

                                            tempTodayOnly =
                                                false;
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            const Text(
                              'Quick Select',

                              style:
                                  TextStyle(
                                color:
                                    Color(0xFF101828),
                                fontSize:
                                    14,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,

                              children: [
                                _quickDateButton(
                                  'Today',
                                  () {
                                    final now =
                                        DateTime.now();

                                    setDialogState(
                                      () {
                                        tempFromDate =
                                            now;

                                        tempToDate =
                                            now;

                                        tempTodayOnly =
                                            true;
                                      },
                                    );
                                  },
                                ),

                                _quickDateButton(
                                  'Last 7 Days',
                                  () {
                                    final now =
                                        DateTime.now();

                                    setDialogState(
                                      () {
                                        tempFromDate =
                                            DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                        ).subtract(
                                          const Duration(
                                            days: 6,
                                          ),
                                        );

                                        tempToDate =
                                            now;

                                        tempTodayOnly =
                                            false;
                                      },
                                    );
                                  },
                                ),

                                _quickDateButton(
                                  'This Month',
                                  () {
                                    final now =
                                        DateTime.now();

                                    setDialogState(
                                      () {
                                        tempFromDate =
                                            DateTime(
                                          now.year,
                                          now.month,
                                          1,
                                        );

                                        tempToDate =
                                            now;

                                        tempTodayOnly =
                                            false;
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // FOOTER
                      // ==================================================

                      Container(
                        padding:
                            const EdgeInsets.all(18),

                        decoration:
                            const BoxDecoration(
                          color:
                              Color(0xFFF9FAFB),

                          borderRadius:
                              BorderRadius.only(
                            bottomLeft:
                                Radius.circular(18),
                            bottomRight:
                                Radius.circular(18),
                          ),
                        ),

                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setDialogState(
                                  () {
                                    tempFromDate =
                                        null;

                                    tempToDate =
                                        null;

                                    tempTodayOnly =
                                        false;
                                  },
                                );
                              },

                              child:
                                  const Text(
                                'Clear',
                              ),
                            ),

                            const Spacer(),

                            OutlinedButton(
                              onPressed:
                                  () =>
                                      Navigator.pop(
                                dialogContext,
                              ),

                              child:
                                  const Text(
                                'Cancel',
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            ElevatedButton(
                              onPressed:
                                  () async {
                                setState(
                                  () {
                                    fromDate =
                                        tempFromDate;

                                    toDate =
                                        tempToDate;

                                    todayOnly =
                                        tempTodayOnly;
                                  },
                                );

                                Navigator.pop(
                                  dialogContext,
                                );

                                await _loadTrackingSummary();
                              },

                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    const Color(
                                  0xFF315BEF,
                                ),

                                foregroundColor:
                                    Colors.white,

                                elevation: 0,
                              ),

                              child:
                                  const Text(
                                'Apply Filter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<DateTime?> _pickSingleDate(
    BuildContext context,
    DateTime initialDate,
  ) async {
    return showDatePicker(
      context: context,

      initialDate: initialDate,

      firstDate:
          DateTime(2020),

      lastDate:
          DateTime(2035),

      builder:
          (context, child) {
        return Theme(
          data:
              Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.light(
              primary:
                  Color(0xFF315BEF),

              onPrimary:
                  Colors.white,

              surface:
                  Colors.white,

              onSurface:
                  Color(0xFF101828),
            ),

            datePickerTheme:
                const DatePickerThemeData(
              backgroundColor:
                  Colors.white,

              headerBackgroundColor:
                  Color(0xFF101828),

              headerForegroundColor:
                  Colors.white,
            ),
          ),

          child:
              child!,
        );
      },
    );
  }

  // ============================================================
  // DATE BOX
  // ============================================================

  Widget _dateBox({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(10),

      child: Container(
        padding:
            const EdgeInsets.all(12),

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          border:
              Border.all(
            color:
                const Color(0xFFD0D5DD),
          ),

          borderRadius:
              BorderRadius.circular(10),
        ),

        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,

              size: 18,

              color:
                  Color(0xFF667085),
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    label,

                    style:
                        const TextStyle(
                      color:
                          Color(0xFF667085),

                      fontSize:
                          10,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    date == null
                        ? 'Select date'
                        : _formatDateLabel(
                            date,
                          ),

                    style:
                        TextStyle(
                      color:
                          date == null
                              ? const Color(
                                  0xFF98A2B3,
                                )
                              : const Color(
                                  0xFF101828,
                                ),

                      fontSize:
                          13,

                      fontWeight:
                          FontWeight.w600,
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
  // QUICK DATE BUTTON
  // ============================================================

  Widget _quickDateButton(
    String label,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed:
          onPressed,

      style:
          OutlinedButton.styleFrom(
        foregroundColor:
            const Color(0xFF315BEF),

        side:
            const BorderSide(
          color:
              Color(0xFFD0D5DD),
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(8),
        ),
      ),

      child:
          Text(
        label,

        style:
            const TextStyle(
          fontSize:
              12,

          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // CLEAR DATE FILTER
  // ============================================================

  Future<void> _clearDateFilters() async {
    setState(() {
      fromDate = null;

      toDate = null;

      todayOnly = false;
    });

    await _loadTrackingSummary();
  }

  // ============================================================
  // ACTIVE DATE FILTER
  // ============================================================

  Widget _buildActiveDateFilter() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF8FAFF),

        borderRadius:
            BorderRadius.circular(8),

        border:
            Border.all(
          color:
              const Color(0xFFDCE5FF),
        ),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_outlined,

            size: 17,

            color:
                Color(0xFF315BEF),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child:
                Text(
              todayOnly
                  ? 'Showing dashboard data for today'
                  : 'Date: ${_getDateText()}',

              style:
                  const TextStyle(
                color:
                    Color(0xFF344054),

                fontSize:
                    13,

                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          TextButton(
            onPressed:
                _clearDateFilters,

            child:
                const Text(
              'Clear',

              style:
                  TextStyle(
                color:
                    Color(0xFF315BEF),

                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
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
    return Container(
      width:
          double.infinity,

      height:
          double.infinity,

      color:
          const Color(0xFFF5F7FA),

      child:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            _buildDashboardHeader(),

            const SizedBox(
              height: 22,
            ),

            if (_hasActiveDateFilter) ...[
              _buildActiveDateFilter(),

              const SizedBox(
                height: 16,
              ),
            ],

            if (_summaryError != null) ...[
              _buildErrorBanner(),

              const SizedBox(
                height: 16,
              ),
            ],

            _buildStatistics(),

            const SizedBox(
              height: 20,
            ),

            _buildAnalytics(),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR BANNER
  // ============================================================

  Widget _buildErrorBanner() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(12),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFFFF4F4),

        border:
            Border.all(
          color:
              const Color(0xFFFECACA),
        ),

        borderRadius:
            BorderRadius.circular(8),
      ),

      child:
          Row(
        children: [
          const Icon(
            Icons.error_outline,

            color:
                Color(0xFFE72D3B),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child:
                Text(
              _summaryError!,

              style:
                  const TextStyle(
                color:
                    Color(0xFF991B1B),

                fontSize:
                    13,
              ),
            ),
          ),

          TextButton(
            onPressed:
                () =>
                    _loadTrackingSummary(),

            child:
                const Text(
              'Retry',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD HEADER
  // ============================================================

  Widget _buildDashboardHeader() {
    final String welcomeText =
        widget.user == null
            ? "Welcome back! Here's what's happening."
            : "Welcome back, ${widget.user!.firstName}! Here's what's happening.";

    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {
        if (constraints.maxWidth < 500) {
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'Dashboard',

                style:
                    TextStyle(
                  color:
                      Color(0xFF172033),

                  fontSize:
                      28,

                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                welcomeText,

                style:
                    const TextStyle(
                  color:
                      Color(0xFF667085),

                  fontSize:
                      14,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              Row(
                children: [
                  _buildDateButton(),

                  const SizedBox(
                    width: 8,
                  ),

                  _buildRefreshButton(),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Dashboard',

                    style:
                        TextStyle(
                      color:
                          Color(0xFF172033),

                      fontSize:
                          28,

                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    welcomeText,

                    style:
                        const TextStyle(
                      color:
                          Color(0xFF667085),

                      fontSize:
                          14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 15,
            ),

            _buildDateButton(),

            const SizedBox(
              width: 8,
            ),

            _buildRefreshButton(),
          ],
        );
      },
    );
  }

  // ============================================================
  // REFRESH BUTTON
  // ============================================================

  Widget _buildRefreshButton() {
    return InkWell(
      onTap: _isRefreshing
          ? null
          : () =>
              _loadTrackingSummary(
                showLoading: false,
              ),

      borderRadius:
          BorderRadius.circular(8),

      child:
          Container(
        width:
            42,

        height:
            42,

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          border:
              Border.all(
            color:
                const Color(0xFFD0D5DD),
          ),

          borderRadius:
              BorderRadius.circular(8),
        ),

        child:
            _isRefreshing
                ? const Padding(
                    padding:
                        EdgeInsets.all(11),

                    child:
                        SizedBox(
                      width:
                          18,

                      height:
                          18,

                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.refresh,

                    size:
                        19,

                    color:
                        Color(0xFF667085),
                  ),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {
        final double width =
            constraints.maxWidth;

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
          shrinkWrap:
              true,

          physics:
              const NeverScrollableScrollPhysics(),

          itemCount:
              10,

          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                columns,

            crossAxisSpacing:
                14,

            mainAxisSpacing:
                14,

            childAspectRatio:
                width < 650
                    ? 1.25
                    : 1.45,
          ),

          itemBuilder:
              (
            context,
            index,
          ) {
            return _buildStatCard(
              index,
            );
          },
        );
      },
    );
  }

  // ============================================================
  // STAT CARDS
  // ============================================================

  Widget _buildStatCard(
    int index,
  ) {
    final cards = [
      // ========================================================
      // TOTAL MAILS
      // ========================================================

      DashboardStatCard(
        title:
            'Total Mails',

        value:
            _countLabel(
          'totalMails',
        ),

        subtitle:
            'Total emails',

        icon:
            Icons.mail_outline,

        iconColor:
            const Color(0xFF1677FF),
      ),

      // ========================================================
      // TOTAL LEADS
      // ========================================================

      DashboardStatCard(
        title:
            'Total Leads',

        value:
            _countLabel(
          'totalLeads',
        ),

        subtitle:
            'Total leads',

        icon:
            Icons.groups_outlined,

        iconColor:
            const Color(0xFF9146FF),
      ),

      // ========================================================
      // TODAY LEADS
      // ========================================================

      DashboardStatCard(
        title:
            'Today Leads',

        value:
            _countLabel(
          'todayLeads',
        ),

        subtitle:
            'Today leads',

        icon:
            Icons.people_alt_outlined,

        iconColor:
            const Color(0xFF8D7777),
      ),

      // ========================================================
      // PENDING
      // ========================================================

      DashboardStatCard(
        title:
            'Pending',

        value:
            _countLabel(
          'pending',
        ),

        subtitle:
            'Pending emails',

        icon:
            Icons.access_time,

        iconColor:
            const Color(0xFFFFB800),
      ),

      // ========================================================
      // SENT
      // ========================================================

      DashboardStatCard(
        title:
            'Sent',

        value:
            _countLabel(
          'sent',
        ),

        subtitle:
            'Successfully sent',

        icon:
            Icons.send_outlined,

        iconColor:
            const Color(0xFF15955E),
      ),

      // ========================================================
      // SEEN
      // ========================================================

      DashboardStatCard(
        title:
            'Seen',

        value:
            _countLabel(
          'opened',
        ),

        subtitle:
            'Opened emails',

        icon:
            Icons.visibility_outlined,

        iconColor:
            const Color(0xFF7041C5),
      ),

      // ========================================================
      // FAILED
      // ========================================================

      DashboardStatCard(
        title:
            'Failed',

        value:
            _countLabel(
          'failed',
        ),

        subtitle:
            'Failed emails',

        icon:
            Icons.cancel_outlined,

        iconColor:
            const Color(0xFFE72D3B),
      ),

      // ========================================================
      // INTERESTED
      // ========================================================

      DashboardStatCard(
        title:
            'Interested',

        value:
            _countLabel(
          'interested',
        ),

        subtitle:
            'Interested leads',

        icon:
            Icons.thumb_up_alt_outlined,

        iconColor:
            const Color(0xFF1BC69B),
      ),

      // ========================================================
      // NOT INTERESTED
      // ========================================================

      DashboardStatCard(
        title:
            'Not Interested',

        value:
            _countLabel(
          'notInterested',
        ),

        subtitle:
            'Not interested leads',

        icon:
            Icons.thumb_down_alt_outlined,

        iconColor:
            const Color(0xFFFF7800),
      ),

      // ========================================================
      // QR SCANS
      // ========================================================

      DashboardStatCard(
        title:
            'QR Scans',

        value:
            _countLabel(
          'qrScans',
        ),

        subtitle:
            'Total QR code scans',

        icon:
            Icons.qr_code_2,

        iconColor:
            const Color(0xFF10B8D8),
      ),
    ];

    return cards[index];
  }

  // ============================================================
  // ANALYTICS
  // ============================================================

  Widget _buildAnalytics() {
    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {
        if (constraints.maxWidth < 1000) {
          return Column(
            children: [
              CampaignStatusCard(
                total:
                    _numericValue(
                  'totalMails',
                ),

                pending:
                    _numericValue(
                  'pending',
                ),

                sent:
                    _numericValue(
                  'sent',
                ),

                opened:
                    _numericValue(
                  'opened',
                ),

                failed:
                    _numericValue(
                  'failed',
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              PlatformTrackingCard(
                totalClicks:
                    _numericValue(
                  'clicked',
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              QrAnalyticsCard(
                total:
                    _numericValue(
                  'qrScans',
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Expanded(
              child:
                  CampaignStatusCard(
                total:
                    _numericValue(
                  'totalMails',
                ),

                pending:
                    _numericValue(
                  'pending',
                ),

                sent:
                    _numericValue(
                  'sent',
                ),

                opened:
                    _numericValue(
                  'opened',
                ),

                failed:
                    _numericValue(
                  'failed',
                ),
              ),
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
              child:
                  PlatformTrackingCard(
                totalClicks:
                    _numericValue(
                  'clicked',
                ),
              ),
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
              child:
                  QrAnalyticsCard(
                total:
                    _numericValue(
                  'qrScans',
                ),
              ),
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
      onTap:
          _showDateFilter,

      child:
          Container(
        height:
            42,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          border:
              Border.all(
            color:
                const Color(0xFFD0D5DD),
          ),

          borderRadius:
              BorderRadius.circular(8),
        ),

        child:
            Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.calendar_month_outlined,

              size:
                  18,

              color:
                  Color(0xFF667085),
            ),

            const SizedBox(
              width: 8,
            ),

            Text(
              _getDateText(),

              style:
                  const TextStyle(
                color:
                    Color(0xFF344054),

                fontSize:
                    14,

                fontWeight:
                    FontWeight.w500,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            const Icon(
              Icons.keyboard_arrow_down,

              size:
                  20,

              color:
                  Color(0xFF667085),
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
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(14),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(7),

        border:
            Border.all(
          color:
              const Color(0xFFE4E7EC),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.04,
            ),

            blurRadius:
                5,

            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child:
          Row(
        children: [
          Expanded(
            child:
                Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisSize:
                  MainAxisSize.min,

              children: [
                Text(
                  title,

                  softWrap:
                      false,

                  overflow:
                      TextOverflow.visible,

                  style:
                      TextStyle(
                    color:
                        iconColor,

                    fontSize:
                        13,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  value,

                  style:
                      const TextStyle(
                    color:
                        Color(0xFF101828),

                    fontSize:
                        22,

                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  subtitle,

                  softWrap:
                      false,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    color:
                        Color(0xFF667085),

                    fontSize:
                        10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Container(
            width:
                45,

            height:
                45,

            decoration:
                BoxDecoration(
              color:
                  iconColor,

              borderRadius:
                  BorderRadius.circular(11),
            ),

            child:
                Icon(
              icon,

              color:
                  Colors.white,

              size:
                  23,
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
  final int total;

  final int pending;

  final int sent;

  final int opened;

  final int failed;

  const CampaignStatusCard({
    super.key,

    required this.total,

    required this.pending,

    required this.sent,

    required this.opened,

    required this.failed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return _AnalyticsCard(
      title:
          'Campaign Status Overview',

      child:
          SizedBox(
        height:
            230,

        child:
            _CampaignStatusContent(
          total:
              total,

          pending:
              pending,

          sent:
              sent,

          opened:
              opened,

          failed:
              failed,
        ),
      ),
    );
  }
}

class _CampaignStatusContent extends StatelessWidget {
  final int total;

  final int pending;

  final int sent;

  final int opened;

  final int failed;

  const _CampaignStatusContent({
    required this.total,

    required this.pending,

    required this.sent,

    required this.opened,

    required this.failed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,

      children: [
        SizedBox(
          width:
              130,

          height:
              130,

          child:
              CustomPaint(
            painter:
                CampaignDonutPainter(
              pending:
                  pending,

              sent:
                  sent,

              opened:
                  opened,

              failed:
                  failed,
            ),

            child:
                Center(
              child:
                  Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  const Text(
                    'Total Mail',

                    style:
                        TextStyle(
                      color:
                          Color(0xFF667085),

                      fontSize:
                          12,
                    ),
                  ),

                  const SizedBox(
                    height:
                        5,
                  ),

                  Text(
                    total.toString(),

                    style:
                        const TextStyle(
                      color:
                          Color(0xFF101828),

                      fontSize:
                          18,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(
          width:
              18,
        ),

        Flexible(
          child:
              Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              _LegendItem(
                color:
                    const Color(0xFFFFA800),

                title:
                    'Pending ($pending)',
              ),

              _LegendItem(
                color:
                    const Color(0xFF19A974),

                title:
                    'Sent ($sent)',
              ),

              _LegendItem(
                color:
                    const Color(0xFF7C4DFF),

                title:
                    'Seen ($opened)',
              ),

              _LegendItem(
                color:
                    const Color(0xFFE73B45),

                title:
                    'Fail ($failed)',
              ),

              const _LegendItem(
                color:
                    Color(0xFF11B5D6),

                title:
                    'Interested',
              ),

              const _LegendItem(
                color:
                    Color(0xFF667085),

                title:
                    'Not Interested',
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
  final int totalClicks;

  const PlatformTrackingCard({
    super.key,

    this.totalClicks = 0,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return _AnalyticsCard(
      title:
          'Platform Click Tracking',

      child:
          SizedBox(
        height:
            230,

        child:
            _PlatformTrackingContent(
          totalClicks:
              totalClicks,
        ),
      ),
    );
  }
}

class _PlatformTrackingContent extends StatelessWidget {
  final int totalClicks;

  const _PlatformTrackingContent({
    required this.totalClicks,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,

      children: [
        SizedBox(
          width:
              130,

          height:
              130,

          child:
              CustomPaint(
            painter:
                const EmptyDonutPainter(),

            child:
                Center(
              child:
                  Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  const Text(
                    'Total Clicks',

                    style:
                        TextStyle(
                      color:
                          Color(0xFF667085),

                      fontSize:
                          12,
                    ),
                  ),

                  const SizedBox(
                    height:
                        5,
                  ),

                  Text(
                    totalClicks.toString(),

                    style:
                        const TextStyle(
                      color:
                          Color(0xFF101828),

                      fontSize:
                          18,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(
          width:
              15,
        ),

        const Flexible(
          child:
              Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              _LegendItem(
                color:
                    Color(0xFF20C978),

                title:
                    'WhatsApp',
              ),

              _LegendItem(
                color:
                    Color(0xFFE83F55),

                title:
                    'Instagram',
              ),

              _LegendItem(
                color:
                    Color(0xFF2877E8),

                title:
                    'Facebook Messenger',
              ),

              _LegendItem(
                color:
                    Color(0xFF2299D5),

                title:
                    'Telegram',
              ),

              _LegendItem(
                color:
                    Color(0xFF0A66C2),

                title:
                    'LinkedIn',
              ),

              _LegendItem(
                color:
                    Colors.black,

                title:
                    'X (Twitter)',
              ),

              _LegendItem(
                color:
                    Color(0xFF7C3AED),

                title:
                    'Threads',
              ),

              _LegendItem(
                color:
                    Color(0xFF667085),

                title:
                    'Other',
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
  final int total;

  const QrAnalyticsCard({
    super.key,

    this.total = 0,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return _AnalyticsCard(
      title:
          'QR Button Click Analytics',

      trailing:
          Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 9,

          vertical: 5,
        ),

        decoration:
            BoxDecoration(
          color:
              const Color(0xFF15955E),

          borderRadius:
              BorderRadius.circular(5),
        ),

        child:
            Text(
          'Total: $total',

          style:
              const TextStyle(
            color:
                Colors.white,

            fontSize:
                11,

            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      child:
          SizedBox(
        height:
            230,

        child:
            total <= 0
                ? const Center(
                    child:
                        Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [
                        Icon(
                          Icons.qr_code_2,

                          size:
                              45,

                          color:
                              Color(0xFFD0D5DD),
                        ),

                        SizedBox(
                          height:
                              10,
                        ),

                        Text(
                          'No QR click data available',

                          style:
                              TextStyle(
                            color:
                                Color(0xFF667085),

                            fontSize:
                                13,
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child:
                        Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [
                        const Icon(
                          Icons.qr_code_2,

                          size:
                              45,

                          color:
                              Color(0xFF15955E),
                        ),

                        const SizedBox(
                          height:
                              10,
                        ),

                        Text(
                          '$total QR scans',

                          style:
                              const TextStyle(
                            color:
                                Color(0xFF101828),

                            fontSize:
                                18,

                            fontWeight:
                                FontWeight.w600,
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
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(7),

        border:
            Border.all(
          color:
              const Color(0xFFE4E7EC),
        ),
      ),

      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Container(
            height:
                45,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
            ),

            decoration:
                const BoxDecoration(
              border:
                  Border(
                bottom:
                    BorderSide(
                  color:
                      Color(0xFFE4E7EC),
                ),
              ),
            ),

            child:
                Row(
              children: [
                Expanded(
                  child:
                      Text(
                    title,

                    maxLines:
                        1,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      color:
                          Color(0xFF101828),

                      fontSize:
                          16,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                if (trailing != null) ...[
                  const SizedBox(
                    width:
                        8,
                  ),

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
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            2.5,
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Container(
            width:
                9,

            height:
                9,

            decoration:
                BoxDecoration(
              color:
                  color,

              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width:
                6,
          ),

          Flexible(
            child:
                Text(
              title,

              maxLines:
                  1,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                color:
                    Color(0xFF475467),

                fontSize:
                    10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// CAMPAIGN DONUT
// =================================================================

class CampaignDonutPainter extends CustomPainter {
  final int pending;

  final int sent;

  final int opened;

  final int failed;

  const CampaignDonutPainter({
    required this.pending,

    required this.sent,

    required this.opened,

    required this.failed,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center =
        Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        size.width / 2 - 10;

    final total =
        pending +
            sent +
            opened +
            failed;

    final backgroundPaint =
        Paint()
          ..style =
              PaintingStyle.stroke

          ..strokeWidth =
              18

          ..color =
              const Color(0xFFE9EDF2);

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    if (total <= 0) {
      return;
    }

    final values = [
      pending,
      sent,
      opened,
      failed,
    ];

    final colors = [
      const Color(0xFFFFA800),
      const Color(0xFF19A974),
      const Color(0xFF7C4DFF),
      const Color(0xFFE73B45),
    ];

    double startAngle =
        -1.5708;

    for (int i = 0;
        i < values.length;
        i++) {
      if (values[i] <= 0) {
        continue;
      }

      final sweepAngle =
          (values[i] / total) *
              6.283185307;

      final paint =
          Paint()
            ..style =
                PaintingStyle.stroke

            ..strokeWidth =
                18

            ..strokeCap =
                StrokeCap.butt

            ..color =
                colors[i];

      canvas.drawArc(
        Rect.fromCircle(
          center:
              center,

          radius:
              radius,
        ),

        startAngle,

        sweepAngle,

        false,

        paint,
      );

      startAngle +=
          sweepAngle;
    }
  }

  @override
  bool shouldRepaint(
    covariant CampaignDonutPainter
        oldDelegate,
  ) {
    return oldDelegate.pending !=
            pending ||
        oldDelegate.sent !=
            sent ||
        oldDelegate.opened !=
            opened ||
        oldDelegate.failed !=
            failed;
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
    final center =
        Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        size.width / 2 - 10;

    final paint =
        Paint()
          ..style =
              PaintingStyle.stroke

          ..strokeWidth =
              18

          ..color =
              const Color(0xFFE9EDF2);

    canvas.drawCircle(
      center,
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant EmptyDonutPainter
        oldDelegate,
  ) {
    return false;
  }
}