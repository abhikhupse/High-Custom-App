import 'dart:async';

import 'package:flutter/material.dart';

import 'create_sequence_screen.dart';
import '../../../services/sequence_api.dart';

class MasterListScreen extends StatefulWidget {
  const MasterListScreen({super.key});

  @override
  State<MasterListScreen> createState() => _MasterListScreenState();
}

class _MasterListScreenState extends State<MasterListScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController searchController =
      TextEditingController();

  Timer? _searchDebounce;

  // ============================================================
  // PAGINATION
  // ============================================================

  int entriesPerPage = 10;
  int currentPage = 1;
  int totalPages = 1;
  int totalSequences = 0;

  // ============================================================
  // DATA
  // ============================================================

  List<Map<String, dynamic>> sequences = [];

  // ============================================================
  // STATES
  // ============================================================

  bool isLoading = false;
  String? errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadSequences(page: 1);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD SEQUENCES
  // ============================================================

  Future<void> _loadSequences({
    int page = 1,
  }) async {
    if (!mounted) return;

    if (page < 1) {
      page = 1;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await SequenceApi.getSequences(
        page: page,
        limit: entriesPerPage,
        search: searchController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final dynamic rawData = result['data'];

        final List<dynamic> apiData =
            rawData is List ? rawData : [];

        final dynamic rawPagination =
            result['pagination'];

        final Map<String, dynamic> pagination =
            rawPagination is Map
                ? Map<String, dynamic>.from(rawPagination)
                : {};

        final int backendPage = _toInt(
          pagination['page'],
          fallback: page,
        );

        final int backendLimit = _toInt(
          pagination['limit'],
          fallback: entriesPerPage,
        );

        final int backendTotal = _toInt(
          pagination['total'],
          fallback: apiData.length,
        );

        int backendTotalPages = _toInt(
          pagination['totalPages'],
          fallback: 1,
        );

        if (backendTotalPages < 1) {
          backendTotalPages = 1;
        }

        setState(() {
          sequences = apiData
              .whereType<Map>()
              .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();

          currentPage = backendPage;
          totalPages = backendTotalPages;
          totalSequences = backendTotal;

          if (backendLimit > 0) {
            entriesPerPage = backendLimit;
          }

          isLoading = false;
        });

        return;
      }

      setState(() {
        isLoading = false;

        errorMessage =
            result['message']?.toString() ??
                'Unable to fetch sequences.';
      });

      if (result['sessionExpired'] == true) {
        _showMessage(
          result['message']?.toString() ??
              'Session expired. Please login again.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load sequences.';
      });

      debugPrint(
        'LOAD SEQUENCES ERROR: $e',
      );
    }
  }

  // ============================================================
  // INTEGER HELPER
  // ============================================================

  int _toInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () async {
        if (!mounted) return;

        await _loadSequences(
          page: 1,
        );
      },
    );

    setState(() {});
  }

  // ============================================================
  // CLEAR SEARCH
  // ============================================================

  Future<void> _clearSearch() async {
    _searchDebounce?.cancel();

    searchController.clear();

    FocusScope.of(context).unfocus();

    setState(() {});

    await _loadSequences(
      page: 1,
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshSequences() async {
    await _loadSequences(
      page: currentPage,
    );
  }

  // ============================================================
  // CHANGE PAGE
  // ============================================================

  Future<void> _goToPage(
    int page,
  ) async {
    if (isLoading) return;

    if (page < 1) return;

    if (page > totalPages) return;

    if (page == currentPage) return;

    await _loadSequences(
      page: page,
    );
  }

  // ============================================================
  // CHANGE ENTRIES PER PAGE
  // ============================================================

  Future<void> _changeEntriesPerPage(
    int value,
  ) async {
    if (value == entriesPerPage) {
      return;
    }

    setState(() {
      entriesPerPage = value;
      currentPage = 1;
    });

    await _loadSequences(
      page: 1,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // IMPORTANT:
    // Use the actual screen width.
    //
    // Do NOT use LayoutBuilder constraints here because
    // MasterListScreen is inside the dashboard/sidebar layout.
    final double screenWidth =
        MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            isMobile ? 16 : 28,
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
                    isMobile ? 24 : 30,
              ),

              _buildSequenceContainer(
                isMobile,
              ),
            ],
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
            'Sequence List',
            style: TextStyle(
              color: Color(0xFF101828),
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Manage your automated email campaign sequences',
            style: TextStyle(
              color: Color(0xFF667085),
              fontSize: 15,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  isLoading
                      ? null
                      : _addNewSequence,
              icon: const Icon(
                Icons.add_circle_outline,
              ),
              label: const Text(
                'Add New Sequence',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF315BEF),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Sequence List',
                style: TextStyle(
                  color:
                      Color(0xFF101828),
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Manage your automated email campaign sequences',
                style: TextStyle(
                  color:
                      Color(0xFF667085),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        ElevatedButton.icon(
          onPressed:
              isLoading
                  ? null
                  : _addNewSequence,
          icon: const Icon(
            Icons.add_circle_outline,
          ),
          label: const Text(
            'Add New Sequence',
          ),
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF315BEF),
            foregroundColor:
                Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
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

  Widget _buildSequenceContainer(
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
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildTableControls(
            isMobile,
          ),

          const SizedBox(height: 22),

          if (isLoading)
            _buildLoadingState()
          else if (errorMessage != null)
            _buildErrorState()
          else if (sequences.isEmpty)
            _buildEmptyState()
          else if (isMobile)
            _buildMobileTable()
          else
            _buildDesktopTable(),

          const SizedBox(height: 20),

          _buildPagination(),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE CONTROLS
  // ============================================================

  Widget _buildTableControls(
    bool isMobile,
  ) {
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
                  fontSize: 14,
                ),
              ),

              const SizedBox(width: 10),

              _buildEntriesDropdown(),

              const SizedBox(width: 10),

              const Text(
                'entries',
                style: TextStyle(
                  color: Color(0xFF344054),
                  fontSize: 14,
                ),
              ),

              const Spacer(),

              IconButton(
                tooltip: 'Refresh',
                onPressed:
                    isLoading
                        ? null
                        : _refreshSequences,
                icon: const Icon(
                  Icons.refresh,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSearchField(
            isMobile: true,
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
            fontSize: 14,
          ),
        ),

        const SizedBox(width: 8),

        _buildEntriesDropdown(),

        const SizedBox(width: 8),

        const Text(
          'entries',
          style: TextStyle(
            color: Color(0xFF344054),
            fontSize: 14,
          ),
        ),

        const Spacer(),

        const Text(
          'Search:',
          style: TextStyle(
            color: Color(0xFF344054),
            fontSize: 14,
          ),
        ),

        const SizedBox(width: 10),

        _buildSearchField(
          isMobile: false,
        ),

        const SizedBox(width: 8),

        IconButton(
          tooltip: 'Refresh',
          onPressed:
              isLoading
                  ? null
                  : _refreshSequences,
          icon: const Icon(
            Icons.refresh,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH FIELD
  // ============================================================

  Widget _buildSearchField({
    required bool isMobile,
  }) {
    return SizedBox(
      width:
          isMobile
              ? double.infinity
              : 260,
      height: 42,
      child: TextField(
        controller:
            searchController,
        onChanged:
            _onSearchChanged,
        decoration:
            _searchDecoration(
          'Search sequence...',
        ).copyWith(
          suffixIcon:
              searchController
                      .text
                      .isNotEmpty
                  ? IconButton(
                      onPressed:
                          _clearSearch,
                      icon: const Icon(
                        Icons.clear,
                        size: 20,
                      ),
                    )
                  : null,
        ),
      ),
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
        border: Border.all(
          color:
              const Color(0xFFD0D5DD),
        ),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child:
          DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: entriesPerPage,
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
          onChanged:
              isLoading
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      _changeEntriesPerPage(
                        value,
                      );
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
      prefixIcon:
          const Icon(Icons.search),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(8),
        borderSide:
            const BorderSide(
          color: Color(0xFFD0D5DD),
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(8),
        borderSide:
            const BorderSide(
          color: Color(0xFFD0D5DD),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(8),
        borderSide:
            const BorderSide(
          color: Color(0xFF315BEF),
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return const Padding(
      padding:
          EdgeInsets.symmetric(
        vertical: 70,
      ),
      child: Center(
        child:
            CircularProgressIndicator(
          color: Color(0xFF315BEF),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 50,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),

          const SizedBox(height: 12),

          Text(
            errorMessage ??
                'Something went wrong.',
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed:
                isLoading
                    ? null
                    : () {
                        _loadSequences(
                          page: currentPage,
                        );
                      },
            icon:
                const Icon(Icons.refresh),
            label:
                const Text('Retry'),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF315BEF),
              foregroundColor:
                  Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE TABLE
  // ============================================================

  Widget _buildMobileTable() {
    if (sequences.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 46,
            dataRowMinHeight: 58,
            dataRowMaxHeight: 70,
            columnSpacing: 16,
            horizontalMargin: 12,
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFF101828),
            ),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            dataTextStyle: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 12,
            ),
            columns: const [
              DataColumn(label: Text('STEP')),
              DataColumn(label: Text('GAP DAYS')),
              DataColumn(label: Text('VARIANT')),
              DataColumn(label: Text('MESSAGE')),
              DataColumn(label: Text('SUBJECT')),
              DataColumn(label: Text('BUSINESS TYPE')),
              DataColumn(label: Text('WHATSAPP')),
              DataColumn(label: Text('CREATED AT')),
              DataColumn(label: Text('UPDATED AT')),
              DataColumn(label: Text('DELETE')),
              DataColumn(label: Text('EDIT')),
              DataColumn(label: Text('VIEW')),
            ],
            rows: sequences.map((sequence) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      sequence['step']?.toString() ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      sequence['gapDays']?.toString() ?? '-',
                    ),
                  ),
                  DataCell(
                    _variantBadge(
                      sequence['variant']?.toString() ?? '-',
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        sequence['content']?.toString() ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        sequence['subject']?.toString() ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 140,
                      child: Text(
                        sequence['type']?.toString() ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        _getWhatsApp(sequence),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatDateTime(sequence['createdAt']),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatDateTime(sequence['updatedAt']),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      tooltip: 'Delete sequence',
                      onPressed: () => _deleteSequence(sequence),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                  DataCell(
                    ElevatedButton(
                      onPressed: () => _editSequence(sequence),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF315BEF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    OutlinedButton(
                      onPressed: () => _viewSequence(sequence),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF315BEF),
                        side: const BorderSide(
                          color: Color(0xFF315BEF),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
  // VARIANT BADGE
  // ============================================================

  Widget _variantBadge(
    String variant,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFEFF4FF),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        'Variant $variant',
        style:
            const TextStyle(
          color:
              Color(0xFF315BEF),
          fontSize: 12,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE INFO ROW
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
          size: 20,
          color:
              const Color(0xFF667085),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  color:
                      Color(0xFF667085),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color:
                      Color(0xFF101828),
                  fontSize: 14,
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
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable() {
    if (sequences.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color:
              const Color(0xFFE4E7EC),
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              minWidth: 1500,
            ),
            child: DataTable(
              horizontalMargin: 16,
              columnSpacing: 24,

              headingRowHeight: 52,

              dataRowMinHeight: 60,
              dataRowMaxHeight: 90,

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

              // ==================================================
              // EXACT COLUMN ORDER
              // ==================================================

              columns: const [
                DataColumn(
                  label: Text('STEP'),
                ),
                DataColumn(
                  label: Text('GAP DAYS'),
                ),
                DataColumn(
                  label: Text('VARIANT'),
                ),
                DataColumn(
                  label: Text('MESSAGE'),
                ),
                DataColumn(
                  label: Text('SUBJECT'),
                ),
                DataColumn(
                  label: Text('BUSINESS TYPE'),
                ),
                DataColumn(
                  label: Text('WHATSAPP'),
                ),
                DataColumn(
                  label: Text('CREATED AT'),
                ),
                DataColumn(
                  label: Text('UPDATED AT'),
                ),
                DataColumn(
                  label: Text('DELETE'),
                ),
                DataColumn(
                  label: Text('EDIT'),
                ),
                DataColumn(
                  label: Text('VIEW'),
                ),
              ],

              // ==================================================
              // ROWS
              // ==================================================

              rows: sequences.map<DataRow>(
                (sequence) {
                  return DataRow(
                    cells: [
                      // STEP
                      DataCell(
                        Text(
                          sequence['step']
                                  ?.toString() ??
                              '-',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w700,
                            color:
                                Color(0xFF101828),
                          ),
                        ),
                      ),

                      // GAP DAYS
                      DataCell(
                        Text(
                          sequence['gapDays']
                                  ?.toString() ??
                              '-',
                        ),
                      ),

                      // VARIANT
                      DataCell(
                        _variantBadge(
                          sequence['variant']
                                  ?.toString() ??
                              '-',
                        ),
                      ),

                      // MESSAGE
                      DataCell(
                        SizedBox(
                          width: 250,
                          child: Text(
                            sequence['content']
                                    ?.toString() ??
                                '-',
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                        ),
                      ),

                      // SUBJECT
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            sequence['subject']
                                    ?.toString() ??
                                '-',
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                        ),
                      ),

                      // BUSINESS TYPE
                      DataCell(
                        SizedBox(
                          width: 140,
                          child: Text(
                            sequence['type']
                                    ?.toString() ??
                                '-',
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                        ),
                      ),

                      // WHATSAPP
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Text(
                            _getWhatsApp(
                              sequence,
                            ),
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                        ),
                      ),

                      // CREATED AT
                      DataCell(
                        Text(
                          _formatDateTime(
                            sequence[
                                'createdAt'],
                          ),
                        ),
                      ),

                      // UPDATED AT
                      DataCell(
                        Text(
                          _formatDateTime(
                            sequence[
                                'updatedAt'],
                          ),
                        ),
                      ),

                      // DELETE
                      DataCell(
                        IconButton(
                          tooltip:
                              'Delete sequence',
                          onPressed: () {
                            _deleteSequence(
                              sequence,
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .delete_outline,
                            color:
                                Colors.red,
                            size: 21,
                          ),
                        ),
                      ),

                      // EDIT
                      DataCell(
                        ElevatedButton(
                          onPressed: () {
                            _editSequence(
                              sequence,
                            );
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
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                7,
                              ),
                            ),
                          ),
                          child:
                              const Text(
                            'Edit',
                            style:
                                TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ),

                      // VIEW
                      DataCell(
                        OutlinedButton(
                          onPressed: () {
                            _viewSequence(
                              sequence,
                            );
                          },
                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                const Color(
                              0xFF315BEF,
                            ),
                            side:
                                const BorderSide(
                              color:
                                  Color(
                                0xFF315BEF,
                              ),
                            ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                7,
                              ),
                            ),
                          ),
                          child:
                              const Text(
                            'View',
                            style:
                                TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    final bool searching =
        searchController.text
            .trim()
            .isNotEmpty;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 50,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.email_outlined,
            size: 45,
            color:
                Color(0xFF98A2B3),
          ),

          const SizedBox(height: 12),

          Text(
            searching
                ? 'No sequences found'
                : 'No sequences available',
            style: const TextStyle(
              color:
                  Color(0xFF344054),
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          if (searching) ...[
            const SizedBox(height: 6),

            const Text(
              'Try changing your search.',
              style: TextStyle(
                color:
                    Color(0xFF667085),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    if (totalSequences == 0) {
      return const SizedBox.shrink();
    }

    final int start =
        ((currentPage - 1) *
                entriesPerPage) +
            1;

    final int end =
        ((currentPage *
                    entriesPerPage) >
                totalSequences)
            ? totalSequences
            : currentPage *
                entriesPerPage;

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final bool isMobile =
            constraints.maxWidth < 600;

        return Container(
          margin:
              const EdgeInsets.only(
            top: 8,
          ),
          padding:
              const EdgeInsets.only(
            top: 20,
          ),
          decoration:
              const BoxDecoration(
            border: Border(
              top: BorderSide(
                color:
                    Color(0xFFE4E7EC),
              ),
            ),
          ),
          child: isMobile
              ? _buildMobilePagination(
                  start,
                  end,
                )
              : _buildDesktopPagination(
                  start,
                  end,
                ),
        );
      },
    );
  }

  // ============================================================
  // DESKTOP PAGINATION
  // ============================================================

  Widget _buildDesktopPagination(
    int start,
    int end,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Showing $start–$end of $totalSequences entries',
            style: const TextStyle(
              color:
                  Color(0xFF667085),
              fontSize: 13,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),

        Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            _paginationIconButton(
              icon: Icons
                  .keyboard_double_arrow_left_rounded,
              tooltip: 'First page',
              enabled:
                  currentPage > 1 &&
                      !isLoading,
              onPressed: () {
                _goToPage(1);
              },
            ),

            const SizedBox(width: 6),

            _paginationIconButton(
              icon:
                  Icons.chevron_left_rounded,
              tooltip: 'Previous',
              enabled:
                  currentPage > 1 &&
                      !isLoading,
              onPressed: () {
                _goToPage(
                  currentPage - 1,
                );
              },
            ),

            const SizedBox(width: 8),

            _buildImprovedPageNumbers(),

            const SizedBox(width: 8),

            _paginationIconButton(
              icon:
                  Icons.chevron_right_rounded,
              tooltip: 'Next',
              enabled:
                  currentPage <
                          totalPages &&
                      !isLoading,
              onPressed: () {
                _goToPage(
                  currentPage + 1,
                );
              },
            ),

            const SizedBox(width: 6),

            _paginationIconButton(
              icon: Icons
                  .keyboard_double_arrow_right_rounded,
              tooltip: 'Last page',
              enabled:
                  currentPage <
                          totalPages &&
                      !isLoading,
              onPressed: () {
                _goToPage(
                  totalPages,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE PAGINATION
  // ============================================================

  Widget _buildMobilePagination(
    int start,
    int end,
  ) {
    return Column(
      children: [
        Text(
          'Showing $start–$end of $totalSequences',
          style: const TextStyle(
            color:
                Color(0xFF667085),
            fontSize: 13,
            fontWeight:
                FontWeight.w500,
          ),
        ),

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            _paginationIconButton(
              icon:
                  Icons.chevron_left_rounded,
              tooltip: 'Previous',
              enabled:
                  currentPage > 1 &&
                      !isLoading,
              onPressed: () {
                _goToPage(
                  currentPage - 1,
                );
              },
            ),

            const SizedBox(width: 8),

            _currentPageIndicator(),

            const SizedBox(width: 8),

            _paginationIconButton(
              icon:
                  Icons.chevron_right_rounded,
              tooltip: 'Next',
              enabled:
                  currentPage <
                          totalPages &&
                      !isLoading,
              onPressed: () {
                _goToPage(
                  currentPage + 1,
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          'Page $currentPage of $totalPages',
          style: const TextStyle(
            color:
                Color(0xFF98A2B3),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAGE NUMBERS
  // ============================================================

  Widget _buildImprovedPageNumbers() {
    final List<int?> pages = [];

    if (totalPages <= 7) {
      for (
        int i = 1;
        i <= totalPages;
        i++
      ) {
        pages.add(i);
      }
    } else {
      pages.add(1);

      if (currentPage > 4) {
        pages.add(null);
      }

      int start =
          currentPage - 1;

      int end =
          currentPage + 1;

      if (currentPage <= 4) {
        start = 2;
        end = 5;
      }

      if (currentPage >=
          totalPages - 3) {
        start =
            totalPages - 4;
        end =
            totalPages - 1;
      }

      for (
        int i = start;
        i <= end;
        i++
      ) {
        if (i > 1 &&
            i < totalPages) {
          pages.add(i);
        }
      }

      if (currentPage <
          totalPages - 3) {
        pages.add(null);
      }

      pages.add(totalPages);
    }

    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children:
          pages.map((page) {
        if (page == null) {
          return const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 5,
            ),
            child: Text(
              '•••',
              style: TextStyle(
                color:
                    Color(0xFF98A2B3),
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          );
        }

        return Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 3,
          ),
          child:
              _pageNumberButton(
            page,
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // PAGE NUMBER BUTTON
  // ============================================================

  Widget _pageNumberButton(
    int page,
  ) {
    final bool selected =
        page == currentPage;

    return InkWell(
      onTap:
          selected || isLoading
              ? null
              : () {
                  _goToPage(page);
                },
      borderRadius:
          BorderRadius.circular(8),
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 180,
        ),
        width: 38,
        height: 38,
        alignment:
            Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(
                  0xFF315BEF,
                )
              : Colors.white,
          borderRadius:
              BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(
                    0xFF315BEF,
                  )
                : const Color(
                    0xFFD0D5DD,
                  ),
          ),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: selected
                ? Colors.white
                : const Color(
                    0xFF344054,
                  ),
            fontSize: 13,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAGINATION ICON
  // ============================================================

  Widget _paginationIconButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap:
            enabled
                ? onPressed
                : null,
        borderRadius:
            BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          alignment:
              Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? Colors.white
                : const Color(
                    0xFFF9FAFB,
                  ),
            borderRadius:
                BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? const Color(
                      0xFFD0D5DD,
                    )
                  : const Color(
                      0xFFE4E7EC,
                    ),
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: enabled
                ? const Color(
                    0xFF344054,
                  )
                : const Color(
                    0xFFD0D5DD,
                  ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT PAGE
  // ============================================================

  Widget _currentPageIndicator() {
    return Container(
      height: 38,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      alignment:
          Alignment.center,
      decoration: BoxDecoration(
        color:
            const Color(0xFF315BEF),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Text(
        '$currentPage',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // VIEW SEQUENCE
  // ============================================================

  void _viewSequence(
    Map<String, dynamic> sequence,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) {
        return Dialog(
          backgroundColor:
              Colors.transparent,
          insetPadding:
              const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 850,
              maxHeight: 750,
            ),
            child: Container(
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: Column(
                children: [
                  // HEADER
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 26,
                      vertical: 22,
                    ),
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFF101828),
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
                        const Icon(
                          Icons.email_outlined,
                          color:
                              Color(0xFF7C9AFF),
                          size: 28,
                        ),

                        const SizedBox(
                            width: 14),

                        Expanded(
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Sequence Details',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize:
                                      20,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),

                              const SizedBox(
                                  height: 4),

                              Text(
                                'Step ${sequence['step'] ?? '-'} • Variant ${sequence['variant'] ?? '-'}',
                                style:
                                    const TextStyle(
                                  color:
                                      Color(0xFF98A2B3),
                                  fontSize:
                                      13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        _dialogStatus(
                          sequence['status']
                                  ?.toString() ??
                              '-',
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

                  // BODY
                  Expanded(
                    child:
                        SingleChildScrollView(
                      padding:
                          const EdgeInsets.all(
                        26,
                      ),
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Sequence Information',
                            style:
                                TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                              height: 14),

                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _sequenceInfoCard(
                                icon: Icons
                                    .layers_outlined,
                                title:
                                    'Step',
                                value:
                                    sequence['step']
                                            ?.toString() ??
                                        '-',
                              ),

                              _sequenceInfoCard(
                                icon: Icons
                                    .schedule_outlined,
                                title:
                                    'Gap Days',
                                value:
                                    '${sequence['gapDays'] ?? 0} Day(s)',
                              ),

                              _sequenceInfoCard(
                                icon: Icons
                                    .alt_route_outlined,
                                title:
                                    'Variant',
                                value:
                                    sequence['variant']
                                            ?.toString() ??
                                        '-',
                              ),

                              _sequenceInfoCard(
                                icon: Icons
                                    .business_outlined,
                                title:
                                    'Business Type',
                                value:
                                    sequence['type']
                                            ?.toString() ??
                                        '-',
                              ),
                            ],
                          ),

                          const SizedBox(
                              height: 28),

                          const Text(
                            'Email Details',
                            style:
                                TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                              height: 14),

                          _emailDetailContainer(
                            title:
                                'Subject',
                            icon: Icons
                                .subject_outlined,
                            child:
                                Text(
                              sequence['subject']
                                      ?.toString() ??
                                  '-',
                              style:
                                  const TextStyle(
                                fontSize:
                                    15,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),

                          const SizedBox(
                              height: 14),

                          _emailDetailContainer(
                            title:
                                'Message',
                            icon: Icons
                                .message_outlined,
                            child:
                                Container(
                              width:
                                  double.infinity,
                              padding:
                                  const EdgeInsets
                                      .all(
                                16,
                              ),
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
                              ),
                              child:
                                  Text(
                                sequence['content']
                                        ?.toString() ??
                                    '-',
                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                    0xFF344054,
                                  ),
                                  fontSize:
                                      14,
                                  height:
                                      1.6,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                              height: 28),

                          Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets
                                    .all(
                              18,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFF9FAFB,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            child:
                                Column(
                              children: [
                                _detailRow(
                                  'Business Type',
                                  sequence['type']
                                          ?.toString() ??
                                      '-',
                                  Icons
                                      .business_outlined,
                                ),

                                const Divider(
                                  height: 24,
                                ),

                                _detailRow(
                                  'WhatsApp',
                                  _getWhatsApp(
                                    sequence,
                                  ),
                                  Icons
                                      .chat_outlined,
                                ),

                                const Divider(
                                  height: 24,
                                ),

                                _detailRow(
                                  'Created At',
                                  _formatDateTime(
                                    sequence[
                                        'createdAt'],
                                  ),
                                  Icons
                                      .calendar_today_outlined,
                                ),

                                const Divider(
                                  height: 24,
                                ),

                                _detailRow(
                                  'Updated At',
                                  _formatDateTime(
                                    sequence[
                                        'updatedAt'],
                                  ),
                                  Icons
                                      .update_outlined,
                                ),
                              ],
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
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed:
                              () {
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
                            width: 12),

                        ElevatedButton.icon(
                          onPressed:
                              () {
                            Navigator.pop(
                              dialogContext,
                            );

                            _editSequence(
                              sequence,
                            );
                          },
                          icon:
                              const Icon(
                            Icons.edit_outlined,
                          ),
                          label:
                              const Text(
                            'Edit Sequence',
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xFF315BEF,
                            ),
                            foregroundColor:
                                Colors.white,
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
  // DIALOG STATUS
  // ============================================================

  Widget _dialogStatus(
    String status,
  ) {
    final bool active =
        status.toLowerCase() ==
            'active';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(
                0xFF12B76A,
              ).withOpacity(0.15)
            : Colors.white
                .withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: active
              ? const Color(
                  0xFF32D583,
                )
              : const Color(
                  0xFF98A2B3,
                ),
          fontSize: 12,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _sequenceInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return SizedBox(
      width: 175,
      child: Container(
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              const Color(0xFFF9FAFB),
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color:
                const Color(0xFFE4E7EC),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  const Color(0xFF315BEF),
              size: 20,
            ),

            const SizedBox(width: 10),

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
                          Color(0xFF667085),
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(
                      height: 4),

                  Text(
                    value,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF101828),
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
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
  // EMAIL DETAIL
  // ============================================================

  Widget _emailDetailContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(0xFFE4E7EC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 19,
                color:
                    const Color(0xFF667085),
              ),

              const SizedBox(width: 8),

              Text(
                title,
                style:
                    const TextStyle(
                  color:
                      Color(0xFF344054),
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    String title,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color:
              const Color(0xFF667085),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(
              color:
                  Color(0xFF667085),
              fontSize: 13,
            ),
          ),
        ),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style:
                const TextStyle(
              color:
                  Color(0xFF101828),
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADD NEW SEQUENCE
  // ============================================================

  Future<void> _addNewSequence() async {
    final result =
        await Navigator.of(
      context,
      rootNavigator: true,
    ).push(
      MaterialPageRoute(
        builder: (context) =>
            const CreateSequenceScreen(),
      ),
    );

    if (result == true) {
      await _loadSequences(
        page: currentPage,
      );
    }
  }

  // ============================================================
  // EDIT SEQUENCE
  // ============================================================

  Future<void> _editSequence(
    Map<String, dynamic> sequence,
  ) async {
    final result =
        await Navigator.of(
      context,
      rootNavigator: true,
    ).push(
      MaterialPageRoute(
        builder: (context) =>
            const CreateSequenceScreen(),
      ),
    );

    if (result == true) {
      await _loadSequences(
        page: currentPage,
      );
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _deleteSequence(
    Map<String, dynamic> sequence,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Sequence',
          ),
          content: Text(
            'Are you sure you want to delete Step ${sequence['step'] ?? '-'}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  sequences.remove(
                    sequence,
                  );

                  totalSequences =
                      totalSequences > 0
                          ? totalSequences - 1
                          : 0;

                  if (sequences.isEmpty &&
                      currentPage > 1) {
                    currentPage--;
                  }
                });

                Navigator.pop(
                  dialogContext,
                );

                _showMessage(
                  'Sequence removed from the list.',
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // WHATSAPP
  // ============================================================

  String _getWhatsApp(
    Map<String, dynamic> sequence,
  ) {
    final actionLinks =
        sequence['actionLinks'];

    if (actionLinks is Map) {
      return actionLinks['whatsapp']
              ?.toString() ??
          '-';
    }

    return '-';
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

    try {
      final date =
          DateTime.parse(
        value.toString(),
      );

      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // DATE TIME
  // ============================================================

  String _formatDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

    try {
      final date =
          DateTime.parse(
        value.toString(),
      );

      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}