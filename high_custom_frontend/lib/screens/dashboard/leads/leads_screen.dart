import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/leads_api.dart';
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

  static const Color pageBackground = Color(0xFF08111A);
  static const Color panelColor = Color(0xFF121A24);
  static const Color tableColor = Color(0xFF101822);
  

  static const Color gold = Color(0xFFF2C45F);
  static const Color goldDark = Color(0xFFD9A93F);

  static const Color white = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFFE8EAF0);
  static const Color mutedText = Color(0xFF9CA3AF);

  static const Color blue = Color(0xFF315BEF);
  static const Color borderColor = Color(0xFF3B4652);
  static const Color green = Color(0xFF32C46D);
  static const Color red = Color(0xFFFF5B5B);
  static const Color orange = Color(0xFFFFA41B);

  // ============================================================
  // EDIT CONTROLLERS
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

  bool todayOnly = true;
  bool trackingEnabled = true;

  bool _isRefreshingTracking = false;

  Timer? _trackingRefreshTimer;

  int currentPage = 1;
  int entriesPerPage = 10;

  DateTime? fromDate;
  DateTime? toDate;

  String selectedType = 'Email';

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
      const Duration(seconds: 5),
      (_) {
        _refreshTrackingStatus();
      },
    );
  }

  // ============================================================
  // REFRESH TRACKING STATUS
  //
  // DOES NOT:
  // - SHOW LOADER
  // - RESET CURRENT PAGE
  // - SHOW ERROR SNACKBAR
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
      final response =
          await LeadsApi.getLeads();

      if (!mounted) {
        return;
      }

      if (response['success'] != true) {
        return;
      }

      final serverLeads =
          response['leads'];

      if (serverLeads is! List) {
        return;
      }

      final List<Map<String, dynamic>>
          refreshed = [];

      for (final item in serverLeads) {
        if (item is Map) {
          refreshed.add(
            _normalizeLead(
              Map<String, dynamic>.from(
                item,
              ),
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
      });

      debugPrint(
        '✅ Lead tracking status automatically refreshed.',
      );
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
      final response =
          await LeadsApi.getLeads();

      if (!mounted) {
        return;
      }

      if (response['success'] == true) {
        final serverLeads =
            response['leads'];

        final List<Map<String, dynamic>>
            loaded = [];

        if (serverLeads is List) {
          for (final item in serverLeads) {
            if (item is Map) {
              loaded.add(
                _normalizeLead(
                  Map<String, dynamic>.from(
                    item,
                  ),
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
        });
      } else {
        _showMessage(
          response['message']
                  ?.toString() ??
              'Unable to load leads.',
        );
      }
    } catch (_) {
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
    final addedDate =
        _parseDate(
      lead['addedDate'] ??
          lead['createdAt'],
    );

    final updatedDate =
        _parseDate(
      lead['updatedDate'] ??
          lead['updatedAt'],
    );

    final tracking =
        lead['tracking'] == true;

    String trackingStatus =
        lead['trackingStatus']
                ?.toString()
                .trim() ??
            '';

    if (trackingStatus.isEmpty) {
      trackingStatus =
          tracking ? 'Pending' : 'Skip';
    }

    return {
      '_id':
          lead['_id'] ?? lead['id'] ?? '',
      'email':
          lead['email']?.toString() ?? '',
      'firstName':
          lead['firstName']?.toString() ??
              '',
      'lastName':
          lead['lastName']?.toString() ??
              '',
      'company':
          lead['company']?.toString() ??
              '',
      'type':
          lead['type']?.toString() ??
              'Email',
      'tracking': tracking,
      'trackingStatus':
          trackingStatus,
      'addedDate':
          addedDate ?? DateTime.now(),
      'updatedDate':
          updatedDate,
    };
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(
        value,
      );
    }

    return null;
  }

  // ============================================================
  // TODAY COUNT
  // ============================================================

  int get todayAddedCount {
    final now =
        DateTime.now();

    return leads.where(
      (lead) {
        final date =
            lead['addedDate']
                as DateTime;

        return date.year ==
                now.year &&
            date.month ==
                now.month &&
            date.day ==
                now.day;
      },
    ).length;
  }

  // ============================================================
  // FILTERED LEADS
  // ============================================================

  List<Map<String, dynamic>>
      get filteredLeads {
    List<Map<String, dynamic>>
        result =
        List<Map<String, dynamic>>.from(
      leads,
    );

    // SEARCH

    final query = searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where(
        (lead) {
          final firstName =
              lead['firstName']?.toString().toLowerCase() ?? '';
          final lastName =
              lead['lastName']?.toString().toLowerCase() ?? '';
          final email =
              lead['email']?.toString().toLowerCase() ?? '';
          final company =
              lead['company']?.toString().toLowerCase() ?? '';

          return '$firstName $lastName'.contains(query) ||
              email.contains(query) ||
              company.contains(query);
        },
      ).toList();
    }

    // TODAY

    if (todayOnly) {
      final now =
          DateTime.now();

      result =
          result.where(
        (lead) {
          final date =
              lead['addedDate']
                  as DateTime;

          return date.year ==
                  now.year &&
              date.month ==
                  now.month &&
              date.day ==
                  now.day;
        },
      ).toList();
    }

    // FROM

    if (fromDate != null) {
      final startDate =
          DateTime(
        fromDate!.year,
        fromDate!.month,
        fromDate!.day,
      );

      result =
          result.where(
        (lead) {
          final date =
              lead['addedDate']
                  as DateTime;

          return !date.isBefore(
            startDate,
          );
        },
      ).toList();
    }

    // TO

    if (toDate != null) {
      final endDate =
          DateTime(
        toDate!.year,
        toDate!.month,
        toDate!.day,
        23,
        59,
        59,
      );

      result =
          result.where(
        (lead) {
          final date =
              lead['addedDate']
                  as DateTime;

          return !date.isAfter(
            endDate,
          );
        },
      ).toList();
    }

    return result;
  }

  // ============================================================
  // PAGINATION DATA
  // ============================================================

  List<Map<String, dynamic>>
      get paginatedLeads {
    final data =
        filteredLeads;

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
        calculatedEnd >
                data.length
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.15, -0.75),
            radius: 1.35,
            colors: [
              Color(0xFF172330),
              Color(0xFF0B141D),
              Color(0xFF071019),
            ],
            stops: [0.0, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: gold,
            backgroundColor: panelColor,
            onRefresh: () async {
              await _loadLeads(
                showLoader: false,
              );
            },
            child: LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final bool isMobile =
                    constraints.maxWidth < 850;

                final double horizontalPadding =
                    isMobile ? 16 : 30;

                final double topPadding =
                    isMobile ? 18 : 30;

                const double bottomPadding = 24;

                final double headerHeight =
                    isMobile ? 76 : 82;

                final double headerGap =
                    isMobile ? 22 : 28;

                final double panelMinHeight =
                    (constraints.maxHeight -
                            topPadding -
                            bottomPadding -
                            headerHeight -
                            headerGap)
                        .clamp(
                          isMobile ? 520.0 : 560.0,
                          double.infinity,
                        );

                return SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      _buildPageHeader(
                        isMobile,
                      ),
                      SizedBox(
                        height: headerGap,
                      ),
                      _buildLeadsPanel(
                        isMobile,
                        panelMinHeight,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader(
    bool isMobile,
  ) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leads',
          style: TextStyle(
            color: white,
            fontSize: isMobile ? 27 : 31,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.0,
          ),
        ),
        SizedBox(
          height: isMobile ? 8 : 6,
        ),
        Text(
          'Manage and track all your leads',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: mutedText,
            fontSize: isMobile ? 12.5 : 14,
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        ),
      ],
    );

    final addLeadButton = SizedBox(
      height: isMobile ? 48 : 58,
      width: isMobile ? 142 : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD978),
              Color(0xFFF1B735),
            ],
          ),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: const Color(0xFFFFE29A),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: gold.withOpacity(0.16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _openAddLeadScreen,
          icon: Icon(
            Icons.add,
            size: isMobile ? 23 : 28,
          ),
          label: Text(
            'Add Lead',
            maxLines: 1,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF17120A),
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 13 : 22,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: titleBlock,
        ),
        SizedBox(
          width: isMobile ? 10 : 14,
        ),
        addLeadButton,
      ],
    );
  }

  Widget _headerTitle() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 38,
          decoration:
              BoxDecoration(
            color: gold,
            borderRadius:
                BorderRadius.circular(
              4,
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        const Icon(
          Icons
              .people_alt_outlined,
          color: gold,
          size: 21,
        ),

        const SizedBox(
          width: 9,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                'Leads',
                style:
                    TextStyle(
                  color: white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight
                          .w700,
                ),
              ),
              SizedBox(
                height: 3,
              ),
              Text(
                'Manage and organize your leads',
                style:
                    TextStyle(
                  color:
                      mutedText,
                  fontSize: 11,
                ),
              ),
            ],
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
        builder:
            (context) =>
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
  // LEADS PANEL
  // ============================================================

  Widget _buildLeadsPanel(
    bool isMobile,
    double panelMinHeight,
  ) {
    final double tableMinHeight =
        (panelMinHeight - (isMobile ? 176 : 194)).clamp(
      isMobile ? 360.0 : 400.0,
      double.infinity,
    );

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: panelMinHeight,
      ),
      decoration: BoxDecoration(
        color: panelColor.withOpacity(0.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 10 : 16,
              isMobile ? 10 : 15,
              isMobile ? 8 : 16,
              isMobile ? 9 : 14,
            ),
            child: _buildExcelToolbar(
              isMobile,
            ),
          ),
          Container(
            height: 1,
            color: borderColor.withOpacity(0.75),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 16,
              isMobile ? 12 : 16,
              isMobile ? 12 : 16,
              isMobile ? 12 : 16,
            ),
            child: _buildSearchAndFilters(
              isMobile,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              0,
              6,
              0,
              0,
            ),
            child: _buildTable(
              isMobile,
              tableMinHeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
    bool isMobile,
  ) {
    final searchField = Container(
      height: isMobile ? 46 : 50,
      decoration: BoxDecoration(
        color: const Color(0xFF0A121B),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            currentPage = 1;
          });
        },
        style: TextStyle(
          color: lightText,
          fontSize: isMobile ? 11.5 : 13,
        ),
        cursorColor: gold,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: mutedText,
            size: isMobile ? 21 : 25,
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: isMobile ? 42 : 48,
          ),
          hintText: isMobile
              ? 'Search leads...'
              : 'Search by name, email or company...',
          hintStyle: TextStyle(
            color: mutedText,
            fontSize: isMobile ? 11 : 13,
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: isMobile ? 13 : 15,
          ),
        ),
      ),
    );

    final dateButton = SizedBox(
      height: isMobile ? 46 : 50,
      child: OutlinedButton.icon(
        onPressed: _showDateFilter,
        icon: Icon(
          Icons.calendar_month_outlined,
          size: isMobile ? 18 : 20,
        ),
        label: Text(
          'Date Filter',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: lightText,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12,
          ),
          side: const BorderSide(
            color: borderColor,
          ),
          backgroundColor: const Color(0xFF0A121B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          textStyle: TextStyle(
            fontSize: isMobile ? 11 : 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: searchField,
        ),
      ],
    );
  }

  // ============================================================
  // EXCEL TOOLBAR
  // ============================================================

  Widget _buildExcelToolbar(
    bool isMobile,
  ) {
    final download = _toolbarButton(
      icon: Icons.file_download_outlined,
      label: isDownloadingExcel
          ? 'Downloading...'
          : (isMobile ? 'Download' : 'Download Excel'),
      onPressed: isDownloadingExcel
          ? null
          : _downloadExcel,
      compact: isMobile,
    );

    final upload = _toolbarButton(
      icon: Icons.file_upload_outlined,
      label: isUploadingExcel
          ? 'Uploading...'
          : (isMobile ? 'Upload' : 'Upload Excel'),
      onPressed: isUploadingExcel
          ? null
          : _uploadExcel,
      compact: isMobile,
    );

    return Row(
      children: [
        Expanded(
          flex: 10,
          child: download,
        ),
        _toolbarDivider(
          compact: isMobile,
        ),
        Expanded(
          flex: 10,
          child: upload,
        ),
        _toolbarDivider(
          compact: isMobile,
        ),
        Expanded(
          flex: isMobile ? 9 : 10,
          child: _dateFilterButton(
            compact: isMobile,
          ),
        ),
      ],
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool compact = false,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: gold,
        size: compact ? 19 : 22,
      ),
      label: Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: lightText,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 2 : 12,
          vertical: compact ? 12 : 15,
        ),
        textStyle: TextStyle(
          fontSize: compact ? 10.5 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _toolbarDivider({
    bool compact = false,
  }) {
    return Container(
      width: 1,
      height: compact ? 38 : 46,
      margin: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 8,
      ),
      color: borderColor,
    );
  }

  // ============================================================
  // TODAY FILTER
  // ============================================================

  Widget _todayFilterButton() {
    return _dateFilterButton();
  }

  // ============================================================
  // DATE FILTER BUTTON
  // ============================================================

  Widget _dateFilterButton({
    bool compact = false,
  }) {
    String label = todayOnly ? 'Today' : 'All Dates';

    if (fromDate != null && toDate != null) {
      label = '${_shortDate(fromDate!)} - ${_shortDate(toDate!)}';
    } else if (fromDate != null) {
      label = 'From ${_shortDate(fromDate!)}';
    } else if (toDate != null) {
      label = 'Until ${_shortDate(toDate!)}';
    }

    return PopupMenuButton<String>(
      color: const Color(0xFF0A121B),
      tooltip: 'Date Filter',
      onSelected: (value) {
        if (value == 'today') {
          setState(() {
            todayOnly = true;
            fromDate = null;
            toDate = null;
            currentPage = 1;
          });
        } else if (value == 'all') {
          setState(() {
            todayOnly = false;
            fromDate = null;
            toDate = null;
            currentPage = 1;
          });
        } else if (value == 'custom') {
          _showDateFilter();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'today',
          child: Text(
            'Today',
            style: TextStyle(
              color: lightText,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'all',
          child: Text(
            'All Dates',
            style: TextStyle(
              color: lightText,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'custom',
          child: Text(
            'Custom Range',
            style: TextStyle(
              color: lightText,
            ),
          ),
        ),
      ],
      child: Container(
        height: compact ? 42 : 48,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF09111A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: compact ? 17 : 19,
              color: gold,
            ),
            SizedBox(
              width: compact ? 4 : 8,
            ),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: gold,
                  fontSize: compact ? 10.5 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: compact ? 2 : 6,
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: compact ? 17 : 19,
              color: gold,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildTable(
    bool isMobile,
    double tableMinHeight,
  ) {
    if (isLoading) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: tableMinHeight,
        ),
        child: _buildLoadingState(),
      );
    }

    final data = paginatedLeads;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: tableMinHeight,
      ),
      decoration: BoxDecoration(
        color: tableColor.withOpacity(0.93),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(
          color: borderColor,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (data.isEmpty)
            SizedBox(
              height: tableMinHeight,
              child: Center(
                child: _buildEmptyTable(),
              ),
            )
          else
            _buildDataTable(
              data,
              isMobile,
            ),
          if (filteredLeads.isNotEmpty)
            _buildPagination(
              isMobile,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // DATA TABLE
  //
  // EMAIL
  // TRACKING
  // VIEW
  // ============================================================

  Widget _buildDataTable(
    List<Map<String, dynamic>> data,
    bool isMobile,
  ) {
    final table = DataTable(
      headingRowHeight: 60,
      dataRowMinHeight: 72,
      dataRowMaxHeight: 82,
      horizontalMargin: 16,
      columnSpacing: isMobile ? 18 : 28,
      dividerThickness: 0.35,
      headingRowColor: WidgetStateProperty.all(
        const Color(0xFF121B25),
      ),
      dataRowColor: WidgetStateProperty.all(tableColor),
      headingTextStyle: const TextStyle(
        color: gold,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      dataTextStyle: const TextStyle(
        color: lightText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      columns: const [
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Tracking')),
        DataColumn(label: Text('Added Date')),
        DataColumn(label: Text('Actions')),
      ],
      rows: data.map((lead) {
        final email = lead['email']?.toString().trim() ?? '';
        final addedDate = lead['addedDate'] as DateTime;

        return DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: isMobile ? 170 : 230,
                child: Text(
                  email.isEmpty ? '-' : email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: lightText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            DataCell(_trackingBadge(lead)),
            DataCell(
              SizedBox(
                width: 125,
                child: Text(
                  _formatDate(addedDate),
                  maxLines: 2,
                  style: const TextStyle(
                    color: lightText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: 'View Details',
                    onPressed: () => _showViewLeadDialog(lead),
                    icon: const Icon(Icons.visibility_outlined, color: gold, size: 21),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF0B131C),
                    icon: const Icon(Icons.more_vert, color: gold, size: 21),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditLeadDialog(lead);
                      } else if (value == 'delete') {
                        _deleteLead(lead);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, color: gold, size: 18),
                          SizedBox(width: 10),
                          Text('Edit', style: TextStyle(color: lightText, fontSize: 14)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline, color: red, size: 18),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: red, fontSize: 14)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: table,
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
            ? (lead['tracking'] == true
                ? 'Pending'
                : 'Skip')
            : rawStatus;

    final normalized =
        status.toLowerCase();

    Color color;

    if (normalized == 'sent') {
      color =
          const Color(
        0xFF58AFFF,
      );
    } else if (normalized == 'opened' ||
        normalized == 'open' ||
        normalized == 'seen') {
      color = green;
    } else if (normalized == 'failed' ||
        normalized == 'fail') {
      color = red;
    } else if (normalized ==
        'pending') {
      color = orange;
    } else if (normalized == 'clicked' ||
        normalized == 'click') {
      color =
          const Color(
        0xFFB78BFF,
      );
    } else {
      color =
          const Color(
        0xFF9AA3AD,
      );
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            color.withOpacity(
          0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              color.withOpacity(
            0.42,
          ),
        ),
      ),
      child: Text(
        _capitalizeStatus(
          status,
        ),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
              FontWeight.w700,
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

    return value[0]
            .toUpperCase() +
        value
            .substring(1)
            .toLowerCase();
  }

  // ============================================================
  // VIEW DETAILS CARD
  // ============================================================

  void _showViewLeadDialog(
    Map<String, dynamic>
        lead,
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
        '$firstName $lastName'
            .trim();

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
        lead['type']
                ?.toString() ??
            'Email';

    final addedDate =
        lead['addedDate']
            as DateTime;

    showDialog(
      context: context,
      builder:
          (dialogContext) {
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
              maxWidth: 620,
            ),
            child:
                Container(
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFF10141F,
                ),
                borderRadius:
                    BorderRadius
                        .circular(
                  22,
                ),
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFF2A3040,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black
                            .withOpacity(
                      0.30,
                    ),
                    blurRadius:
                        28,
                    offset:
                        const Offset(
                      0,
                      12,
                    ),
                  ),
                ],
              ),
              child:
                  Column(
                mainAxisSize:
                    MainAxisSize
                        .min,
                children: [
                  // ==================================================
                  // CARD HEADER
                  // ==================================================

                  Container(
                    padding:
                        const EdgeInsets
                            .all(
                      18,
                    ),
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(
                        0xFF080B13,
                      ),
                      borderRadius:
                          BorderRadius
                              .only(
                        topLeft:
                            Radius
                                .circular(
                          22,
                        ),
                        topRight:
                            Radius
                                .circular(
                          22,
                        ),
                      ),
                    ),
                    child:
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
                              0.12,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            border:
                                Border.all(
                              color:
                                  gold.withOpacity(
                                0.28,
                              ),
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .person_outline,
                            color:
                                gold,
                            size:
                                24,
                          ),
                        ),

                        const SizedBox(
                          width:
                              13,
                        ),

                        Expanded(
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                fullName
                                        .isEmpty
                                    ? 'Lead Details'
                                    : fullName,
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
                                      18,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),

                              const SizedBox(
                                height:
                                    4,
                              ),

                              Text(
                                email
                                        .isEmpty
                                    ? 'Lead information'
                                    : email,
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
                            Icons
                                .close,
                            color:
                                mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // DETAILS
                  // ==================================================

                  Flexible(
                    child:
                        SingleChildScrollView(
                      padding:
                          const EdgeInsets
                              .all(
                        20,
                      ),
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          // TRACKING CARD

                          Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets
                                    .all(
                              15,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFF161A27,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              border:
                                  Border.all(
                                color:
                                    const Color(
                                  0xFF292E3D,
                                ),
                              ),
                            ),
                            child:
                                Row(
                              children: [
                                Container(
                                  width:
                                      40,
                                  height:
                                      40,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        gold.withOpacity(
                                      0.10,
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
                                        .analytics_outlined,
                                    color:
                                        gold,
                                    size:
                                        19,
                                  ),
                                ),

                                const SizedBox(
                                  width:
                                      12,
                                ),

                                const Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        'EMAIL ACTIVITY',
                                        style:
                                            TextStyle(
                                          color:
                                              mutedText,
                                          fontSize:
                                              9,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                          letterSpacing:
                                              0.7,
                                        ),
                                      ),
                                      SizedBox(
                                        height:
                                            4,
                                      ),
                                      Text(
                                        'Tracking Status',
                                        style:
                                            TextStyle(
                                          color:
                                              lightText,
                                          fontSize:
                                              13,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                _trackingBadge(
                                  lead,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height:
                                20,
                          ),

                          const Text(
                            'CONTACT INFORMATION',
                            style:
                                TextStyle(
                              color:
                                  gold,
                              fontSize:
                                  10,
                              fontWeight:
                                  FontWeight
                                      .w800,
                              letterSpacing:
                                  0.8,
                            ),
                          ),

                          const SizedBox(
                            height:
                                10,
                          ),

                          _viewInfoRow(
                            'Email',
                            email
                                    .isEmpty
                                ? '-'
                                : email,
                            Icons
                                .email_outlined,
                          ),

                          const SizedBox(
                            height:
                                10,
                          ),

                          _viewInfoRow(
                            'Full Name',
                            fullName
                                    .isEmpty
                                ? '-'
                                : fullName,
                            Icons
                                .person_outline,
                          ),

                          const SizedBox(
                            height:
                                10,
                          ),

                          _viewInfoRow(
                            'Company',
                            company
                                    .isEmpty
                                ? '-'
                                : company,
                            Icons
                                .business_outlined,
                          ),

                          const SizedBox(
                            height:
                                10,
                          ),

                          if (isMobile) ...[
                            _viewInfoRow(
                              'Type',
                              type,
                              Icons
                                  .category_outlined,
                            ),

                            const SizedBox(
                              height:
                                  10,
                            ),

                            _viewInfoRow(
                              'Added Date',
                              _formatDate(
                                addedDate,
                              ),
                              Icons
                                  .calendar_today_outlined,
                            ),
                          ] else
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Expanded(
                                  child:
                                      _viewInfoRow(
                                    'Type',
                                    type,
                                    Icons
                                        .category_outlined,
                                  ),
                                ),

                                const SizedBox(
                                  width:
                                      10,
                                ),

                                Expanded(
                                  child:
                                      _viewInfoRow(
                                    'Added Date',
                                    _formatDate(
                                      addedDate,
                                    ),
                                    Icons
                                        .calendar_today_outlined,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ==================================================
                  // EDIT / DELETE
                  // ==================================================

                  Container(
                    padding:
                        const EdgeInsets
                            .all(
                      16,
                    ),
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(
                        0xFF0B0F18,
                      ),
                      borderRadius:
                          BorderRadius
                              .only(
                        bottomLeft:
                            Radius
                                .circular(
                          22,
                        ),
                        bottomRight:
                            Radius
                                .circular(
                          22,
                        ),
                      ),
                    ),
                    child:
                        isMobile
                            ? Column(
                                children: [
                                  SizedBox(
                                    width:
                                        double.infinity,
                                    height:
                                        44,
                                    child:
                                        ElevatedButton
                                            .icon(
                                      onPressed:
                                          () {
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
                                        Icons.edit_outlined,
                                        size:
                                            17,
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
                                          0xFF30270F,
                                        ),
                                        elevation:
                                            0,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height:
                                        10,
                                  ),

                                  SizedBox(
                                    width:
                                        double.infinity,
                                    height:
                                        44,
                                    child:
                                        OutlinedButton
                                            .icon(
                                      onPressed:
                                          () {
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
                                        Icons.delete_outline,
                                        size:
                                            17,
                                      ),
                                      label:
                                          const Text(
                                        'Delete Lead',
                                      ),
                                      style:
                                          OutlinedButton
                                              .styleFrom(
                                        foregroundColor:
                                            const Color(
                                          0xFFFF7676,
                                        ),
                                        side:
                                            const BorderSide(
                                          color:
                                              Color(
                                            0xFF8A3D46,
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
                                        SizedBox(
                                      height:
                                          44,
                                      child:
                                          OutlinedButton
                                              .icon(
                                        onPressed:
                                            () {
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
                                          Icons.delete_outline,
                                          size:
                                              17,
                                        ),
                                        label:
                                            const Text(
                                          'Delete',
                                        ),
                                        style:
                                            OutlinedButton
                                                .styleFrom(
                                          foregroundColor:
                                              const Color(
                                            0xFFFF7676,
                                          ),
                                          side:
                                              const BorderSide(
                                            color:
                                                Color(
                                              0xFF8A3D46,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    width:
                                        10,
                                  ),

                                  Expanded(
                                    flex:
                                        2,
                                    child:
                                        SizedBox(
                                      height:
                                          44,
                                      child:
                                          ElevatedButton
                                              .icon(
                                        onPressed:
                                            () {
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
                                          Icons.edit_outlined,
                                          size:
                                              17,
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
                                            0xFF30270F,
                                          ),
                                          elevation:
                                              0,
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

  // ============================================================
  // VIEW INFO ROW
  // ============================================================

  Widget _viewInfoRow(
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment
              .start,
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
            color:
                const Color(
              0xFF161A27,
            ),
            borderRadius:
                BorderRadius
                    .circular(
              10,
            ),
            border:
                Border.all(
              color:
                  const Color(
                0xFF292E3D,
              ),
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
                    color:
                        lightText,
                    fontSize:
                        12,
                    fontWeight:
                        FontWeight
                            .w500,
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
  // EDIT DIALOG
  // ============================================================

  void _showEditLeadDialog(
    Map<String, dynamic>
        lead,
  ) {
    editEmailController.text =
        lead['email']
                ?.toString() ??
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
        lead['type']
                ?.toString() ??
            'Email';

    trackingEnabled =
        lead['tracking'] ==
            true;

    showDialog(
      context: context,
      barrierDismissible:
          false,
      builder:
          (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return Dialog(
              backgroundColor:
                  Colors
                      .transparent,
              insetPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal:
                    18,
                vertical:
                    20,
              ),
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth:
                      600,
                ),
                child:
                    Container(
                  decoration:
                      BoxDecoration(
                    color:
                        tableColor,
                    borderRadius:
                        BorderRadius
                            .circular(
                      18,
                    ),
                  ),
                  child:
                      Column(
                    mainAxisSize:
                        MainAxisSize
                            .min,
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
                              const EdgeInsets
                                  .all(
                            22,
                          ),
                          child:
                              Column(
                            children: [
                              _dialogInput(
                                controller:
                                    editEmailController,
                                label:
                                    'Email Address',
                                hint:
                                    'john@example.com',
                                icon:
                                    Icons.email_outlined,
                                keyboardType:
                                    TextInputType.emailAddress,
                              ),

                              const SizedBox(
                                height:
                                    14,
                              ),

                              Row(
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
                                      icon:
                                          Icons.person_outline,
                                    ),
                                  ),

                                  const SizedBox(
                                    width:
                                        12,
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
                                      icon:
                                          Icons.person_outline,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height:
                                    14,
                              ),

                              _dialogInput(
                                controller:
                                    editCompanyController,
                                label:
                                    'Company',
                                hint:
                                    'Company name',
                                icon:
                                    Icons.business_outlined,
                              ),

                              const SizedBox(
                                height:
                                    14,
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
                                height:
                                    14,
                              ),

                              Container(
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFF161A27,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    10,
                                  ),
                                  border:
                                      Border.all(
                                    color:
                                        const Color(
                                      0xFF2A2F40,
                                    ),
                                  ),
                                ),
                                child:
                                    SwitchListTile(
                                  title:
                                      const Text(
                                    'Enable Tracking',
                                    style:
                                        TextStyle(
                                      color:
                                          white,
                                      fontWeight:
                                          FontWeight.w600,
                                      fontSize:
                                          13,
                                    ),
                                  ),
                                  subtitle:
                                      const Text(
                                    'Track email activity',
                                    style:
                                        TextStyle(
                                      color:
                                          mutedText,
                                      fontSize:
                                          11,
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
                            const EdgeInsets
                                .all(
                          16,
                        ),
                        decoration:
                            const BoxDecoration(
                          color:
                              Color(
                            0xFF141824,
                          ),
                          borderRadius:
                              BorderRadius
                                  .only(
                            bottomLeft:
                                Radius.circular(
                              18,
                            ),
                            bottomRight:
                                Radius.circular(
                              18,
                            ),
                          ),
                        ),
                        child:
                            Row(
                          mainAxisAlignment:
                              MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed:
                                  isUpdatingLead
                                      ? null
                                      : () {
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
                                      mutedText,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width:
                                  8,
                            ),

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
                              icon:
                                  isUpdatingLead
                                      ? const SizedBox(
                                          width:
                                              15,
                                          height:
                                              15,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                            color:
                                                Color(
                                              0xFF30270F,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_outlined,
                                          size:
                                              17,
                                        ),
                              label:
                                  Text(
                                isUpdatingLead
                                    ? 'Saving...'
                                    : 'Save Changes',
                              ),
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    gold,
                                foregroundColor:
                                    const Color(
                                  0xFF30270F,
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
    Map<String, dynamic>
        lead,
  ) async {
    final leadId =
        lead['_id']
                ?.toString() ??
            '';

    if (leadId.isEmpty) {
      _showMessage(
        'Lead ID not found.',
      );

      return;
    }

    final email =
        editEmailController
            .text
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
        editCompanyController
            .text
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
        .hasMatch(
      email,
    )) {
      _showMessage(
        'Please enter a valid email address.',
      );

      return;
    }

    setState(() {
      isUpdatingLead =
          true;
    });

    try {
      final response =
          await LeadsApi
              .updateLead(
        leadId: leadId,
        email: email,
        firstName:
            firstName,
        lastName:
            lastName,
        company: company,
        type:
            selectedType,
        tracking:
            trackingEnabled,
      );

      if (!mounted) {
        return;
      }

      if (response['success'] ==
          true) {
        Navigator.pop(
          dialogContext,
        );

        _showMessage(
          response['message']
                  ?.toString() ??
              'Lead updated successfully.',
        );

        await _loadLeads(
          showLoader:
              false,
          resetPage:
              false,
        );
      } else {
        _showMessage(
          response['message']
                  ?.toString() ??
              'Unable to update lead.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to update lead.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingLead =
              false;
        });
      }
    }
  }

  // ============================================================
  // DELETE LEAD
  // ============================================================

  void _deleteLead(
    Map<String, dynamic>
        lead,
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
        lead['email']
                ?.toString() ??
            '';

    final fullName =
        '$firstName $lastName'
            .trim();

    showDialog(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(
            0xFF141824,
          ),
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
            style:
                TextStyle(
              color: white,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content:
              Text(
            'Are you sure you want to delete '
            '${fullName.isEmpty ? email : fullName}?',
            style:
                const TextStyle(
              color:
                  mutedText,
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
                      mutedText,
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
                Icons
                    .delete_outline,
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
    Map<String, dynamic>
        lead,
  ) async {
    final leadId =
        lead['_id']
                ?.toString() ??
            '';

    if (leadId.isEmpty) {
      _showMessage(
        'Lead ID not found.',
      );

      return;
    }

    setState(() {
      isDeletingLead =
          true;
    });

    try {
      final response =
          await LeadsApi
              .deleteLead(
        leadId:
            leadId,
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
          showLoader:
              false,
          resetPage:
              false,
        );
      } else {
        _showMessage(
          response['message']
                  ?.toString() ??
              'Unable to delete lead.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to delete lead.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDeletingLead =
              false;
        });
      }
    }
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination(
    bool isMobile,
  ) {
    final pages = totalPages;

    if (filteredLeads.isEmpty) {
      return const SizedBox.shrink();
    }

    final start =
        (currentPage - 1) * entriesPerPage + 1;

    final end = mathMin(
      currentPage * entriesPerPage,
      filteredLeads.length,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 16,
        vertical: isMobile ? 11 : 14,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: borderColor,
          ),
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Showing $start to $end of ${filteredLeads.length} leads',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mutedText,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _entriesDropdown(
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _paginationControls(
                  pages,
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  'Showing $start to $end of ${filteredLeads.length} leads',
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                _paginationControls(
                  pages,
                ),
                const SizedBox(width: 24),
                _entriesDropdown(),
              ],
            ),
    );
  }

  int mathMin(
    int a,
    int b,
  ) {
    return a < b ? a : b;
  }

  Widget _paginationControls(
    int pages,
  ) {
    return Row(
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
              horizontal: 10,
            ),
            child: Text(
              '...',
              style:
                  TextStyle(
                color:
                    mutedText,
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
        7,
      ),
      child: Container(
        width: 38,
        height: 38,
        alignment:
            Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? gold.withOpacity(
                  0.08,
                )
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(
            7,
          ),
          border: Border.all(
            color: selected
                ? gold
                : borderColor,
          ),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: selected
                ? gold
                : lightText,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _pageArrow({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 38,
      height: 38,
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
            0.35,
          ),
          side: const BorderSide(
            color: borderColor,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              7,
            ),
          ),
        ),
        child: Icon(
          icon,
          size: 19,
        ),
      ),
    );
  }

  Widget _entriesDropdown({
    bool compact = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          const Text(
            'Entries per page',
            style: TextStyle(
              color: mutedText,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          height: compact ? 32 : 38,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: entriesPerPage,
              dropdownColor: tableColor,
              iconEnabledColor: lightText,
              iconSize: compact ? 17 : 24,
              style: TextStyle(
                color: lightText,
                fontSize: compact ? 10 : 14,
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
        ),
      ],
    );
  }

  // ============================================================
  // DATE FILTER DIALOG
  // ============================================================

  Future<void>
      _showDateFilter() async {
    DateTime? tempFrom =
        fromDate;

    DateTime? tempTo =
        toDate;

    await showDialog(
      context: context,
      builder:
          (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return Dialog(
              backgroundColor:
                  Colors.transparent,
              child:
                  Container(
                constraints:
                    const BoxConstraints(
                  maxWidth:
                      500,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      tableColor,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child:
                    Column(
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
                          const EdgeInsets
                              .all(
                        20,
                      ),
                      child:
                          Column(
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
                            height:
                                12,
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
                          const EdgeInsets
                              .all(
                        16,
                      ),
                      child:
                          Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed:
                                () {
                              setDialogState(
                                () {
                                  tempFrom =
                                      null;

                                  tempTo =
                                      null;
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

                          const SizedBox(
                            width:
                                8,
                          ),

                          ElevatedButton(
                            onPressed:
                                () {
                              setState(
                                () {
                                  fromDate =
                                      tempFrom;

                                  toDate =
                                      tempTo;

                                  todayOnly =
                                      false;

                                  currentPage =
                                      1;
                                },
                              );

                              Navigator.pop(
                                dialogContext,
                              );
                            },
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  gold,
                              foregroundColor:
                                  const Color(
                                0xFF30270F,
                              ),
                            ),
                            child:
                                const Text(
                              'Apply',
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

  Future<DateTime?>
      _pickDate(
    DateTime? value,
  ) {
    return showDatePicker(
      context: context,
      firstDate:
          DateTime(
        2020,
      ),
      lastDate:
          DateTime(
        2035,
      ),
      initialDate:
          value ??
              DateTime.now(),
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
                const ColorScheme
                    .dark(
              primary:
                  gold,
              surface:
                  Color(
                0xFF141824,
              ),
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
          CrossAxisAlignment
              .start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color:
                mutedText,
            fontSize:
                11,
            fontWeight:
                FontWeight
                    .w600,
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
          child:
              Container(
            height: 46,
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal:
                  11,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFF161A27,
              ),
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
              border:
                  Border.all(
                color:
                    const Color(
                  0xFF292E3D,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .calendar_today_outlined,
                  size: 16,
                  color: gold,
                ),

                const SizedBox(
                  width: 8,
                ),

                Text(
                  value ==
                          null
                      ? 'Select date'
                      : _formatDate(
                          value,
                        ),
                  style:
                      const TextStyle(
                    color:
                        lightText,
                    fontSize:
                        12,
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
          await FilePicker
              .platform
              .pickFiles(
        type:
            FileType.custom,
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
        isUploadingExcel =
            true;
      });

      final response =
          await LeadsApi
              .uploadLeadsExcel(
        bytes: bytes,
        fileName:
            file.name,
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
          showLoader:
              false,
        );
      } else {
        _showMessage(
          response['message']
                  ?.toString() ??
              'Unable to import Excel file.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Excel upload failed.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploadingExcel =
              false;
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
              _escapeHtml(
            value,
          );

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

      await FilePicker
          .platform
          .saveFile(
        fileName:
            fileName,
        bytes: bytes,
      );

      if (mounted) {
        _showMessage(
          'Excel file prepared successfully.',
        );
      }
    } catch (_) {
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
        18,
      ),
      decoration:
          const BoxDecoration(
        color:
            Color(
          0xFF080B13,
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
                0.12,
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
                    color:
                        white,
                    fontSize:
                        17,
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
                    color:
                        mutedText,
                    fontSize:
                        11,
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
              color: white,
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
          CrossAxisAlignment
              .start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color:
                lightText,
            fontSize:
                12,
            fontWeight:
                FontWeight
                    .w600,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        TextField(
          controller:
              controller,
          keyboardType:
              keyboardType,
          style:
              const TextStyle(
            color: white,
            fontSize: 13,
          ),
          decoration:
              InputDecoration(
            hintText:
                hint,
            hintStyle:
                const TextStyle(
              color:
                  Color(
                0xFF687083,
              ),
              fontSize:
                  12,
            ),
            prefixIcon:
                Icon(
              icon,
              color:
                  mutedText,
              size: 18,
            ),
            filled:
                true,
            fillColor:
                const Color(
              0xFF161A27,
            ),
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
                color:
                    Color(
                  0xFF292E3D,
                ),
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
                color:
                    gold,
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
          CrossAxisAlignment
              .start,
      children: [
        const Text(
          'Type',
          style:
              TextStyle(
            color:
                lightText,
            fontSize:
                12,
            fontWeight:
                FontWeight
                    .w600,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        Container(
          height: 48,
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                12,
          ),
          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFF161A27,
            ),
            borderRadius:
                BorderRadius.circular(
              9,
            ),
            border:
                Border.all(
              color:
                  const Color(
                0xFF292E3D,
              ),
            ),
          ),
          child:
              DropdownButtonHideUnderline(
            child:
                DropdownButton<String>(
              value:
                  value,
              isExpanded:
                  true,
              dropdownColor:
                  const Color(
                0xFF161A27,
              ),
              style:
                  const TextStyle(
                color:
                    white,
                fontSize:
                    13,
              ),
              items:
                  const [
                DropdownMenuItem(
                  value:
                      'Email',
                  child:
                      Text(
                    'Email',
                  ),
                ),
                DropdownMenuItem(
                  value:
                      'WhatsApp',
                  child:
                      Text(
                    'WhatsApp',
                  ),
                ),
              ],
              onChanged:
                  onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyTable() {
    final message =
        todayOnly
            ? 'No leads found for today'
            : 'No leads found for this period';

    return SizedBox(
      width:
          double.infinity,
      height: 150,
      child: Center(
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .people_outline,
              color: gold,
              size: 19,
            ),

            const SizedBox(
              width: 8,
            ),

            Text(
              message,
              style:
                  const TextStyle(
                color:
                    lightText,
                fontSize:
                    13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      width:
          double.infinity,
      height: 180,
      color: tableColor,
      child:
          const Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child:
                  CircularProgressIndicator(
                strokeWidth:
                    2.5,
                color:
                    gold,
              ),
            ),

            SizedBox(
              height: 12,
            ),

            Text(
              'Loading leads...',
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
    );
  }

  // ============================================================
  // GOLD BUTTON
  // ============================================================

  Widget _goldButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 44,
      child:
          ElevatedButton.icon(
        onPressed:
            onPressed,
        icon:
            Icon(
          icon,
          size: 17,
        ),
        label:
            Text(
          label,
          style:
              const TextStyle(
            fontSize:
                12,
            fontWeight:
                FontWeight
                    .w800,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              gold,
          foregroundColor:
              const Color(
            0xFF30270F,
          ),
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
  // DARK ACTION BUTTON
  // ============================================================

  Widget _darkActionButton({
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    bool outlined = false,
  }) {
    return SizedBox(
      height: 40,
      child: Container(
        decoration:
            BoxDecoration(
          color:
              outlined
                  ? Colors.transparent
                  : const Color(
                      0xFF41444C,
                    ),
          borderRadius:
              BorderRadius.circular(
            10,
          ),
          border:
              outlined
                  ? Border.all(
                      color:
                          const Color(
                        0xFF858890,
                      ),
                    )
                  : null,
        ),
        child:
            TextButton(
          onPressed:
              onPressed,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            children: [
              Icon(
                icon,
                color:
                    gold,
                size:
                    16,
              ),

              const SizedBox(
                width:
                    6,
              ),

              Flexible(
                child:
                    Text(
                  text,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        gold,
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          message,
        ),
        behavior:
            SnackBarBehavior
                .floating,
        backgroundColor:
            const Color(
          0xFF20242E,
        ),
      ),
    );
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