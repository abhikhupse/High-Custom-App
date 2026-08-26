import 'dart:async';

import 'package:flutter/material.dart';

import 'create_sequence_screen.dart';
import '../../../services/sequence_api.dart';
import '../../../widgets/app_feedback.dart';

// ============================================================
// MASTER / SEQUENCE LIST SCREEN
// ============================================================

class MasterListScreen extends StatefulWidget {
  const MasterListScreen({super.key});

  @override
  State<MasterListScreen> createState() => _MasterListScreenState();
}

class _MasterListScreenState extends State<MasterListScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color pageBackground = Color(0xFF050505);
  static const Color cardBackground = Color(0xFF0C0D0F);
  static const Color elevatedCard = Color(0xFF111214);

  static const Color borderColor = Color(0xFF292B2F);
  static const Color borderSoft = Color(0xFF1E2023);

  static const Color gold = Color(0xFFF2C45F);
  static const Color goldDark = Color(0xFFD9A93F);

  static const Color white = Color(0xFFF5F5F6);
  static const Color lightText = Color(0xFFD7D8DC);
  static const Color mutedText = Color(0xFF92959D);
  static const Color softText = Color(0xFF696D76);

  static const Color green = Color(0xFF4ADE80);
  static const Color blue = Color(0xFF4C8DFF);
  static const Color orange = Color(0xFFFFA52F);
  static const Color purple = Color(0xFF9A63FF);
  static const Color red = Color(0xFFFF5D68);

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
  // STATE
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
                (item) =>
                    Map<String, dynamic>.from(item),
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
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to load sequences.';
      });

      debugPrint(
        'LOAD SEQUENCES ERROR: $e',
      );
    }
  }

  // ============================================================
  // INTEGER
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
  // PAGE
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
  // ENTRIES
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
    final double width =
        MediaQuery.of(context).size.width;

    final bool isMobile = width < 600;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: gold,
          backgroundColor: elevatedCard,
          onRefresh: _refreshSequences,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              isMobile ? 18 : 28,
              isMobile ? 20 : 28,
              isMobile ? 18 : 28,
              40,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildPageHeader(isMobile),

                SizedBox(
                  height: isMobile ? 24 : 30,
                ),

                if (isMobile)
                  _buildMobileContent()
                else
                  _buildDesktopContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildPageHeader(
    bool isMobile,
  ) {
    if (!isMobile) {
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
                  'Sequences',
                  style: TextStyle(
                    color: white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Manage your automated email campaigns',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          ElevatedButton.icon(
            onPressed:
                isLoading
                    ? null
                    : _addNewSequence,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'New Sequence',
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor:
                  Colors.black,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Sequences',
                style: TextStyle(
                  color: white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Manage your email sequences',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        _headerAction(
          icon: Icons.refresh_rounded,
          onTap:
              isLoading
                  ? null
                  : _refreshSequences,
          outlined: true,
        ),

        const SizedBox(width: 10),

        _headerAction(
          icon: Icons.add_rounded,
          onTap:
              isLoading
                  ? null
                  : _addNewSequence,
          outlined: false,
        ),
      ],
    );
  }

  Widget _headerAction({
    required IconData icon,
    required VoidCallback? onTap,
    required bool outlined,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color:
              outlined
                  ? elevatedCard
                  : gold,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color:
                outlined
                    ? borderColor
                    : gold,
          ),
          boxShadow:
              outlined
                  ? []
                  : [
                      BoxShadow(
                        color:
                            gold.withOpacity(
                              0.14,
                            ),
                        blurRadius: 16,
                        offset:
                            const Offset(
                              0,
                              5,
                            ),
                      ),
                    ],
        ),
        child: Icon(
          icon,
          color:
              outlined
                  ? lightText
                  : Colors.black,
          size: 25,
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE CONTENT
  // ============================================================

  Widget _buildMobileContent() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // ========================================================
        // SEARCH
        // ========================================================

        _buildSearchField(
          isMobile: true,
        ),

        const SizedBox(height: 12),

        // ========================================================
        // CONTROLS
        // ========================================================

        Row(
          children: [
            Expanded(
              child: _buildEntriesControl(),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildResultCount(),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ========================================================
        // CONTENT
        // ========================================================

        if (isLoading)
          _buildLoadingState()
        else if (errorMessage != null)
          _buildErrorState()
        else if (sequences.isEmpty)
          _buildEmptyState()
        else
          _buildMobileCards(),

        if (!isLoading &&
            errorMessage == null &&
            totalSequences > 0) ...[
          const SizedBox(height: 22),
          _buildPagination(),
        ],
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField({
    required bool isMobile,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: _onSearchChanged,
        cursorColor: gold,
        style: const TextStyle(
          color: white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText:
              'Search sequences...',
          hintStyle:
              const TextStyle(
            color: softText,
            fontSize: 14,
          ),
          prefixIcon:
              const Icon(
            Icons.search_rounded,
            color: mutedText,
            size: 23,
          ),
          suffixIcon:
              searchController
                      .text
                      .isNotEmpty
                  ? IconButton(
                      onPressed:
                          _clearSearch,
                      icon:
                          const Icon(
                        Icons
                            .close_rounded,
                        color:
                            mutedText,
                        size: 20,
                      ),
                    )
                  : null,
          border:
              InputBorder.none,
          enabledBorder:
              InputBorder.none,
          focusedBorder:
              InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 17,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ENTRIES CONTROL
  // ============================================================

  Widget _buildEntriesControl() {
    return Container(
      height: 48,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child:
          DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: entriesPerPage,
          dropdownColor:
              elevatedCard,
          icon:
              const Icon(
            Icons
                .keyboard_arrow_down_rounded,
            color: mutedText,
          ),
          style:
              const TextStyle(
            color: white,
            fontSize: 13,
          ),
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: 10,
              child: Text(
                '10 entries',
              ),
            ),
            DropdownMenuItem(
              value: 25,
              child: Text(
                '25 entries',
              ),
            ),
            DropdownMenuItem(
              value: 50,
              child: Text(
                '50 entries',
              ),
            ),
          ],
          onChanged:
              isLoading
                  ? null
                  : (value) {
                      if (value ==
                          null) {
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
  // RESULT COUNT
  // ============================================================

  Widget _buildResultCount() {
    return Container(
      height: 48,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
      ),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration:
                BoxDecoration(
              color:
                  gold.withOpacity(
                    0.10,
                  ),
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),
            child: const Icon(
              Icons
                  .format_list_bulleted_rounded,
              color: gold,
              size: 16,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              '$totalSequences sequences',
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color: lightText,
                fontSize: 12.5,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE SEQUENCE CARDS
  // ============================================================

  Widget _buildMobileCards() {
    return ListView.separated(
      itemCount: sequences.length,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      separatorBuilder:
          (_, __) =>
              const SizedBox(
        height: 12,
      ),
      itemBuilder:
          (context, index) {
        final sequence =
            sequences[index];

        return _buildSequenceCard(
          sequence,
        );
      },
    );
  }

  Widget _buildSequenceCard(
    Map<String, dynamic> sequence,
  ) {
    final String step =
        sequence['step']?.toString() ??
            '-';

    final String gap =
        sequence['gapDays']
                ?.toString() ??
            '0';

    final String variant =
        sequence['variant']
                ?.toString() ??
            '-';

    final String subject =
        sequence['subject']
                ?.toString()
                .trim() ??
            '';

    final String content =
        sequence['content']
                ?.toString()
                .trim() ??
            '';

    final String type =
        sequence['businessType']
                ?.toString() ??
            '-';

    final String status =
        sequence['status']
                ?.toString() ??
            'draft';

    return InkWell(
      onTap: () {
        _viewSequence(sequence);
      },
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // TOP
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _sequenceIcon(
                  type,
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
                        subject.isEmpty
                            ? 'Untitled Sequence'
                            : subject,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color: white,
                          fontSize: 15.5,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        '$type Sequence',
                        style:
                            const TextStyle(
                          color:
                              mutedText,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                PopupMenuButton<String>(
                  color: elevatedCard,
                  elevation: 12,
                  surfaceTintColor:
                      Colors.transparent,
                  icon:
                      const Icon(
                    Icons
                        .more_vert_rounded,
                    color: mutedText,
                    size: 23,
                  ),
                  onSelected:
                      (value) {
                    switch (value) {
                      case 'view':
                        _viewSequence(
                          sequence,
                        );
                        break;

                      case 'edit':
                        _editSequence(
                          sequence,
                        );
                        break;

                      case 'delete':
                        _deleteSequence(
                          sequence,
                        );
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                    _menuItem(
                      value: 'view',
                      icon:
                          Icons
                              .visibility_outlined,
                      title: 'View',
                    ),
                    _menuItem(
                      value: 'edit',
                      icon:
                          Icons.edit_outlined,
                      title: 'Edit',
                    ),
                    _menuItem(
                      value: 'delete',
                      icon:
                          Icons
                              .delete_outline,
                      title: 'Delete',
                      danger: true,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // BADGES
            // ==================================================

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _variantBadge(
                  variant,
                ),

                _statusBadge(
                  status,
                ),

                _typeBadge(
                  type,
                ),
              ],
            ),

            const SizedBox(
              height: 15,
            ),

            Container(
              height: 1,
              color: borderSoft,
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // STEP INFO
            // ==================================================

            Row(
              children: [
                Expanded(
                  child:
                      _sequenceMetric(
                    icon:
                        Icons
                            .layers_outlined,
                    label: 'Step',
                    value: step,
                  ),
                ),

                Container(
                  width: 1,
                  height: 42,
                  color: borderSoft,
                ),

                Expanded(
                  child:
                      _sequenceMetric(
                    icon:
                        Icons
                            .schedule_outlined,
                    label: 'Gap Days',
                    value:
                        '$gap day${gap == '1' ? '' : 's'}',
                  ),
                ),
              ],
            ),

            if (content.isNotEmpty) ...[
              const SizedBox(
                height: 15,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets
                        .all(12),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF090A0C,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                  border:
                      Border.all(
                    color:
                        borderSoft,
                  ),
                ),
                child: Text(
                  content,
                  maxLines: 2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        lightText,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ],

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // DATE
            // ==================================================

            Row(
              children: [
                const Icon(
                  Icons
                      .calendar_today_outlined,
                  size: 15,
                  color: mutedText,
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child: Text(
                    _formatDateTime(
                      sequence[
                          'createdAt'],
                    ),
                    style:
                        const TextStyle(
                      color:
                          mutedText,
                      fontSize: 11.5,
                    ),
                  ),
                ),

                const Icon(
                  Icons
                      .chevron_right_rounded,
                  size: 19,
                  color: softText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MENU
  // ============================================================

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String title,
    bool danger = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color:
                danger
                    ? red
                    : lightText,
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            title,
            style: TextStyle(
              color:
                  danger
                      ? red
                      : white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEQUENCE ICON
  // ============================================================

  Widget _sequenceIcon(
    String type,
  ) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'whatsapp':
        icon =
            Icons.chat_outlined;
        color = green;
        break;

      case 'sms':
        icon =
            Icons.sms_outlined;
        color = purple;
        break;

      case 'email':
      default:
        icon =
            Icons.email_outlined;
        color = gold;
    }

    return Container(
      width: 46,
      height: 46,
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(
              0.11,
            ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 22,
      ),
    );
  }

  // ============================================================
  // METRIC
  // ============================================================

  Widget _sequenceMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration:
              BoxDecoration(
            color:
                gold.withOpacity(
                  0.08,
                ),
            borderRadius:
                BorderRadius.circular(
              9,
            ),
          ),
          child: Icon(
            icon,
            color: gold,
            size: 17,
          ),
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
                  color: mutedText,
                  fontSize: 10.5,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                value,
                maxLines: 1,
                overflow:
                    TextOverflow
                        .ellipsis,
                style:
                    const TextStyle(
                  color: white,
                  fontSize: 12.5,
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
  // VARIANT BADGE
  // ============================================================

  Widget _variantBadge(
    String variant,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            gold.withOpacity(
              0.10,
            ),
        borderRadius:
            BorderRadius.circular(7),
        border: Border.all(
          color:
              gold.withOpacity(
                0.18,
              ),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          const Icon(
            Icons
                .alt_route_rounded,
            color: gold,
            size: 13,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            'Variant $variant',
            style:
                const TextStyle(
              color: gold,
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    String status,
  ) {
    Color statusColor;
    IconData icon;

    switch (
        status.toLowerCase()) {
      case 'active':
        statusColor = green;
        icon =
            Icons
                .play_circle_outline;
        break;

      case 'scheduled':
        statusColor = blue;
        icon =
            Icons.schedule_rounded;
        break;

      case 'paused':
        statusColor = orange;
        icon =
            Icons
                .pause_circle_outline;
        break;

      case 'draft':
      default:
        statusColor =
            mutedText;
        icon =
            Icons
                .edit_note_outlined;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            statusColor.withOpacity(
              0.10,
            ),
        borderRadius:
            BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: statusColor,
            size: 13,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            _capitalize(status),
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TYPE BADGE
  // ============================================================

  Widget _typeBadge(
    String type,
  ) {
    Color typeColor;

    switch (type.toLowerCase()) {
      case 'whatsapp':
        typeColor = green;
        break;

      case 'sms':
        typeColor = purple;
        break;

      case 'email':
      default:
        typeColor = blue;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            typeColor.withOpacity(
              0.10,
            ),
        borderRadius:
            BorderRadius.circular(7),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: typeColor,
          fontSize: 11,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopContent() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildEntriesControl(),

              const Spacer(),

              SizedBox(
                width: 320,
                child:
                    _buildSearchField(
                  isMobile: false,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          if (isLoading)
            _buildLoadingState()
          else if (errorMessage !=
              null)
            _buildErrorState()
          else if (sequences
              .isEmpty)
            _buildEmptyState()
          else
            _buildDesktopTable(),

          if (totalSequences >
              0) ...[
            const SizedBox(
              height: 20,
            ),
            _buildPagination(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(12),
        child:
            SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(
              elevatedCard,
            ),
            dataRowColor:
                WidgetStateProperty.all(
              cardBackground,
            ),
            headingTextStyle:
                const TextStyle(
              color: gold,
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
            dataTextStyle:
                const TextStyle(
              color: lightText,
              fontSize: 12,
            ),
            columns: const [
              DataColumn(
                label: Text('STEP'),
              ),
              DataColumn(
                label:
                    Text('GAP DAYS'),
              ),
              DataColumn(
                label:
                    Text('VARIANT'),
              ),
              DataColumn(
                label:
                    Text('SUBJECT'),
              ),
              DataColumn(
                label: Text('TYPE'),
              ),
              DataColumn(
                label:
                    Text('STATUS'),
              ),
              DataColumn(
                label:
                    Text('CREATED'),
              ),
              DataColumn(
                label:
                    Text('ACTIONS'),
              ),
            ],
            rows:
                sequences.map(
              (sequence) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        sequence[
                                    'step']
                                ?.toString() ??
                            '-',
                      ),
                    ),

                    DataCell(
                      Text(
                        sequence[
                                    'gapDays']
                                ?.toString() ??
                            '-',
                      ),
                    ),

                    DataCell(
                      _variantBadge(
                        sequence[
                                    'variant']
                                ?.toString() ??
                            '-',
                      ),
                    ),

                    DataCell(
                      SizedBox(
                        width: 220,
                        child: Text(
                          sequence[
                                      'subject']
                                  ?.toString() ??
                              '-',
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),
                      ),
                    ),

                    DataCell(
                      Text(
                        sequence[
                                    'type']
                                ?.toString() ??
                            '-',
                      ),
                    ),

                    DataCell(
                      _statusBadge(
                        sequence[
                                    'status']
                                ?.toString() ??
                            'draft',
                      ),
                    ),

                    DataCell(
                      Text(
                        _formatDateTime(
                          sequence[
                              'createdAt'],
                        ),
                      ),
                    ),

                    DataCell(
                      PopupMenuButton<
                          String>(
                        color:
                            elevatedCard,
                        icon:
                            const Icon(
                          Icons
                              .more_vert,
                          color:
                              mutedText,
                        ),
                        onSelected:
                            (value) {
                          if (value ==
                              'view') {
                            _viewSequence(
                              sequence,
                            );
                          }

                          if (value ==
                              'edit') {
                            _editSequence(
                              sequence,
                            );
                          }

                          if (value ==
                              'delete') {
                            _deleteSequence(
                              sequence,
                            );
                          }
                        },
                        itemBuilder:
                            (_) => [
                          _menuItem(
                            value:
                                'view',
                            icon: Icons
                                .visibility_outlined,
                            title:
                                'View',
                          ),
                          _menuItem(
                            value:
                                'edit',
                            icon: Icons
                                .edit_outlined,
                            title:
                                'Edit',
                          ),
                          _menuItem(
                            value:
                                'delete',
                            icon: Icons
                                .delete_outline,
                            title:
                                'Delete',
                            danger:
                                true,
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
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 80,
      ),
      child: const Center(
        child:
            CircularProgressIndicator(
          color: gold,
          strokeWidth: 2.5,
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
        vertical: 55,
        horizontal: 25,
      ),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration:
                BoxDecoration(
              color:
                  red.withOpacity(
                    0.10,
                  ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons
                  .error_outline_rounded,
              color: red,
              size: 28,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Text(
            errorMessage ??
                'Something went wrong.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: lightText,
              fontSize: 14,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          OutlinedButton.icon(
            onPressed:
                isLoading
                    ? null
                    : () {
                        _loadSequences(
                          page:
                              currentPage,
                        );
                      },
            icon:
                const Icon(
              Icons.refresh,
              size: 18,
            ),
            label:
                const Text(
              'Try Again',
            ),
            style:
                OutlinedButton.styleFrom(
              foregroundColor: gold,
              side:
                  const BorderSide(
                color: goldDark,
              ),
            ),
          ),
        ],
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
        vertical: 65,
        horizontal: 25,
      ),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
                BoxDecoration(
              color:
                  gold.withOpacity(
                    0.08,
                  ),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: const Icon(
              Icons.email_outlined,
              size: 27,
              color: gold,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            searching
                ? 'No sequences found'
                : 'No sequences yet',
            style:
                const TextStyle(
              color: white,
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            searching
                ? 'Try changing your search.'
                : 'Create your first email sequence to get started.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: mutedText,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),

          if (!searching) ...[
            const SizedBox(
              height: 18,
            ),

            ElevatedButton.icon(
              onPressed:
                  _addNewSequence,
              icon:
                  const Icon(
                Icons.add,
                size: 18,
              ),
              label:
                  const Text(
                'New Sequence',
              ),
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    gold,
                foregroundColor:
                    Colors.black,
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

    final int calculatedEnd =
        currentPage *
            entriesPerPage;

    final int end =
        calculatedEnd >
                totalSequences
            ? totalSequences
            : calculatedEnd;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Showing $start–$end of $totalSequences',
            style:
                const TextStyle(
              color: mutedText,
              fontSize: 12,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              _paginationButton(
                icon:
                    Icons
                        .chevron_left_rounded,
                enabled:
                    currentPage > 1 &&
                        !isLoading,
                onTap: () {
                  _goToPage(
                    currentPage - 1,
                  );
                },
              ),

              const SizedBox(
                width: 10,
              ),

              Container(
                height: 40,
                constraints:
                    const BoxConstraints(
                  minWidth: 44,
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                ),
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color: gold,
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),
                child: Text(
                  '$currentPage',
                  style:
                      const TextStyle(
                    color:
                        Colors.black,
                    fontSize: 14,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              _paginationButton(
                icon:
                    Icons
                        .chevron_right_rounded,
                enabled:
                    currentPage <
                            totalPages &&
                        !isLoading,
                onTap: () {
                  _goToPage(
                    currentPage + 1,
                  );
                },
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            'Page $currentPage of $totalPages',
            style:
                const TextStyle(
              color: softText,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap:
          enabled ? onTap : null,
      borderRadius:
          BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        alignment:
            Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? elevatedCard
              : const Color(
                  0xFF090A0B,
                ),
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color:
                enabled
                    ? borderColor
                    : borderSoft,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color:
              enabled
                  ? lightText
                  : softText,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder:
              (
                context,
                scrollController,
              ) {
            return Container(
              decoration:
                  const BoxDecoration(
                color:
                    pageBackground,
                borderRadius:
                    BorderRadius.vertical(
                  top:
                      Radius.circular(
                    24,
                  ),
                ),
                border: Border(
                  top:
                      BorderSide(
                    color:
                        borderColor,
                  ),
                ),
              ),
              child:
                  SingleChildScrollView(
                controller:
                    scrollController,
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  20,
                  12,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Center(
                      child:
                          Container(
                        width: 44,
                        height: 4,
                        decoration:
                            BoxDecoration(
                          color:
                              borderColor,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    Row(
                      children: [
                        _sequenceIcon(
                          sequence[
                                      'type']
                                  ?.toString() ??
                              'Email',
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
                              const Text(
                                'Sequence Details',
                                style:
                                    TextStyle(
                                  color:
                                      white,
                                  fontSize:
                                      20,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              Text(
                                'Step ${sequence['step'] ?? '-'} • Variant ${sequence['variant'] ?? '-'}',
                                style:
                                    const TextStyle(
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
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .close_rounded,
                            color:
                                lightText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    _detailsSection(
                      title:
                          'Sequence Information',
                      children: [
                        _detailRow(
                          'Step',
                          sequence['step']
                                  ?.toString() ??
                              '-',
                          Icons
                              .layers_outlined,
                        ),

                        _detailDivider(),

                        _detailRow(
                          'Gap Days',
                          '${sequence['gapDays'] ?? 0}',
                          Icons
                              .schedule_outlined,
                        ),

                        _detailDivider(),

                        _detailRow(
                          'Variant',
                          sequence['variant']
                                  ?.toString() ??
                              '-',
                          Icons
                              .alt_route_outlined,
                        ),

                        _detailDivider(),

                        _detailRow(
                          'Business Type',
                          sequence['businessType']
                                  ?.toString() ??
                              '-',
                          Icons
                              .email_outlined,
                        ),

                        _detailDivider(),

                        _detailRow(
                          'Status',
                          sequence['status']
                                  ?.toString() ??
                              'draft',
                          Icons
                              .info_outline_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _detailsSection(
                      title:
                          'Email Subject',
                      children: [
                        Text(
                          sequence[
                                      'subject']
                                  ?.toString() ??
                              '-',
                          style:
                              const TextStyle(
                            color:
                                white,
                            fontSize:
                                14,
                            height: 1.45,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _detailsSection(
                      title:
                          'Message',
                      children: [
                        Text(
                          sequence[
                                      'content']
                                  ?.toString() ??
                              '-',
                          style:
                              const TextStyle(
                            color:
                                lightText,
                            fontSize:
                                13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _detailsSection(
                      title:
                          'Additional Information',
                      children: [
                        _detailRow(
                          'WhatsApp',
                          _getWhatsApp(
                            sequence,
                          ),
                          Icons
                              .chat_outlined,
                        ),

                        _detailDivider(),

                        _detailRow(
                          'Created',
                          _formatDateTime(
                            sequence[
                                'createdAt'],
                          ),
                          Icons
                              .calendar_today_outlined,
                        ),

                        _detailDivider(),

                        _detailRow(
                          'Updated',
                          _formatDateTime(
                            sequence[
                                'updatedAt'],
                          ),
                          Icons
                              .update_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 50,
                      child:
                          ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                          );

                          _editSequence(
                            sequence,
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
                          'Edit Sequence',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              gold,
                          foregroundColor:
                              Colors.black,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
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
  // DETAILS SECTION
  // ============================================================

  Widget _detailsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              color: gold,
              fontSize: 12.5,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          ...children,
        ],
      ),
    );
  }

  Widget _detailDivider() {
    return const Divider(
      height: 24,
      color: borderSoft,
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: mutedText,
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 86,
          child: Text(
            title,
            style:
                const TextStyle(
              color: mutedText,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style:
                const TextStyle(
              color: white,
              fontSize: 12.5,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADD SEQUENCE
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

    // CreateSequenceForm currently returns a result map,
    // so check for non-null instead of only `result == true`.
    if (result != null) {
      await _loadSequences(
        page: currentPage,
      );
    }
  }

  // ============================================================
  // EDIT
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
            CreateSequenceScreen(
          sequence:
              Map<String, dynamic>.from(
            sequence,
          ),
        ),
      ),
    );

    if (result != null) {
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
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              elevatedCard,
          surfaceTintColor:
              Colors.transparent,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
            side:
                const BorderSide(
              color: borderColor,
            ),
          ),
          title:
              const Row(
            children: [
              Icon(
                Icons
                    .delete_outline_rounded,
                color: red,
              ),
              SizedBox(width: 10),
              Text(
                'Delete Sequence',
                style: TextStyle(
                  color: white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete Step ${sequence['step'] ?? '-'}?',
            style:
                const TextStyle(
              color: lightText,
              fontSize: 13,
              height: 1.5,
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

            ElevatedButton(
              onPressed: () {
                setState(() {
                  sequences.remove(
                    sequence,
                  );

                  totalSequences =
                      totalSequences > 0
                          ? totalSequences -
                              1
                          : 0;

                  if (sequences
                          .isEmpty &&
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
                  ElevatedButton
                      .styleFrom(
                backgroundColor: red,
                foregroundColor:
                    Colors.white,
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
  // DATE TIME
  // ============================================================

  String _formatDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

    try {
      final date = DateTime.parse(
        value.toString(),
      ).toLocal();

      final String day =
          date.day
              .toString()
              .padLeft(2, '0');

      final String month =
          date.month
              .toString()
              .padLeft(2, '0');

      final String hour =
          date.hour
              .toString()
              .padLeft(2, '0');

      final String minute =
          date.minute
              .toString()
              .padLeft(2, '0');

      return '$day-$month-${date.year}  $hour:$minute';
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // CAPITALIZE
  // ============================================================

  String _capitalize(
    String value,
  ) {
    if (value.trim().isEmpty) {
      return value;
    }

    final String text =
        value.trim();

    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    AppFeedback.show(context, message, isError: isError);
  }
}
