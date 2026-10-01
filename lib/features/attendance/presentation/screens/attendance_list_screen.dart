import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../../data/models/attendance_item.dart';
import '../../../../routes/app_routes.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _repository = AttendanceRepository();
  late DateTime _selectedMonth;
  bool _isLoading = true;
  List<AttendanceItem> _records = const [];

  static const _navy = Color(0xFF080D30);
  static const _muted = Color(0xFF7180A3);
  static const _green = Color(0xFF00A65A);
  static const _red = Color(0xFFFF1744);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    try {
      final month = _selectedMonth.month.toString().padLeft(2, '0');
      final prefix = '${_selectedMonth.year}-$month';
      final lastDay = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
      ).day;
      final records = await _repository.getAttendanceList(
        startDate: '$prefix-01',
        endDate: '$prefix-${lastDay.toString().padLeft(2, '0')}',
      );
      records.removeWhere(
        (record) => record.date.isNotEmpty && !record.date.startsWith(prefix),
      );
      records.sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.sTime.compareTo(a.sTime);
      });
      if (mounted) setState(() => _records = records);
    } catch (_) {
      if (mounted) setState(() => _records = const []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
    _fetchAttendance();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        backgroundColor: const Color(0xFFF6FAFD),
        body: Column(children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchAttendance,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildMonthSelector(),
                  ),
                  const SizedBox(height: 8),
                  _buildAttendanceCard(),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.splashGradientStart,
              AppColors.splashGradientMiddle,
              AppColors.splashGradientEnd,
            ],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 60,
            child: Stack(alignment: Alignment.center, children: [
              Positioned(
                left: 14,
                child: _headerButton(
                  Icons.menu_rounded,
                  () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
              const Text(
                'Attendance List',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Positioned(
                right: 14,
                child: _headerButton(
                  Icons.filter_alt_rounded,
                  _showMonthPicker,
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _headerButton(IconData icon, VoidCallback onTap) => Material(
        color: Colors.white.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, color: Colors.white, size: 23),
          ),
        ),
      );

  Widget _buildMonthSelector() => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: _cardDecoration(17),
        child: Row(children: [
          _monthArrow(Icons.chevron_left_rounded, () => _changeMonth(-1)),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _showMonthPicker,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: _navy,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    _monthLabel(_selectedMonth),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: _navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]),
            ),
          ),
          _monthArrow(Icons.chevron_right_rounded, () => _changeMonth(1)),
        ]),
      );

  Widget _monthArrow(IconData icon, VoidCallback onTap) => Material(
        color: const Color(0xFFF8F7FD),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, color: _navy, size: 20),
          ),
        ),
      );

  Widget _buildAttendanceCard() => Container(
        clipBehavior: Clip.antiAlias,
        decoration: _cardDecoration(18),
        child: Column(children: [
          _buildTableHeader(),
          if (_isLoading)
            const SizedBox(
              height: 260,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_records.isEmpty)
            const SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'No attendance records found',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: _muted,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 7),
              child: Column(
                children: _records.map(_buildRecordRow).toList(),
              ),
            ),
        ]),
      );

  BoxDecoration _cardDecoration(double radius) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF21385B).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      );

  Widget _buildTableHeader() => Container(
        height: 44,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF4F7), Color(0xFFFFEAF0)],
          ),
        ),
        child: Row(children: [
          _headerCell(Icons.calendar_today_outlined, 'Date', 26),
          _headerCell(Icons.article_outlined, 'Status', 25),
          _headerCell(Icons.access_time_rounded, 'Time-In', 23),
          _headerCell(Icons.access_time_rounded, 'Time-Out', 26),
        ]),
      );

  Widget _headerCell(IconData icon, String label, int flex) => Expanded(
        flex: flex,
        child: Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: Colors.white, width: 1.5)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AppColors.primary, size: 15),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),
        ),
      );

  Widget _buildRecordRow(AttendanceItem record) {
    final date = DateTime.tryParse(record.date);
    final present = record.workHours > 0 || _hasTime(record.sTime);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => _showDetails(record),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFE8EDF4)),
              gradient: LinearGradient(
                colors: [
                  present
                      ? _green.withValues(alpha: 0.045)
                      : _red.withValues(alpha: 0.045),
                  Colors.white,
                ],
                stops: const [0, 0.28],
              ),
            ),
            child: Row(children: [
              Expanded(flex: 27, child: _dateCell(date, record.date)),
              Expanded(flex: 26, child: _statusChip(present)),
              Expanded(flex: 22, child: _timeChip(record.sTime, true)),
              Expanded(
                flex: 25,
                child: Row(children: [
                  Expanded(child: _timeChip(record.eTime, false)),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: _muted,
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _dateCell(DateTime? date, String fallback) {
    final text = date == null
        ? fallback
        : '${date.day.toString().padLeft(2, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.year.toString().substring(2)}';
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: _navy,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            date == null ? '' : _weekday(date.weekday),
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: _muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool present) {
    final color = present ? _green : _red;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            present ? 'Present' : 'Absent',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _timeChip(String value, bool timeIn) {
    final available = _hasTime(value);
    final color = timeIn ? _green : _red;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      decoration: BoxDecoration(
        color: available
            ? color.withValues(alpha: 0.075)
            : const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          Icons.access_time_rounded,
          color: available ? color : _muted,
          size: 13,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            _formatTime(value),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: _navy,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ]),
    );
  }

  void _showDetails(AttendanceItem record) {
    final present = record.workHours > 0 || _hasTime(record.sTime);
    final statusColor = present ? _green : _red;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFD),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC6134B), Color(0xFF850D37)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ATTENDANCE RECORD',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Color(0xFFFFC8D9),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _detailDateLabel(record.date),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            present ? 'Present' : 'Absent',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: statusColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7ECF3)),
                ),
                child: Row(
                  children: [
                    _timePoint(
                      'CLOCK IN',
                      _formatTime(record.sTime),
                      _green,
                      Icons.login_rounded,
                    ),
                    Column(
                      children: [
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFFB3BDD0),
                          size: 20,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${record.workHours.toStringAsFixed(2)} h',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: _muted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    _timePoint(
                      'CLOCK OUT',
                      _formatTime(record.eTime),
                      _red,
                      Icons.logout_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      Icons.schedule_rounded,
                      'Work hours',
                      '${record.workHours.toStringAsFixed(2)} h',
                      const Color(0xFF3156C8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      Icons.bolt_rounded,
                      'Overtime',
                      '${record.overtimeHours.toStringAsFixed(2)} h',
                      const Color(0xFFE48A00),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timePoint(
    String label,
    String value,
    Color color,
    IconData icon,
  ) =>
      Expanded(
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: _muted,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Widget _metricCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: _muted,
                      fontSize: 9.5,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: _navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _sheetHandle() => Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFDCE1E9),
          borderRadius: BorderRadius.circular(4),
        ),
      );

  void _showMonthPicker() {
    final now = DateTime.now();
    final months = List.generate(
      12,
      (index) => DateTime(now.year, now.month - index),
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(),
            const SizedBox(height: 14),
            const Text(
              'Select Month',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: _navy,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: months.length,
                itemBuilder: (context, index) {
                  final month = months[index];
                  final selected = month.year == _selectedMonth.year &&
                      month.month == _selectedMonth.month;
                  return ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(_monthLabel(month)),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedMonth = month);
                      _fetchAttendance();
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  static bool _hasTime(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isNotEmpty &&
        normalized != '—' &&
        normalized != 'n/a' &&
        normalized != 'false';
  }

  static String _formatTime(String value) {
    if (!_hasTime(value)) return '--:--';
    final cleaned = value.trim().replaceAll('.', ':');
    final parts = cleaned.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return '${hour.toString().padLeft(2, '0')}:'
            '${minute.toString().padLeft(2, '0')}';
      }
    }
    final decimal = double.tryParse(value);
    if (decimal != null) {
      final hour = decimal.floor();
      final minute = ((decimal - hour) * 60).round();
      return '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
    }
    return value;
  }

  static String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]}, ${date.year}';
  }

  static String _detailDateLabel(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
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
    return '${_weekday(date.weekday)}, ${date.day} '
        '${months[date.month - 1]} ${date.year}';
  }

  static String _weekday(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
