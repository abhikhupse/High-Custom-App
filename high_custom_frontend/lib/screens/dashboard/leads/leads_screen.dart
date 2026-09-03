import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/leads_api.dart';
import '../../../widgets/app_feedback.dart';
import '../../../widgets/app_skeleton.dart';
import 'add_lead_screen.dart';

// ============================================================
// LEADS SCREEN
// ============================================================

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color pageBackground = Color(0xFF090A0C);

  static const Color cardBackground = Color(0xFF101113);
  static const Color cardBackground2 = Color(0xFF151619);

  static const Color borderColor = Color(0xFF292B2F);

  static const Color gold = Color(0xFFF4C451);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFFE8E8EA);
  static const Color mutedText = Color(0xFF9B9CA3);

  static const Color green = Color(0xFF38C977);
  static const Color red = Color(0xFFFF4D5E);
  static const Color orange = Color(0xFFFF9D25);
  static const Color purple = Color(0xFF8B4DFF);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController editEmailController =
      TextEditingController();

  final TextEditingController editFirstNameController =
      TextEditingController();

  final TextEditingController editLastNameController =
      TextEditingController();

  final TextEditingController editCompanyController =
      TextEditingController();

  final TextEditingController searchController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;

  bool isUpdatingLead = false;
  bool isDeletingLead = false;

  bool isUploadingExcel = false;
  bool isDownloadingExcel = false;

  bool todayOnly = false;

  bool trackingEnabled = true;

  bool _isRefreshingTracking = false;

  Timer? _trackingRefreshTimer;

  int currentPage = 1;
  int entriesPerPage = 10;

  DateTime? fromDate;
  DateTime? toDate;

  String selectedType = 'Email';

  String selectedTypeFilter = 'All Types';

  String selectedStatusFilter = 'All Status';

  String searchQuery = '';

  // ============================================================
  // DATA
  // ============================================================

  final List<Map<String, dynamic>> leads = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadLeads();

    _startTrackingRefresh();
  }

  // ============================================================
  // AUTOMATIC TRACKING REFRESH
  // ============================================================

  void _startTrackingRefresh() {
    _trackingRefreshTimer?.cancel();

    debugPrint(
      '✅ Leads automatic tracking refresh started.',
    );

    _trackingRefreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        _refreshTrackingStatus();
      },
    );
  }

  // ============================================================
  // REFRESH TRACKING STATUS
  // ============================================================

  Future<void> _refreshTrackingStatus() async {
    if (!mounted ||
        isLoading ||
        isUploadingExcel ||
        isDownloadingExcel ||
        isUpdatingLead ||
        isDeletingLead ||
        _isRefreshingTracking) {
      return;
    }

    _isRefreshingTracking = true;

    try {
      final response = await LeadsApi.getLeads();

      if (!mounted) {
        return;
      }

      if (response['success'] != true) {
        return;
      }

      final serverLeads = response['leads'];

      if (serverLeads is! List) {
        return;
      }

      final List<Map<String, dynamic>> refreshed = [];

      for (final item in serverLeads) {
        if (item is Map) {
          refreshed.add(
            _normalizeLead(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        leads
          ..clear()
          ..addAll(refreshed);

        _fixCurrentPage();
      });
    } catch (error) {
      debugPrint(
        'Automatic tracking refresh error: $error',
      );
    } finally {
      _isRefreshingTracking = false;
    }
  }

  // ============================================================
  // LOAD LEADS
  // ============================================================

  Future<void> _loadLeads({
    bool showLoader = true,
    bool resetPage = true,
  }) async {
    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response = await LeadsApi.getLeads();

      if (!mounted) {
        return;
      }

      if (response['success'] == true) {
        final serverLeads = response['leads'];

        final List<Map<String, dynamic>> loaded = [];

        if (serverLeads is List) {
          for (final item in serverLeads) {
            if (item is Map) {
              loaded.add(
                _normalizeLead(
                  Map<String, dynamic>.from(item),
                ),
              );
            }
          }
        }

        setState(() {
          leads
            ..clear()
            ..addAll(loaded);

          if (resetPage) {
            currentPage = 1;
          }

          _fixCurrentPage();
        });
      } else {
        _showMessage(
          response['message']?.toString() ??
              'Unable to load leads.',
        );
      }
    } catch (error) {
      debugPrint(
        'Load leads error: $error',
      );

      if (mounted) {
        _showMessage(
          'Unable to load leads.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // NORMALIZE LEAD
  // ============================================================

  Map<String, dynamic> _normalizeLead(
    Map<String, dynamic> lead,
  ) {
    final addedDate = _parseDate(
      lead['addedDate'] ?? lead['createdAt'],
    );

    final updatedDate = _parseDate(
      lead['updatedDate'] ?? lead['updatedAt'],
    );

    final tracking = lead['tracking'] == true;

    String trackingStatus =
        lead['trackingStatus']?.toString().trim() ?? '';

    if (trackingStatus.isEmpty) {
      trackingStatus =
          tracking ? 'Pending' : 'Skip';
    }

    return {
      '_id': lead['_id'] ?? lead['id'] ?? '',
      'email': lead['email']?.toString() ?? '',
      'firstName':
          lead['firstName']?.toString() ?? '',
      'lastName':
          lead['lastName']?.toString() ?? '',
      'company':
          lead['company']?.toString() ?? '',
      'type':
          lead['type']?.toString() ?? 'Email',
      'tracking': tracking,
      'trackingStatus': trackingStatus,
      'addedDate':
          addedDate ?? DateTime.now(),
      'updatedDate': updatedDate,
    };
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // FILTERED LEADS
  // ============================================================

  List<Map<String, dynamic>>
      get filteredLeads {
    List<Map<String, dynamic>> result =
        List<Map<String, dynamic>>.from(
      leads,
    );

    // ==========================================================
    // SEARCH
    // ==========================================================

    final query =
        searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((lead) {
        final firstName =
            lead['firstName']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final lastName =
            lead['lastName']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final email =
            lead['email']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final company =
            lead['company']
                    ?.toString()
                    .toLowerCase() ??
                '';

        return '$firstName $lastName'
                .contains(query) ||
            email.contains(query) ||
            company.contains(query);
      }).toList();
    }

    // ==========================================================
    // TYPE
    // ==========================================================

    if (selectedTypeFilter !=
        'All Types') {
      result = result.where((lead) {
        final type =
            lead['type']
                    ?.toString()
                    .toLowerCase() ??
                '';

        return type ==
            selectedTypeFilter
                .toLowerCase();
      }).toList();
    }

    // ==========================================================
    // STATUS
    // ==========================================================

    if (selectedStatusFilter !=
        'All Status') {
      result = result.where((lead) {
        final status =
            lead['trackingStatus']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final wanted =
            selectedStatusFilter
                .toLowerCase();

        if (wanted == 'opened') {
          return status == 'opened' ||
              status == 'open' ||
              status == 'seen';
        }

        if (wanted == 'replied') {
          return status == 'replied' ||
              status == 'reply';
        }

        if (wanted == 'failed') {
          return status == 'failed' ||
              status == 'fail';
        }

        return status == wanted;
      }).toList();
    }

    // ==========================================================
    // TODAY
    // ==========================================================

    if (todayOnly) {
      final now = DateTime.now();

      result = result.where((lead) {
        final date =
            lead['addedDate']
                as DateTime;

        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList();
    }

    // ==========================================================
    // FROM DATE
    // ==========================================================

    if (fromDate != null) {
      final start = DateTime(
        fromDate!.year,
        fromDate!.month,
        fromDate!.day,
      );

      result = result.where((lead) {
        final date =
            lead['addedDate']
                as DateTime;

        return !date.isBefore(start);
      }).toList();
    }

    // ==========================================================
    // TO DATE
    // ==========================================================

    if (toDate != null) {
      final end = DateTime(
        toDate!.year,
        toDate!.month,
        toDate!.day,
        23,
        59,
        59,
        999,
      );

      result = result.where((lead) {
        final date =
            lead['addedDate']
                as DateTime;

        return !date.isAfter(end);
      }).toList();
    }

    return result;
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  List<Map<String, dynamic>>
      get paginatedLeads {
    final data = filteredLeads;

    if (data.isEmpty) {
      return [];
    }

    final start =
        (currentPage - 1) *
            entriesPerPage;

    if (start >= data.length) {
      return [];
    }

    final calculatedEnd =
        start + entriesPerPage;

    final end =
        calculatedEnd > data.length
            ? data.length
            : calculatedEnd;

    return data.sublist(
      start,
      end,
    );
  }

  int get totalPages {
    if (filteredLeads.isEmpty) {
      return 1;
    }

    return (filteredLeads.length /
            entriesPerPage)
        .ceil();
  }

  void _fixCurrentPage() {
    final pages = totalPages;

    if (currentPage > pages) {
      currentPage = pages;
    }

    if (currentPage < 1) {
      currentPage = 1;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: gold,
          backgroundColor:
              cardBackground,
          onRefresh: () async {
            await _loadLeads(
              showLoader: false,
              resetPage: false,
            );
          },
          child: LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              final isMobile =
                  constraints.maxWidth <
                      850;

              if (isMobile) {
                return _buildMobileView();
              }

              return _buildDesktopView();
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE VIEW
  // ============================================================

  Widget _buildMobileView() {
    return CustomScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            40,
          ),
          sliver: SliverList(
            delegate:
                SliverChildListDelegate(
              [
                _buildMobileHeader(),

                const SizedBox(
                  height: 24,
                ),

                _buildMobileSearch(),

                const SizedBox(
                  height: 12,
                ),

                _buildMobileFilters(),

                const SizedBox(
                  height: 12,
                ),

                _buildMobileExcelActions(),

                const SizedBox(
                  height: 20,
                ),

                if (isLoading)
                  _buildMobileLoading()
                else if (paginatedLeads
                    .isEmpty)
                  _buildMobileEmpty()
                else
                  ...paginatedLeads.map(
                    (lead) => Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        bottom: 12,
                      ),
                      child:
                          _buildMobileLeadCard(
                        lead,
                      ),
                    ),
                  ),

                if (!isLoading &&
                    filteredLeads
                        .isNotEmpty) ...[
                  const SizedBox(
                    height: 8,
                  ),

                  _buildMobilePagination(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE HEADER
  // ============================================================

  Widget _buildMobileHeader() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: const [
              Text(
                'Leads',
                style: TextStyle(
                  color: white,
                  fontSize: 29,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(
                height: 5,
              ),

              Text(
                'Manage and track your leads',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Search',
          onPressed: () {
            FocusScope.of(context)
                .requestFocus(
              FocusNode(),
            );
          },
          icon: const Icon(
            Icons.search_rounded,
            color: lightText,
            size: 30,
          ),
        ),

        const SizedBox(
          width: 4,
        ),

        InkWell(
          onTap:
              _openAddLeadScreen,
          borderRadius:
              BorderRadius.circular(
            13,
          ),
          child: Container(
            width: 54,
            height: 54,
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
                colors: [
                  Color(
                    0xFFFFD66F,
                  ),
                  Color(
                    0xFFF0B93C,
                  ),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      gold.withOpacity(
                    0.20,
                  ),
                  blurRadius: 18,
                  offset:
                      const Offset(
                    0,
                    6,
                  ),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 32,
              color: Color(
                0xFF171208,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE SEARCH
  // ============================================================

  Widget _buildMobileSearch() {
    return Container(
      height: 58,
      decoration:
          BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: TextField(
        controller:
            searchController,
        cursorColor: gold,
        onChanged: (value) {
          setState(() {
            searchQuery = value;

            currentPage = 1;
          });
        },
        style:
            const TextStyle(
          color: lightText,
          fontSize: 14,
        ),
        decoration:
            const InputDecoration(
          border:
              InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: mutedText,
            size: 27,
          ),
          hintText:
              'Search by name, email, company...',
          hintStyle:
              TextStyle(
            color: Color(
              0xFF74767E,
            ),
            fontSize: 12.5,
          ),
          contentPadding:
              EdgeInsets.symmetric(
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE FILTERS
  // ============================================================

  Widget _buildMobileFilters() {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final narrow =
            constraints.maxWidth <
                360;

        if (narrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child:
                        _mobileDropdownButton(
                      value:
                          selectedTypeFilter,
                      items: const [
                        'All Types',
                        'Email',
                        'WhatsApp',
                      ],
                      onChanged:
                          _changeTypeFilter,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                        _mobileDropdownButton(
                      value:
                          selectedStatusFilter,
                      items: const [
                        'All Status',
                        'Pending',
                        'Sent',
                        'Opened',
                        'Clicked',
                        'Replied',
                        'Failed',
                        'Skip',
                        'Interested',
                        'Not Interested',
                      ],
                      onChanged:
                          _changeStatusFilter,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    _mobileFilterButton(),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child:
                  _mobileDropdownButton(
                value:
                    selectedTypeFilter,
                items: const [
                  'All Types',
                  'Email',
                  'WhatsApp',
                ],
                onChanged:
                    _changeTypeFilter,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child:
                  _mobileDropdownButton(
                value:
                    selectedStatusFilter,
                items: const [
                  'All Status',
                  'Pending',
                  'Sent',
                  'Opened',
                  'Clicked',
                  'Replied',
                  'Failed',
                  'Skip',
                  'Interested',
                  'Not Interested',
                ],
                onChanged:
                    _changeStatusFilter,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child:
                  _mobileFilterButton(),
            ),
          ],
        );
      },
    );
  }

  void _changeTypeFilter(
    String? value,
  ) {
    if (value == null) {
      return;
    }

    setState(() {
      selectedTypeFilter =
          value;

      currentPage = 1;
    });
  }

  void _changeStatusFilter(
    String? value,
  ) {
    if (value == null) {
      return;
    }

    setState(() {
      selectedStatusFilter =
          value;

      currentPage = 1;
    });
  }

  Widget _mobileDropdownButton({
    required String value,
    required List<String> items,
    required ValueChanged<String?>
        onChanged,
  }) {
    return Container(
      height: 54,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration:
          BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(
          11,
        ),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child:
          DropdownButtonHideUnderline(
        child:
            DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor:
              cardBackground2,
          icon: const Icon(
            Icons
                .keyboard_arrow_down_rounded,
            color: mutedText,
            size: 20,
          ),
          style:
              const TextStyle(
            color: lightText,
            fontSize: 11.5,
            fontWeight:
                FontWeight.w500,
          ),
          items: items.map(
            (item) {
              return DropdownMenuItem<
                  String>(
                value: item,
                child: Text(
                  item,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                ),
              );
            },
          ).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _mobileFilterButton() {
    String label = 'Filters';

    if (todayOnly) {
      label = 'Today';
    } else if (fromDate != null &&
        toDate != null) {
      label =
          '${_shortDate(fromDate!)}-${_shortDate(toDate!)}';
    }

    return InkWell(
      onTap: _showFilterOptions,
      borderRadius:
          BorderRadius.circular(
        11,
      ),
      child: Container(
        height: 54,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        decoration:
            BoxDecoration(
          color: cardBackground,
          borderRadius:
              BorderRadius.circular(
            11,
          ),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.filter_alt_rounded,
              color: gold,
              size: 20,
            ),

            const SizedBox(
              width: 5,
            ),

            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow:
                    TextOverflow
                        .ellipsis,
                style:
                    const TextStyle(
                  color: gold,
                  fontSize: 11.5,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTER OPTIONS
  // ============================================================

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          cardBackground2,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(
            22,
          ),
        ),
      ),
      builder: (
        bottomContext,
      ) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,
              children: [
                const Text(
                  'Filter Leads',
                  style: TextStyle(
                    color: white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                _filterSheetOption(
                  icon: Icons
                      .today_outlined,
                  title: 'Today',
                  onTap: () {
                    Navigator.pop(
                      bottomContext,
                    );

                    setState(() {
                      todayOnly = true;

                      fromDate = null;
                      toDate = null;

                      currentPage = 1;
                    });
                  },
                ),

                _filterSheetOption(
                  icon: Icons
                      .calendar_month_outlined,
                  title: 'All Dates',
                  onTap: () {
                    Navigator.pop(
                      bottomContext,
                    );

                    setState(() {
                      todayOnly = false;

                      fromDate = null;
                      toDate = null;

                      currentPage = 1;
                    });
                  },
                ),

                _filterSheetOption(
                  icon: Icons
                      .date_range_outlined,
                  title:
                      'Custom Date Range',
                  onTap: () {
                    Navigator.pop(
                      bottomContext,
                    );

                    Future.microtask(
                      () {
                        if (mounted) {
                          _showDateFilter();
                        }
                      },
                    );
                  },
                ),

                _filterSheetOption(
                  icon:
                      Icons.restart_alt,
                  title:
                      'Reset All Filters',
                  onTap: () {
                    Navigator.pop(
                      bottomContext,
                    );

                    _resetFilters();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration:
            BoxDecoration(
          color:
              gold.withOpacity(
            0.10,
          ),
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
        child: Icon(
          icon,
          color: gold,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style:
            const TextStyle(
          color: lightText,
          fontSize: 14,
          fontWeight:
              FontWeight.w500,
        ),
      ),
      trailing:
          const Icon(
        Icons.chevron_right,
        color: mutedText,
      ),
      onTap: onTap,
    );
  }

  void _resetFilters() {
    setState(() {
      todayOnly = false;

      fromDate = null;
      toDate = null;

      selectedTypeFilter =
          'All Types';

      selectedStatusFilter =
          'All Status';

      searchController.clear();

      searchQuery = '';

      currentPage = 1;
    });
  }

  // ============================================================
  // MOBILE EXCEL ACTIONS
  // ============================================================

  Widget _buildMobileExcelActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                isDownloadingExcel
                    ? null
                    : _downloadExcel,
            icon: const Icon(
              Icons
                  .file_download_outlined,
              size: 18,
            ),
            label: Text(
              isDownloadingExcel
                  ? 'Downloading...'
                  : 'Export',
            ),
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  lightText,
              disabledForegroundColor:
                  mutedText,
              side:
                  const BorderSide(
                color:
                    borderColor,
              ),
              minimumSize:
                  const Size(
                0,
                47,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  10,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                isUploadingExcel
                    ? null
                    : _uploadExcel,
            icon: const Icon(
              Icons
                  .file_upload_outlined,
              size: 18,
            ),
            label: Text(
              isUploadingExcel
                  ? 'Uploading...'
                  : 'Import',
            ),
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  lightText,
              disabledForegroundColor:
                  mutedText,
              side:
                  const BorderSide(
                color:
                    borderColor,
              ),
              minimumSize:
                  const Size(
                0,
                47,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE LEAD CARD
  // ============================================================

  Widget _buildMobileLeadCard(
    Map<String, dynamic> lead,
  ) {
    final firstName =
        lead['firstName']
                ?.toString()
                .trim() ??
            '';

    final lastName =
        lead['lastName']
                ?.toString()
                .trim() ??
            '';

    final fullName =
        '$firstName $lastName'.trim();

    final email =
        lead['email']
                ?.toString()
                .trim() ??
            '';

    final company =
        lead['company']
                ?.toString()
                .trim() ??
            '';

    final type =
        lead['type']?.toString() ??
            'Email';

    final addedDate =
        lead['addedDate']
            as DateTime;

    final displayName =
        fullName.isEmpty
            ? email
            : fullName;

    final initials =
        _getInitials(
      firstName,
      lastName,
      email,
    );

    final avatarColor =
        _avatarColor(
      displayName,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showViewLeadDialog(
            lead,
          );
        },
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        child: Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.all(
            15,
          ),
          decoration:
              BoxDecoration(
            color: cardBackground,
            borderRadius:
                BorderRadius.circular(
              15,
            ),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child:
              LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              final narrow =
                  constraints
                          .maxWidth <
                      330;

              if (narrow) {
                return _buildNarrowLeadCard(
                  lead: lead,
                  firstName:
                      firstName,
                  lastName:
                      lastName,
                  displayName:
                      displayName,
                  email: email,
                  company:
                      company,
                  type: type,
                  addedDate:
                      addedDate,
                  initials:
                      initials,
                  avatarColor:
                      avatarColor,
                );
              }

              return Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  // AVATAR

                  Container(
                    width: 55,
                    height: 55,
                    alignment:
                        Alignment.center,
                    decoration:
                        BoxDecoration(
                      color: avatarColor
                          .withOpacity(
                        0.13,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child: Text(
                      initials,
                      style:
                          TextStyle(
                        color:
                            avatarColor,
                        fontSize: 19,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 13,
                  ),

                  // LEFT DETAILS

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          displayName
                                  .isEmpty
                              ? 'Unnamed Lead'
                              : displayName,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color: white,
                            fontSize: 15.5,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),

                        if (company
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            company,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  mutedText,
                              fontSize:
                                  12.5,
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          email,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                mutedText,
                            fontSize:
                                11.5,
                          ),
                        ),

                        const SizedBox(
                          height: 11,
                        ),

                        _trackingBadge(
                          lead,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  // RIGHT SIDE

                  SizedBox(
                    width: 91,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          type,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                lightText,
                            fontSize:
                                12.5,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Padding(
                              padding:
                                  EdgeInsets
                                      .only(
                                top: 1,
                              ),
                              child: Icon(
                                Icons
                                    .calendar_today_outlined,
                                color:
                                    mutedText,
                                size: 14,
                              ),
                            ),

                            const SizedBox(
                              width: 5,
                            ),

                            Expanded(
                              child: Text(
                                _formatShortCardDate(
                                  addedDate,
                                ),
                                maxLines: 3,
                                style:
                                    const TextStyle(
                                  color:
                                      mutedText,
                                  fontSize:
                                      10.5,
                                  height:
                                      1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  _leadMenu(
                    lead,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowLeadCard({
    required Map<String, dynamic>
        lead,
    required String firstName,
    required String lastName,
    required String displayName,
    required String email,
    required String company,
    required String type,
    required DateTime addedDate,
    required String initials,
    required Color avatarColor,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          alignment:
              Alignment.center,
          decoration:
              BoxDecoration(
            color:
                avatarColor.withOpacity(
              0.13,
            ),
            shape: BoxShape.circle,
          ),
          child: Text(
            initials,
            style:
                TextStyle(
              color: avatarColor,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName.isEmpty
                          ? 'Unnamed Lead'
                          : displayName,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color: white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),

                  _leadMenu(
                    lead,
                  ),
                ],
              ),

              if (company.isNotEmpty)
                Text(
                  company,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color: mutedText,
                    fontSize: 12,
                  ),
                ),

              const SizedBox(
                height: 4,
              ),

              Text(
                email,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color: mutedText,
                  fontSize: 11,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Row(
                children: [
                  _trackingBadge(
                    lead,
                  ),

                  const Spacer(),

                  Text(
                    type,
                    style:
                        const TextStyle(
                      color: lightText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 9,
              ),

              Row(
                children: [
                  const Icon(
                    Icons
                        .calendar_today_outlined,
                    size: 13,
                    color: mutedText,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Text(
                    _formatShortCardDate(
                      addedDate,
                    ),
                    style:
                        const TextStyle(
                      color: mutedText,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _leadMenu(
    Map<String, dynamic> lead,
  ) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints:
          const BoxConstraints(
        minWidth: 125,
      ),
      color: cardBackground2,
      icon: const Icon(
        Icons.more_vert_rounded,
        color: mutedText,
        size: 23,
      ),
      onSelected: (value) {
        if (value == 'view') {
          _showViewLeadDialog(
            lead,
          );
        } else if (value == 'edit') {
          _showEditLeadDialog(
            lead,
          );
        } else if (value ==
            'delete') {
          _deleteLead(
            lead,
          );
        }
      },
      itemBuilder: (context) =>
          const [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(
                Icons
                    .visibility_outlined,
                color: lightText,
                size: 18,
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                'View',
                style: TextStyle(
                  color: lightText,
                ),
              ),
            ],
          ),
        ),

        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: gold,
                size: 18,
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                'Edit',
                style: TextStyle(
                  color: lightText,
                ),
              ),
            ],
          ),
        ),

        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: red,
                size: 18,
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                'Delete',
                style: TextStyle(
                  color: red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TRACKING BADGE
  // ============================================================

  Widget _trackingBadge(
    Map<String, dynamic> lead,
  ) {
    final rawStatus =
        lead['trackingStatus']
                ?.toString()
                .trim() ??
            '';

    final status =
        rawStatus.isEmpty
            ? (lead['tracking'] ==
                    true
                ? 'Pending'
                : 'Skip')
            : rawStatus;

    final normalized =
        status.toLowerCase();

    Color color;
    IconData icon;

    if (normalized == 'interested') {
      color = green;
      icon = Icons.thumb_up_alt_rounded;
    } else if (normalized == 'not interested') {
      color = red;
      icon = Icons.unsubscribe_rounded;
    } else if (normalized == 'sent') {
      color =
          const Color(
        0xFF4D9CFF,
      );

      icon =
          Icons.email_rounded;
    } else if (normalized ==
            'opened' ||
        normalized == 'open' ||
        normalized == 'seen') {
      color = orange;

      icon =
          Icons.visibility_rounded;
    } else if (normalized ==
            'clicked' ||
        normalized == 'click') {
      color = purple;

      icon =
          Icons.touch_app_rounded;
    } else if (normalized ==
            'replied' ||
        normalized == 'reply') {
      color = purple;

      icon =
          Icons.reply_rounded;
    } else if (normalized ==
            'failed' ||
        normalized == 'fail') {
      color = red;

      icon =
          Icons.error_outline_rounded;
    } else if (normalized ==
        'pending') {
      color = gold;

      icon =
          Icons.schedule_rounded;
    } else {
      color =
          const Color(
        0xFF9698A1,
      );

      icon =
          Icons.remove_circle_outline;
    }

    return Align(
      alignment:
          Alignment.centerLeft,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 5,
        ),
        decoration:
            BoxDecoration(
          color:
              color.withOpacity(
            0.10,
          ),
          borderRadius:
              BorderRadius.circular(
            7,
          ),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 13,
            ),

            const SizedBox(
              width: 5,
            ),

            Text(
              _capitalizeStatus(
                status,
              ),
              style:
                  TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizeStatus(
    String value,
  ) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value
            .substring(1)
            .toLowerCase();
  }

  // ============================================================
  // AVATAR
  // ============================================================

  String _getInitials(
    String firstName,
    String lastName,
    String email,
  ) {
    String result = '';

    if (firstName.isNotEmpty) {
      result +=
          firstName[0].toUpperCase();
    }

    if (lastName.isNotEmpty) {
      result +=
          lastName[0].toUpperCase();
    }

    if (result.isEmpty &&
        email.isNotEmpty) {
      result =
          email[0].toUpperCase();
    }

    return result.isEmpty
        ? '?'
        : result;
  }

  Color _avatarColor(
    String value,
  ) {
    final colors = [
      const Color(
        0xFF4D95FF,
      ),
      const Color(
        0xFF45CB7A,
      ),
      const Color(
        0xFF8D54FF,
      ),
      const Color(
        0xFFFFC63D,
      ),
      const Color(
        0xFFFF5666,
      ),
      const Color(
        0xFF38C3D8,
      ),
    ];

    if (value.isEmpty) {
      return colors.first;
    }

    final sum =
        value.codeUnits.fold<int>(
      0,
      (
        previous,
        element,
      ) {
        return previous +
            element;
      },
    );

    return colors[
        sum % colors.length];
  }

  // ============================================================
  // MOBILE PAGINATION
  // ============================================================

  Widget _buildMobilePagination() {
    final data =
        filteredLeads;

    final start = data.isEmpty
        ? 0
        : (currentPage - 1) *
                entriesPerPage +
            1;

    final calculatedEnd =
        currentPage *
            entriesPerPage;

    final end =
        calculatedEnd > data.length
            ? data.length
            : calculatedEnd;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Showing $start to $end of ${data.length} leads',
                  style:
                      const TextStyle(
                    color: mutedText,
                    fontSize: 10.5,
                  ),
                ),
              ),

              _entriesDropdown(
                compact: true,
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          _paginationControls(
            totalPages,
          ),
        ],
      ),
    );
  }

  Widget _paginationControls(
    int pages,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      mainAxisSize:
          MainAxisSize.min,
      children: [
        _pageArrow(
          icon:
              Icons.chevron_left,
          onPressed:
              currentPage > 1
                  ? () {
                      setState(() {
                        currentPage--;
                      });
                    }
                  : null,
        ),

        const SizedBox(
          width: 8,
        ),

        _pageNumber(
          currentPage,
          selected: true,
        ),

        if (currentPage <
            pages) ...[
          const SizedBox(
            width: 8,
          ),

          _pageNumber(
            currentPage + 1,
            selected: false,
          ),
        ],

        if (currentPage + 1 <
            pages) ...[
          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: Text(
              '...',
              style: TextStyle(
                color: mutedText,
              ),
            ),
          ),

          _pageNumber(
            pages,
            selected: false,
          ),
        ],

        const SizedBox(
          width: 8,
        ),

        _pageArrow(
          icon:
              Icons.chevron_right,
          onPressed:
              currentPage < pages
                  ? () {
                      setState(() {
                        currentPage++;
                      });
                    }
                  : null,
        ),
      ],
    );
  }

  Widget _pageNumber(
    int page, {
    required bool selected,
  }) {
    return InkWell(
      onTap: selected
          ? null
          : () {
              setState(() {
                currentPage = page;
              });
            },
      borderRadius:
          BorderRadius.circular(
        8,
      ),
      child: Container(
        width: 36,
        height: 36,
        alignment:
            Alignment.center,
        decoration:
            BoxDecoration(
          color: selected
              ? gold.withOpacity(
                  0.10,
                )
              : cardBackground,
          borderRadius:
              BorderRadius.circular(
            8,
          ),
          border: Border.all(
            color: selected
                ? gold
                : borderColor,
          ),
        ),
        child: Text(
          '$page',
          style:
              TextStyle(
            color: selected
                ? gold
                : lightText,
            fontWeight:
                FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _pageArrow({
    required IconData icon,
    required VoidCallback?
        onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style:
            OutlinedButton.styleFrom(
          padding:
              EdgeInsets.zero,
          foregroundColor:
              lightText,
          disabledForegroundColor:
              mutedText.withOpacity(
            0.25,
          ),
          side:
              const BorderSide(
            color: borderColor,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              8,
            ),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
        ),
      ),
    );
  }

  Widget _entriesDropdown({
    bool compact = false,
  }) {
    return Container(
      height:
          compact ? 34 : 40,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      decoration:
          BoxDecoration(
        color: cardBackground,
        border: Border.all(
          color: borderColor,
        ),
        borderRadius:
            BorderRadius.circular(
          8,
        ),
      ),
      child:
          DropdownButtonHideUnderline(
        child:
            DropdownButton<int>(
          value: entriesPerPage,
          dropdownColor:
              cardBackground2,
          iconEnabledColor:
              lightText,
          style:
              TextStyle(
            color: lightText,
            fontSize:
                compact ? 10 : 12,
          ),
          items: const [
            DropdownMenuItem(
              value: 10,
              child: Text('10'),
            ),
            DropdownMenuItem(
              value: 25,
              child: Text('25'),
            ),
            DropdownMenuItem(
              value: 50,
              child: Text('50'),
            ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              entriesPerPage = value;

              currentPage = 1;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE LOADING
  // ============================================================

  Widget _buildMobileLoading() {
    return const AppCardSkeletonList(
      itemCount: 5,
      compact: true,
    );
  }

  // ============================================================
  // MOBILE EMPTY
  // ============================================================

  Widget _buildMobileEmpty() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 60,
        horizontal: 20,
      ),
      decoration:
          BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child:
          const Column(
        children: [
          Icon(
            Icons
                .people_outline_rounded,
            color: gold,
            size: 44,
          ),

          SizedBox(
            height: 14,
          ),

          Text(
            'No leads found',
            style: TextStyle(
              color: white,
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          SizedBox(
            height: 6,
          ),

          Text(
            'Try changing your search or filters.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP VIEW
  // ============================================================

  Widget _buildDesktopView() {
    return SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(
        30,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _buildDesktopHeader(),

          const SizedBox(
            height: 24,
          ),

          Row(
            children: [
              Expanded(
                flex: 3,
                child:
                    _buildMobileSearch(),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                flex: 2,
                child:
                    _buildMobileFilters(),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Align(
            alignment:
                Alignment.centerRight,
            child: SizedBox(
              width: 300,
              child:
                  _buildMobileExcelActions(),
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          if (isLoading)
            _buildMobileLoading()
          else if (paginatedLeads
              .isEmpty)
            _buildMobileEmpty()
          else
            LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final cardWidth =
                    (constraints.maxWidth -
                            16) /
                        2;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children:
                      paginatedLeads
                          .map(
                    (lead) {
                      return SizedBox(
                        width:
                            cardWidth,
                        child:
                            _buildMobileLeadCard(
                          lead,
                        ),
                      );
                    },
                  ).toList(),
                );
              },
            ),

          if (!isLoading &&
              filteredLeads
                  .isNotEmpty) ...[
            const SizedBox(
              height: 20,
            ),

            _buildMobilePagination(),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Leads',
                style: TextStyle(
                  color: white,
                  fontSize: 32,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              SizedBox(
                height: 6,
              ),

              Text(
                'Manage and track all your leads',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        ElevatedButton.icon(
          onPressed:
              _openAddLeadScreen,
          icon:
              const Icon(
            Icons.add_rounded,
          ),
          label:
              const Text(
            'Add Lead',
          ),
          style:
              ElevatedButton.styleFrom(
            backgroundColor: gold,
            foregroundColor:
                const Color(
              0xFF171208,
            ),
            minimumSize:
                const Size(
              140,
              50,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // OPEN ADD LEAD
  // ============================================================

  Future<void>
      _openAddLeadScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (
          context,
        ) =>
            const AddLeadScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadLeads(
      showLoader: false,
    );
  }

  // ============================================================
  // VIEW LEAD
  // ============================================================

  void _showViewLeadDialog(
    Map<String, dynamic> lead,
  ) {
    final firstName =
        lead['firstName']
                ?.toString()
                .trim() ??
            '';

    final lastName =
        lead['lastName']
                ?.toString()
                .trim() ??
            '';

    final fullName =
        '$firstName $lastName'.trim();

    final email =
        lead['email']
                ?.toString()
                .trim() ??
            '';

    final company =
        lead['company']
                ?.toString()
                .trim() ??
            '';

    final type =
        lead['type']?.toString() ??
            'Email';

    final addedDate =
        lead['addedDate']
            as DateTime;

    showDialog(
      context: context,
      builder: (
        dialogContext,
      ) {
        final width =
            MediaQuery.of(
          dialogContext,
        ).size.width;

        final isMobile =
            width < 600;

        return Dialog(
          backgroundColor:
              Colors.transparent,
          insetPadding:
              EdgeInsets.symmetric(
            horizontal:
                isMobile ? 14 : 24,
            vertical: 20,
          ),
          child:
              ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 560,
            ),
            child: Container(
              decoration:
                  BoxDecoration(
                color: cardBackground,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  // HEADER

                  Container(
                    padding:
                        const EdgeInsets.all(
                      17,
                    ),
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(
                        0xFF0C0D0F,
                      ),
                      borderRadius:
                          BorderRadius.only(
                        topLeft:
                            Radius.circular(
                          20,
                        ),
                        topRight:
                            Radius.circular(
                          20,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration:
                              BoxDecoration(
                            color:
                                gold.withOpacity(
                              0.10,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              13,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .person_outline,
                            color: gold,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                fullName.isEmpty
                                    ? 'Lead Details'
                                    : fullName,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color: white,
                                  fontSize: 17,
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
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      mutedText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed: () {
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

                  Flexible(
                    child:
                        SingleChildScrollView(
                      padding:
                          const EdgeInsets.all(
                        18,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets.all(
                              14,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  cardBackground2,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                              border:
                                  Border.all(
                                color:
                                    borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons
                                      .analytics_outlined,
                                  color: gold,
                                  size: 20,
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                const Expanded(
                                  child: Text(
                                    'Tracking Status',
                                    style:
                                        TextStyle(
                                      color:
                                          lightText,
                                      fontSize:
                                          13,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                ),

                                _trackingBadge(
                                  lead,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          _viewInfoRow(
                            'Email',
                            email.isEmpty
                                ? '-'
                                : email,
                            Icons
                                .email_outlined,
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          _viewInfoRow(
                            'Full Name',
                            fullName.isEmpty
                                ? '-'
                                : fullName,
                            Icons
                                .person_outline,
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          _viewInfoRow(
                            'Company',
                            company.isEmpty
                                ? '-'
                                : company,
                            Icons
                                .business_outlined,
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          _viewInfoRow(
                            'Type',
                            type,
                            Icons
                                .category_outlined,
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          _viewInfoRow(
                            'Added Date',
                            _formatDate(
                              addedDate,
                            ),
                            Icons
                                .calendar_today_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      15,
                    ),
                    child: isMobile
                        ? Column(
                            children: [
                              SizedBox(
                                width:
                                    double.infinity,
                                height: 44,
                                child:
                                    ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(
                                      dialogContext,
                                    );

                                    Future.microtask(
                                      () {
                                        if (mounted) {
                                          _showEditLeadDialog(
                                            lead,
                                          );
                                        }
                                      },
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons
                                        .edit_outlined,
                                    size: 17,
                                  ),
                                  label:
                                      const Text(
                                    'Edit Lead',
                                  ),
                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        gold,
                                    foregroundColor:
                                        const Color(
                                      0xFF171208,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              SizedBox(
                                width:
                                    double.infinity,
                                height: 44,
                                child:
                                    OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(
                                      dialogContext,
                                    );

                                    Future.microtask(
                                      () {
                                        if (mounted) {
                                          _deleteLead(
                                            lead,
                                          );
                                        }
                                      },
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons
                                        .delete_outline,
                                  ),
                                  label:
                                      const Text(
                                    'Delete Lead',
                                  ),
                                  style:
                                      OutlinedButton
                                          .styleFrom(
                                    foregroundColor:
                                        red,
                                    side:
                                        const BorderSide(
                                      color:
                                          Color(
                                        0xFF76333D,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child:
                                    OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(
                                      dialogContext,
                                    );

                                    _deleteLead(
                                      lead,
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons
                                        .delete_outline,
                                  ),
                                  label:
                                      const Text(
                                    'Delete',
                                  ),
                                  style:
                                      OutlinedButton
                                          .styleFrom(
                                    foregroundColor:
                                        red,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child:
                                    ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(
                                      dialogContext,
                                    );

                                    _showEditLeadDialog(
                                      lead,
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons
                                        .edit_outlined,
                                  ),
                                  label:
                                      const Text(
                                    'Edit Lead',
                                  ),
                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        gold,
                                    foregroundColor:
                                        const Color(
                                      0xFF171208,
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
          ),
        );
      },
    );
  }

  Widget _viewInfoRow(
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color: mutedText,
            fontSize: 10,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration:
              BoxDecoration(
            color: cardBackground2,
            borderRadius:
                BorderRadius.circular(
              10,
            ),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: gold,
                size: 17,
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color: lightText,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EDIT LEAD DIALOG
  // ============================================================

  void _showEditLeadDialog(
    Map<String, dynamic> lead,
  ) {
    editEmailController.text =
        lead['email']?.toString() ??
            '';

    editFirstNameController.text =
        lead['firstName']
                ?.toString() ??
            '';

    editLastNameController.text =
        lead['lastName']
                ?.toString() ??
            '';

    editCompanyController.text =
        lead['company']
                ?.toString() ??
            '';

    selectedType =
        lead['type']?.toString() ??
            'Email';

    trackingEnabled =
        lead['tracking'] == true;

    showDialog(
      context: context,
      barrierDismissible: false,
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
                horizontal: 16,
                vertical: 20,
              ),
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 560,
                ),
                child: Container(
                  decoration:
                      BoxDecoration(
                    color:
                        cardBackground,
                    borderRadius:
                        BorderRadius
                            .circular(
                      18,
                    ),
                    border: Border.all(
                      color:
                          borderColor,
                    ),
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      _dialogHeader(
                        dialogContext,
                        Icons
                            .edit_outlined,
                        'Edit Lead',
                        'Update lead information',
                      ),

                      Flexible(
                        child:
                            SingleChildScrollView(
                          padding:
                              const EdgeInsets.all(
                            20,
                          ),
                          child: Column(
                            children: [
                              _dialogInput(
                                controller:
                                    editEmailController,
                                label:
                                    'Email Address',
                                hint:
                                    'john@example.com',
                                icon: Icons
                                    .email_outlined,
                                keyboardType:
                                    TextInputType
                                        .emailAddress,
                              ),

                              const SizedBox(
                                height: 14,
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
                                        _dialogInput(
                                          controller:
                                              editFirstNameController,
                                          label:
                                              'First Name',
                                          hint:
                                              'John',
                                          icon: Icons
                                              .person_outline,
                                        ),

                                        const SizedBox(
                                          height: 14,
                                        ),

                                        _dialogInput(
                                          controller:
                                              editLastNameController,
                                          label:
                                              'Last Name',
                                          hint:
                                              'Doe',
                                          icon: Icons
                                              .person_outline,
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(
                                        child:
                                            _dialogInput(
                                          controller:
                                              editFirstNameController,
                                          label:
                                              'First Name',
                                          hint:
                                              'John',
                                          icon: Icons
                                              .person_outline,
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 12,
                                      ),

                                      Expanded(
                                        child:
                                            _dialogInput(
                                          controller:
                                              editLastNameController,
                                          label:
                                              'Last Name',
                                          hint:
                                              'Doe',
                                          icon: Icons
                                              .person_outline,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              _dialogInput(
                                controller:
                                    editCompanyController,
                                label:
                                    'Company',
                                hint:
                                    'Company name',
                                icon: Icons
                                    .business_outlined,
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              _dialogDropdown(
                                value:
                                    selectedType,
                                onChanged:
                                    (value) {
                                  setDialogState(
                                    () {
                                      selectedType =
                                          value ??
                                              'Email';
                                    },
                                  );
                                },
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              Container(
                                decoration:
                                    BoxDecoration(
                                  color:
                                      cardBackground2,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                  border:
                                      Border.all(
                                    color:
                                        borderColor,
                                  ),
                                ),
                                child:
                                    SwitchListTile(
                                  title:
                                      const Text(
                                    'Enable Tracking',
                                    style:
                                        TextStyle(
                                      color: white,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle:
                                      const Text(
                                    'Track email activity',
                                    style:
                                        TextStyle(
                                      color:
                                          mutedText,
                                      fontSize: 11,
                                    ),
                                  ),
                                  value:
                                      trackingEnabled,
                                  activeColor:
                                      gold,
                                  onChanged:
                                      (value) {
                                    setDialogState(
                                      () {
                                        trackingEnabled =
                                            value;
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets.all(
                          15,
                        ),
                        decoration:
                            const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color:
                                  borderColor,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child:
                                  OutlinedButton(
                                onPressed:
                                    isUpdatingLead
                                        ? null
                                        : () {
                                            Navigator.pop(
                                              dialogContext,
                                            );
                                          },
                                style:
                                    OutlinedButton
                                        .styleFrom(
                                  foregroundColor:
                                      mutedText,
                                  minimumSize:
                                      const Size(
                                    0,
                                    46,
                                  ),
                                ),
                                child:
                                    const Text(
                                  'Cancel',
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              flex: 2,
                              child:
                                  ElevatedButton.icon(
                                onPressed:
                                    isUpdatingLead
                                        ? null
                                        : () {
                                            _updateLead(
                                              dialogContext,
                                              lead,
                                            );
                                          },
                                icon: isUpdatingLead
                                    ? const SizedBox(
                                        width: 15,
                                        height: 15,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                          color:
                                              Color(
                                            0xFF171208,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons
                                            .save_outlined,
                                        size: 17,
                                      ),
                                label: Text(
                                  isUpdatingLead
                                      ? 'Saving...'
                                      : 'Save Changes',
                                ),
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      gold,
                                  foregroundColor:
                                      const Color(
                                    0xFF171208,
                                  ),
                                  minimumSize:
                                      const Size(
                                    0,
                                    46,
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
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // UPDATE LEAD
  // ============================================================

  Future<void> _updateLead(
    BuildContext dialogContext,
    Map<String, dynamic> lead,
  ) async {
    final leadId =
        lead['_id']?.toString() ??
            '';

    if (leadId.isEmpty) {
      _showMessage(
        'Lead ID not found.',
      );

      return;
    }

    final email =
        editEmailController.text
            .trim();

    final firstName =
        editFirstNameController
            .text
            .trim();

    final lastName =
        editLastNameController
            .text
            .trim();

    final company =
        editCompanyController.text
            .trim();

    if (email.isEmpty) {
      _showMessage(
        'Email is required.',
      );

      return;
    }

    final emailRegex =
        RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex
        .hasMatch(email)) {
      _showMessage(
        'Please enter a valid email address.',
      );

      return;
    }

    setState(() {
      isUpdatingLead = true;
    });

    try {
      final response =
          await LeadsApi.updateLead(
        leadId: leadId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        company: company,
        type: selectedType,
        tracking: trackingEnabled,
      );

      if (!mounted) {
        return;
      }

      if (response['success'] ==
          true) {
        if (dialogContext.mounted) {
          Navigator.pop(
            dialogContext,
          );
        }

        _showMessage(
          response['message']
                  ?.toString() ??
              'Lead updated successfully.',
        );

        await _loadLeads(
          showLoader: false,
          resetPage: false,
        );
      } else {
        _showMessage(
          response['message']
                  ?.toString() ??
              'Unable to update lead.',
        );
      }
    } catch (error) {
      debugPrint(
        'Update lead error: $error',
      );

      if (mounted) {
        _showMessage(
          'Unable to update lead.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingLead = false;
        });
      }
    }
  }

  // ============================================================
  // DELETE LEAD
  // ============================================================

  void _deleteLead(
    Map<String, dynamic> lead,
  ) {
    final firstName =
        lead['firstName']
                ?.toString() ??
            '';

    final lastName =
        lead['lastName']
                ?.toString() ??
            '';

    final email =
        lead['email']?.toString() ??
            '';

    final fullName =
        '$firstName $lastName'
            .trim();

    showDialog(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              cardBackground2,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          title:
              const Text(
            'Delete Lead',
            style: TextStyle(
              color: white,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete '
            '${fullName.isEmpty ? email : fullName}?',
            style:
                const TextStyle(
              color: mutedText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text(
                'Cancel',
                style: TextStyle(
                  color: mutedText,
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed:
                  isDeletingLead
                      ? null
                      : () async {
                          Navigator.pop(
                            dialogContext,
                          );

                          await _performDeleteLead(
                            lead,
                          );
                        },
              icon:
                  const Icon(
                Icons.delete_outline,
                size: 17,
              ),
              label:
                  const Text(
                'Delete',
              ),
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    const Color(
                  0xFFC94141,
                ),
                foregroundColor:
                    white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void>
      _performDeleteLead(
    Map<String, dynamic> lead,
  ) async {
    final leadId =
        lead['_id']?.toString() ??
            '';

    if (leadId.isEmpty) {
      _showMessage(
        'Lead ID not found.',
      );

      return;
    }

    setState(() {
      isDeletingLead = true;
    });

    try {
      final response =
          await LeadsApi.deleteLead(
        leadId: leadId,
      );

      if (!mounted) {
        return;
      }

      if (response['success'] ==
          true) {
        _showMessage(
          response['message']
                  ?.toString() ??
              'Lead deleted successfully.',
        );

        await _loadLeads(
          showLoader: false,
          resetPage: false,
        );
      } else {
        _showMessage(
          response['message']
                  ?.toString() ??
              'Unable to delete lead.',
        );
      }
    } catch (error) {
      debugPrint(
        'Delete lead error: $error',
      );

      if (mounted) {
        _showMessage(
          'Unable to delete lead.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDeletingLead = false;
        });
      }
    }
  }

  // ============================================================
  // DATE FILTER
  // ============================================================

  Future<void>
      _showDateFilter() async {
    DateTime? tempFrom =
        fromDate;

    DateTime? tempTo =
        toDate;

    await showDialog(
      context: context,
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
                horizontal: 16,
              ),
              child: Container(
                constraints:
                    const BoxConstraints(
                  maxWidth: 500,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      cardBackground,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  border: Border.all(
                    color:
                        borderColor,
                  ),
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    _dialogHeader(
                      dialogContext,
                      Icons
                          .date_range_outlined,
                      'Filter by Date',
                      'Select date range',
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      child: Column(
                        children: [
                          _dateSelector(
                            label:
                                'From Date',
                            value:
                                tempFrom,
                            onTap:
                                () async {
                              final picked =
                                  await _pickDate(
                                tempFrom,
                              );

                              if (picked !=
                                  null) {
                                setDialogState(
                                  () {
                                    tempFrom =
                                        picked;
                                  },
                                );
                              }
                            },
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          _dateSelector(
                            label:
                                'To Date',
                            value:
                                tempTo,
                            onTap:
                                () async {
                              final picked =
                                  await _pickDate(
                                tempTo,
                              );

                              if (picked !=
                                  null) {
                                setDialogState(
                                  () {
                                    tempTo =
                                        picked;
                                  },
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child:
                                OutlinedButton(
                              onPressed: () {
                                setDialogState(
                                  () {
                                    tempFrom =
                                        null;

                                    tempTo =
                                        null;
                                  },
                                );
                              },
                              style:
                                  OutlinedButton
                                      .styleFrom(
                                foregroundColor:
                                    mutedText,
                                minimumSize:
                                    const Size(
                                  0,
                                  44,
                                ),
                              ),
                              child:
                                  const Text(
                                'Clear',
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child:
                                ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  fromDate =
                                      tempFrom;

                                  toDate =
                                      tempTo;

                                  todayOnly =
                                      false;

                                  currentPage =
                                      1;
                                });

                                Navigator.pop(
                                  dialogContext,
                                );
                              },
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    gold,
                                foregroundColor:
                                    const Color(
                                  0xFF171208,
                                ),
                                minimumSize:
                                    const Size(
                                  0,
                                  44,
                                ),
                              ),
                              child:
                                  const Text(
                                'Apply',
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
      },
    );
  }

  Future<DateTime?> _pickDate(
    DateTime? value,
  ) {
    return showDatePicker(
      context: context,
      firstDate: DateTime(
        2020,
      ),
      lastDate: DateTime(
        2035,
      ),
      initialDate:
          value ?? DateTime.now(),
      builder: (
        context,
        child,
      ) {
        return Theme(
          data:
              Theme.of(context)
                  .copyWith(
            colorScheme:
                const ColorScheme.dark(
              primary: gold,
              surface:
                  cardBackground2,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Widget _dateSelector({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color: mutedText,
            fontSize: 11,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(
            9,
          ),
          child: Container(
            height: 48,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            decoration:
                BoxDecoration(
              color:
                  cardBackground2,
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .calendar_today_outlined,
                  color: gold,
                  size: 17,
                ),

                const SizedBox(
                  width: 9,
                ),

                Text(
                  value == null
                      ? 'Select date'
                      : _formatDate(
                          value,
                        ),
                  style:
                      const TextStyle(
                    color: lightText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EXCEL UPLOAD
  // ============================================================

  Future<void>
      _uploadExcel() async {
    try {
      final result =
          await FilePicker.platform
              .pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'xlsx',
          'xls',
        ],
        withData: true,
      );

      if (result == null) {
        return;
      }

      final file =
          result.files.single;

      final Uint8List? bytes =
          file.bytes;

      if (bytes == null ||
          bytes.isEmpty) {
        _showMessage(
          'Unable to read selected Excel file.',
        );

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isUploadingExcel = true;
      });

      final response =
          await LeadsApi
              .uploadLeadsExcel(
        bytes: bytes,
        fileName: file.name,
      );

      if (!mounted) {
        return;
      }

      if (response['success'] ==
          true) {
        final imported =
            response['imported'] ??
                0;

        final skipped =
            response['skipped'] ??
                0;

        _showMessage(
          'Excel import completed. Imported: $imported, Skipped: $skipped.',
        );

        await _loadLeads(
          showLoader: false,
        );
      } else {
        _showMessage(
          response['message']
                  ?.toString() ??
              'Unable to import Excel file.',
        );
      }
    } catch (error) {
      debugPrint(
        'Excel upload error: $error',
      );

      if (mounted) {
        _showMessage(
          'Excel upload failed.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploadingExcel = false;
        });
      }
    }
  }

  // ============================================================
  // EXCEL DOWNLOAD
  // ============================================================

  Future<void>
      _downloadExcel() async {
    if (leads.isEmpty) {
      _showMessage(
        'There are no leads to download.',
      );

      return;
    }

    try {
      setState(() {
        isDownloadingExcel =
            true;
      });

      final rows =
          <List<String>>[
        [
          'Email',
          'First Name',
          'Last Name',
          'Company',
          'Type',
          'Tracking',
          'Added Date',
        ],
      ];

      for (final lead
          in leads) {
        rows.add(
          [
            lead['email']
                    ?.toString() ??
                '',
            lead['firstName']
                    ?.toString() ??
                '',
            lead['lastName']
                    ?.toString() ??
                '',
            lead['company']
                    ?.toString() ??
                '',
            lead['type']
                    ?.toString() ??
                '',
            lead['trackingStatus']
                    ?.toString() ??
                '',
            _formatDate(
              lead['addedDate']
                  as DateTime,
            ),
          ],
        );
      }

      final html =
          StringBuffer();

      html.write(
        '<html>'
        '<head>'
        '<meta charset="UTF-8">'
        '</head>'
        '<body>'
        '<table border="1">',
      );

      for (int i = 0;
          i < rows.length;
          i++) {
        html.write(
          '<tr>',
        );

        for (final value
            in rows[i]) {
          final escaped =
              _escapeHtml(value);

          if (i == 0) {
            html.write(
              '<th>$escaped</th>',
            );
          } else {
            html.write(
              '<td>$escaped</td>',
            );
          }
        }

        html.write(
          '</tr>',
        );
      }

      html.write(
        '</table>'
        '</body>'
        '</html>',
      );

      final bytes =
          Uint8List.fromList(
        utf8.encode(
          html.toString(),
        ),
      );

      final fileName =
          'HighCustomAI_Leads_${DateTime.now().millisecondsSinceEpoch}.xls';

      await FilePicker.platform
          .saveFile(
        fileName: fileName,
        bytes: bytes,
      );

      if (mounted) {
        _showMessage(
          'Excel file prepared successfully.',
        );
      }
    } catch (error) {
      debugPrint(
        'Excel download error: $error',
      );

      if (mounted) {
        _showMessage(
          'Unable to download Excel file.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDownloadingExcel =
              false;
        });
      }
    }
  }

  // ============================================================
  // DIALOG HEADER
  // ============================================================

  Widget _dialogHeader(
    BuildContext dialogContext,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        17,
      ),
      decoration:
          const BoxDecoration(
        color: Color(
          0xFF0C0D0F,
        ),
        borderRadius:
            BorderRadius.only(
          topLeft:
              Radius.circular(
            18,
          ),
          topRight:
              Radius.circular(
            18,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(
              color:
                  gold.withOpacity(
                0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              color: gold,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color: white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    color: mutedText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
              );
            },
            icon:
                const Icon(
              Icons.close,
              color: mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOG INPUT
  // ============================================================

  Widget _dialogInput({
    required TextEditingController
        controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color: lightText,
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        TextField(
          controller: controller,
          keyboardType:
              keyboardType,
          cursorColor: gold,
          style:
              const TextStyle(
            color: white,
            fontSize: 13,
          ),
          decoration:
              InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(
              color: Color(
                0xFF687083,
              ),
              fontSize: 12,
            ),
            prefixIcon: Icon(
              icon,
              color: mutedText,
              size: 18,
            ),
            filled: true,
            fillColor:
                cardBackground2,
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
              borderSide:
                  BorderSide.none,
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
              borderSide:
                  const BorderSide(
                color: borderColor,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
              borderSide:
                  const BorderSide(
                color: gold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TYPE DROPDOWN
  // ============================================================

  Widget _dialogDropdown({
    required String value,
    required ValueChanged<String?>
        onChanged,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Type',
          style: TextStyle(
            color: lightText,
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        Container(
          height: 48,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration:
              BoxDecoration(
            color: cardBackground2,
            borderRadius:
                BorderRadius.circular(
              9,
            ),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child:
              DropdownButtonHideUnderline(
            child:
                DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor:
                  cardBackground2,
              style:
                  const TextStyle(
                color: white,
                fontSize: 13,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Email',
                  child:
                      Text('Email'),
                ),

                DropdownMenuItem(
                  value:
                      'WhatsApp',
                  child:
                      Text('WhatsApp'),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _escapeHtml(
    String value,
  ) {
    return value
        .replaceAll(
          '&',
          '&amp;',
        )
        .replaceAll(
          '<',
          '&lt;',
        )
        .replaceAll(
          '>',
          '&gt;',
        )
        .replaceAll(
          '"',
          '&quot;',
        )
        .replaceAll(
          "'",
          '&#039;',
        );
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year}';
  }

  String _shortDate(
    DateTime date,
  ) {
    return '${date.day}/${date.month}';
  }

  String _formatShortCardDate(
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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    AppFeedback.show(context, message);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _trackingRefreshTimer
        ?.cancel();

    editEmailController
        .dispose();

    editFirstNameController
        .dispose();

    editLastNameController
        .dispose();

    editCompanyController
        .dispose();

    searchController.dispose();

    super.dispose();
  }
}
