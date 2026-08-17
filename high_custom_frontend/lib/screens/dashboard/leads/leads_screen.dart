import 'package:flutter/material.dart';
import '../../../services/leads_api.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF315BEF);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textColor = Color(0xFF101828);
  static const Color secondaryTextColor = Color(0xFF667085);
  static const Color borderColor = Color(0xFFD0D5DD);

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
  // PAGINATION
  // ============================================================

  int entriesPerPage = 10;
  int currentPage = 1;

  // ============================================================
  // DATE FILTER
  // ============================================================

  DateTime? fromDate;
  DateTime? toDate;

  bool todayOnly = false;

  // ============================================================
  // ADD / EDIT LEAD
  // ============================================================

  String selectedType = 'Email';

  bool trackingEnabled = true;
  bool isAddingLead = false;

  // ============================================================
  // DUMMY LEADS
  // ============================================================

 final List<Map<String, dynamic>> leads = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    searchController.addListener(_onSearchChanged);
  }

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
    searchController.removeListener(_onSearchChanged);

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
    List<Map<String, dynamic>> result = List.from(leads);

    final search = searchController.text.trim().toLowerCase();

    if (search.isNotEmpty) {
      result = result.where((lead) {
        final email = lead['email'].toString().toLowerCase();
        final firstName =
            lead['firstName'].toString().toLowerCase();
        final lastName =
            lead['lastName'].toString().toLowerCase();
        final company =
            lead['company'].toString().toLowerCase();

        return email.contains(search) ||
            firstName.contains(search) ||
            lastName.contains(search) ||
            company.contains(search);
      }).toList();
    }

    // ==========================================================
    // TODAY FILTER
    // ==========================================================

    if (todayOnly) {
      final now = DateTime.now();

      result = result.where((lead) {
        final date = lead['addedDate'] as DateTime;

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
        final date = lead['addedDate'] as DateTime;

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
        final date = lead['addedDate'] as DateTime;

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

    final start = (currentPage - 1) * entriesPerPage;

    if (start >= data.length) {
      return [];
    }

    final end =
        (start + entriesPerPage) > data.length
            ? data.length
            : start + entriesPerPage;

    return data.sublist(start, end);
  }

  // ============================================================
  // TOTAL PAGES
  // ============================================================

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
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 18 : 28),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(isMobile),
                  SizedBox(
                    height: isMobile ? 22 : 28,
                  ),
                  _buildMainContainer(isMobile),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader(bool isMobile) {
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
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage and organize your leads',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _showAddLeadDialog,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add Lead',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }

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
                  color: textColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Manage and organize your leads',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddLeadDialog,
          icon: const Icon(Icons.add, size: 20),
          label: const Text(
            'Add Lead',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
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

  Widget _buildMainContainer(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionBar(isMobile),
          const SizedBox(height: 22),
          _buildActiveFilters(),
          if (_hasActiveFilter)
            const SizedBox(height: 18),
          _buildTableControls(isMobile),
          const SizedBox(height: 20),
          if (isMobile)
            _buildMobileList()
          else
            _buildDesktopTable(),
          const SizedBox(height: 20),
          _buildPagination(),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BAR
  // ============================================================

  Widget _buildActionBar(bool isMobile) {
    final buttons = [
      _actionButton(
        icon: Icons.download_outlined,
        label: 'Download Excel',
        onPressed: _downloadExcel,
      ),
      _actionButton(
        icon: Icons.upload_file_outlined,
        label: 'Upload Excel',
        onPressed: _uploadExcel,
      ),
      _actionButton(
        icon: Icons.today_outlined,
        label: 'Today Added',
        active: todayOnly,
        onPressed: _toggleTodayFilter,
      ),
      _actionButton(
        icon: Icons.calendar_month_outlined,
        label: 'Date Filter',
        active:
            fromDate != null || toDate != null,
        onPressed: _showDateFilter,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: buttons[0]),
              const SizedBox(width: 8),
              Expanded(child: buttons[1]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: buttons[2]),
              const SizedBox(width: 8),
              Expanded(child: buttons[3]),
            ],
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: buttons,
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: active
              ? Colors.white
              : const Color(0xFF344054),
          backgroundColor:
              active ? primaryColor : Colors.white,
          side: BorderSide(
            color: active
                ? primaryColor
                : const Color(0xFFD0D5DD),
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTIVE FILTER
  // ============================================================

  bool get _hasActiveFilter {
    return todayOnly ||
        fromDate != null ||
        toDate != null;
  }

  Widget _buildActiveFilters() {
    if (!_hasActiveFilter) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFDCE5FF),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_outlined,
            size: 17,
            color: primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              todayOnly
                  ? 'Showing leads added today'
                  : 'Date: ${_formatDateOnly(fromDate)}'
                      '${toDate != null ? ' - ${_formatDateOnly(toDate)}' : ''}',
              style: const TextStyle(
                color: Color(0xFF344054),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _clearDateFilters,
            child: const Text(
              'Clear',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE CONTROLS
  // ============================================================

  Widget _buildTableControls(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Show',
                style: TextStyle(
                  color: Color(0xFF344054),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 7),
              _buildEntriesDropdown(),
              const SizedBox(width: 7),
              const Text(
                'entries',
                style: TextStyle(
                  color: Color(0xFF344054),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: TextField(
              controller: searchController,
              style: const TextStyle(
                color: textColor,
                fontSize: 14,
              ),
              cursorColor: primaryColor,
              decoration:
                  _searchDecoration(
                'Search leads...',
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Text(
          'Show',
          style: TextStyle(
            color: Color(0xFF344054),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 7),
        _buildEntriesDropdown(),
        const SizedBox(width: 7),
        const Text(
          'entries',
          style: TextStyle(
            color: Color(0xFF344054),
            fontSize: 13,
          ),
        ),
        const Spacer(),
        const Text(
          'Search:',
          style: TextStyle(
            color: Color(0xFF344054),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 270,
          height: 42,
          child: TextField(
            controller: searchController,
            style: const TextStyle(
              color: textColor,
              fontSize: 14,
            ),
            cursorColor: primaryColor,
            decoration:
                _searchDecoration(
              'Search leads...',
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ENTRIES DROPDOWN
  // ============================================================

  Widget _buildEntriesDropdown() {
    return Container(
      height: 40,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: borderColor,
        ),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child:
          DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: entriesPerPage,
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: textColor,
            fontSize: 13,
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
            if (value == null) return;

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
  // SEARCH DECORATION
  // ============================================================

  InputDecoration _searchDecoration(
    String hint,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF98A2B3),
        fontSize: 13,
      ),
      prefixIcon: const Icon(
        Icons.search,
        size: 19,
        color: Color(0xFF667085),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(8),
        borderSide:
            const BorderSide(
          color: borderColor,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(8),
        borderSide:
            const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(8),
        borderSide:
            const BorderSide(
          color: primaryColor,
          width: 1.5,
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(10),
        child: SingleChildScrollView(
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
              color: Color(0xFF344054),
              fontSize: 13,
            ),
            columnSpacing: 24,
            columns: const [
              DataColumn(
                label: Text('EMAIL'),
              ),
              DataColumn(
                label: Text('FIRST NAME'),
              ),
              DataColumn(
                label: Text('LAST NAME'),
              ),
              DataColumn(
                label: Text('COMPANY'),
              ),
              DataColumn(
                label: Text('TYPE'),
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
            rows: data.map((lead) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 190,
                      child: Text(
                        lead['email'].toString(),
                        overflow:
                            TextOverflow.ellipsis,
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
                      width: 150,
                      child: Text(
                        lead['company']
                            .toString(),
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    _typeBadge(
                      lead['type'].toString(),
                    ),
                  ),
                  DataCell(
                    _trackingBadge(
                      lead['tracking'] == true,
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatDateTime(
                        lead['addedDate'],
                      ),
                    ),
                  ),

                  // ==================================================
                  // VIEW + EDIT + DELETE
                  // ==================================================

                  DataCell(
                    Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'View Lead',
                          onPressed: () {
                            _viewLead(lead);
                          },
                          icon: const Icon(
                            Icons.visibility_outlined,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit Lead',
                          onPressed: () {
                            _showEditLeadDialog(
                              lead,
                            );
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(
                              0xFF344054,
                            ),
                            size: 20,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete Lead',
                          onPressed: () {
                            _deleteLead(lead);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE LIST
  // ============================================================

  Widget _buildMobileList() {
    final data = paginatedLeads;

    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: data.map((lead) {
        return _buildLeadCard(lead);
      }).toList(),
    );
  }

  // ============================================================
  // MOBILE CARD
  // ============================================================

  Widget _buildLeadCard(
    Map<String, dynamic> lead,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEFF4FF),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lead['firstName']} ${lead['lastName']}',
                      style:
                          const TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lead['email'].toString(),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // VIEW
              IconButton(
                tooltip: 'View Lead',
                onPressed: () {
                  _viewLead(lead);
                },
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: primaryColor,
                  size: 21,
                ),
              ),

              // EDIT
              IconButton(
                tooltip: 'Edit Lead',
                onPressed: () {
                  _showEditLeadDialog(lead);
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF344054),
                  size: 21,
                ),
              ),

              // DELETE
              IconButton(
                tooltip: 'Delete Lead',
                onPressed: () {
                  _deleteLead(lead);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _mobileInfoRow(
            'Company',
            lead['company'].toString(),
            Icons.business_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _mobileInfoRow(
                  'Type',
                  lead['type'].toString(),
                  Icons.category_outlined,
                ),
              ),
              Expanded(
                child: _mobileInfoRow(
                  'Tracking',
                  lead['tracking'] == true
                      ? 'Enabled'
                      : 'Disabled',
                  Icons.track_changes_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _mobileInfoRow(
            'Added Date',
            _formatDateTime(
              lead['addedDate'],
            ),
            Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE INFO
  // ============================================================

  Widget _mobileInfoRow(
    String title,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: secondaryTextColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color:
                      secondaryTextColor,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TYPE BADGE
  // ============================================================

  Widget _typeBadge(String type) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Color(0xFF344054),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // TRACKING BADGE
  // ============================================================

  Widget _trackingBadge(bool enabled) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFFECFDF3)
            : const Color(0xFFF2F4F7),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            enabled
                ? Icons.check_circle
                : Icons.cancel_outlined,
            size: 14,
            color: enabled
                ? const Color(0xFF027A48)
                : secondaryTextColor,
          ),
          const SizedBox(width: 5),
          Text(
            enabled
                ? 'Enabled'
                : 'Disabled',
            style: TextStyle(
              color: enabled
                  ? const Color(0xFF027A48)
                  : secondaryTextColor,
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
        vertical: 55,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 48,
            color: Color(0xFF98A2B3),
          ),
          const SizedBox(height: 12),
          const Text(
            'No leads found',
            style: TextStyle(
              color: Color(0xFF344054),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Try changing your search or filters.',
            style: TextStyle(
              color: secondaryTextColor,
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
    final total = filteredLeads.length;

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.end,
      children: [
        Text(
          'Total: $total',
          style: const TextStyle(
            color: secondaryTextColor,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: currentPage > 1
              ? () {
                  setState(() {
                    currentPage--;
                  });
                }
              : null,
          child: const Text('Previous'),
        ),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius:
                BorderRadius.circular(8),
          ),
          child: Text(
            '$currentPage / $totalPages',
            style: const TextStyle(
              color: primaryColor,
              fontWeight:
                  FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: currentPage < totalPages
              ? () {
                  setState(() {
                    currentPage++;
                  });
                }
              : null,
          child: const Text('Next'),
        ),
      ],
    );
  }

  // ============================================================
  // VIEW LEAD
  // ============================================================

  void _viewLead(
    Map<String, dynamic> lead,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor:
              Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 550,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  // HEADER
                  Container(
                    padding:
                        const EdgeInsets.all(20),
                    decoration:
                        const BoxDecoration(
                      color: Color(0xFF101828),
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
                            color: primaryColor
                                .withOpacity(
                              0.18,
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
                                .visibility_outlined,
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
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Lead Details',
                                style:
                                    TextStyle(
                                  color:
                                      Colors
                                          .white,
                                  fontSize:
                                      19,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                              SizedBox(
                                  height: 3),
                              Text(
                                'View complete lead information',
                                style:
                                    TextStyle(
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
                          onPressed: () {
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

                  // BODY
                  Padding(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child: Column(
                      children: [
                        _viewInfoRow(
                          'Email Address',
                          lead['email']
                              .toString(),
                          Icons
                              .email_outlined,
                        ),
                        _viewInfoRow(
                          'First Name',
                          lead['firstName']
                              .toString(),
                          Icons
                              .person_outline,
                        ),
                        _viewInfoRow(
                          'Last Name',
                          lead['lastName']
                              .toString(),
                          Icons
                              .person_outline,
                        ),
                        _viewInfoRow(
                          'Company',
                          lead['company']
                              .toString(),
                          Icons
                              .business_outlined,
                        ),
                        _viewInfoRow(
                          'Type',
                          lead['type']
                              .toString(),
                          Icons
                              .category_outlined,
                        ),
                        _viewInfoRow(
                          'Tracking',
                          lead['tracking'] ==
                                  true
                              ? 'Enabled'
                              : 'Disabled',
                          Icons
                              .track_changes_outlined,
                        ),
                        _viewInfoRow(
                          'Added Date',
                          _formatDateTime(
                            lead['addedDate'],
                          ),
                          Icons
                              .calendar_today_outlined,
                        ),
                      ],
                    ),
                  ),

                  // FOOTER
                  Container(
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFFF9FAFB),
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
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                            );
                          },
                          child:
                              const Text(
                            'Close',
                          ),
                        ),
                        const SizedBox(
                            width: 10),
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
                            size: 18,
                          ),
                          label:
                              const Text(
                            'Edit Lead',
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                primaryColor,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
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
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFEFF4FF),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
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
                        secondaryTextColor,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style:
                      const TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
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
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 600,
                ),
                child: Container(
                  constraints:
                      BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context)
                                .size
                                .height *
                            0.90,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      _buildEditDialogHeader(
                        dialogContext,
                      ),

                      Flexible(
                        child:
                            SingleChildScrollView(
                          padding:
                              const EdgeInsets.all(
                            22,
                          ),
                          child: Column(
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
                                          'Smith',
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
                                    'ABC Company',
                                icon:
                                    Icons
                                        .business_outlined,
                              ),

                              const SizedBox(
                                height: 16,
                              ),

                              _dropdownField(
                                label: 'Type',
                                value:
                                    selectedType,
                                items: const [
                                  'Email',
                                  'WhatsApp',
                                ],
                                onChanged:
                                    (value) {
                                  if (value ==
                                      null) {
                                    return;
                                  }

                                  setDialogState(
                                    () {
                                      selectedType =
                                          value;
                                    },
                                  );
                                },
                              ),

                              const SizedBox(
                                height: 16,
                              ),

                              Container(
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFF9FAFB,
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
                                      0xFFE4E7EC,
                                    ),
                                  ),
                                ),
                                child:
                                    SwitchListTile(
                                  contentPadding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        14,
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
                                          FontWeight
                                              .w600,
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
                              ),
                            ],
                          ),
                        ),
                      ),

                      // FOOTER
                      Container(
                        padding:
                            const EdgeInsets.all(
                          18,
                        ),
                        decoration:
                            const BoxDecoration(
                          color:
                              Color(0xFFF9FAFB),
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
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
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
                                width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                _updateLead(
                                  dialogContext,
                                  lead,
                                );
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .save_outlined,
                                size: 18,
                              ),
                              label:
                                  const Text(
                                'Save Changes',
                              ),
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    primaryColor,
                                foregroundColor:
                                    Colors.white,
                                elevation: 0,
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
  // EDIT DIALOG HEADER
  // ============================================================

  Widget _buildEditDialogHeader(
    BuildContext dialogContext,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF101828),
        borderRadius:
            BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  primaryColor.withOpacity(
                0.18,
              ),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF7C9AFF),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Lead',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Update lead information',
                  style: TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 12,
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
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD LEAD DIALOG
  // ============================================================

  void _showAddLeadDialog() {
    emailController.clear();
    firstNameController.clear();
    lastNameController.clear();
    companyController.clear();

    selectedType = 'Email';
    trackingEnabled = true;

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
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 600,
                ),
                child: Container(
                  constraints:
                      BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context)
                                .size
                                .height *
                            0.90,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      _buildDialogHeader(
                        dialogContext,
                      ),
                      Flexible(
                        child:
                            SingleChildScrollView(
                          padding:
                              const EdgeInsets.all(
                            22,
                          ),
                          child: Column(
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
                                          'Smith',
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
                                    'ABC Company',
                                icon:
                                    Icons
                                        .business_outlined,
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              _dropdownField(
                                label: 'Type',
                                value:
                                    selectedType,
                                items: const [
                                  'Email',
                                  'WhatsApp',
                                ],
                                onChanged:
                                    (value) {
                                  if (value ==
                                      null) {
                                    return;
                                  }

                                  setDialogState(
                                    () {
                                      selectedType =
                                          value;
                                    },
                                  );
                                },
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Container(
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFF9FAFB,
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
                                      0xFFE4E7EC,
                                    ),
                                  ),
                                ),
                                child:
                                    SwitchListTile(
                                  contentPadding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        14,
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
                                          FontWeight
                                              .w600,
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
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildDialogFooter(
                        dialogContext,
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
  // DIALOG HEADER
  // ============================================================

  Widget _buildDialogHeader(
    BuildContext dialogContext,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF101828),
        borderRadius:
            BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  primaryColor.withOpacity(
                0.18,
              ),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_add_outlined,
              color: Color(0xFF7C9AFF),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Lead',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Add a new lead to your database',
                  style: TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 12,
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
              color: Colors.white,
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
  ) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
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
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
              );
            },
            child: const Text(
              'Cancel',
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () {
              _addLead(dialogContext);
            },
            icon: const Icon(
              Icons.person_add_outlined,
              size: 18,
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
            ),
          ),
        ],
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
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: primaryColor,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF98A2B3),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              size: 19,
              color: secondaryTextColor,
            ),
            filled: true,
            fillColor: Colors.white,
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8),
              borderSide:
                  const BorderSide(
                color: borderColor,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8),
              borderSide:
                  const BorderSide(
                color: borderColor,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8),
              borderSide:
                  const BorderSide(
                color: primaryColor,
                width: 1.5,
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

  Widget _dropdownField({
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
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          height: 48,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: borderColor,
            ),
            borderRadius:
                BorderRadius.circular(8),
          ),
          child:
              DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: textColor,
                fontSize: 14,
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADD LEAD
  // ============================================================

  Future<void> _addLead(
    BuildContext dialogContext,
  ) async {
    final email = emailController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final company = companyController.text.trim();

    if (email.isEmpty) {
      _showMessage('Email is Required.');
      return;
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showMessage('Email is Required.');
      return;
    }

    setState(() {
      isAddingLead = true;
    });

    try {
      final response = await LeadsApi.createLead(
        email: email,
        firstName: firstName,
        lastName: lastName,
        company: company,
        type: selectedType,
        tracking: trackingEnabled,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        Navigator.pop(dialogContext);
        _showMessage(
          response['message'] ?? 'Lead added successfully.',
        );
        emailController.clear();
        firstNameController.clear();
        lastNameController.clear();
        companyController.clear();
        selectedType = 'Email';
        trackingEnabled = true;
      } else {
        _showMessage(
          response['message'] ?? 'Unable to add lead.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to add lead. Please try again.');
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
  // UPDATE LEAD
  // ============================================================

  void _updateLead(
    BuildContext dialogContext,
    Map<String, dynamic> lead,
  ) {
    final email = emailController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final company = companyController.text.trim();

    if (email.isEmpty) {
      _showMessage('Email is required.');
      return;
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    setState(() {
      lead['email'] = email;
      lead['firstName'] = firstName;
      lead['lastName'] = lastName;
      lead['company'] = company;
      lead['type'] = selectedType;
      lead['tracking'] = trackingEnabled;
    });

    Navigator.pop(dialogContext);

    _showMessage('Lead updated successfully.');
  }

  // ============================================================
  // DELETE LEAD
  // ============================================================

  void _deleteLead(
    Map<String, dynamic> lead,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Delete Lead',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete '
            '${lead['firstName']} ${lead['lastName']}?',
            style: const TextStyle(
              color: secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  leads.removeWhere((item) {
                    final sameEmail = item['email'] == lead['email'];
                    final sameName =
                        item['firstName'] == lead['firstName'] &&
                            item['lastName'] == lead['lastName'];
                    return sameEmail && sameName;
                  });
                  currentPage = 1;
                });
                _showMessage('Lead deleted successfully.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // TODAY FILTER
  // ============================================================

  void _toggleTodayFilter() {
    setState(() {
      todayOnly = !todayOnly;

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
    DateTime? tempFromDate = fromDate;
    DateTime? tempToDate = toDate;

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
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.all(
                          20,
                        ),
                        decoration:
                            const BoxDecoration(
                          color:
                              Color(0xFF101828),
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
                              width: 42,
                              height: 42,
                              decoration:
                                  BoxDecoration(
                                color:
                                    primaryColor
                                        .withOpacity(
                                  0.18,
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
                                    .calendar_month_outlined,
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
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    'Filter Leads',
                                    style:
                                        TextStyle(
                                      color:
                                          Colors
                                              .white,
                                      fontSize:
                                          18,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 3,
                                  ),
                                  Text(
                                    'Select a date range to filter leads',
                                    style:
                                        TextStyle(
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
                              onPressed: () {
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
                            const EdgeInsets.all(
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              'Date Range',
                              style:
                                  TextStyle(
                                color:
                                    textColor,
                                fontSize: 14,
                                fontWeight:
                                    FontWeight
                                        .w700,
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
                                            DateTime
                                                .now(),
                                      );

                                      if (date !=
                                          null) {
                                        setDialogState(
                                          () {
                                            tempFromDate =
                                                date;

                                            if (tempToDate !=
                                                    null &&
                                                tempToDate!.isBefore(
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
                                            DateTime
                                                .now(),
                                      );

                                      if (date !=
                                          null) {
                                        if (tempFromDate !=
                                                null &&
                                            date.isBefore(
                                              tempFromDate!,
                                            )) {
                                          _showMessage(
                                            'To Date cannot be before From Date.',
                                          );
                                          return;
                                        }

                                        setDialogState(
                                          () {
                                            tempToDate =
                                                date;
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
                                    textColor,
                                fontSize: 14,
                                fontWeight:
                                    FontWeight
                                        .w700,
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
                                            now.subtract(
                                          const Duration(
                                            days: 6,
                                          ),
                                        );
                                        tempToDate =
                                            now;
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
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets.all(
                          18,
                        ),
                        decoration:
                            const BoxDecoration(
                          color:
                              Color(0xFFF9FAFB),
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
                              onPressed: () {
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
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  fromDate =
                                      tempFromDate;
                                  toDate =
                                      tempToDate;
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
                                    primaryColor,
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
  // SINGLE DATE PICKER
  // ============================================================

  Future<DateTime?> _pickSingleDate(
    BuildContext context,
    DateTime initialDate,
  ) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textColor,
            ),
            datePickerTheme:
                const DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor:
                  Color(0xFF101828),
              headerForegroundColor:
                  Colors.white,
            ),
          ),
          child: child!,
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
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: borderColor,
          ),
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: secondaryTextColor,
            ),
            const SizedBox(width: 9),
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
                          secondaryTextColor,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date == null
                        ? 'Select date'
                        : _formatDateOnly(date),
                    style:
                        TextStyle(
                      color: date == null
                          ? const Color(
                              0xFF98A2B3,
                            )
                          : textColor,
                      fontSize: 13,
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
      onPressed: onPressed,
      style:
          OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(
          color: Color(0xFFD0D5DD),
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
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // CLEAR FILTERS
  // ============================================================

  void _clearDateFilters() {
    setState(() {
      fromDate = null;
      toDate = null;
      todayOnly = false;
      currentPage = 1;
    });
  }

  // ============================================================
  // DOWNLOAD EXCEL
  // ============================================================

  void _downloadExcel() {
    _showMessage(
      'Excel download will be connected to the backend.',
    );
  }

  // ============================================================
  // UPLOAD EXCEL
  // ============================================================

  void _uploadExcel() {
    _showMessage(
      'Excel upload will be connected to the backend.',
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateOnly(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  String _formatDateTime(dynamic value) {
    if (value == null) {
      return '-';
    }

    DateTime? date;

    if (value is DateTime) {
      date = value;
    } else {
      try {
        date = DateTime.parse(
          value.toString(),
        );
      } catch (_) {
        return value.toString();
      }
    }

    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}