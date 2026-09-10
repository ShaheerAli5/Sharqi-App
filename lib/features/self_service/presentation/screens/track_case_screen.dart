import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../../core/services/storage_service.dart';

class TrackCaseArguments {
  final String labelText;
  final String hintText;
  final String buttonText;

  const TrackCaseArguments({
    this.labelText = 'INCIDENT CODE',
    this.hintText = 'e.g. INC-20481',
    this.buttonText = 'Search Case',
  });
}

class TrackCaseScreen extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final String? buttonText;

  const TrackCaseScreen({
    super.key,
    this.labelText,
    this.hintText,
    this.buttonText,
  });

  @override
  State<TrackCaseScreen> createState() => _TrackCaseScreenState();
}

class _TrackCaseScreenState extends State<TrackCaseScreen> {
  final TextEditingController _codeController = TextEditingController();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isLoading = true;
  String? _searchError;
  List<Map<String, dynamic>> _cases = [];

  @override
  void initState() {
    super.initState();
    _fetchCases();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchCases({String searchCode = ''}) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _searchError = null;
    });

    try {
      final caseList =
          await _attendanceRepository.getEmployeeCases(code: searchCode);
      if (!mounted) return;

      setState(() {
        _cases = caseList;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = 'Failed to fetch case status from backend: $e';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCaseCard(Map<String, dynamic> data) {
    final code = data['code']?.toString() ??
        data['reference']?.toString() ??
        data['name']?.toString() ??
        data['id']?.toString() ??
        'Case Record';
    final category = data['category']?.toString() ??
        data['type']?.toString() ??
        data['title']?.toString() ??
        'Self Service Request';
    final status = data['status']?.toString() ??
        data['state']?.toString() ??
        data['stage']?.toString() ??
        'Submitted';
    final date = data['date']?.toString() ??
        data['created_at']?.toString() ??
        data['submission_date']?.toString() ??
        '';
    final empName = data['employee_name']?.toString() ??
        data['emp_name']?.toString() ??
        StorageService.getValue(StorageService.keyFullName);
    final empNo = data['emp_no']?.toString() ??
        data['employee_number']?.toString() ??
        StorageService.getValue(StorageService.keyEmpNo);
    final description = data['description']?.toString() ??
        data['note']?.toString() ??
        data['reason']?.toString();
    final remarks = data['manager_comment']?.toString() ??
        data['remarks']?.toString() ??
        data['comment']?.toString();

    // Status badge color logic
    Color badgeBg = const Color(0xFFFDE8EE);
    Color badgeText = AppColors.primary;

    final statusLower = status.toLowerCase();
    if (statusLower.contains('approve') ||
        statusLower.contains('done') ||
        statusLower.contains('resolve') ||
        statusLower.contains('close')) {
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = const Color(0xFF2E7D32);
    } else if (statusLower.contains('progress') ||
        statusLower.contains('review') ||
        statusLower.contains('pending')) {
      badgeBg = const Color(0xFFFFF8E1);
      badgeText = const Color(0xFFF57F17);
    } else if (statusLower.contains('reject') ||
        statusLower.contains('cancel')) {
      badgeBg = const Color(0xFFFFEBEE);
      badgeText = const Color(0xFFC62828);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                code,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1310),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _buildInfoRow('Category', category),
          if (empName.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
                'Employee', empNo.isNotEmpty ? '$empName ($empNo)' : empName),
          ],
          if (date.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Date', date),
          ],
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Details', description),
          ],
          if (remarks != null && remarks.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Remarks', remarks),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B5D58),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1310),
            ),
          ),
        ),
      ],
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

    final args = ModalRoute.of(context)?.settings.arguments as TrackCaseArguments?;
    final effectiveLabelText = widget.labelText ?? args?.labelText ?? 'INCIDENT CODE';
    final effectiveHintText = widget.hintText ?? args?.hintText ?? 'e.g. INC-20481';
    final effectiveButtonText = widget.buttonText ?? args?.buttonText ?? 'Search Case';

    return Scaffold(
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
                color: Color(0xFFFBF6F3),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: RefreshIndicator(
                onRefresh: () => _fetchCases(searchCode: _codeController.text.trim()),
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    children: [
                      // Floating Search Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                            bottomLeft: Radius.circular(6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: effectiveLabelText,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF5E5855),
                                          letterSpacing: 0.0,
                                          height: 1.0,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' *',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFC6134B),
                                          letterSpacing: 0.0,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                SizedBox(
                                  height: 44,
                                  child: TextFormField(
                                    controller: _codeController,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      color: Color(0xFF1A1310),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: effectiveHintText,
                                      hintStyle: const TextStyle(
                                        fontFamily: 'Outfit',
                                        color: Color(0xFFA0A0A0),
                                        fontSize: 14,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFFAF7F5),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE8DFE1),
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _fetchCases(
                                                searchCode:
                                                    _codeController.text.trim(),
                                              ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFC6134B),
                                        disabledBackgroundColor:
                                            Colors.grey.shade400,
                                        elevation: 0,
                                        padding: const EdgeInsets.fromLTRB(
                                            6, 1, 6, 1),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(26),
                                            topRight: Radius.circular(26),
                                            bottomRight: Radius.circular(26),
                                            bottomLeft: Radius.circular(6),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            effectiveButtonText,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            softWrap: false,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              letterSpacing: 0.16,
                                              height: 1.0,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.search_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (_codeController.text.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      _codeController.clear();
                                      _fetchCases(searchCode: '');
                                    },
                                    icon: const Icon(Icons.clear_rounded,
                                        color: AppColors.primary),
                                    tooltip: 'Show All Cases',
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Search Results Display Area
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: AppColors.primary),
                                SizedBox(height: 12),
                                Text(
                                  'Fetching case records from backend...',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_searchError != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF9A9A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Color(0xFFC62828)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _searchError!,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    color: Color(0xFFC62828),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_cases.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_open_rounded,
                                  size: 48, color: Color(0xFF887775)),
                              SizedBox(height: 12),
                              Text(
                                'No data exists',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1310),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'No self-service case records found for this employee account.',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  color: Color(0xFF666666),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cases.length,
                          itemBuilder: (context, index) {
                            return _buildCaseCard(_cases[index]);
                          },
                        ),
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
              const SizedBox(
                height: 15,
                child: Center(
                  child: Text(
                    'TRACK CASE',
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
