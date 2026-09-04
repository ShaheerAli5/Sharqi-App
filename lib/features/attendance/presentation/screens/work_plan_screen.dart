import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
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

  String _selectedMonth = 'Jun, 2025';
  final List<String> _months = [
    'Jun, 2025',
    'May, 2025',
    'Apr, 2025',
    'Mar, 2025',
  ];

  final List<WorkPlanGroup> _workPlanData = const [
    WorkPlanGroup(
      dateRangeLabel: 'JUN 23 – JUN 29',
      groupTotalHours: '27.00',
      records: [
        WorkPlanRecord(
          dateNum: '25',
          dayName: 'WED',
          type: WorkDayType.workDay,
          timeRange: '15:00 – 01:00',
          totalHours: '09.00',
          otHours: '+01.00',
        ),
        WorkPlanRecord(
          dateNum: '24',
          dayName: 'TUE',
          type: WorkDayType.workDay,
          timeRange: '15:00 – 01:00',
          totalHours: '09.00',
          otHours: '+01.00',
        ),
        WorkPlanRecord(
          dateNum: '23',
          dayName: 'MON',
          type: WorkDayType.workDay,
          timeRange: '15:00 – 01:00',
          totalHours: '09.00',
          otHours: '+01.00',
        ),
      ],
    ),
    WorkPlanGroup(
      dateRangeLabel: 'JUN 16 – JUN 22',
      groupTotalHours: '45.00',
      records: [
        WorkPlanRecord(
          dateNum: '22',
          dayName: 'SUN',
          type: WorkDayType.workDay,
          timeRange: '15:00 – 01:00',
          totalHours: '09.00',
          otHours: '+01.00',
        ),
        WorkPlanRecord(
          dateNum: '21',
          dayName: 'SAT',
          type: WorkDayType.offDay,
        ),
        WorkPlanRecord(
          dateNum: '20',
          dayName: 'FRI',
          type: WorkDayType.workDay,
          timeRange: '15:00 – 01:00',
          totalHours: '09.00',
          otHours: '+01.00',
        ),
        WorkPlanRecord(
          dateNum: '19',
          dayName: 'THU',
          type: WorkDayType.workDay,
          timeRange: '15:00 – 01:00',
          totalHours: '09.00',
          otHours: '+01.00',
        ),
        WorkPlanRecord(
          dateNum: '18',
          dayName: 'WED',
          type: WorkDayType.leave,
        ),
        WorkPlanRecord(
          dateNum: '17',
          dayName: 'TUE',
          type: WorkDayType.workDay,
          timeRange: '15:00 – 01:00',
          totalHours: '09.00',
          otHours: '+01.00',
        ),
        WorkPlanRecord(
          dateNum: '16',
          dayName: 'MON',
          type: WorkDayType.workDay,
          timeRange: '15:00 – 01:00',
          totalHours: '09.00',
          otHours: '+01.00',
        ),
      ],
    ),
  ];

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

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Bar with Burgundy Gradient
          _buildHeader(context),

          // Main Body Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF6F3), // Exact Hex: #FBF6F3
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24), // Exact Radius: 24px
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
                    // Top Summary Card (WORK DAYS: 21, OFF DAYS: 3, LEAVE: 1, TOTAL OT: 21h)
                    _buildSummaryCard(),

                    const SizedBox(height: 18),

                    // Location Subtitle Row
                    Row(
                      children: const [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF5E5855),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Ritz Carlton hotel — B Lounge',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1310),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // SCHEDULE Header & Month Selector Row
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

                    // Work Plan Groups List
                    ListView.separated(
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
              value: '21',
              label: 'WORK DAYS',
              valueColor: const Color(0xFF1E854A), // Green
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildSummaryItem(
              value: '3',
              label: 'OFF DAYS',
              valueColor: const Color(0xFF1A1310), // Dark
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildSummaryItem(
              value: '1',
              label: 'LEAVE',
              valueColor: const Color(0xFFC6134B), // Maroon
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildSummaryItem(
              value: '21h',
              label: 'TOTAL OT',
              valueColor: const Color(0xFF8A5A10), // Brown
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
        // Group Header Row
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

        // Records List
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
          // Day Number & Day Name Column
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

          // Day Type Badge (WORK DAY / OFF DAY / LEAVE)
          _buildDayTypeBadge(record.type),

          const SizedBox(width: 10),

          // Time Range or Dash
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

          // Total Hours (if workDay)
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

          // Overtime Badge (if any)
          if (record.otHours != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEED9), // Soft tan/amber
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
        bgColor = const Color(0xFFE2F7EB); // Soft green
        textColor = const Color(0xFF1E854A); // Green text
        label = 'WORK DAY';
        break;
      case WorkDayType.offDay:
        bgColor = const Color(0xFFEFECE8); // Soft grey
        textColor = const Color(0xFF666666); // Grey text
        label = 'OFF DAY';
        break;
      case WorkDayType.leave:
        bgColor = const Color(0xFFFDE8EE); // Soft pink
        textColor = const Color(0xFFC6134B); // Maroon text
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
              // Back Button Container
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
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

              // Title Text: "WORK PLAN"
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
