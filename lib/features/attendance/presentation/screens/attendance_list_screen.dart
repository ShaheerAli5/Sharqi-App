import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../../routes/app_routes.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';

class AttendanceRecord {
  final String dateNum;
  final String dayName;
  final String timeRange;
  final String totalHours;
  final String? otHours;
  final bool isApproved;

  const AttendanceRecord({
    required this.dateNum,
    required this.dayName,
    required this.timeRange,
    required this.totalHours,
    this.otHours,
    this.isApproved = false,
  });
}

class AttendanceGroup {
  final String dateRangeLabel;
  final String groupTotalHours;
  final List<AttendanceRecord> records;

  const AttendanceGroup({
    required this.dateRangeLabel,
    required this.groupTotalHours,
    required this.records,
  });
}

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isLoading = true;
  List<AttendanceGroup> _attendanceData = [];
  int _presentCount = 0;
  int _absentCount = 0;
  double _totalOtHours = 0.0;
  int _approvedCount = 0;

  late String _selectedMonth;
  late List<String> _months;

  @override
  void initState() {
    super.initState();
    _months = _generateDynamicMonths();
    _selectedMonth = _months.isNotEmpty ? _months.first : _formatMonthYear(DateTime.now());
    _fetchAttendanceList();
  }

  static String _formatMonthYear(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]}, ${dt.year}';
  }

  static List<String> _generateDynamicMonths() {
    List<String> result = [];
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      result.add(_formatMonthYear(date));
    }
    return result;
  }

  static Map<String, String>? _getStartAndEndDateForMonth(String monthStr) {
    try {
      final parts = monthStr.split(', ');
      if (parts.length == 2) {
        final monthName = parts[0];
        final year = int.parse(parts[1]);
        final monthIndex = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'].indexOf(monthName) + 1;
        if (monthIndex > 0) {
          final lastDay = DateTime(year, monthIndex + 1, 0).day;
          final mStr = monthIndex.toString().padLeft(2, '0');
          return {
            'start_date': '$year-$mStr-01',
            'end_date': '$year-$mStr-${lastDay.toString().padLeft(2, '0')}',
          };
        }
      }
    } catch (_) {}
    return null;
  }

  static String _getWeekRangeLabel(DateTime dt) {
    final monday = dt.subtract(Duration(days: dt.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final monthNames = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final startM = monthNames[monday.month - 1];
    final endM = monthNames[sunday.month - 1];

    if (startM == endM) {
      return '$startM ${monday.day} – ${sunday.day}';
    } else {
      return '$startM ${monday.day} – $endM ${sunday.day}';
    }
  }

  static String _formatTimeClean(String val) {
    if (val.isEmpty || val == '—' || val == 'N/A') return '—';
    final cleaned = val.replaceAll('.', ':').trim();
    if (cleaned.contains(':')) {
      final parts = cleaned.split(':');
      final h = (int.tryParse(parts[0]) ?? 0).toString().padLeft(2, '0');
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0).toString().padLeft(2, '0') : '00';
      return '$h:$m';
    }
    final numVal = double.tryParse(val);
    if (numVal != null) {
      final h = numVal.floor().toString().padLeft(2, '0');
      final m = ((numVal - numVal.floor()) * 60).round().toString().padLeft(2, '0');
      return '$h:$m';
    }
    return val;
  }

  Future<void> _fetchAttendanceList() async {
    setState(() => _isLoading = true);
    try {
      final dates = _getStartAndEndDateForMonth(_selectedMonth);
      final list = await _attendanceRepository.getAttendanceList(
        startDate: dates?['start_date'],
        endDate: dates?['end_date'],
      );

      // Sort records by date and start time in descending order (newest date/day on top)
      list.sort((a, b) {
        int cmp = b.date.compareTo(a.date);
        if (cmp != 0) return cmp;
        return b.sTime.compareTo(a.sTime);
      });

      final monthPrefix = dates?['start_date'] != null && dates!['start_date']!.length >= 7
          ? dates['start_date']!.substring(0, 7)
          : null;

      Map<String, List<dynamic>> groupsMap = {};
      int present = 0;
      int absent = 0;
      double totalOt = 0.0;
      int approved = 0;

      for (var item in list) {
        // Strict filtering: ensure record date matches the selected month/year (e.g. "2026-09")
        if (monthPrefix != null && item.date.isNotEmpty && !item.date.startsWith(monthPrefix)) {
          continue;
        }

        if (item.workHours > 0) {
          present++;
        } else {
          absent++;
        }
        totalOt += item.overtimeHours;
        if (item.isApproved) {
          approved++;
        }

        DateTime? dt;
        if (item.date.isNotEmpty) {
          dt = DateTime.tryParse(item.date);
        }
        final weekLabel = dt != null ? _getWeekRangeLabel(dt) : 'ATTENDANCE RECORDS';

        groupsMap.putIfAbsent(weekLabel, () => []).add(item);
      }

      List<AttendanceGroup> groups = [];
      groupsMap.forEach((label, items) {
        double groupHours = 0.0;
        List<AttendanceRecord> recs = [];

        for (var item in items) {
          groupHours += item.workHours;

          String dayName = '';
          if (item.date.isNotEmpty) {
            final dt = DateTime.tryParse(item.date);
            if (dt != null) {
              final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
              dayName = days[dt.weekday - 1];
            }
          }

          final sTimeClean = _formatTimeClean(item.sTime);
          final eTimeClean = _formatTimeClean(item.eTime);
          final timeRangeStr = (sTimeClean.isNotEmpty && eTimeClean.isNotEmpty && sTimeClean != '—' && eTimeClean != '—')
              ? '$sTimeClean – $eTimeClean'
              : '—';

          recs.add(AttendanceRecord(
            dateNum: item.date.isNotEmpty ? item.date.split('-').last.padLeft(2, '0') : '',
            dayName: dayName,
            timeRange: timeRangeStr,
            totalHours: item.workHours.toStringAsFixed(2).padLeft(5, '0'),
            otHours: item.overtimeHours > 0 ? '+${item.overtimeHours.toStringAsFixed(2).padLeft(5, '0')}' : null,
            isApproved: item.isApproved,
          ));
        }

        groups.add(AttendanceGroup(
          dateRangeLabel: label,
          groupTotalHours: groupHours.toStringAsFixed(2),
          records: recs,
        ));
      });

      setState(() {
        _presentCount = present;
        _absentCount = absent;
        _totalOtHours = totalOt;
        _approvedCount = approved;
        _attendanceData = groups;
      });
    } catch (_) {
      setState(() => _attendanceData = []);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onBackPressed(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  void _showMonthSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFBF6F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Select Month',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1310),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _months.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, index) {
                      final month = _months[index];
                      final isSelected = month == _selectedMonth;
                      return ListTile(
                        title: Text(
                          month,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF1A1310),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedMonth = month;
                          });
                          Navigator.pop(context);
                          _fetchAttendanceList();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBF6F3),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 20.0,
                        ),
                        child: Column(
                          children: [
                            _buildSummaryCard(),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'RECORDS',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5E5855),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showMonthSelectionModal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_month_outlined,
                                        size: 16,
                                        color: Color(0xFFC6134B),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectedMonth,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFC6134B),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: Color(0xFFC6134B),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _attendanceData.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(40.0),
                                    child: Center(
                                      child: Text(
                                        'No attendance records found',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14,
                                          color: Color(0xFF888888),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _attendanceData.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 24),
                                    itemBuilder: (context, index) {
                                      final group = _attendanceData[index];
                                      return _buildAttendanceGroup(group);
                                    },
                                  ),
                            const SizedBox(height: 20),
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

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              value: _presentCount.toString(),
              label: 'PRESENT',
              valueColor: const Color(0xFF1E854A),
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildSummaryItem(
              value: _absentCount.toString(),
              label: 'ABSENT',
              valueColor: const Color(0xFFC6134B),
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildSummaryItem(
              value: '${_totalOtHours.toStringAsFixed(0)}h',
              label: 'TOTAL OT',
              valueColor: const Color(0xFF8A5A10),
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildSummaryItem(
              value: _approvedCount.toString(),
              label: 'APPROVED',
              valueColor: const Color(0xFF1A1310),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF888888),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFFEEEEEE),
    );
  }

  Widget _buildAttendanceGroup(AttendanceGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              group.dateRangeLabel,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF666666),
                letterSpacing: 0.3,
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: group.groupTotalHours,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC6134B),
                    ),
                  ),
                  const TextSpan(
                    text: 'h',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, color: Color(0xFFE8DFE1)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: group.records.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 16, color: Color(0xFFF2ECE8)),
          itemBuilder: (context, index) {
            final record = group.records[index];
            return _buildRecordRow(record);
          },
        ),
      ],
    );
  }

  Widget _buildRecordRow(AttendanceRecord record) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.dateNum,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1310),
                    height: 1.0,
                  ),
                ),
                Text(
                  record.dayName,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              record.timeRange,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF555555),
              ),
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: record.totalHours,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1310),
                  ),
                ),
                const TextSpan(
                  text: 'h',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (record.otHours != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEED9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                record.otHours!,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A5A10),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            const SizedBox(width: 52),
          ],
          if (record.isApproved)
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE2F7EB),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 12,
                color: Color(0xFF1E854A),
              ),
            )
          else
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFB0A8A4),
                  width: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _onBackPressed(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.fromLTRB(6, 1, 6, 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
                child: Center(
                  child: Text(
                    'ATTENDANCE LIST',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.68,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
