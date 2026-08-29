import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/sequence_api.dart';

// ============================================================
// DASHBOARD CONTENT
// ============================================================

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
  // COLORS
  // ============================================================

  static const Color background = Color(0xFF020507);
  static const Color panelColor2 = Color(0xFF0D1116);

  static const Color gold = Color(0xFFF2C45F);

  static const Color white = Colors.white;

  static const Color mutedText = Color(0xFFADB2BB);

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
    'replied': 0,
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
    if (!mounted) {
      return;
    }

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
      final result =
          await SequenceApi.getTrackingSummary(
        startDate: fromDate,
        endDate: toDate,
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // API ERROR
      // ========================================================

      if (result['success'] == false) {
        setState(() {
          _summaryError =
              result['message']?.toString() ??
                  'Unable to load dashboard data.';
        });

        return;
      }

      // ========================================================
      // GET DATA
      // ========================================================

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
            'replied': _toInt(
              data['replied'],
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
      if (!mounted) {
        return;
      }

      setState(() {
        _summaryError =
            'Unable to load dashboard statistics.';
      });

      debugPrint(
        'Dashboard summary error: $error',
      );
    } finally {
      if (!mounted) {
        return;
      }

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

  String _formatDateLabel(
    DateTime date,
  ) {
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
      builder: (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return Dialog(
              backgroundColor:
                  Colors.transparent,
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
                    color:
                        const Color(
                      0xFF080B0F,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    border:
                        Border.all(
                      color:
                          gold.withOpacity(
                        0.35,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(
                          0.55,
                        ),
                        blurRadius:
                            30,
                        offset:
                            const Offset(
                          0,
                          15,
                        ),
                      ),
                    ],
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
                            const EdgeInsets.all(
                          20,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFF05070A,
                          ),
                          borderRadius:
                              const BorderRadius.only(
                            topLeft:
                                Radius.circular(
                              18,
                            ),
                            topRight:
                                Radius.circular(
                              18,
                            ),
                          ),
                          border:
                              Border(
                            bottom:
                                BorderSide(
                              color:
                                  gold.withOpacity(
                                0.18,
                              ),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration:
                                  BoxDecoration(
                                color:
                                    gold.withOpacity(
                                  0.10,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  11,
                                ),
                                border:
                                    Border.all(
                                  color:
                                      gold.withOpacity(
                                    0.25,
                                  ),
                                ),
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .calendar_month_outlined,
                                color:
                                    gold,
                                size:
                                    23,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            const Expanded(
                              child:
                                  Column(
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
                                    height: 4,
                                  ),
                                  Text(
                                    'Select a date range to filter stats',
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

                            IconButton(
                              onPressed:
                                  () {
                                Navigator.pop(
                                  dialogContext,
                                );
                              },
                              icon:
                                  const Icon(
                                Icons.close,
                                color:
                                    mutedText,
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
                            const EdgeInsets.all(
                          20,
                        ),
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date Range',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    14,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            LayoutBuilder(
                              builder: (
                                context,
                                constraints,
                              ) {
                                if (constraints
                                        .maxWidth <
                                    420) {
                                  return Column(
                                    children: [
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

                                          if (date ==
                                              null) {
                                            return;
                                          }

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
                                        },
                                      ),

                                      const SizedBox(
                                        height: 10,
                                      ),

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

                                          if (date ==
                                              null) {
                                            return;
                                          }

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
                                        },
                                      ),
                                    ],
                                  );
                                }

                                return Row(
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

                                          if (date ==
                                              null) {
                                            return;
                                          }

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

                                          if (date ==
                                              null) {
                                            return;
                                          }

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
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            const Text(
                              'Quick Select',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
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
                            const EdgeInsets.all(
                          18,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFF06090C,
                          ),
                          borderRadius:
                              const BorderRadius.only(
                            bottomLeft:
                                Radius.circular(
                              18,
                            ),
                            bottomRight:
                                Radius.circular(
                              18,
                            ),
                          ),
                          border:
                              Border(
                            top:
                                BorderSide(
                              color:
                                  gold.withOpacity(
                                0.15,
                              ),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed:
                                  () {
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
                                style:
                                    TextStyle(
                                  color:
                                      mutedText,
                                ),
                              ),
                            ),

                            const Spacer(),

                            OutlinedButton(
                              onPressed:
                                  () {
                                Navigator.pop(
                                  dialogContext,
                                );
                              },
                              style:
                                  OutlinedButton.styleFrom(
                                foregroundColor:
                                    white,
                                side:
                                    BorderSide(
                                  color:
                                      gold.withOpacity(
                                    0.30,
                                  ),
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    8,
                                  ),
                                ),
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
                                    8,
                                  ),
                                ),
                              ),
                              child:
                                  const Text(
                                'Apply Filter',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.w700,
                                ),
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
      firstDate: DateTime(
        2020,
      ),
      lastDate: DateTime(
        2035,
      ),
      builder: (
        context,
        child,
      ) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme:
                const ColorScheme.dark(
              primary: gold,
              onPrimary:
                  Colors.black,
              surface:
                  Color(
                0xFF0D1116,
              ),
              onSurface:
                  Colors.white,
            ),
            datePickerTheme:
                const DatePickerThemeData(
              backgroundColor:
                  Color(
                0xFF080B0F,
              ),
              headerBackgroundColor:
                  Color(
                0xFF05070A,
              ),
              headerForegroundColor:
                  gold,
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
      onTap:
          onTap,
      borderRadius:
          BorderRadius.circular(
        10,
      ),
      child: Container(
        padding:
            const EdgeInsets.all(
          12,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFF0D1116,
          ),
          border:
              Border.all(
            color:
                gold.withOpacity(
              0.28,
            ),
          ),
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons
                  .calendar_today_outlined,
              size: 18,
              color: gold,
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        const TextStyle(
                      color:
                          mutedText,
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
                      color: date ==
                              null
                          ? mutedText
                          : white,
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
            gold,
        side:
            BorderSide(
          color:
              gold.withOpacity(
            0.30,
          ),
        ),
        backgroundColor:
            gold.withOpacity(
          0.03,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            8,
          ),
        ),
      ),
      child: Text(
        label,
        style:
            const TextStyle(
          fontSize: 12,
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
  // BACKGROUND
  // ============================================================

  Widget _buildBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit:
              StackFit.expand,
          children: [
            const ColoredBox(
              color:
                  background,
            ),

            // ==================================================
            // JEWELLERY IMAGE
            // ==================================================

            Align(
              alignment:
                  Alignment.topRight,
              child: SizedBox(
                width: 650,
                height: 470,
                child: Opacity(
                  opacity: 0.48,
                  child:
                      Image.asset(
                    'assets/images/login_jewellery.png',
                    fit:
                        BoxFit.cover,
                    alignment:
                        Alignment.center,
                    filterQuality:
                        FilterQuality.high,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const SizedBox
                          .shrink();
                    },
                  ),
                ),
              ),
            ),

            // ==================================================
            // DARK FADE
            // ==================================================

            DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.topRight,
                  end:
                      Alignment.bottomLeft,
                  colors: [
                    Colors
                        .transparent,
                    background
                        .withOpacity(
                      0.25,
                    ),
                    background
                        .withOpacity(
                      0.83,
                    ),
                    background,
                  ],
                  stops:
                      const [
                    0.0,
                    0.30,
                    0.64,
                    1.0,
                  ],
                ),
              ),
            ),

            // ==================================================
            // GOLD GLOW
            // ==================================================

            Positioned(
              right: -120,
              top: 80,
              child:
                  Container(
                width: 400,
                height: 400,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  gradient:
                      RadialGradient(
                    colors: [
                      gold.withOpacity(
                        0.10,
                      ),
                      Colors
                          .transparent,
                    ],
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
  Widget build(
    BuildContext context,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(),

        RefreshIndicator(
          color:
              gold,
          backgroundColor:
              panelColor2,
          onRefresh:
              () {
            return _loadTrackingSummary(
              showLoading: false,
            );
          },
          child:
              SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.all(
              20,
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildDashboardHeader(),

                const SizedBox(
                  height: 24,
                ),

                if (_hasActiveDateFilter) ...[
                  _buildActiveDateFilter(),

                  const SizedBox(
                    height: 16,
                  ),
                ],

                if (_summaryError !=
                    null) ...[
                  _buildErrorBanner(),

                  const SizedBox(
                    height: 16,
                  ),
                ],

                _buildStatistics(),

                const SizedBox(
                  height: 24,
                ),

                _buildAnalytics(),

                const SizedBox(
                  height: 35,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DASHBOARD HEADER
  // ============================================================

  Widget _buildDashboardHeader() {
    final String firstName =
        widget.user?.firstName ??
            '';

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final bool mobile =
            constraints.maxWidth <
                600;

        final Widget heading =
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize:
                    mobile
                        ? 29
                        : 34,
                fontWeight:
                    FontWeight.w800,
                letterSpacing:
                    -0.5,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            RichText(
              text:
                  TextSpan(
                style:
                    const TextStyle(
                  color:
                      mutedText,
                  fontSize:
                      15,
                ),
                children: [
                  const TextSpan(
                    text:
                        'Welcome back',
                  ),

                  if (firstName
                      .isNotEmpty)
                    TextSpan(
                      text:
                          ', $firstName',
                      style:
                          const TextStyle(
                        color:
                            gold,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                  const TextSpan(
                    text:
                        "! Here's what's happening.",
                  ),
                ],
              ),
            ),
          ],
        );

        final Widget controls =
            Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            _buildDateButton(),

            const SizedBox(
              width: 10,
            ),

            _buildRefreshButton(),
          ],
        );

        if (mobile) {
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              heading,

              const SizedBox(
                height: 18,
              ),

              controls,
            ],
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Expanded(
              child:
                  heading,
            ),

            controls,
          ],
        );
      },
    );
  }

  // ============================================================
  // DATE BUTTON
  // ============================================================

  Widget _buildDateButton() {
    return InkWell(
      onTap:
          _showDateFilter,
      borderRadius:
          BorderRadius.circular(
        10,
      ),
      child: Container(
        height: 48,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(
            0xD90A0D11,
          ),
          border:
              Border.all(
            color:
                gold.withOpacity(
              0.58,
            ),
          ),
          borderRadius:
              BorderRadius.circular(
            10,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(
                0.22,
              ),
              blurRadius:
                  10,
              offset:
                  const Offset(
                0,
                4,
              ),
            ),
          ],
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .calendar_month_outlined,
              size: 20,
              color: gold,
            ),

            const SizedBox(
              width: 8,
            ),

            Text(
              _getDateText(),
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize:
                    14,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            const Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              size: 20,
              color: gold,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REFRESH BUTTON
  // ============================================================

  Widget _buildRefreshButton() {
    return InkWell(
      onTap:
          _isRefreshing
              ? null
              : () {
                  _loadTrackingSummary(
                    showLoading:
                        false,
                  );
                },
      borderRadius:
          BorderRadius.circular(
        10,
      ),
      child: Container(
        width: 50,
        height: 48,
        decoration:
            BoxDecoration(
          color:
              const Color(
            0xD90A0D11,
          ),
          border:
              Border.all(
            color:
                gold.withOpacity(
              0.58,
            ),
          ),
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
        child:
            _isRefreshing
                ? const Padding(
                    padding:
                        EdgeInsets.all(
                      14,
                    ),
                    child:
                        CircularProgressIndicator(
                      strokeWidth:
                          2,
                      color:
                          gold,
                    ),
                  )
                : const Icon(
                    Icons
                        .refresh_rounded,
                    size:
                        22,
                    color:
                        gold,
                  ),
      ),
    );
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
        horizontal: 13,
        vertical: 9,
      ),
      decoration:
          BoxDecoration(
        color:
            gold.withOpacity(
          0.055,
        ),
        borderRadius:
            BorderRadius.circular(
          9,
        ),
        border:
            Border.all(
          color:
              gold.withOpacity(
            0.25,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons
                .filter_alt_outlined,
            size: 18,
            color: gold,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              todayOnly
                  ? 'Showing dashboard data for today'
                  : 'Date: ${_getDateText()}',
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFFD1D4DA,
                ),
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
                    gold,
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
  // ERROR BANNER
  // ============================================================

  Widget _buildErrorBanner() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF2A1014,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFF87313A,
          ),
        ),
        borderRadius:
            BorderRadius.circular(
          9,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons
                .error_outline,
            color:
                Color(
              0xFFFF6674,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              _summaryError!,
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFFFFB6BC,
                ),
                fontSize:
                    13,
              ),
            ),
          ),

          TextButton(
            onPressed:
                () {
              _loadTrackingSummary();
            },
            child:
                const Text(
              'Retry',
              style:
                  TextStyle(
                color:
                    gold,
              ),
            ),
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
        final double width =
            constraints.maxWidth;

        int columns;

        if (width >=
            1200) {
          columns = 4;
        } else if (width >=
            800) {
          columns = 3;
        } else {
          columns = 2;
        }

        double ratio;

        if (width <
            400) {
          ratio = 1.05;
        } else if (width <
            650) {
          ratio = 1.18;
        } else {
          ratio = 1.45;
        }

        return GridView.builder(
          shrinkWrap:
              true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount:
              11,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                columns,
            crossAxisSpacing:
                12,
            mainAxisSpacing:
                12,
            childAspectRatio:
                ratio,
          ),
          itemBuilder: (
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
            const Color(
          0xFF2388FF,
        ),
      ),

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
            const Color(
          0xFF9A4DFF,
        ),
      ),

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
            const Color(
          0xFF96756E,
        ),
      ),

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
            const Color(
          0xFFFFAD00,
        ),
      ),

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
            const Color(
          0xFF18A56B,
        ),
      ),

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
            const Color(
          0xFF7542D8,
        ),
      ),

      DashboardStatCard(
        title:
            'Replied',
        value:
            _countLabel(
          'replied',
        ),
        subtitle:
            'Recipient replies',
        icon:
            Icons.reply_rounded,
        iconColor:
            const Color(
          0xFF36D67A,
        ),
      ),

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
            const Color(
          0xFFFF3548,
        ),
      ),

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
            const Color(
          0xFF18C6A1,
        ),
      ),

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
            const Color(
          0xFFFF8000,
        ),
      ),

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
            const Color(
          0xFF12B8D4,
        ),
      ),
    ];

    return cards[
        index];
  }

  // ============================================================
  // ANALYTICS
  // ============================================================

  Widget _buildAnalytics() {
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
          interested:
              _numericValue(
            'interested',
          ),
          notInterested:
              _numericValue(
            'notInterested',
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        PlatformTrackingCard(
          totalClicks:
              _numericValue(
            'clicked',
          ),
        ),

        const SizedBox(
          height: 20,
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
}

// ============================================================
// DASHBOARD STAT CARD
// ============================================================

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

  static const Color gold =
      Color(
    0xFFF2C45F,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        15,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xE60A0D11,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border:
            Border.all(
          color:
              gold.withOpacity(
            0.34,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.32,
            ),
            blurRadius:
                16,
            offset:
                const Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Row(
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
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color:
                        iconColor,
                    fontSize:
                        14,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                Text(
                  value,
                  maxLines: 1,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        27,
                    fontWeight:
                        FontWeight.w700,
                    height:
                        1,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFFB1B6BF,
                    ),
                    fontSize:
                        10.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Container(
            width: 50,
            height: 50,
            decoration:
                BoxDecoration(
              color:
                  iconColor,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      iconColor.withOpacity(
                    0.22,
                  ),
                  blurRadius:
                      14,
                ),
              ],
            ),
            child: Icon(
              icon,
              color:
                  Colors.white,
              size:
                  26,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ANALYTICS CARD
// ============================================================

class _AnalyticsCard extends StatelessWidget {
  final String title;

  final Widget child;

  final Widget? trailing;

  const _AnalyticsCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  static const Color gold =
      Color(
    0xFFF2C45F,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xEA0A0D11,
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border:
            Border.all(
          color:
              gold.withOpacity(
            0.35,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.35,
            ),
            blurRadius:
                20,
            offset:
                const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          // ====================================================
          // FIXED:
          // Container has no minHeight argument.
          // ====================================================

          Container(
            constraints:
                const BoxConstraints(
              minHeight: 56,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          17,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),

                if (trailing !=
                    null) ...[
                  const SizedBox(
                    width: 8,
                  ),

                  trailing!,
                ],
              ],
            ),
          ),

          Container(
            height:
                1,
            color:
                gold.withOpacity(
              0.12,
            ),
          ),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// CAMPAIGN STATUS
// ============================================================

class CampaignStatusCard extends StatelessWidget {
  final int total;

  final int pending;

  final int sent;

  final int opened;

  final int failed;

  final int interested;

  final int notInterested;

  const CampaignStatusCard({
    super.key,
    required this.total,
    required this.pending,
    required this.sent,
    required this.opened,
    required this.failed,
    required this.interested,
    required this.notInterested,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return _AnalyticsCard(
      title:
          'Campaign Status Overview',
      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final bool mobile =
                constraints.maxWidth <
                    550;

            final chart =
                SizedBox(
              width: 180,
              height: 180,
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
                              Color(
                            0xFFADB2BB,
                          ),
                          fontSize:
                              14,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        total
                            .toString(),
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              28,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            final legend =
                Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _LegendItem(
                  color:
                      const Color(
                    0xFFFFA800,
                  ),
                  title:
                      'Pending',
                  value:
                      pending,
                ),

                _LegendItem(
                  color:
                      const Color(
                    0xFF19A974,
                  ),
                  title:
                      'Sent',
                  value:
                      sent,
                ),

                _LegendItem(
                  color:
                      const Color(
                    0xFF7C4DFF,
                  ),
                  title:
                      'Seen',
                  value:
                      opened,
                ),

                _LegendItem(
                  color:
                      const Color(
                    0xFFE73B45,
                  ),
                  title:
                      'Fail',
                  value:
                      failed,
                ),

                _LegendItem(
                  color:
                      const Color(
                    0xFF11B5D6,
                  ),
                  title:
                      'Interested',
                  value:
                      interested,
                ),

                _LegendItem(
                  color:
                      const Color(
                    0xFF667085,
                  ),
                  title:
                      'Not Interested',
                  value:
                      notInterested,
                ),
              ],
            );

            if (mobile) {
              return Column(
                children: [
                  chart,

                  const SizedBox(
                    height: 22,
                  ),

                  legend,
                ],
              );
            }

            return SizedBox(
              height:
                  245,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  chart,

                  const SizedBox(
                    width: 65,
                  ),

                  Flexible(
                    child:
                        legend,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// PLATFORM CLICK TRACKING
// ============================================================

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
      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final bool mobile =
                constraints.maxWidth <
                    600;

            final chart =
                SizedBox(
              width: 165,
              height: 165,
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
                              Color(
                            0xFFADB2BB,
                          ),
                          fontSize:
                              14,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        totalClicks
                            .toString(),
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              28,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            final platforms =
                Wrap(
              spacing:
                  26,
              runSpacing:
                  1,
              children:
                  const [
                SizedBox(
                  width:
                      210,
                  child:
                      Column(
                    children: [
                      _LegendItem(
                        color:
                            Color(
                          0xFF20C978,
                        ),
                        title:
                            'WhatsApp',
                        value:
                            0,
                      ),

                      _LegendItem(
                        color:
                            Color(
                          0xFFE83F55,
                        ),
                        title:
                            'Instagram',
                        value:
                            0,
                      ),

                      _LegendItem(
                        color:
                            Color(
                          0xFF2877E8,
                        ),
                        title:
                            'Facebook Messenger',
                        value:
                            0,
                      ),

                      _LegendItem(
                        color:
                            Color(
                          0xFF2299D5,
                        ),
                        title:
                            'Telegram',
                        value:
                            0,
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  width:
                      175,
                  child:
                      Column(
                    children: [
                      _LegendItem(
                        color:
                            Color(
                          0xFF0A66C2,
                        ),
                        title:
                            'LinkedIn',
                        value:
                            0,
                      ),

                      _LegendItem(
                        color:
                            Colors.white,
                        title:
                            'X (Twitter)',
                        value:
                            0,
                      ),

                      _LegendItem(
                        color:
                            Color(
                          0xFF7C3AED,
                        ),
                        title:
                            'Threads',
                        value:
                            0,
                      ),

                      _LegendItem(
                        color:
                            Color(
                          0xFF667085,
                        ),
                        title:
                            'Other',
                        value:
                            0,
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (mobile) {
              return Column(
                children: [
                  chart,

                  const SizedBox(
                    height: 26,
                  ),

                  platforms,
                ],
              );
            }

            return SizedBox(
              height:
                  240,
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                  ),

                  chart,

                  const SizedBox(
                    width: 45,
                  ),

                  Expanded(
                    child:
                        platforms,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// QR ANALYTICS
// ============================================================

class QrAnalyticsCard extends StatelessWidget {
  final int total;

  const QrAnalyticsCard({
    super.key,
    this.total = 0,
  });

  static const Color gold =
      Color(
    0xFFF2C45F,
  );

  // ============================================================
  // FIXED:
  // mutedText is now defined inside this class.
  // ============================================================

  static const Color mutedText =
      Color(
    0xFFADB2BB,
  );

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
          horizontal: 12,
          vertical: 6,
        ),
        decoration:
            BoxDecoration(
          color:
              gold.withOpacity(
            0.06,
          ),
          borderRadius:
              BorderRadius.circular(
            7,
          ),
          border:
              Border.all(
            color:
                gold.withOpacity(
              0.42,
            ),
          ),
        ),
        child: Text(
          'Total: $total',
          style:
              const TextStyle(
            color:
                gold,
            fontSize:
                12,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      child: Container(
        width:
            double.infinity,
        constraints:
            const BoxConstraints(
          minHeight: 235,
        ),
        padding:
            const EdgeInsets.all(
          25,
        ),
        child: Center(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration:
                    BoxDecoration(
                  color:
                      gold.withOpacity(
                    0.045,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border:
                      Border.all(
                    color:
                        gold.withOpacity(
                      0.42,
                    ),
                  ),
                ),
                child:
                    const Icon(
                  Icons.qr_code_2,
                  color:
                      gold,
                  size:
                      53,
                ),
              ),

              const SizedBox(
                height: 17,
              ),

              Text(
                total <= 0
                    ? 'No QR click data available'
                    : '$total QR scans',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color: total <=
                          0
                      ? mutedText
                      : Colors.white,
                  fontSize:
                      total <= 0
                          ? 13
                          : 17,
                  fontWeight: total <=
                          0
                      ? FontWeight.w400
                      : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LEGEND ITEM
// ============================================================

class _LegendItem extends StatelessWidget {
  final Color color;

  final String title;

  final int value;

  const _LegendItem({
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(
              color:
                  color,
              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFFC0C4CB,
                ),
                fontSize:
                    11.5,
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            value
                .toString(),
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize:
                  12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CAMPAIGN DONUT PAINTER
// ============================================================

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
    final Offset center =
        Offset(
      size.width / 2,
      size.height / 2,
    );

    final double radius =
        math.min(
              size.width,
              size.height,
            ) /
            2 -
        13;

    final int total =
        pending +
            sent +
            opened +
            failed;

    // ==========================================================
    // BACKGROUND RING
    // ==========================================================

    final Paint backgroundPaint =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              23
          ..strokeCap =
              StrokeCap.butt
          ..color =
              const Color(
            0xFF252A33,
          );

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    if (total <= 0) {
      return;
    }

    final List<int> values = [
      pending,
      sent,
      opened,
      failed,
    ];

    final List<Color> colors = [
      const Color(
        0xFFFFA800,
      ),

      const Color(
        0xFF19A974,
      ),

      const Color(
        0xFF7C4DFF,
      ),

      const Color(
        0xFFE73B45,
      ),
    ];

    double startAngle =
        -math.pi / 2;

    for (int index = 0;
        index < values.length;
        index++) {
      if (values[index] <= 0) {
        continue;
      }

      final double sweepAngle =
          (values[index] /
                  total) *
              math.pi *
              2;

      final Paint paint =
          Paint()
            ..style =
                PaintingStyle.stroke
            ..strokeWidth =
                23
            ..strokeCap =
                StrokeCap.butt
            ..color =
                colors[index];

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
    covariant CampaignDonutPainter oldDelegate,
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

// ============================================================
// EMPTY DONUT PAINTER
// ============================================================

class EmptyDonutPainter extends CustomPainter {
  const EmptyDonutPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center =
        Offset(
      size.width / 2,
      size.height / 2,
    );

    final double radius =
        math.min(
              size.width,
              size.height,
            ) /
            2 -
        13;

    final Paint paint =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              23
          ..strokeCap =
              StrokeCap.round
          ..color =
              const Color(
            0xFF252A33,
          );

    canvas.drawCircle(
      center,
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant EmptyDonutPainter oldDelegate,
  ) {
    return false;
  }
}