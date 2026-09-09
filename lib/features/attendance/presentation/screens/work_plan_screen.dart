import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';

enum WorkDayType { workDay, offDay, leave }

class WorkPlanRecord {
  final String dateNum;
  final String dayName;
  final WorkDayType type;
  final String? timeRange;
  final String? totalHours;
  final String? otHours;

  const WorkPlanRecord({
    required this.dateNum,
    required this.dayName,
    required this.type,
    this.timeRange,
    this.totalHours,
    this.otHours,
  });
}

class WorkPlanGroup {
  final String dateRangeLabel;
  final String groupTotalHours;
  final List<WorkPlanRecord> records;

  const WorkPlanGroup({
    required this.dateRangeLabel,
    required this.groupTotalHours,
    required this.records,
  });
}

class WorkPlanScreen extends StatefulWidget {
  const WorkPlanScreen({super.key});

  @override
  State<WorkPlanScreen> createState() => _WorkPlanScreenState();
}

class _WorkPlanScreenState extends State<WorkPlanScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isLoading = true;
  bool _isInitialLoad = true;
  List<WorkPlanGroup> _workPlanData = [];
  int _workDays = 0;
  int _offDays = 0;
  int _leaveDays = 0;
  double _totalOt = 0.0;
  String _locationName = '';

  late String _selectedMonth;
  late List<String> _months;

  @override
  void initState() {
    super.initState();
    _months = _generateDynamicMonths();
    _selectedMonth = _months.isNotEmpty ? _months.first : _formatMonthYear(DateTime.now());
    _fetchWorkPlan();
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

  static String _formatDecimalToTime(double val) {
    if (val <= 0) return '00:00';
    final h = val.floor() % 24;
    final m = ((val - val.floor()) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchWorkPlan() async {
    setState(() => _isLoading = true);
    try {
      final dates = _getStartAndEndDateForMonth(_selectedMonth);
      final list = await _attendanceRepository.getWorkPlan(
        startDate: dates?['start_date'],
        endDate: dates?['end_date'],
      );

      final Set<String> availableMonths = {};
      for (var item in list) {
        if (item.date.length >= 7) {
          final dt = DateTime.tryParse(item.date);
          if (dt != null) {
            availableMonths.add(_formatMonthYear(dt));
          }
        }
      }

      for (var m in availableMonths) {
        if (!_months.contains(m)) {
          _months.add(m);
        }
      }

      String monthToUse = _selectedMonth;
      if (_isInitialLoad && availableMonths.isNotEmpty) {
        final currentMonthPrefix = dates?['start_date']?.substring(0, 7);
        final hasCurrentData = list.any((item) => item.date.startsWith(currentMonthPrefix ?? ''));
        if (!hasCurrentData) {
          monthToUse = availableMonths.first;
          _selectedMonth = monthToUse;
        }
        _isInitialLoad = false;
      }

      final targetDates = _getStartAndEndDateForMonth(monthToUse);
      final monthPrefix = targetDates?['start_date'] != null && targetDates!['start_date']!.length >= 7
          ? targetDates['start_date']!.substring(0, 7)
          : null;

      final displayList = monthPrefix != null
          ? list.where((item) => item.date.startsWith(monthPrefix)).toList()
          : list;

      // Sort displayList descending by date and workFrom so newest date/day shows on top
      displayList.sort((a, b) {
        int cmp = b.date.compareTo(a.date);
        if (cmp != 0) return cmp;
        return b.workFrom.compareTo(a.workFrom);
      });

      String locName = '';
      for (var item in displayList) {
        if (item.location.isNotEmpty) {
          locName = item.location;
          break;
        } else if (item.area.isNotEmpty) {
          locName = item.area;
          break;
        }
      }
      if (locName.isEmpty) {
        for (var item in list) {
          if (item.location.isNotEmpty) {
            locName = item.location;
            break;
          } else if (item.area.isNotEmpty) {
            locName = item.area;
            break;
          }
        }
      }

      Map<String, List<dynamic>> groupsMap = {};
      int workDays = 0;
      int offDays = 0;
      int leaveDays = 0;
      double totalOt = 0.0;

      for (var item in displayList) {
        final wType = item.workType.toLowerCase();
        if (wType.contains('off') || item.totalHours == 0) {
          offDays++;
        } else if (wType.contains('leave')) {
          leaveDays++;
        } else {
          workDays++;
        }
        totalOt += item.overtimeHours;

        DateTime? dt;
        if (item.date.isNotEmpty) {
          dt = DateTime.tryParse(item.date);
        }
        final weekLabel = dt != null ? _getWeekRangeLabel(dt) : 'SCHEDULE';

        groupsMap.putIfAbsent(weekLabel, () => []).add(item);
      }

      List<WorkPlanGroup> groups = [];
      groupsMap.forEach((label, items) {
        double groupHours = 0.0;
        List<WorkPlanRecord> recs = [];

        for (var item in items) {
          groupHours += item.totalHours;

          WorkDayType type = WorkDayType.workDay;
          final wType = item.workType.toLowerCase();
          if (wType.contains('off') || item.totalHours == 0) {
            type = WorkDayType.offDay;
          } else if (wType.contains('leave')) {
            type = WorkDayType.leave;
          } else {
            type = WorkDayType.workDay;
          }

          String dayName = '';
          final daysList = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
          if (item.date.isNotEmpty) {
            final dt = DateTime.tryParse(item.date);
            if (dt != null) {
              dayName = daysList[dt.weekday - 1];
            }
          }
          if (dayName.isEmpty && item.dayOfWeek.isNotEmpty) {
            final idx = int.tryParse(item.dayOfWeek);
            if (idx != null && idx >= 0 && idx < 7) {
              dayName = daysList[idx];
            } else {
              dayName = item.dayOfWeek.toUpperCase();
            }
          }

          final fromStr = _formatDecimalToTime(item.workFrom);
          final toStr = _formatDecimalToTime(item.workTo);
          final timeRangeStr = (type == WorkDayType.workDay && (item.workFrom > 0 || item.workTo > 0))
              ? '$fromStr – $toStr'
              : null;

          recs.add(WorkPlanRecord(
            dateNum: item.date.isNotEmpty ? item.date.split('-').last.padLeft(2, '0') : '',
            dayName: dayName,
            type: type,
            timeRange: timeRangeStr,
            totalHours: type == WorkDayType.workDay ? item.totalHours.toStringAsFixed(2).padLeft(5, '0') : null,
            otHours: item.overtimeHours > 0 ? '+${item.overtimeHours.toStringAsFixed(2).padLeft(5, '0')}' : null,
          ));
        }

        groups.add(WorkPlanGroup(
          dateRangeLabel: label,
          groupTotalHours: groupHours.toStringAsFixed(2),
          records: recs,
        ));
      });

      setState(() {
        _locationName = locName;
        _workDays = workDays;
        _offDays = offDays;
        _leaveDays = leaveDays;
        _totalOt = totalOt;
        _workPlanData = groups;
      });
    } catch (_) {
      setState(() => _workPlanData = []);
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
                          _fetchWorkPlan();
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Color(0xFF5E5855),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _locationName.isNotEmpty
                                  ? _locationName
                                  : (StorageService.getValue(StorageService.keyCompanyName).isNotEmpty
                                      ? StorageService.getValue(StorageService.keyCompanyName)
                                      : 'Work Location'),
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1310),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SCHEDULE',
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
                      _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            )
                          : _workPlanData.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: Center(
                                    child: Text(
                                      'No work plan records found',
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
                                  itemCount: _workPlanData.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 24),
                                  itemBuilder: (context, index) {
                                    final group = _workPlanData[index];
                                    return _buildWorkPlanGroup(group);
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
              value: _workDays.toString(),
              label: 'WORK DAYS',
              valueColor: const Color(0xFF1E854A),
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildSummaryItem(
              value: _offDays.toString(),
              label: 'OFF DAYS',
              valueColor: const Color(0xFF1A1310),
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildSummaryItem(
              value: _leaveDays.toString(),
              label: 'LEAVE',
              valueColor: const Color(0xFFC6134B),
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildSummaryItem(
              value: '${_totalOt.toStringAsFixed(0)}h',
              label: 'TOTAL OT',
              valueColor: const Color(0xFF8A5A10),
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

  Widget _buildWorkPlanGroup(WorkPlanGroup group) {
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

  Widget _buildRecordRow(WorkPlanRecord record) {
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
          _buildDayTypeBadge(record.type),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              record.timeRange ?? '—',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: record.type == WorkDayType.workDay
                    ? const Color(0xFF555555)
                    : const Color(0xFF888888),
              ),
            ),
          ),
          if (record.totalHours != null) ...[
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: record.totalHours!,
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
          ],
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
          ],
        ],
      ),
    );
  }

  Widget _buildDayTypeBadge(WorkDayType type) {
    Color bgColor;
    Color textColor;
    String label;

    switch (type) {
      case WorkDayType.workDay:
        bgColor = const Color(0xFFE2F7EB);
        textColor = const Color(0xFF1E854A);
        label = 'WORK DAY';
        break;
      case WorkDayType.offDay:
        bgColor = const Color(0xFFEFECE8);
        textColor = const Color(0xFF666666);
        label = 'OFF DAY';
        break;
      case WorkDayType.leave:
        bgColor = const Color(0xFFFDE8EE);
        textColor = const Color(0xFFC6134B);
        label = 'LEAVE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.2,
        ),
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
                    'WORK PLAN',
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
