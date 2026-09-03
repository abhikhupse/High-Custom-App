import 'package:flutter/material.dart';

import '../../services/tracking_api.dart';

class TrackingReportScreen extends StatefulWidget {
  final ValueChanged<String>? onNavigate;

  const TrackingReportScreen({super.key, this.onNavigate});

  @override
  State<TrackingReportScreen> createState() => _TrackingReportScreenState();
}

class _TrackingReportScreenState extends State<TrackingReportScreen> {
  static const _gold = Color(0xFFFFC83D);
  static const _background = Color(0xFF080B0D);
  static const _line = Color(0xFF383C40);
  static const _muted = Color(0xFFB6B6BF);

  String _date = 'All Dates';
  String _status = 'All Status';
  final _searchController = TextEditingController();
  List<_Activity> _activities = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await TrackingApi.getTrackingReport(
      page: page,
      limit: _pageSize,
    );
    if (!mounted) return;

    if (response['success'] != true) {
      setState(() {
        _loading = false;
        _error = response['message']?.toString() ?? 'Unable to load report.';
      });
      return;
    }

    final deliveries = response['deliveries'] as List<dynamic>? ?? const [];
    final pagination = response['pagination'];
    setState(() {
      _activities = deliveries
          .whereType<Map>()
          .map((item) => _activityFromDelivery(Map<String, dynamic>.from(item)))
          .toList();
      if (pagination is Map) {
        _currentPage = (pagination['page'] as num?)?.toInt() ?? page;
        _totalPages = (pagination['totalPages'] as num?)?.toInt() ?? 1;
        _totalRecords =
            (pagination['total'] as num?)?.toInt() ?? _activities.length;
      }
      _loading = false;
    });
  }

  _Activity _activityFromDelivery(Map<String, dynamic> delivery) {
    final lead = delivery['leadId'] is Map
        ? Map<String, dynamic>.from(delivery['leadId'] as Map)
        : <String, dynamic>{};
    final sequence = delivery['sequenceId'] is Map
        ? Map<String, dynamic>.from(delivery['sequenceId'] as Map)
        : <String, dynamic>{};
    final firstName = lead['firstName']?.toString().trim() ?? '';
    final lastName = lead['lastName']?.toString().trim() ?? '';
    final name = '$firstName $lastName'.trim();
    final email = lead['email']?.toString() ?? 'Unknown email';

    String status;
    dynamic eventDate;
    if (delivery['responseStatus'] != null) {
      status = delivery['responseStatus'].toString();
      eventDate = delivery['repliedAt'] ?? delivery['updatedAt'];
    } else if (delivery['repliedAt'] != null) {
      status = 'Replied';
      eventDate = delivery['repliedAt'];
    } else if (delivery['openedAt'] != null) {
      status = 'Seen';
      eventDate = delivery['openedAt'];
    } else {
      final raw = delivery['status']?.toString().toLowerCase() ?? 'pending';
      status = raw.isEmpty
          ? 'Pending'
          : '${raw[0].toUpperCase()}${raw.substring(1)}';
      eventDate =
          delivery['sentAt'] ??
          delivery['scheduledAt'] ??
          delivery['createdAt'];
    }

    final date = DateTime.tryParse(eventDate?.toString() ?? '')?.toLocal();
    return _Activity(
      initial: (name.isNotEmpty ? name : email).substring(0, 1).toUpperCase(),
      name: name,
      email: email,
      status: status,
      subject: sequence['subject']?.toString() ?? 'No subject',
      step: sequence['step']?.toString() ?? 'Steps',
      variant: sequence['variant']?.toString() ?? 'Variant',
      timeLabel: date == null ? status : '$status at ${_formatTime(date)}',
      dateLabel: date == null ? '' : 'on ${_formatDate(date)}',
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _formatDate(DateTime date) {
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

  List<_Activity> get _filteredActivities {
    final query = _searchController.text.trim().toLowerCase();
    return _activities.where((activity) {
      final matchesSearch =
          query.isEmpty ||
          activity.name.toLowerCase().contains(query) ||
          activity.email.toLowerCase().contains(query);
      final matchesStatus =
          _status == 'All Status' || activity.status == _status;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 800;
    final horizontal = mobile ? 13.0 : 48.0;
    final visibleActivities = _filteredActivities;

    return ColoredBox(
      color: _background,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                mobile ? 17 : 34,
                horizontal,
                mobile ? 19 : 38,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeading(mobile),
                      SizedBox(height: mobile ? 18 : 36),
                      _buildSearch(mobile),
                      SizedBox(height: mobile ? 14 : 28),
                      _buildActions(mobile),
                      SizedBox(height: mobile ? 21 : 42),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Email Activity',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: mobile ? 18 : 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$_totalRecords records',
                            style: TextStyle(
                              color: _muted,
                              fontSize: mobile ? 14 : 20,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: mobile ? 11 : 22),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 50),
                          child: Center(
                            child: CircularProgressIndicator(color: _gold),
                          ),
                        )
                      else if (_error != null)
                        _buildError()
                      else if (visibleActivities.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 50),
                          child: Center(
                            child: Text(
                              'No email activity found',
                              style: TextStyle(color: _muted, fontSize: 16),
                            ),
                          ),
                        )
                      else ...[
                        ...visibleActivities.map(
                          (activity) => Padding(
                            padding: EdgeInsets.only(bottom: mobile ? 11 : 22),
                            child: _ActivityCard(
                              activity: activity,
                              relatedActivities: _activities
                                  .where(
                                    (item) =>
                                        item.email.toLowerCase() ==
                                        activity.email.toLowerCase(),
                                  )
                                  .toList(),
                              compact: mobile,
                            ),
                          ),
                        ),
                        _buildPagination(mobile),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeading(bool mobile) {
    final title = Row(
      children: [
        Container(
          width: mobile ? 38 : 74,
          height: mobile ? 38 : 74,
          decoration: BoxDecoration(
            border: Border.all(color: _gold, width: 2),
            borderRadius: BorderRadius.circular(mobile ? 9 : 15),
          ),
          child: Icon(
            Icons.trending_up_rounded,
            color: _gold,
            size: mobile ? 23 : 42,
          ),
        ),
        SizedBox(width: mobile ? 12 : 28),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tracking Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: mobile ? 19 : 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: mobile ? 3 : 8),
              Text(
                'Email sequence performance',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _muted, fontSize: mobile ? 11 : 21),
              ),
            ],
          ),
        ),
      ],
    );

    final date = SizedBox(
      width: mobile ? 128 : 250,
      child: _Dropdown(
        compact: mobile,
        icon: Icons.calendar_month_outlined,
        value: _date,
        items: const ['All Dates', 'Today', 'Last 7 Days', 'Last 30 Days'],
        onChanged: (value) => setState(() => _date = value),
      ),
    );
    if (mobile) {
      return Row(
        children: [
          Expanded(child: title),
          const SizedBox(width: 10),
          date,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        date,
      ],
    );
  }

  Widget _buildSearch(bool mobile) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: Colors.white, fontSize: mobile ? 14 : 20),
      decoration: InputDecoration(
        hintText: 'Search by name or email',
        hintStyle: TextStyle(color: _muted, fontSize: mobile ? 14 : 22),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : 24),
          child: Icon(Icons.search, color: _muted, size: mobile ? 24 : 38),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: mobile ? 45 : 80),
        contentPadding: EdgeInsets.symmetric(
          vertical: mobile ? 16 : 32,
          horizontal: mobile ? 10 : 20,
        ),
        filled: true,
        fillColor: const Color(0xA60E1113),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _gold, width: 1.7),
        ),
      ),
    );
  }

  Widget _buildActions(bool mobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: mobile ? 151 : 270,
          child: _StatusFilter(
            compact: mobile,
            value: _status,
            onChanged: (value) => setState(() => _status = value),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('CSV export prepared'))),
          icon: Icon(Icons.download_rounded, size: mobile ? 19 : 32),
          label: const Text('Export CSV'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _gold,
            side: const BorderSide(color: _gold, width: 2),
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 12 : 27,
              vertical: mobile ? 15 : 25,
            ),
            textStyle: TextStyle(
              fontSize: mobile ? 13 : 20,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Color(0xFFFF6B6B),
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Unable to load report.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => _loadReport(page: _currentPage),
            style: OutlinedButton.styleFrom(
              foregroundColor: _gold,
              side: const BorderSide(color: _gold),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(bool mobile) {
    if (_totalPages <= 1) return const SizedBox.shrink();

    final start = (_currentPage - 1) * _pageSize + 1;
    final end = (_currentPage * _pageSize).clamp(0, _totalRecords);
    return Padding(
      padding: EdgeInsets.only(top: mobile ? 8 : 14, bottom: mobile ? 12 : 20),
      child: Row(
        children: [
          Text(
            '$start–$end of $_totalRecords',
            style: TextStyle(color: _muted, fontSize: mobile ? 12 : 15),
          ),
          const Spacer(),
          _PageButton(
            icon: Icons.chevron_left_rounded,
            enabled: _currentPage > 1 && !_loading,
            onTap: () => _loadReport(page: _currentPage - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$_currentPage / $_totalPages',
              style: TextStyle(
                color: Colors.white,
                fontSize: mobile ? 12 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            enabled: _currentPage < _totalPages && !_loading,
            onTap: () => _loadReport(page: _currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  static const statuses = [
    'All Status',
    'Pending',
    'Sent',
    'Seen',
    'Replied',
    'Interested',
    'Not Interested',
    'Failed',
  ];

  final bool compact;
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusFilter({
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = value != 'All Status';
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      color: const Color(0xFF171A1D),
      elevation: 18,
      offset: Offset(0, compact ? 52 : 62),
      constraints: BoxConstraints(
        minWidth: compact ? 205 : 250,
        maxWidth: compact ? 225 : 290,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3C4146), width: 1.2),
      ),
      itemBuilder: (context) => statuses.map((status) {
        final selected = status == value;
        final colors = _StatusColors.forStatus(status);
        return PopupMenuItem<String>(
          value: status,
          height: compact ? 42 : 50,
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
          child: Row(
            children: [
              if (status == 'All Status')
                Icon(
                  Icons.filter_alt_outlined,
                  color: _TrackingReportScreenState._muted,
                  size: compact ? 18 : 22,
                )
              else
                Container(
                  width: compact ? 10 : 13,
                  height: compact ? 10 : 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.foreground,
                    boxShadow: [
                      BoxShadow(
                        color: colors.foreground.withValues(alpha: 0.3),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              SizedBox(width: compact ? 12 : 15),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color: selected
                        ? _TrackingReportScreenState._gold
                        : Colors.white,
                    fontSize: compact ? 13 : 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  color: _TrackingReportScreenState._gold,
                  size: compact ? 18 : 21,
                ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 13 : 24,
          vertical: compact ? 13 : 18,
        ),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A1810) : const Color(0xA60E1113),
          border: Border.all(
            color: active
                ? _TrackingReportScreenState._gold
                : _TrackingReportScreenState._line,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            if (active)
              Container(
                width: compact ? 10 : 14,
                height: compact ? 10 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _StatusColors.forStatus(value).foreground,
                ),
              )
            else
              Icon(
                Icons.filter_alt_outlined,
                color: _TrackingReportScreenState._muted,
                size: compact ? 18 : 25,
              ),
            SizedBox(width: compact ? 10 : 14),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 13 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: compact ? 21 : 27,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(9),
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(
          color: enabled
              ? _TrackingReportScreenState._gold
              : _TrackingReportScreenState._line,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        icon,
        color: enabled
            ? _TrackingReportScreenState._gold
            : const Color(0xFF60646A),
      ),
    ),
  );
}

class _Dropdown extends StatelessWidget {
  final bool compact;
  final bool statusMode;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _Dropdown({
    this.compact = false,
    this.statusMode = false,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeStatus = statusMode && value != 'All Status';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 24,
        vertical: compact ? 4 : 9,
      ),
      decoration: BoxDecoration(
        color: activeStatus ? const Color(0xFF1A1810) : const Color(0xA60E1113),
        border: Border.all(
          color: activeStatus
              ? _TrackingReportScreenState._gold
              : _TrackingReportScreenState._line,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: activeStatus
            ? [
                BoxShadow(
                  color: _TrackingReportScreenState._gold.withValues(
                    alpha: 0.1,
                  ),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF171A1D),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: compact ? 22 : 32,
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 13 : 20,
            fontWeight: FontWeight.w500,
          ),
          selectedItemBuilder: statusMode
              ? (context) => items
                    .map(
                      (item) => Row(
                        children: [
                          if (item != 'All Status')
                            Container(
                              width: compact ? 10 : 14,
                              height: compact ? 10 : 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _StatusColors.forStatus(item).foreground,
                                border: Border.all(
                                  color: _StatusColors.forStatus(item).border,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.filter_alt_outlined,
                              color: _TrackingReportScreenState._muted,
                              size: compact ? 18 : 29,
                            ),
                          SizedBox(width: compact ? 7 : 20),
                          Expanded(
                            child: Text(
                              item,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList()
              : null,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      if (statusMode && item != 'All Status')
                        Container(
                          width: compact ? 10 : 14,
                          height: compact ? 10 : 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _StatusColors.forStatus(item).foreground,
                            border: Border.all(
                              color: _StatusColors.forStatus(item).border,
                            ),
                          ),
                        )
                      else
                        Icon(
                          icon,
                          color: _TrackingReportScreenState._muted,
                          size: compact ? 18 : 29,
                        ),
                      SizedBox(width: compact ? 7 : 20),
                      Expanded(
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _Activity activity;
  final List<_Activity> relatedActivities;
  final bool compact;
  const _ActivityCard({
    required this.activity,
    required this.relatedActivities,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColors = _StatusColors.forStatus(activity.status);
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 28,
        compact ? 16 : 32,
        compact ? 14 : 28,
        compact ? 15 : 30,
      ),
      decoration: BoxDecoration(
        color: const Color(0xE6121517),
        border: Border.all(color: _TrackingReportScreenState._line, width: 1.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 44 : 88,
                height: compact ? 44 : 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _TrackingReportScreenState._gold,
                    width: 2,
                  ),
                ),
                child: Text(
                  activity.initial,
                  style: TextStyle(
                    color: const Color(0xFFFFDA62),
                    fontSize: compact ? 18 : 35,
                  ),
                ),
              ),
              SizedBox(width: compact ? 15 : 30),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name.isEmpty ? '- -' : activity.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 13 : 22,
                      ),
                    ),
                    SizedBox(height: compact ? 7 : 19),
                    Text(
                      activity.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _TrackingReportScreenState._muted,
                        fontSize: compact ? 13 : 20,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 18 : 37,
                  vertical: compact ? 10 : 19,
                ),
                decoration: BoxDecoration(
                  color: statusColors.background,
                  border: Border.all(color: statusColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  activity.status,
                  style: TextStyle(
                    color: statusColors.foreground,
                    fontSize: compact ? 13 : 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 19),
          Wrap(
            spacing: compact ? 11 : 22,
            children: [
              _Tag(
                'Steps',
                compact: compact,
                onPressed: () => _showDetails(context, initialTab: 0),
              ),
              _Tag(
                'Variant',
                compact: compact,
                onPressed: () => _showDetails(context, initialTab: 1),
              ),
              _Tag(
                'Social',
                compact: compact,
                onPressed: () => _showDetails(context, initialTab: 2),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 22),
          const Divider(color: _TrackingReportScreenState._line, height: 1),
          SizedBox(height: compact ? 14 : 27),
          Text(
            activity.subject,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 14 : 22,
              height: 1.35,
            ),
          ),
          SizedBox(height: compact ? 18 : 35),
          Row(
            children: [
              Icon(
                Icons.edit_calendar_outlined,
                color: _TrackingReportScreenState._muted,
                size: compact ? 22 : 38,
              ),
              SizedBox(width: compact ? 10 : 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.timeLabel,
                    style: TextStyle(
                      color: _TrackingReportScreenState._muted,
                      fontSize: compact ? 13 : 20,
                    ),
                  ),
                  SizedBox(height: compact ? 3 : 6),
                  Text(
                    activity.dateLabel,
                    style: TextStyle(
                      color: _TrackingReportScreenState._muted,
                      fontSize: compact ? 13 : 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, {required int initialTab}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      backgroundColor: Colors.transparent,
      builder: (context) => _LeadDetailsSheet(
        activity: activity,
        activities: relatedActivities.isEmpty ? [activity] : relatedActivities,
        initialTab: initialTab,
      ),
    );
  }
}

class _LeadDetailsSheet extends StatefulWidget {
  final _Activity activity;
  final List<_Activity> activities;
  final int initialTab;

  const _LeadDetailsSheet({
    required this.activity,
    required this.activities,
    required this.initialTab,
  });

  @override
  State<_LeadDetailsSheet> createState() => _LeadDetailsSheetState();
}

class _LeadDetailsSheetState extends State<_LeadDetailsSheet> {
  late int _tab = widget.initialTab;

  List<_Activity> get _sortedActivities {
    final items = [...widget.activities];
    items.sort((a, b) {
      final aStep = int.tryParse(a.step) ?? 999;
      final bStep = int.tryParse(b.step) ?? 999;
      return aStep.compareTo(bStep);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final activities = _sortedActivities;
    final variants = <String, _Activity>{};
    for (final item in activities) {
      variants.putIfAbsent(item.variant, () => item);
    }

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141719),
          border: Border.all(
            color: _TrackingReportScreenState._gold,
            width: 1.2,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 30,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF676A6E),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 18, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lead Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.activity.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _TrackingReportScreenState._muted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${activities.length} ${activities.length == 1 ? 'step' : 'steps'}',
                            style: const TextStyle(
                              color: _TrackingReportScreenState._muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF4A4E52)),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Container(
                  height: 48,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF45494D)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _tabButton(
                        0,
                        Icons.format_list_bulleted_rounded,
                        'Steps',
                      ),
                      _tabButton(1, Icons.view_in_ar_outlined, 'Variants'),
                      _tabButton(2, Icons.share_outlined, 'Social'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _tab == 0
                      ? ListView.builder(
                          key: const ValueKey('steps'),
                          padding: const EdgeInsets.fromLTRB(28, 22, 24, 14),
                          itemCount: activities.length,
                          itemBuilder: (context, index) => _timelineItem(
                            activities[index],
                            index,
                            activities.length,
                          ),
                        )
                      : _tab == 1
                      ? ListView(
                          key: const ValueKey('variants'),
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
                          children: variants.entries
                              .map(
                                (entry) => _variantCard(entry.key, entry.value),
                              )
                              .toList(),
                        )
                      : _socialDetails(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _TrackingReportScreenState._gold,
                      side: const BorderSide(
                        color: _TrackingReportScreenState._gold,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String label) {
    final selected = _tab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF242116) : Colors.transparent,
            border: selected
                ? Border.all(color: _TrackingReportScreenState._gold)
                : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected
                    ? _TrackingReportScreenState._gold
                    : _TrackingReportScreenState._muted,
                size: 20,
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? _TrackingReportScreenState._gold
                      : _TrackingReportScreenState._muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timelineItem(_Activity item, int index, int total) {
    final colors = _StatusColors.forStatus(item.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 1.4),
                  ),
                  child: Icon(
                    _statusIcon(item.status),
                    color: colors.foreground,
                    size: 24,
                  ),
                ),
                if (index < total - 1)
                  Expanded(
                    child: Container(width: 1, color: const Color(0xFF5A5E62)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step ${item.step}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: colors.background,
                          border: Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            color: colors.foreground,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.timeLabel,
                    style: const TextStyle(
                      color: _TrackingReportScreenState._muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.dateLabel,
                    style: const TextStyle(
                      color: _TrackingReportScreenState._muted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _variantCard(String variant, _Activity item) {
    final colors = _StatusColors.forStatus(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101315),
        border: Border.all(color: const Color(0xFF3F4347)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: _TrackingReportScreenState._gold),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              variant,
              style: const TextStyle(
                color: _TrackingReportScreenState._gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Variant $variant',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _TrackingReportScreenState._muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.background,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.status,
              style: TextStyle(color: colors.foreground, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialDetails() {
    return ListView(
      key: const ValueKey('social'),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF101315),
            border: Border.all(color: const Color(0xFF3F4347)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.share_outlined,
                    color: _TrackingReportScreenState._gold,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Social Profiles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _TrackingReportScreenState._gold.withValues(
                      alpha: 0.08,
                    ),
                    border: Border.all(
                      color: _TrackingReportScreenState._gold.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(
                      color: _TrackingReportScreenState._gold,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'Social profile tracking will be available soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _TrackingReportScreenState._muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'seen':
        return Icons.visibility_outlined;
      case 'failed':
        return Icons.close_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'interested':
        return Icons.favorite_outline_rounded;
      default:
        return Icons.check_rounded;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool compact;
  final VoidCallback onPressed;
  const _Tag(this.label, {this.compact = false, required this.onPressed});
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: _TrackingReportScreenState._gold.withValues(alpha: 0.82),
      backgroundColor: _TrackingReportScreenState._gold.withValues(
        alpha: 0.035,
      ),
      side: BorderSide(
        color: _TrackingReportScreenState._gold.withValues(alpha: 0.72),
        width: 1.25,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 18,
        vertical: compact ? 5 : 9,
      ),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: TextStyle(
        fontSize: compact ? 11 : 16,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(label),
  );
}

class _BottomNavigation extends StatelessWidget {
  final ValueChanged<String>? onNavigate;
  const _BottomNavigation({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      decoration: const BoxDecoration(
        color: Color(0xFF080B0D),
        border: Border(top: BorderSide(color: Color(0xFF41454A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Dashboard',
            onTap: () => onNavigate?.call('Dashboard'),
          ),
          _NavItem(
            icon: Icons.group_outlined,
            label: 'Leads',
            onTap: () => onNavigate?.call('Leads'),
          ),
          Transform.translate(
            offset: const Offset(0, -26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => onNavigate?.call('Leads'),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 98,
                    height: 98,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD45E), Color(0xFFF2A919)],
                      ),
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 50),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add Lead',
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ],
            ),
          ),
          _NavItem(
            icon: Icons.account_tree_outlined,
            label: 'Sequences',
            onTap: () => onNavigate?.call('Master'),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => onNavigate?.call('Integration'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFBBBCC7), size: 39),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFBBBCC7), fontSize: 16),
          ),
        ],
      ),
    ),
  );
}

class _Activity {
  final String initial;
  final String name;
  final String email;
  final String status;
  final String subject;
  final String step;
  final String variant;
  final String timeLabel;
  final String dateLabel;
  const _Activity({
    required this.initial,
    required this.name,
    required this.email,
    required this.status,
    required this.subject,
    required this.step,
    required this.variant,
    required this.timeLabel,
    required this.dateLabel,
  });
}

class _StatusColors {
  final Color background;
  final Color border;
  final Color foreground;
  const _StatusColors(this.background, this.border, this.foreground);

  static _StatusColors forStatus(String status) {
    switch (status.toLowerCase()) {
      case 'seen':
        return const _StatusColors(
          Color(0xFF092F32),
          Color(0xFF16777E),
          Color(0xFF72E3E8),
        );
      case 'interested':
        return const _StatusColors(
          Color(0xFF0A3217),
          Color(0xFF1F742E),
          Color(0xFFE7EF70),
        );
      case 'not interested':
        return const _StatusColors(
          Color(0xFF3A2410),
          Color(0xFF9C6221),
          Color(0xFFFFC56D),
        );
      case 'replied':
        return const _StatusColors(
          Color(0xFF21153C),
          Color(0xFF7051AA),
          Color(0xFFD6C0FF),
        );
      case 'failed':
        return const _StatusColors(
          Color(0xFF3A1116),
          Color(0xFFA6323E),
          Color(0xFFFF8D98),
        );
      case 'pending':
        return const _StatusColors(
          Color(0xFF302A12),
          Color(0xFF887528),
          Color(0xFFFFDE6A),
        );
      case 'sent':
      default:
        return const _StatusColors(
          Color(0xFF0A3217),
          Color(0xFF1F742E),
          Color(0xFFE7EF70),
        );
    }
  }
}
