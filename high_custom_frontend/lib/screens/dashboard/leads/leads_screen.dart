import 'package:flutter/material.dart';

import '../../../services/leads_api.dart';
import '../../../services/sequence_api.dart';

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

  static const Color primaryColor =
      Color(0xFF4F46E5);

  static const Color backgroundColor =
      Color(0xFFF8FAFC);

  static const Color textColor =
      Color(0xFF101828);

  static const Color secondaryTextColor =
      Color(0xFF667085);

  static const Color borderColor =
      Color(0xFFE4E7EC);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController searchController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController firstNameController =
      TextEditingController();

  final TextEditingController lastNameController =
      TextEditingController();

  final TextEditingController companyController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;

  bool isAddingLead = false;

  bool isUpdatingLead = false;

  bool isDeletingLead = false;

  bool todayOnly = false;

  bool trackingEnabled = true;

  int currentPage = 1;

  int entriesPerPage = 10;

  DateTime? fromDate;

  DateTime? toDate;

  String selectedType = 'Email';

  // ============================================================
  // LEADS DATA
  // ============================================================

  final List<Map<String, dynamic>> leads = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    searchController.addListener(
      _onSearchChanged,
    );

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
      final response =
          await LeadsApi.getLeads();

      if (!mounted) return;

      if (response['success'] == true) {
        final serverLeads =
            response['leads'];

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
    } catch (error) {
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

    return {
      '_id':
          lead['_id'] ??
          lead['id'] ??
          '',

      'email':
          lead['email']?.toString() ?? '',

      'firstName':
          lead['firstName']?.toString() ?? '',

      'lastName':
          lead['lastName']?.toString() ?? '',

      'company':
          lead['company']?.toString() ?? '',

      'type':
          lead['type']?.toString() ?? 'Email',

      'tracking':
          tracking,

      'trackingStatus':
          lead['trackingStatus']?.toString() ??
              (tracking ? 'Sent' : 'Skip'),

      'addedDate':
          addedDate ?? DateTime.now(),

      'updatedDate':
          updatedDate,
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
  // SEARCH CHANGE
  // ============================================================

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      currentPage = 1;
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.removeListener(
      _onSearchChanged,
    );

    searchController.dispose();

    emailController.dispose();

    firstNameController.dispose();

    lastNameController.dispose();

    companyController.dispose();

    super.dispose();
  }

  // ============================================================
  // FILTERED LEADS
  // ============================================================

  List<Map<String, dynamic>> get filteredLeads {
    List<Map<String, dynamic>> result =
        List<Map<String, dynamic>>.from(
      leads,
    );

    final search =
        searchController.text
            .trim()
            .toLowerCase();

    // ==========================================================
    // SEARCH
    // ==========================================================

    if (search.isNotEmpty) {
      result = result.where((lead) {
        final email =
            lead['email']
                .toString()
                .toLowerCase();

        final firstName =
            lead['firstName']
                .toString()
                .toLowerCase();

        final lastName =
            lead['lastName']
                .toString()
                .toLowerCase();

        final company =
            lead['company']
                .toString()
                .toLowerCase();

        return email.contains(search) ||
            firstName.contains(search) ||
            lastName.contains(search) ||
            company.contains(search);
      }).toList();
    }

    // ==========================================================
    // TODAY
    // ==========================================================

    if (todayOnly) {
      final now = DateTime.now();

      result = result.where((lead) {
        final date =
            lead['addedDate'] as DateTime;

        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList();
    }

    // ==========================================================
    // FROM DATE
    // ==========================================================

    if (fromDate != null) {
      final startDate = DateTime(
        fromDate!.year,
        fromDate!.month,
        fromDate!.day,
      );

      result = result.where((lead) {
        final date =
            lead['addedDate'] as DateTime;

        return !date.isBefore(startDate);
      }).toList();
    }

    // ==========================================================
    // TO DATE
    // ==========================================================

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
        final date =
            lead['addedDate'] as DateTime;

        return !date.isAfter(endDate);
      }).toList();
    }

    return result;
  }

  // ============================================================
  // PAGINATED LEADS
  // ============================================================

  List<Map<String, dynamic>> get paginatedLeads {
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

    final end =
        (start + entriesPerPage) >
                data.length
            ? data.length
            : start + entriesPerPage;

    return data.sublist(
      start,
      end,
    );
  }

  // ============================================================
  // TOTAL PAGES
  // ============================================================

  int get totalPages {
    if (filteredLeads.isEmpty) {
      return 1;
    }

    return (
      filteredLeads.length /
          entriesPerPage
    ).ceil();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
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
                  constraints.maxWidth < 800;

              return SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(
                  isMobile ? 18 : 28,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(
                      isMobile,
                    ),

                    SizedBox(
                      height:
                          isMobile
                              ? 22
                              : 28,
                    ),

                    _buildMainContainer(
                      isMobile,
                    ),
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

  Widget _buildPageHeader(
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Leads',
            style: TextStyle(
              color: textColor,
              fontSize: 30,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Manage and organize your leads',
            style: TextStyle(
              color:
                  secondaryTextColor,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed:
                  _showAddLeadDialog,
              icon: const Icon(
                Icons.add,
                size: 20,
              ),
              label: const Text(
                'Add Lead',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryColor,
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
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Leads',
                style: TextStyle(
                  color: textColor,
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              SizedBox(height: 6),

              Text(
                'Manage and organize your leads',
                style: TextStyle(
                  color:
                      secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        ElevatedButton.icon(
          onPressed:
              _showAddLeadDialog,
          icon: const Icon(
            Icons.add,
            size: 20,
          ),
          label: const Text(
            'Add Lead',
          ),
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                primaryColor,
            foregroundColor:
                Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MAIN CONTAINER
  // ============================================================

  Widget _buildMainContainer(
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          _buildToolbar(
            isMobile,
          ),

          const SizedBox(height: 18),

          if (isLoading)
            _buildLoadingState()
          else if (isMobile)
            _buildMobileTable()
          else
            _buildDesktopTable(),

          const SizedBox(height: 18),

          if (!isLoading)
            _buildPagination(),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING STATE
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 70,
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child:
                CircularProgressIndicator(
              strokeWidth: 3,
              color: primaryColor,
            ),
          ),

          SizedBox(height: 16),

          Text(
            'Loading leads...',
            style: TextStyle(
              color:
                  secondaryTextColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOOLBAR
  // ============================================================

  Widget _buildToolbar(
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        children: [
          _buildSearchField(),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      _toggleTodayFilter,
                  icon: const Icon(
                    Icons.today_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'Today',
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      _showDateFilter,
                  icon: const Icon(
                    Icons
                        .date_range_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'Date',
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildSearchField(),
        ),

        const SizedBox(width: 12),

        OutlinedButton.icon(
          onPressed:
              _toggleTodayFilter,
          icon: const Icon(
            Icons.today_outlined,
            size: 18,
          ),
          label: const Text(
            'Today',
          ),
        ),

        const SizedBox(width: 10),

        OutlinedButton.icon(
          onPressed:
              _showDateFilter,
          icon: const Icon(
            Icons.date_range_outlined,
            size: 18,
          ),
          label: const Text(
            'Date',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField() {
    return TextField(
      controller:
          searchController,
      style: const TextStyle(
        color: textColor,
        fontSize: 13,
      ),
      decoration:
          InputDecoration(
        hintText:
            'Search by email, name or company...',
        hintStyle:
            const TextStyle(
          color: Color(0xFF98A2B3),
          fontSize: 13,
        ),
        prefixIcon:
            const Icon(
          Icons.search,
          size: 19,
          color:
              Color(0xFF667085),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            8,
          ),
          borderSide:
              const BorderSide(
            color: borderColor,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            8,
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
            8,
          ),
          borderSide:
              const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable() {
    final data = paginatedLeads;

    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return _buildDataTable(
      data,
      emailWidth: 190,
      companyWidth: 150,
      spacing: 24,
    );
  }

  // ============================================================
  // MOBILE TABLE
  // ============================================================

  Widget _buildMobileTable() {
    final data = paginatedLeads;

    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return _buildDataTable(
      data,
      emailWidth: 180,
      companyWidth: 140,
      spacing: 20,
    );
  }

  // ============================================================
  // DATA TABLE
  // ============================================================

  Widget _buildDataTable(
    List<Map<String, dynamic>> data, {
    required double emailWidth,
    required double companyWidth,
    required double spacing,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(10),
        child:
            SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(
              const Color(0xFF101828),
            ),
            headingTextStyle:
                const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w700,
              fontSize: 12,
            ),
            dataTextStyle:
                const TextStyle(
              color:
                  Color(0xFF344054),
              fontSize: 13,
            ),
            columnSpacing:
                spacing,
            columns: const [
              DataColumn(
                label:
                    Text('EMAIL'),
              ),
              DataColumn(
                label:
                    Text('FIRST NAME'),
              ),
              DataColumn(
                label:
                    Text('LAST NAME'),
              ),
              DataColumn(
                label:
                    Text('COMPANY'),
              ),
              DataColumn(
                label:
                    Text('TYPE'),
              ),
              DataColumn(
                label:
                    Text('TRACKING'),
              ),
              DataColumn(
                label:
                    Text('ADDED DATE'),
              ),
              DataColumn(
                label:
                    Text('ACTIONS'),
              ),
            ],
            rows:
                data.map(
              (lead) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width:
                            emailWidth,
                        child: Text(
                          lead['email']
                              .toString(),
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),
                      ),
                    ),

                    DataCell(
                      Text(
                        lead['firstName']
                            .toString(),
                      ),
                    ),

                    DataCell(
                      Text(
                        lead['lastName']
                            .toString(),
                      ),
                    ),

                    DataCell(
                      SizedBox(
                        width:
                            companyWidth,
                        child: Text(
                          lead['company']
                              .toString(),
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),
                      ),
                    ),

                    DataCell(
                      _typeBadge(
                        lead['type']
                            .toString(),
                      ),
                    ),

                    DataCell(
                      _trackingBadge(
                        lead[
                                'trackingStatus']
                            ?.toString() ??
                            'Skip',
                      ),
                    ),

                    DataCell(
                      Text(
                        _formatDate(
                          lead['addedDate']
                              as DateTime,
                        ),
                      ),
                    ),

                    DataCell(
                      Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip:
                                'Edit',
                            onPressed:
                                () {
                              _showEditLeadDialog(
                                lead,
                              );
                            },
                            icon:
                                const Icon(
                              Icons
                                  .edit_outlined,
                              size: 19,
                              color:
                                  secondaryTextColor,
                            ),
                          ),

                          IconButton(
                            tooltip:
                                'Delete',
                            onPressed:
                                () {
                              _deleteLead(
                                lead,
                              );
                            },
                            icon:
                                const Icon(
                              Icons
                                  .delete_outline,
                              size: 19,
                              color:
                                  Color(
                                0xFFD92D20,
                              ),
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
        ),
      ),
    );
  }

  // ============================================================
  // TYPE BADGE
  // ============================================================

  Widget _typeBadge(
    String type,
  ) {
    Color background;
    Color foreground;
    IconData icon;

    switch (
        type.toLowerCase()) {
      case 'email':
        background =
            const Color(
          0xFFEFF4FF,
        );
        foreground =
            const Color(
          0xFF3538CD,
        );
        icon =
            Icons.email_outlined;
        break;

      case 'whatsapp':
        background =
            const Color(
          0xFFECFDF3,
        );
        foreground =
            const Color(
          0xFF027A48,
        );
        icon =
            Icons.chat_outlined;
        break;

      default:
        background =
            const Color(
          0xFFF2F4F7,
        );
        foreground =
            const Color(
          0xFF344054,
        );
        icon =
            Icons.category_outlined;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: foreground,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            type,
            style:
                TextStyle(
              color:
                  foreground,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRACKING BADGE
  // ============================================================

  Widget _trackingBadge(
    String status,
  ) {
    Color background;
    Color foreground;
    IconData icon;

    switch (
        status.trim().toLowerCase()) {
      case 'sent':
        background =
            const Color(
          0xFFECFDF3,
        );
        foreground =
            const Color(
          0xFF027A48,
        );
        icon =
            Icons.check_circle_outline;
        break;

      case 'seen':
        background =
            const Color(
          0xFFEFF4FF,
        );
        foreground =
            const Color(
          0xFF315BEF,
        );
        icon =
            Icons.visibility_outlined;
        break;

      case 'skip':
      case 'skipped':
        background =
            const Color(
          0xFFF2F4F7,
        );
        foreground =
            const Color(
          0xFF667085,
        );
        icon =
            Icons.remove_circle_outline;
        break;

      case 'failed':
        background =
            const Color(
          0xFFFEF3F2,
        );
        foreground =
            const Color(
          0xFFB42318,
        );
        icon =
            Icons.error_outline;
        break;

      case 'pending':
        background =
            const Color(
          0xFFFFFAEB,
        );
        foreground =
            const Color(
          0xFFB54708,
        );
        icon =
            Icons.schedule_outlined;
        break;

      default:
        background =
            const Color(
          0xFFF2F4F7,
        );
        foreground =
            const Color(
          0xFF344054,
        );
        icon =
            Icons.help_outline;

        status = 'Unknown';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: foreground,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            status,
            style:
                TextStyle(
              color:
                  foreground,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 60,
        horizontal: 20,
      ),
      decoration:
          BoxDecoration(
        border: Border.all(
          color: borderColor,
        ),
        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 46,
            color:
                Color(0xFF98A2B3),
          ),

          SizedBox(height: 14),

          Text(
            'No leads found',
            style:
                TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Try changing your search or filters.',
            style:
                TextStyle(
              color:
                  secondaryTextColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    final total =
        filteredLeads.length;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final start =
        ((currentPage - 1) *
                entriesPerPage) +
            1;

    final end =
        (currentPage *
                entriesPerPage) >
            total
        ? total
        : currentPage *
            entriesPerPage;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Showing $start - $end of $total',
            style:
                const TextStyle(
              color:
                  secondaryTextColor,
              fontSize: 13,
            ),
          ),
        ),

        IconButton(
          tooltip:
              'Previous',
          onPressed:
              currentPage > 1
                  ? () {
                      setState(() {
                        currentPage--;
                      });
                    }
                  : null,
          icon:
              const Icon(
            Icons.chevron_left,
          ),
        ),

        Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration:
              BoxDecoration(
            color:
                primaryColor,
            borderRadius:
                BorderRadius.circular(
              6,
            ),
          ),
          child: Text(
            '$currentPage',
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        IconButton(
          tooltip:
              'Next',
          onPressed:
              currentPage <
                      totalPages
                  ? () {
                      setState(() {
                        currentPage++;
                      });
                    }
                  : null,
          icon:
              const Icon(
            Icons.chevron_right,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final year =
        date.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // ADD LEAD
  // ============================================================

  Future<void> _addLead(
    BuildContext dialogContext,
  ) async {
    final email =
        emailController.text.trim();

    final firstName =
        firstNameController.text.trim();

    final lastName =
        lastNameController.text.trim();

    final company =
        companyController.text.trim();

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

    if (!emailRegex.hasMatch(
      email,
    )) {
      _showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    setState(() {
      isAddingLead = true;
    });

    try {
      final response =
          await LeadsApi.createLead(
        email: email,
        firstName: firstName,
        lastName: lastName,
        company: company,
        type: selectedType,
        tracking: trackingEnabled,
      );

      if (!mounted) return;

      if (response['success'] ==
          true) {
        Map<String, dynamic>? sequenceResponse;

        if (trackingEnabled && selectedType == 'Email') {
          sequenceResponse =
              await SequenceApi.runSequence();
        }

        Navigator.pop(
          dialogContext,
        );

        _clearForm();

        final sequenceFailed =
          sequenceResponse != null &&
            sequenceResponse['success'] != true;

        _showMessage(
          sequenceFailed
            ? 'Lead added, but the sequence could not be run.'
            : response['message']
                ?.toString() ??
              'Lead added successfully.',
        );

        await _loadLeads(
          showLoader: false,
        );
      } else {
        _showMessage(
          response['message']
                  ?.toString() ??
              'Unable to add lead.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to add lead. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isAddingLead = false;
        });
      }
    }
  }

  // ============================================================
  // CLEAR FORM
  // ============================================================

  void _clearForm() {
    emailController.clear();

    firstNameController.clear();

    lastNameController.clear();

    companyController.clear();

    selectedType = 'Email';

    trackingEnabled = true;
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
        emailController.text.trim();

    final firstName =
        firstNameController.text.trim();

    final lastName =
        lastNameController.text.trim();

    final company =
        companyController.text.trim();

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

    if (!emailRegex.hasMatch(
      email,
    )) {
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

      if (response['success'] ==
          true) {
        Navigator.pop(
          dialogContext,
        );

        _clearForm();

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
          'Unable to update lead. Please try again.',
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
    showDialog(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          backgroundColor:
              Colors.white,

          title:
              const Text(
            'Delete Lead',
            style:
                TextStyle(
              color:
                  textColor,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          content:
              Text(
            'Are you sure you want to delete '
            '${lead['firstName']} '
            '${lead['lastName']}?',
            style:
                const TextStyle(
              color:
                  secondaryTextColor,
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
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
                elevation:
                    0,
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

      if (response['success'] ==
          true) {
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
  // TODAY FILTER
  // ============================================================

  void _toggleTodayFilter() {
    setState(() {
      todayOnly =
          !todayOnly;

      if (todayOnly) {
        fromDate = null;
        toDate = null;
      }

      currentPage = 1;
    });
  }

  // ============================================================
  // DATE FILTER
  // ============================================================

  Future<void> _showDateFilter() async {
    DateTime? tempFromDate =
        fromDate;

    DateTime? tempToDate =
        toDate;

    await showDialog(
      context: context,
      barrierDismissible:
          true,
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
              insetPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: Container(
                constraints:
                    const BoxConstraints(
                  maxWidth: 520,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius
                          .circular(
                    18,
                  ),
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets
                              .all(
                        20,
                      ),
                      decoration:
                          const BoxDecoration(
                        color:
                            Color(
                          0xFF101828,
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
                      child:
                          Row(
                        children: [
                          Container(
                            width:
                                42,
                            height:
                                42,
                            decoration:
                                BoxDecoration(
                              color:
                                  primaryColor.withOpacity(
                                0.18,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .date_range_outlined,
                              color:
                                  Color(
                                0xFF7C9AFF,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          const Expanded(
                            child:
                                Text(
                              'Filter by Date',
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
                                  Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets
                              .all(
                        22,
                      ),
                      child:
                          Row(
                        children: [
                          Expanded(
                            child:
                                _dateSelector(
                              label:
                                  'From Date',
                              value:
                                  tempFromDate,
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
                                      tempFromDate ??
                                          DateTime
                                              .now(),
                                );

                                if (picked !=
                                    null) {
                                  setDialogState(
                                    () {
                                      tempFromDate =
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
                                  tempToDate,
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
                                      tempToDate ??
                                          DateTime
                                              .now(),
                                );

                                if (picked !=
                                    null) {
                                  setDialogState(
                                    () {
                                      tempToDate =
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
                          const EdgeInsets
                              .all(
                        18,
                      ),
                      decoration:
                          const BoxDecoration(
                        color:
                            Color(
                          0xFFF9FAFB,
                        ),
                        borderRadius:
                            BorderRadius.only(
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
                            MainAxisAlignment
                                .end,
                        children: [
                          OutlinedButton(
                            onPressed:
                                () {
                              setDialogState(
                                () {
                                  tempFromDate =
                                      null;
                                  tempToDate =
                                      null;
                                },
                              );
                            },
                            child:
                                const Text(
                              'Clear',
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          ElevatedButton(
                            onPressed:
                                () {
                              setState(
                                () {
                                  fromDate =
                                      tempFromDate;

                                  toDate =
                                      tempToDate;

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
                                  primaryColor,
                              foregroundColor:
                                  Colors.white,
                              elevation:
                                  0,
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
            color:
                secondaryTextColor,
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(
            8,
          ),
          child:
              Container(
            height: 48,
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 12,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              border:
                  Border.all(
                color:
                    borderColor,
              ),
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),
            child:
                Row(
              children: [
                const Icon(
                  Icons
                      .calendar_today_outlined,
                  size: 17,
                  color:
                      secondaryTextColor,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child:
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
                          textColor,
                      fontSize:
                          13,
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
  // ADD LEAD DIALOG
  // ============================================================

  void _showAddLeadDialog() {
    _clearForm();

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
                  Colors.transparent,
              insetPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 18,
                vertical: 20,
              ),
              child:
                  _buildLeadDialog(
                dialogContext:
                    dialogContext,
                setDialogState:
                    setDialogState,
                isEdit:
                    false,
                lead:
                    null,
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EDIT LEAD DIALOG
  // ============================================================

  void _showEditLeadDialog(
    Map<String, dynamic> lead,
  ) {
    emailController.text =
        lead['email'].toString();

    firstNameController.text =
        lead['firstName'].toString();

    lastNameController.text =
        lead['lastName'].toString();

    companyController.text =
        lead['company'].toString();

    selectedType =
        lead['type'].toString();

    trackingEnabled =
        lead['tracking'] == true;

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
                  Colors.transparent,
              insetPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 18,
                vertical: 20,
              ),
              child:
                  _buildLeadDialog(
                dialogContext:
                    dialogContext,
                setDialogState:
                    setDialogState,
                isEdit:
                    true,
                lead:
                    lead,
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
    return ConstrainedBox(
      constraints:
          const BoxConstraints(
        maxWidth: 600,
      ),
      child: Container(
        constraints:
            BoxConstraints(
          maxHeight:
              MediaQuery.of(
                    context,
                  ).size.height *
                  0.90,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.white,
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
            isEdit
                ? _buildEditDialogHeader(
                    dialogContext,
                  )
                : _buildDialogHeader(
                    dialogContext,
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
                    _formField(
                      controller:
                          emailController,
                      label:
                          'Email Address',
                      hint:
                          'john@example.com',
                      icon:
                          Icons
                              .email_outlined,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                              _formField(
                            controller:
                                firstNameController,
                            label:
                                'First Name',
                            hint:
                                'John',
                            icon:
                                Icons
                                    .person_outline,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child:
                              _formField(
                            controller:
                                lastNameController,
                            label:
                                'Last Name',
                            hint:
                                'Doe',
                            icon:
                                Icons
                                    .person_outline,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _formField(
                      controller:
                          companyController,
                      label:
                          'Company',
                      hint:
                          'Company name',
                      icon:
                          Icons
                              .business_outlined,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _buildDropdownField(
                      label:
                          'Type',
                      value:
                          selectedType,
                      items:
                          const [
                        'Email',
                        'WhatsApp',
                      ],
                      onChanged:
                          (value) {
                        setDialogState(
                          () {
                            selectedType =
                                value!;
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _buildTrackingSwitch(
                      setDialogState,
                    ),
                  ],
                ),
              ),
            ),

            _buildDialogFooter(
              dialogContext,
              isEdit,
              lead,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TRACKING SWITCH
  // ============================================================

  Widget _buildTrackingSwitch(
    StateSetter setDialogState,
  ) {
    return Container(
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF9FAFB,
        ),
        borderRadius:
            BorderRadius.circular(
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
        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        title:
            const Text(
          'Enable Tracking',
          style:
              TextStyle(
            color:
                textColor,
            fontSize:
                14,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle:
            const Text(
          'Track email opens and clicks',
          style:
              TextStyle(
            color:
                secondaryTextColor,
            fontSize:
                12,
          ),
        ),
        value:
            trackingEnabled,
        activeColor:
            primaryColor,
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
    );
  }

  // ============================================================
  // FORM FIELD
  // ============================================================

  Widget _formField({
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
            color:
                textColor,
            fontSize:
                13,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        TextField(
          controller:
              controller,
          keyboardType:
              keyboardType,
          style:
              const TextStyle(
            color:
                textColor,
            fontSize:
                14,
          ),
          decoration:
              InputDecoration(
            hintText:
                hint,
            hintStyle:
                const TextStyle(
              color:
                  Color(
                0xFF98A2B3,
              ),
              fontSize:
                  13,
            ),
            prefixIcon:
                Icon(
              icon,
              size:
                  19,
              color:
                  secondaryTextColor,
            ),
            filled:
                true,
            fillColor:
                Colors.white,
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal:
                  12,
            ),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                8,
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
                8,
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
                8,
              ),
              borderSide:
                  const BorderSide(
                color:
                    primaryColor,
                width:
                    1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color:
                textColor,
            fontSize:
                13,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        Container(
          width:
              double.infinity,
          height:
              48,
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                12,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.white,
            border:
                Border.all(
              color:
                  borderColor,
            ),
            borderRadius:
                BorderRadius.circular(
              8,
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
                  Colors.white,
              style:
                  const TextStyle(
                color:
                    textColor,
                fontSize:
                    14,
              ),
              items:
                  items.map(
                (
                  item,
                ) {
                  return DropdownMenuItem<
                      String>(
                    value:
                        item,
                    child:
                        Text(
                      item,
                    ),
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
  // DIALOG HEADER
  // ============================================================

  Widget _buildDialogHeader(
    BuildContext dialogContext,
  ) {
    return _dialogHeader(
      dialogContext,
      Icons.person_add_outlined,
      'Add New Lead',
      'Add a new lead to your database',
    );
  }

  // ============================================================
  // EDIT HEADER
  // ============================================================

  Widget _buildEditDialogHeader(
    BuildContext dialogContext,
  ) {
    return _dialogHeader(
      dialogContext,
      Icons.edit_outlined,
      'Edit Lead',
      'Update lead information',
    );
  }

  // ============================================================
  // COMMON HEADER
  // ============================================================

  Widget _dialogHeader(
    BuildContext dialogContext,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets
              .all(
        20,
      ),
      decoration:
          const BoxDecoration(
        color:
            Color(
          0xFF101828,
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
      child:
          Row(
        children: [
          Container(
            width:
                42,
            height:
                42,
            decoration:
                BoxDecoration(
              color:
                  primaryColor
                      .withOpacity(
                0.18,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child:
                Icon(
              icon,
              color:
                  const Color(
                0xFF7C9AFF,
              ),
            ),
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
                  title,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        19,
                    fontWeight:
                        FontWeight.w700,
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
                        Color(
                      0xFF98A2B3,
                    ),
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
                  Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOG FOOTER
  // ============================================================

  Widget _buildDialogFooter(
    BuildContext dialogContext,
    bool isEdit,
    Map<String, dynamic>? lead,
  ) {
    final saving =
        isEdit
            ? isUpdatingLead
            : isAddingLead;

    return Container(
      padding:
          const EdgeInsets
              .all(
        18,
      ),
      decoration:
          const BoxDecoration(
        color:
            Color(
          0xFFF9FAFB,
        ),
        borderRadius:
            BorderRadius.only(
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
            MainAxisAlignment
                .end,
        children: [
          OutlinedButton(
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
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          ElevatedButton.icon(
            onPressed:
                saving
                    ? null
                    : () {
                        if (isEdit) {
                          _updateLead(
                            dialogContext,
                            lead!,
                          );
                        } else {
                          _addLead(
                            dialogContext,
                          );
                        }
                      },
            icon:
                saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons
                            .save_outlined,
                        size: 18,
                      ),
            label:
                Text(
              saving
                  ? 'Saving...'
                  : isEdit
                      ? 'Save Changes'
                      : 'Save Lead',
            ),
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  primaryColor,
              foregroundColor:
                  Colors.white,
              elevation:
                  0,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
        behavior:
            SnackBarBehavior
                .floating,
      ),
    );
  }
}