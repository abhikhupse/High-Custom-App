import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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

  static const Color pageBackground = Color(0xFFF4F6FA);
  static const Color panelColor = Color(0xFF5B5E66);
  static const Color tableColor = Color(0xFF0D101B);
  static const Color inputColor = Color(0xFF0D101B);

  static const Color gold = Color(0xFFF2C45F);
  static const Color goldDark = Color(0xFFD9A93F);

  static const Color white = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFFE8EAF0);
  static const Color mutedText = Color(0xFF9CA3AF);
  static const Color border = Color(0xFF777A82);

  static const Color blue = Color(0xFF315BEF);

  // ============================================================
  // API
  // ============================================================

  static const String baseUrl =
      'http://192.168.1.18:3000/api';

  static const FlutterSecureStorage storage =
      FlutterSecureStorage();

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

  int currentPage = 1;
  int entriesPerPage = 10;

  DateTime? fromDate;
  DateTime? toDate;

  String selectedType = 'Email';

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
  }

  // ============================================================
  // LOAD LEADS
  // ============================================================

  Future<void> _loadLeads({
    bool showLoader = true,
  }) async {
    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response = await LeadsApi.getLeads();

      if (!mounted) return;

      if (response['success'] == true) {
        final serverLeads = response['leads'];

        if (serverLeads is List) {
          setState(() {
            leads.clear();

            for (final item in serverLeads) {
              if (item is Map) {
                leads.add(
                  _normalizeLead(
                    Map<String, dynamic>.from(item),
                  ),
                );
              }
            }

            currentPage = 1;
          });
        } else {
          setState(() {
            leads.clear();
            currentPage = 1;
          });
        }
      } else {
        _showMessage(
          response['message']?.toString() ??
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
      trackingStatus = tracking ? 'Sent' : 'Skip';
    }

    return {
      '_id': lead['_id'] ?? lead['id'] ?? '',
      'email': lead['email']?.toString() ?? '',
      'firstName': lead['firstName']?.toString() ?? '',
      'lastName': lead['lastName']?.toString() ?? '',
      'company': lead['company']?.toString() ?? '',
      'type': lead['type']?.toString() ?? 'Email',
      'tracking': tracking,
      'trackingStatus': trackingStatus,
      'addedDate': addedDate ?? DateTime.now(),
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
  // TODAY COUNT
  // ============================================================

  int get todayAddedCount {
    final now = DateTime.now();

    return leads.where((lead) {
      final date = lead['addedDate'] as DateTime;

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  // ============================================================
  // FILTERED LEADS
  // ============================================================

  List<Map<String, dynamic>> get filteredLeads {
    List<Map<String, dynamic>> result =
        List<Map<String, dynamic>>.from(leads);

    // ----------------------------------------------------------
    // TODAY FILTER
    // ----------------------------------------------------------

    if (todayOnly) {
      final now = DateTime.now();

      result = result.where((lead) {
        final date = lead['addedDate'] as DateTime;

        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList();
    }

    // ----------------------------------------------------------
    // FROM DATE
    // ----------------------------------------------------------

    if (fromDate != null) {
      final startDate = DateTime(
        fromDate!.year,
        fromDate!.month,
        fromDate!.day,
      );

      result = result.where((lead) {
        final date = lead['addedDate'] as DateTime;

        return !date.isBefore(startDate);
      }).toList();
    }

    // ----------------------------------------------------------
    // TO DATE
    // ----------------------------------------------------------

    if (toDate != null) {
      final endDate = DateTime(
        toDate!.year,
        toDate!.month,
        toDate!.day,
        23,
        59,
        59,
      );

      result = result.where((lead) {
        final date = lead['addedDate'] as DateTime;

        return !date.isAfter(endDate);
      }).toList();
    }

    return result;
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  List<Map<String, dynamic>> get paginatedLeads {
    final data = filteredLeads;

    if (data.isEmpty) {
      return [];
    }

    final start =
        (currentPage - 1) * entriesPerPage;

    if (start >= data.length) {
      return [];
    }

    final end =
        start + entriesPerPage > data.length
            ? data.length
            : start + entriesPerPage;

    return data.sublist(start, end);
  }

  int get totalPages {
    if (filteredLeads.isEmpty) {
      return 1;
    }

    return (filteredLeads.length / entriesPerPage).ceil();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: goldDark,
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
              final isMobile =
                  constraints.maxWidth < 850;

              return SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 14 : 28,
                  isMobile ? 18 : 28,
                  isMobile ? 14 : 28,
                  35,
                ),
                child: Column(
                  children: [
                    _buildPageHeader(isMobile),

                    const SizedBox(height: 16),

                    _buildLeadsPanel(isMobile),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 15 : 16,
      ),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.people_alt_outlined,
                      color: gold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Leads',
                      style: TextStyle(
                        color: white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                const Text(
                  'Manage and organize your leads',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: _goldButton(
                    label: 'Add Lead',
                    icon: Icons.add,
                    onPressed:
                        _openAddLeadScreen,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius:
                        BorderRadius.circular(4),
                  ),
                ),

                const SizedBox(width: 10),

                const Icon(
                  Icons.people_alt_outlined,
                  color: gold,
                  size: 20,
                ),

                const SizedBox(width: 8),

                const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leads',
                      style: TextStyle(
                        color: white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Manage and organize your leads',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                _goldButton(
                  label: 'Add Lead',
                  icon: Icons.add,
                  onPressed:
                      _openAddLeadScreen,
                ),
              ],
            ),
    );
  }

  // ============================================================
  // OPEN ADD LEAD SCREEN
  // ============================================================

  Future<void> _openAddLeadScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddLeadScreen(),
      ),
    );

    if (!mounted) return;

    await _loadLeads(
      showLoader: false,
    );
  }

  // ============================================================
  // LEADS PANEL
  // ============================================================

  Widget _buildLeadsPanel(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 14 : 15,
      ),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildExcelToolbar(isMobile),

          const SizedBox(height: 18),

          _buildTable(isMobile),
        ],
      ),
    );
  }

  // ============================================================
  // EXCEL TOOLBAR
  // ============================================================

  Widget _buildExcelToolbar(bool isMobile) {
    final todayButton =
        _todayFilterButton();

    final dateButton =
        _dateFilterButton();

    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _darkActionButton(
                  icon:
                      Icons.download_outlined,
                  text: isDownloadingExcel
                      ? 'Downloading...'
                      : 'Download Excel',
                  onPressed:
                      isDownloadingExcel
                          ? null
                          : _downloadExcel,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _darkActionButton(
                  icon:
                      Icons.upload_file_outlined,
                  text: isUploadingExcel
                      ? 'Uploading...'
                      : 'Upload Excel',
                  onPressed:
                      isUploadingExcel
                          ? null
                          : _uploadExcel,
                  outlined: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _todayFilterButton(
                  expanded: true,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _dateFilterButton(
                  expanded: true,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _darkActionButton(
          icon: Icons.download_outlined,
          text: isDownloadingExcel
              ? 'Downloading...'
              : 'Download Excel',
          onPressed: isDownloadingExcel
              ? null
              : _downloadExcel,
        ),

        const SizedBox(width: 10),

        _darkActionButton(
          icon: Icons.upload_file_outlined,
          text: isUploadingExcel
              ? 'Uploading...'
              : 'Upload Excel',
          onPressed: isUploadingExcel
              ? null
              : _uploadExcel,
          outlined: true,
        ),

        const Spacer(),

        todayButton,

        const SizedBox(width: 10),

        dateButton,
      ],
    );
  }

  // ============================================================
  // TODAY FILTER BUTTON
  // ============================================================

  Widget _todayFilterButton({
    bool expanded = false,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          todayOnly = true;
          fromDate = null;
          toDate = null;
          currentPage = 1;
        });
      },
      borderRadius:
          BorderRadius.circular(10),
      child: Container(
        height: 40,
        width:
            expanded ? double.infinity : null,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: gold,
          borderRadius:
              BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.10),
              blurRadius: 7,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: expanded
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          mainAxisSize: expanded
              ? MainAxisSize.max
              : MainAxisSize.min,
          children: [
            const Icon(
              Icons.today_outlined,
              size: 16,
              color: Color(0xFF30270F),
            ),

            const SizedBox(width: 6),

            Flexible(
              child: Text(
                'Today Added: $todayAddedCount',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color:
                      Color(0xFF30270F),
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE FILTER BUTTON
  // ============================================================

  Widget _dateFilterButton({
    bool expanded = false,
  }) {
    String label = 'Today';

    if (fromDate != null &&
        toDate != null) {
      label =
          '${_shortDate(fromDate!)} - '
          '${_shortDate(toDate!)}';
    } else if (fromDate != null) {
      label =
          'From ${_shortDate(fromDate!)}';
    } else if (toDate != null) {
      label =
          'Until ${_shortDate(toDate!)}';
    }

    return PopupMenuButton<String>(
      tooltip: 'Date filter',
      onSelected: (value) {
        if (value == 'today') {
          setState(() {
            todayOnly = true;
            fromDate = null;
            toDate = null;
            currentPage = 1;
          });
        }

        if (value == 'all') {
          setState(() {
            todayOnly = false;
            fromDate = null;
            toDate = null;
            currentPage = 1;
          });
        }

        if (value == 'custom') {
          _showDateFilter();
        }
      },
      color: tableColor,
      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: 'today',
            child: Row(
              children: [
                Icon(
                  Icons.today_outlined,
                  color: gold,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Today',
                  style: TextStyle(
                    color: white,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'all',
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: gold,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'All Dates',
                  style: TextStyle(
                    color: white,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'custom',
            child: Row(
              children: [
                Icon(
                  Icons.date_range_outlined,
                  color: gold,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Custom Range',
                  style: TextStyle(
                    color: white,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
      child: Container(
        height: 40,
        width:
            expanded ? double.infinity : null,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF747982),
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: expanded
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          mainAxisSize: expanded
              ? MainAxisSize.max
              : MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 16,
              color: white,
            ),

            const SizedBox(width: 6),

            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color: white,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 3),

            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: white,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildTable(bool isMobile) {
    if (isLoading) {
      return _buildLoadingState();
    }

    final data = paginatedLeads;

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: tableColor,
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(18),
            child: data.isEmpty
                ? _buildEmptyTable()
                : _buildDataTable(
                    data,
                    isMobile,
                  ),
          ),
        ),

        if (filteredLeads.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildPagination(isMobile),
        ],
      ],
    );
  }

  // ============================================================
  // DATA TABLE
  //
  // FINAL STRUCTURE:
  //
  // FULL NAME
  // COMPANY
  // TYPE
  // EMAIL
  // TRACKING
  // ADDED DATE
  // ACTIONS
  // ============================================================

  Widget _buildDataTable(
    List<Map<String, dynamic>> data,
    bool isMobile,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: DataTable(
        headingRowHeight: 48,
        dataRowMinHeight: 60,
        dataRowMaxHeight: 72,

        // Keep enough horizontal space so that
        // the email is readable completely.
        horizontalMargin: 18,

        columnSpacing:
            isMobile ? 24 : 34,

        dividerThickness: 0.25,

        headingRowColor:
            WidgetStateProperty.all(
          tableColor,
        ),

        dataRowColor:
            WidgetStateProperty.all(
          tableColor,
        ),

        headingTextStyle:
            const TextStyle(
          color: gold,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.25,
        ),

        dataTextStyle:
            const TextStyle(
          color: lightText,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),

        columns: const [
          DataColumn(
            label: Text('FULL NAME'),
          ),

          DataColumn(
            label: Text('COMPANY'),
          ),

          DataColumn(
            label: Text('TYPE'),
          ),

          DataColumn(
            label: Text('EMAIL'),
          ),

          DataColumn(
            label: Text('TRACKING'),
          ),

          DataColumn(
            label: Text('ADDED DATE'),
          ),

          DataColumn(
            label: Text('ACTIONS'),
          ),
        ],

        rows: data.map(
          (lead) {
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

            final company =
                lead['company']
                        ?.toString()
                        .trim() ??
                    '';

            final email =
                lead['email']
                        ?.toString()
                        .trim() ??
                    '';

            return DataRow(
              cells: [
                // ==================================================
                // FULL NAME
                // ==================================================

                DataCell(
                  SizedBox(
                    width: isMobile ? 150 : 180,
                    child: Text(
                      fullName.isEmpty
                          ? '-'
                          : fullName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: lightText,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // COMPANY
                // ==================================================

                DataCell(
                  SizedBox(
                    width: isMobile ? 140 : 170,
                    child: Text(
                      company.isEmpty
                          ? '-'
                          : company,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // ==================================================
                // TYPE
                // ==================================================

                DataCell(
                  _typeBadge(
                    lead['type']
                            ?.toString() ??
                        'Email',
                  ),
                ),

                // ==================================================
                // EMAIL
                //
                // FULL EMAIL IS SHOWN.
                // No TextOverflow.ellipsis here.
                // ==================================================

                DataCell(
                  SizedBox(
                    width: isMobile ? 260 : 300,
                    child: Text(
                      email.isEmpty
                          ? '-'
                          : email,
                      maxLines: 1,
                      softWrap: false,
                      overflow:
                          TextOverflow.visible,
                      style:
                          const TextStyle(
                        color: lightText,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // TRACKING
                // ==================================================

                DataCell(
                  _trackingBadge(lead),
                ),

                // ==================================================
                // ADDED DATE
                // ==================================================

                DataCell(
                  Text(
                    _formatDate(
                      lead['addedDate']
                          as DateTime,
                    ),
                    style:
                        const TextStyle(
                      color: lightText,
                      fontSize: 12,
                    ),
                  ),
                ),

                // ==================================================
                // ACTIONS
                // ==================================================

                DataCell(
                  Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      // VIEW
                      IconButton(
                        tooltip: 'View',
                        onPressed: () {
                          _showViewLeadDialog(
                            lead,
                          );
                        },
                        icon: const Icon(
                          Icons.visibility_outlined,
                          color: blue,
                          size: 18,
                        ),
                      ),

                      // EDIT
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () {
                          _showEditLeadDialog(
                            lead,
                          );
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: gold,
                          size: 18,
                        ),
                      ),

                      // DELETE
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () {
                          _deleteLead(
                            lead,
                          );
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color:
                              Color(0xFFFF7676),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ).toList(),
      ),
    );
  }

  // ============================================================
  // TRACKING BADGE
  //
  // SENT    = GREEN
  // OPENED  = BLUE
  // CLICKED = PURPLE
  // FAILED  = RED
  // SKIP    = GREY
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
                ? 'Sent'
                : 'Skip')
            : rawStatus;

    final normalized =
        status.toLowerCase();

    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    // ----------------------------------------------------------
    // SENT
    // ----------------------------------------------------------

    if (normalized == 'sent') {
      backgroundColor =
          const Color(0xFF123D2D);

      borderColor =
          const Color(0xFF287754);

      textColor =
          const Color(0xFF65E49C);

      icon =
          Icons.check_circle_outline;
    }

    // ----------------------------------------------------------
    // OPENED
    // BLUE
    // ----------------------------------------------------------

    else if (normalized == 'opened' ||
        normalized == 'open' ||
        normalized == 'seen') {
      backgroundColor =
          const Color(0xFF102F5C);

      borderColor =
          const Color(0xFF2F70C9);

      textColor =
          const Color(0xFF69A8FF);

      icon =
          Icons.visibility_outlined;
    }

    // ----------------------------------------------------------
    // CLICKED
    // PURPLE
    // ----------------------------------------------------------

    else if (normalized == 'clicked' ||
        normalized == 'click') {
      backgroundColor =
          const Color(0xFF33205A);

      borderColor =
          const Color(0xFF7547C7);

      textColor =
          const Color(0xFFB993FF);

      icon =
          Icons.ads_click_outlined;
    }

    // ----------------------------------------------------------
    // FAILED
    // RED
    // ----------------------------------------------------------

    else if (normalized == 'failed' ||
        normalized == 'fail') {
      backgroundColor =
          const Color(0xFF521F25);

      borderColor =
          const Color(0xFFB63E4A);

      textColor =
          const Color(0xFFFF777F);

      icon =
          Icons.error_outline;
    }

    // ----------------------------------------------------------
    // SKIP
    // GREY
    // ----------------------------------------------------------

    else {
      backgroundColor =
          const Color(0xFF30333A);

      borderColor =
          const Color(0xFF62666F);

      textColor =
          const Color(0xFFB8BDC7);

      icon =
          Icons.remove_circle_outline;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: textColor,
          ),

          const SizedBox(width: 5),

          Text(
            _capitalizeStatus(status),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CAPITALIZE STATUS
  // ============================================================

  String _capitalizeStatus(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1).toLowerCase();
  }

  // ============================================================
  // TYPE BADGE
  // ============================================================

  Widget _typeBadge(String type) {
    final isWhatsApp =
        type.toLowerCase() == 'whatsapp';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isWhatsApp
            ? const Color(0xFF174D37)
            : const Color(0xFF202C59),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: isWhatsApp
              ? const Color(0xFF2D815D)
              : const Color(0xFF4057A2),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            isWhatsApp
                ? Icons.chat_outlined
                : Icons.email_outlined,
            size: 13,
            color: isWhatsApp
                ? const Color(0xFF65E49C)
                : const Color(0xFF9AAEFF),
          ),

          const SizedBox(width: 5),

          Text(
            type,
            style: TextStyle(
              color: isWhatsApp
                  ? const Color(0xFF65E49C)
                  : const Color(0xFF9AAEFF),
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
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
        lead['type']
                ?.toString() ??
            'Email';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor:
              Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 520,
            ),
            child: Container(
              decoration:
                  BoxDecoration(
                color: tableColor,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  _dialogHeader(
                    dialogContext,
                    Icons.visibility_outlined,
                    'Lead Details',
                    'View lead information',
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        _viewInfoRow(
                          'Full Name',
                          fullName.isEmpty
                              ? '-'
                              : fullName,
                          Icons.person_outline,
                        ),

                        const SizedBox(height: 12),

                        _viewInfoRow(
                          'Email',
                          email.isEmpty
                              ? '-'
                              : email,
                          Icons.email_outlined,
                        ),

                        const SizedBox(height: 12),

                        _viewInfoRow(
                          'Company',
                          company.isEmpty
                              ? '-'
                              : company,
                          Icons.business_outlined,
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child:
                                  _viewInfoRow(
                                'Type',
                                type,
                                Icons.category_outlined,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tracking',
                                    style:
                                        TextStyle(
                                      color:
                                          mutedText,
                                      fontSize:
                                          11,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 6,
                                  ),
                                  _trackingBadge(
                                    lead,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _viewInfoRow(
                          'Added Date',
                          _formatDate(
                            lead['addedDate']
                                as DateTime,
                          ),
                          Icons.calendar_today_outlined,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.all(16),
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFF141824),
                      borderRadius:
                          BorderRadius.only(
                        bottomLeft:
                            Radius.circular(18),
                        bottomRight:
                            Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
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
                              0xFF30270F,
                            ),
                            elevation: 0,
                          ),
                          child:
                              const Text(
                            'Close',
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

        const SizedBox(height: 6),

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration:
              BoxDecoration(
            color:
                const Color(0xFF161A27),
            borderRadius:
                BorderRadius.circular(9),
            border: Border.all(
              color:
                  const Color(0xFF292E3D),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: mutedText,
                size: 17,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  value,
                  style:
                      const TextStyle(
                    color: lightText,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w500,
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
  // PAGINATION
  // ============================================================

  Widget _buildPagination(bool isMobile) {
    final pages = totalPages;

    if (pages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF41444C),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF666A73),
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                Text(
                  'Page $currentPage of $pages',
                  style: const TextStyle(
                    color: lightText,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 9),

                SingleChildScrollView(
                  scrollDirection:
                      Axis.horizontal,
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      _paginationButton(
                        icon:
                            Icons.chevron_left,
                        label: 'Previous',
                        enabled:
                            currentPage > 1,
                        onPressed:
                            currentPage > 1
                                ? () {
                                    setState(() {
                                      currentPage--;
                                    });
                                  }
                                : null,
                      ),

                      const SizedBox(width: 8),

                      ..._buildPageNumbers(),

                      const SizedBox(width: 8),

                      _paginationButton(
                        icon:
                            Icons.chevron_right,
                        label: 'Next',
                        enabled:
                            currentPage < pages,
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
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  'Page $currentPage of $pages',
                  style: const TextStyle(
                    color: lightText,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const Spacer(),

                _paginationButton(
                  icon: Icons.chevron_left,
                  label: 'Previous',
                  enabled:
                      currentPage > 1,
                  onPressed:
                      currentPage > 1
                          ? () {
                              setState(() {
                                currentPage--;
                              });
                            }
                          : null,
                ),

                const SizedBox(width: 8),

                ..._buildPageNumbers(),

                const SizedBox(width: 8),

                _paginationButton(
                  icon:
                      Icons.chevron_right,
                  label: 'Next',
                  enabled:
                      currentPage < pages,
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
            ),
    );
  }

  // ============================================================
  // PAGE NUMBERS
  // ============================================================

  List<Widget> _buildPageNumbers() {
    final pages = totalPages;

    final List<int> pageNumbers = [];

    if (pages <= 5) {
      for (
        int i = 1;
        i <= pages;
        i++
      ) {
        pageNumbers.add(i);
      }
    } else {
      pageNumbers.add(1);

      if (currentPage > 3) {
        pageNumbers.add(-1);
      }

      final start =
          currentPage <= 3
              ? 2
              : currentPage - 1;

      final end =
          currentPage >= pages - 2
              ? pages - 1
              : currentPage + 1;

      for (
        int i = start;
        i <= end;
        i++
      ) {
        if (i > 1 && i < pages) {
          pageNumbers.add(i);
        }
      }

      if (currentPage < pages - 2) {
        pageNumbers.add(-1);
      }

      pageNumbers.add(pages);
    }

    return pageNumbers.map(
      (page) {
        if (page == -1) {
          return const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 4,
            ),
            child: Text(
              '...',
              style: TextStyle(
                color: mutedText,
                fontSize: 12,
              ),
            ),
          );
        }

        final selected =
            page == currentPage;

        return Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 2,
          ),
          child: InkWell(
            onTap: selected
                ? null
                : () {
                    setState(() {
                      currentPage = page;
                    });
                  },
            borderRadius:
                BorderRadius.circular(8),
            child: Container(
              width: 34,
              height: 34,
              alignment:
                  Alignment.center,
              decoration:
                  BoxDecoration(
                color: selected
                    ? gold
                    : const Color(
                        0xFF30333B,
                      ),
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
                border: Border.all(
                  color: selected
                      ? gold
                      : const Color(
                          0xFF5F636C,
                        ),
                ),
              ),
              child: Text(
                '$page',
                style: TextStyle(
                  color: selected
                      ? const Color(
                          0xFF30270F,
                        )
                      : lightText,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      },
    ).toList();
  }

  // ============================================================
  // PAGINATION BUTTON
  // ============================================================

  Widget _paginationButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 16,
        ),
        label: Text(
          label,
          style:
              const TextStyle(
            fontSize: 10,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              enabled ? gold : mutedText,
          side: BorderSide(
            color: enabled
                ? const Color(
                    0xFF777A82,
                  )
                : const Color(
                    0xFF4B4E56,
                  ),
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY TABLE
  // ============================================================

  Widget _buildEmptyTable() {
    final message = todayOnly
        ? 'No leads found for today'
        : 'No leads found for this period';

    return SizedBox(
      width: double.infinity,
      height: 150,
      child: Center(
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: gold,
              size: 18,
            ),

            const SizedBox(width: 7),

            Text(
              message,
              style:
                  const TextStyle(
                color: lightText,
                fontSize: 13,
                fontWeight:
                    FontWeight.w500,
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
      width: double.infinity,
      height: 180,
      color: tableColor,
      child: const Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
                color: gold,
              ),
            ),

            SizedBox(height: 12),

            Text(
              'Loading leads...',
              style: TextStyle(
                color: mutedText,
                fontSize: 12,
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
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 17,
        ),
        label: Text(
          label,
          style:
              const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor:
              const Color(0xFF2D2610),
          disabledBackgroundColor:
              const Color(0xFFB89B4C),
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
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
        decoration: BoxDecoration(
          color: outlined
              ? Colors.transparent
              : const Color(0xFF41444C),
          borderRadius:
              BorderRadius.circular(10),
          border: outlined
              ? Border.all(
                  color:
                      const Color(0xFF858890),
                )
              : null,
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            minimumSize: Size.zero,
            tapTargetSize:
                MaterialTapTargetSize
                    .shrinkWrap,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            mainAxisSize:
                MainAxisSize.max,
            children: [
              Icon(
                icon,
                color: gold,
                size: 16,
              ),

              const SizedBox(width: 6),

              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color: gold,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
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
  // EDIT DIALOG
  // ============================================================

  void _showEditLeadDialog(
    Map<String, dynamic> lead,
  ) {
    editEmailController.text =
        lead['email'].toString();

    editFirstNameController.text =
        lead['firstName'].toString();

    editLastNameController.text =
        lead['lastName'].toString();

    editCompanyController.text =
        lead['company'].toString();

    selectedType =
        lead['type'].toString();

    trackingEnabled =
        lead['tracking'] == true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
                horizontal: 18,
                vertical: 20,
              ),
              child: _buildLeadDialog(
                dialogContext:
                    dialogContext,
                setDialogState:
                    setDialogState,
                isEdit: true,
                lead: lead,
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // LEAD DIALOG
  // ============================================================

  Widget _buildLeadDialog({
    required BuildContext dialogContext,
    required StateSetter setDialogState,
    required bool isEdit,
    required Map<String, dynamic>? lead,
  }) {
    final saving = isEdit
        ? isUpdatingLead
        : false;

    return ConstrainedBox(
      constraints:
          const BoxConstraints(
        maxWidth: 600,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: tableColor,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            _dialogHeader(
              dialogContext,
              isEdit
                  ? Icons.edit_outlined
                  : Icons.person_add_outlined,
              isEdit
                  ? 'Edit Lead'
                  : 'Add New Lead',
              isEdit
                  ? 'Update lead information'
                  : 'Add a new lead',
            ),

            Padding(
              padding:
                  const EdgeInsets.all(22),
              child: Column(
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
                        TextInputType
                            .emailAddress,
                  ),

                  const SizedBox(
                    height: 14,
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
                          hint: 'John',
                          icon:
                              Icons.person_outline,
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
                          hint: 'Doe',
                          icon:
                              Icons.person_outline,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _dialogInput(
                    controller:
                        editCompanyController,
                    label: 'Company',
                    hint:
                        'Company name',
                    icon:
                        Icons.business_outlined,
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _dialogDropdown(
                    label: 'Type',
                    value:
                        selectedType,
                    items: const [
                      'Email',
                      'WhatsApp',
                    ],
                    onChanged:
                        (value) {
                      setDialogState(() {
                        selectedType =
                            value ?? 'Email';
                      });
                    },
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Container(
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
                          color: white,
                          fontWeight:
                              FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle:
                          const Text(
                        'Track email opens and clicks',
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
                        setDialogState(() {
                          trackingEnabled =
                              value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFF141824),
                borderRadius:
                    BorderRadius.only(
                  bottomLeft:
                      Radius.circular(18),
                  bottomRight:
                      Radius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        saving
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
                    width: 8,
                  ),

                  ElevatedButton.icon(
                    onPressed:
                        saving
                            ? null
                            : () {
                                _updateLead(
                                  dialogContext,
                                  lead!,
                                );
                              },
                    icon: saving
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Color(
                                0xFF2D2610,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons
                                .save_outlined,
                            size: 17,
                          ),
                    label: Text(
                      saving
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
                        0xFF2D2610,
                      ),
                      elevation: 0,
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
          const EdgeInsets.all(18),
      decoration:
          const BoxDecoration(
        color: Color(0xFF080B13),
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
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(
              color:
                  gold.withOpacity(0.12),
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

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color: white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

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
            icon: const Icon(
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
    required TextEditingController controller,
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

        const SizedBox(height: 6),

        TextField(
          controller: controller,
          keyboardType:
              keyboardType,
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
                    Color(0xFF292E3D),
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
  // DIALOG DROPDOWN
  // ============================================================

  Widget _dialogDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?>
        onChanged,
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

        const SizedBox(height: 6),

        Container(
          height: 48,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration:
              BoxDecoration(
            color:
                const Color(0xFF161A27),
            borderRadius:
                BorderRadius.circular(
              9,
            ),
            border: Border.all(
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
              value: value,
              isExpanded: true,
              dropdownColor:
                  const Color(
                0xFF161A27,
              ),
              icon:
                  const Icon(
                Icons
                    .keyboard_arrow_down,
                color: mutedText,
              ),
              style:
                  const TextStyle(
                color: white,
                fontSize: 13,
              ),
              items:
                  items.map(
                (item) {
                  return DropdownMenuItem<
                      String>(
                    value: item,
                    child:
                        Text(item),
                  );
                },
              ).toList(),
              onChanged:
                  onChanged,
            ),
          ),
        ),
      ],
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
        lead['_id']?.toString() ?? '';

    if (leadId.isEmpty) {
      _showMessage(
        'Lead ID not found.',
      );
      return;
    }

    final email =
        editEmailController.text.trim();

    final firstName =
        editFirstNameController.text.trim();

    final lastName =
        editLastNameController.text.trim();

    final company =
        editCompanyController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        'Email is required.',
      );
      return;
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
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

      if (!mounted) return;

      if (response['success'] == true) {
        Navigator.pop(
          dialogContext,
        );

        _clearEditForm();

        _showMessage(
          response['message']
                  ?.toString() ??
              'Lead updated successfully.',
        );

        await _loadLeads(
          showLoader: false,
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
          isUpdatingLead = false;
        });
      }
    }
  }

  // ============================================================
  // CLEAR EDIT FORM
  // ============================================================

  void _clearEditForm() {
    editEmailController.clear();
    editFirstNameController.clear();
    editLastNameController.clear();
    editCompanyController.clear();

    selectedType = 'Email';
    trackingEnabled = true;
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _deleteLead(
    Map<String, dynamic> lead,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF141824),
          title: const Text(
            'Delete Lead',
            style: TextStyle(
              color: white,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete '
            '${lead['firstName']} '
            '${lead['lastName']}?',
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
                style:
                    TextStyle(
                  color: mutedText,
                ),
              ),
            ),

            ElevatedButton(
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
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFC94141,
                ),
                foregroundColor:
                    white,
                elevation: 0,
              ),
              child:
                  const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PERFORM DELETE
  // ============================================================

  Future<void> _performDeleteLead(
    Map<String, dynamic> lead,
  ) async {
    final leadId =
        lead['_id']?.toString() ?? '';

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

      if (!mounted) return;

      if (response['success'] == true) {
        _showMessage(
          response['message']
                  ?.toString() ??
              'Lead deleted successfully.',
        );

        await _loadLeads(
          showLoader: false,
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
          isDeletingLead = false;
        });
      }
    }
  }

  // ============================================================
  // DATE FILTER
  // ============================================================

  Future<void> _showDateFilter() async {
    DateTime? tempFrom = fromDate;
    DateTime? tempTo = toDate;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return Dialog(
              backgroundColor:
                  Colors.transparent,
              child: Container(
                constraints:
                    const BoxConstraints(
                  maxWidth: 520,
                ),
                decoration:
                    BoxDecoration(
                  color: tableColor,
                  borderRadius:
                      BorderRadius.circular(
                    18,
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
                      'Select the date range for leads',
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child:
                                _dateSelector(
                              label:
                                  'From Date',
                              value:
                                  tempFrom,
                              onTap:
                                  () async {
                                final picked =
                                    await showDatePicker(
                                  context:
                                      context,
                                  firstDate:
                                      DateTime(
                                    2020,
                                  ),
                                  lastDate:
                                      DateTime(
                                    2035,
                                  ),
                                  initialDate:
                                      tempFrom ??
                                          DateTime.now(),
                                  builder:
                                      (
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
                                              gold,
                                          surface:
                                              Color(
                                            0xFF141824,
                                          ),
                                        ),
                                      ),
                                      child:
                                          child!,
                                    );
                                  },
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
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child:
                                _dateSelector(
                              label:
                                  'To Date',
                              value:
                                  tempTo,
                              onTap:
                                  () async {
                                final picked =
                                    await showDatePicker(
                                  context:
                                      context,
                                  firstDate:
                                      DateTime(
                                    2020,
                                  ),
                                  lastDate:
                                      DateTime(
                                    2035,
                                  ),
                                  initialDate:
                                      tempTo ??
                                          DateTime.now(),
                                  builder:
                                      (
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
                                              gold,
                                          surface:
                                              Color(
                                            0xFF141824,
                                          ),
                                        ),
                                      ),
                                      child:
                                          child!,
                                    );
                                  },
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
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .end,
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
                            width: 8,
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
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  gold,
                              foregroundColor:
                                  const Color(
                                0xFF30270F,
                              ),
                              elevation: 0,
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

  // ============================================================
  // DATE SELECTOR
  // ============================================================

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

        const SizedBox(height: 6),

        InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(9),
          child: Container(
            height: 46,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 11,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFF161A27),
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
              border: Border.all(
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
                  width: 7,
                ),

                Expanded(
                  child: Text(
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

  Future<void> _uploadExcel() async {
    try {
      final result =
          await FilePicker.platform.pickFiles(
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
          'Unable to read the selected Excel file.',
        );
        return;
      }

      setState(() {
        isUploadingExcel = true;
      });

      final token =
          await _getToken();

      if (token == null ||
          token.isEmpty) {
        _showMessage(
          'Authentication token not found. Please login again.',
        );
        return;
      }

      final request =
          http.MultipartRequest(
        'POST',
        Uri.parse(
          '$baseUrl/leads/import-excel',
        ),
      );

      request.headers[
              'Authorization'] =
          'Bearer $token';

      request.files.add(
        http.MultipartFile
            .fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

      final streamedResponse =
          await request.send();

      final response =
          await http.Response
              .fromStream(
        streamedResponse,
      );

      Map<String, dynamic>
          responseData = {};

      try {
        final decoded =
            jsonDecode(
          response.body,
        );

        if (decoded is Map) {
          responseData =
              Map<String, dynamic>.from(
            decoded,
          );
        }
      } catch (_) {}

      if (!mounted) return;

      if (response.statusCode >=
              200 &&
          response.statusCode <
              300 &&
          responseData['success'] ==
              true) {
        final imported =
            responseData[
                    'imported'] ??
                0;

        final skipped =
            responseData[
                    'skipped'] ??
                0;

        _showMessage(
          'Excel import completed. '
          'Imported: $imported, Skipped: $skipped.',
        );

        await _loadLeads(
          showLoader: false,
        );
      } else {
        _showMessage(
          responseData['message']
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
          isUploadingExcel = false;
        });
      }
    }
  }

  // ============================================================
  // EXCEL DOWNLOAD
  // ============================================================

  Future<void> _downloadExcel() async {
    if (leads.isEmpty) {
      _showMessage(
        'There are no leads to download.',
      );
      return;
    }

    try {
      setState(() {
        isDownloadingExcel = true;
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

      for (final lead in leads) {
        rows.add([
          lead['email']?.toString() ??
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
          lead['type']?.toString() ??
              '',
          lead['tracking'] == true
              ? 'true'
              : 'false',
          _formatDate(
            lead['addedDate']
                as DateTime,
          ),
        ]);
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

      for (
        int i = 0;
        i < rows.length;
        i++
      ) {
        html.write('<tr>');

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

        html.write('</tr>');
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
          'HighCustomAI_Leads_'
          '${DateTime.now().millisecondsSinceEpoch}.xls';

      await FilePicker.platform.saveFile(
        fileName: fileName,
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
  // TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    try {
      final token =
          await storage.read(
        key: 'auth_token',
      );

      if (token != null &&
          token.trim().isNotEmpty) {
        return token.trim();
      }

      final legacy =
          await storage.read(
        key: 'token',
      );

      if (legacy != null &&
          legacy.trim().isNotEmpty) {
        final clean =
            legacy.trim();

        await storage.write(
          key: 'auth_token',
          value: clean,
        );

        await storage.delete(
          key: 'token',
        );

        return clean;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // HTML ESCAPE
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

  // ============================================================
  // FORMAT DATE
  // ============================================================

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

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xFF20242E),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    editEmailController.dispose();
    editFirstNameController.dispose();
    editLastNameController.dispose();
    editCompanyController.dispose();
    super.dispose();
  }
}