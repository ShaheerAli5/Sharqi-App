import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
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

  String _selectedMonth = 'Jun, 2025';
  final List<String> _months = [
    'Jun, 2025',
    'May, 2025',
    'Apr, 2025',
    'Mar, 2025',
  ];

  final List<AttendanceGroup> _attendanceData = const [
    AttendanceGroup(
      dateRangeLabel: 'JUN 30 – JUL 6',
      groupTotalHours: '9.56',
      records: [
        AttendanceRecord(
          dateNum: '30',
          dayName: 'MON',
          timeRange: '08:32 – 18:28',
          totalHours: '09.56',
          otHours: '+00.56',
          isApproved: false,
        ),
      ],
    ),
    AttendanceGroup(
      dateRangeLabel: 'JUN 23 – JUN 29',
      groupTotalHours: '55.01',
      records: [
        AttendanceRecord(
          dateNum: '29',
          dayName: 'SUN',
          timeRange: '08:50 – 19:51',
          totalHours: '11.01',
          otHours: '+02.01',
          isApproved: true,
        ),
        AttendanceRecord(
          dateNum: '28',
          dayName: 'SAT',
          timeRange: '08:35 – 18:35',
          totalHours: '10.00',
          otHours: '+01.00',
          isApproved: true,
        ),
        AttendanceRecord(
          dateNum: '26',
          dayName: 'THU',
          timeRange: '08:34 – 18:30',
          totalHours: '09.56',
          otHours: '+00.56',
          isApproved: false,
        ),
        AttendanceRecord(
          dateNum: '25',
          dayName: 'WED',
          timeRange: '08:48 – 18:34',
          totalHours: '09.45',
          otHours: '+00.45',
          isApproved: false,
        ),
        AttendanceRecord(
          dateNum: '24',
          dayName: 'TUE',
          timeRange: '08:52 – 19:42',
          totalHours: '10.50',
          otHours: '+01.50',
          isApproved: true,
        ),
        AttendanceRecord(
          dateNum: '23',
          dayName: 'MON',
          timeRange: '08:54 – 08:54',
          totalHours: '00.00',
          otHours: null,
          isApproved: false,
        ),
      ],
    ),
    AttendanceGroup(
      dateRangeLabel: 'JUN 16 – JUN 22',
      groupTotalHours: '58.40',
      records: [
        AttendanceRecord(
          dateNum: '20',
          dayName: 'FRI',
          timeRange: '10:11 – 19:16',
          totalHours: '09.05',
          otHours: '+00.05',
          isApproved: false,
        ),
        AttendanceRecord(
          dateNum: '19',
          dayName: 'THU',
          timeRange: '10:19 – 20:03',
          totalHours: '09.43',
          otHours: '+00.43',
          isApproved: false,
        ),
        AttendanceRecord(
          dateNum: '18',
          dayName: 'WED',
          timeRange: '10:56 – 22:49',
          totalHours: '11.53',
          otHours: '+02.53',
          isApproved: true,
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
                  children: [
                    // Top Summary Card (PRESENT: 18, ABSENT: 2, TOTAL OT: 47h, APPROVED: 12)
                    _buildSummaryCard(),

                    const SizedBox(height: 20),

                    // RECORDS Header & Month Selector Row
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

                    // Attendance Groups List
                    ListView.separated(
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
              value: '18',
              label: 'PRESENT',
              valueColor: const Color(0xFF1E854A), // Green
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildSummaryItem(
              value: '2',
              label: 'ABSENT',
              valueColor: const Color(0xFFC6134B), // Maroon
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildSummaryItem(
              value: '47h',
              label: 'TOTAL OT',
              valueColor: const Color(0xFF8A5A10), // Brown
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildSummaryItem(
              value: '12',
              label: 'APPROVED',
              valueColor: const Color(0xFF1A1310), // Dark
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

  Widget _buildRecordRow(AttendanceRecord record) {
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

          // Time Range
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

          // Total Hours
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
            const SizedBox(width: 8),
          ] else ...[
            const SizedBox(width: 52), // Placeholder alignment spacer
          ],

          // Approval Status Indicator Icon
          if (record.isApproved)
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE2F7EB), // Soft green
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 12,
                color: Color(0xFF1E854A), // Green check
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

              // Title Text: "ATTENDANCE LIST"
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
