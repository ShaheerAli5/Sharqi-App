import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../data/models/app_models.dart';
import '../../../../routes/app_routes.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';

class RecordTimeInScreen extends StatefulWidget {
  const RecordTimeInScreen({super.key});

  @override
  State<RecordTimeInScreen> createState() => _RecordTimeInScreenState();
}

class _RecordTimeInScreenState extends State<RecordTimeInScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  List<WorkLocationItem> _locations = [];
  dynamic _selectedLocation;
  bool _isLoadingLocations = false;
  bool _isSubmitting = false;
  bool _isAlreadyTimeIn = false;
  bool _isValidationComplete = false;
  int? _todayWorkAreaId;
  String? _loadError;
  String? _checkInTimeDisplay;

  String? _detectedLocationName;

  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
    _checkStatusAndFetchLocations();
  }

  Future<void> _checkStatusAndFetchLocations() async {
    setState(() {
      _isLoadingLocations = true;
      _loadError = null;
      _isValidationComplete = false;
      _todayWorkAreaId = null;
    });
    try {
      if (kDebugMode) {
        debugPrint(
            '[RecordTimeIn] Current employee: ${StorageService.getValue(StorageService.keyEmpNo)}');
        debugPrint(
            '[RecordTimeIn] Company ID: ${StorageService.getValue(StorageService.keyCompanyId)}');
      }
      final status = await _attendanceRepository.getTodaysTimeInOut();
      if (kDebugMode) {
        debugPrint(
            '[RecordTimeIn] Attendance status: is_time_in=${status.isTimeIn}');
        debugPrint("[RecordTimeIn] Fetching today's work plan...");
      }
      final todayLoc = await _attendanceRepository.getTodayWorkLocation();
      if (kDebugMode) debugPrint('[RecordTimeIn] Plan found: true');

      if (status.isTimeIn) {
        _isAlreadyTimeIn = true;
        _checkInTimeDisplay =
            _formatCheckInTime(status.lastTimeInDatetime, _now);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('You are already checked in at $_checkInTimeDisplay.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }

      _selectedLocation = todayLoc;
      _detectedLocationName = todayLoc.name;
      _isValidationComplete = true;
      _todayWorkAreaId = todayLoc.id;
    } on NoPlanForTodayException {
      if (kDebugMode) debugPrint('[RecordTimeIn] Plan found: false');
      _selectedLocation = null;
      _detectedLocationName = null;
      _isValidationComplete = true;
      _todayWorkAreaId = null;
      if (mounted) await _showMessage('No plan found for today');
    } on AttendanceRequestException catch (error) {
      _loadError = error.message;
      if (mounted) await _handleAttendanceError(error);
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  String _formatCheckInTime(String? rawTime, DateTime fallbackDateTime) {
    if (rawTime != null && rawTime.trim().isNotEmpty) {
      final trimmed = rawTime.trim();

      if (trimmed.toUpperCase().contains('AM') ||
          trimmed.toUpperCase().contains('PM')) {
        return trimmed;
      }

      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        return _format12HourTime(parsed);
      }

      final spaceSplit = trimmed.split(' ');
      final timeStr =
          spaceSplit.length > 1 ? spaceSplit.last : spaceSplit.first;
      final timeParts = timeStr.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);
        if (hour != null && minute != null) {
          final dt = DateTime(
            fallbackDateTime.year,
            fallbackDateTime.month,
            fallbackDateTime.day,
            hour,
            minute,
          );
          return _format12HourTime(dt);
        }
      }
    }
    return _format12HourTime(fallbackDateTime);
  }

  String _format12HourTime(DateTime dt) {
    final hourOfPeriod = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final hour = hourOfPeriod.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _showLocationModal() async {
    if (_isLoadingLocations || !_isValidationComplete || _isAlreadyTimeIn) {
      return;
    }
    if (_locations.isEmpty) {
      setState(() => _isLoadingLocations = true);
      try {
        _locations = await _attendanceRepository.getWorkLocationList();
      } on AttendanceRequestException catch (error) {
        if (mounted) await _handleAttendanceError(error);
        return;
      } finally {
        if (mounted) setState(() => _isLoadingLocations = false);
      }
    }
    if (!mounted) return;
    await showModalBottomSheet(
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
                    'Select Work Location',
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
                  child: _isLoadingLocations
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _locations.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final loc = _locations[index];
                            final locName = loc.name;
                            final isSelected = _selectedLocation != null &&
                                ((_selectedLocation is WorkLocationItem &&
                                        _selectedLocation.id == loc.id) ||
                                    (_selectedLocation is TodayWorkLocation &&
                                        _selectedLocation.id == loc.id));
                            return ListTile(
                              title: Text(
                                locName,
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
                                  _selectedLocation = loc;
                                  _detectedLocationName = loc.name;
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

  Future<void> _onTimeIn() async {
    if (_isAlreadyTimeIn) {
      final timeStr = _checkInTimeDisplay ?? _formatCheckInTime(null, _now);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are already checked in at $timeStr.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final locationResult = await LocationService.getCurrentLocation();
      if (!locationResult.isSuccess) {
        throw AttendanceRequestException(
          locationResult.errorMessage ??
              'Unable to detect your current location. Please enable GPS and try again.',
        );
      }

      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Self Service'),
          content: const Text('Are you sure you want to record Time In?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('NO'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('YES'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      final now = DateTime.now();
      final timeInStr = _apiTime(now);
      if (kDebugMode) {
        debugPrint('[RecordTimeIn] Attendance type: present');
        debugPrint('[RecordTimeIn] Check-in API selected: standard');
      }
      final res = await _attendanceRepository.recordTimeIn(
        date: _apiDate(now),
        timeIn: timeInStr,
        latitude: locationResult.latitude,
        longitude: locationResult.longitude,
      );

      // Extract time from backend response if available, or use the timeInStr sent
      final serverTimeStr = res['time_in']?.toString() ??
          res['last_time_in_datetime']?.toString() ??
          res['check_in_time']?.toString() ??
          res['time']?.toString();
      final checkInTimeFormatted =
          _formatCheckInTime(serverTimeStr ?? timeInStr, _now);

      // Update area if selected location != scheduled area ID
      final timeInId = res['id'] ?? res['time_in_id'];
      final selectedId = _selectedLocation is WorkLocationItem
          ? _selectedLocation.id
          : (_selectedLocation is TodayWorkLocation
              ? _selectedLocation.id
              : null);

      if (timeInId != null &&
          selectedId != null &&
          selectedId > 0 &&
          selectedId != _todayWorkAreaId) {
        await _attendanceRepository.updateTodayWorkLocation(
          timeInId,
          selectedId,
        );
      }

      if (mounted) {
        setState(() {
          _isAlreadyTimeIn = true;
          _checkInTimeDisplay = checkInTimeFormatted;
        });

        await _showMessage(res['success'].toString());
      }
    } on AttendanceRequestException catch (error) {
      if (mounted) await _handleAttendanceError(error);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[RecordTimeIn] Unexpected check-in error: $error');
      }
      if (mounted) {
        await _showMessage('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showMessage(String message) => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Self Service'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );

  Future<void> _handleAttendanceError(AttendanceRequestException error) async {
    await _showMessage(error.message);
    if (!error.isAuthenticationError) return;
    await StorageService.clearSharedPreference();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.signIn,
        (_) => false,
      );
    }
  }

  String _apiDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _apiTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime dt) {
    final months = [
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
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hourOfPeriod = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final hour = hourOfPeriod.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
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

    String locationName = _isLoadingLocations
        ? 'Loading work plan...'
        : _loadError != null
            ? 'Work plan unavailable'
            : 'No work plan for today';
    if (_detectedLocationName != null &&
        _detectedLocationName!.trim().isNotEmpty) {
      locationName = _detectedLocationName!;
    } else if (_selectedLocation != null) {
      if (_selectedLocation is WorkLocationItem) {
        locationName = _selectedLocation.name;
      } else if (_selectedLocation is TodayWorkLocation) {
        locationName = _selectedLocation.name;
      } else if (_selectedLocation is Map) {
        locationName =
            _selectedLocation['name'] ?? _selectedLocation.toString();
      } else {
        locationName = _selectedLocation.toString();
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          if (_isLoadingLocations)
            const LinearProgressIndicator(color: AppColors.primary),
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
                  vertical: 24.0,
                ),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFBE7EE),
                                    Color(0xFFFBF6F3),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1A1310)
                                        .withValues(alpha: 0.28),
                                    offset: const Offset(0, 10),
                                    blurRadius: 22,
                                    spreadRadius: -14,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  size: 48,
                                  color: Color(0xFFC6134B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              StorageService.getValue(
                                          StorageService.keyFullName)
                                      .isNotEmpty
                                  ? '${StorageService.getValue(StorageService.keyFullName)} (${StorageService.getValue(StorageService.keyEmpNo)})'
                                  : 'Employee',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1310),
                                height: 21 / 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (StorageService.getValue(
                                        StorageService.keyPhone)
                                    .isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDE8EE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.phone_outlined,
                                          size: 12,
                                          color: Color(0xFFC6134B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          StorageService.getValue(
                                              StorageService.keyPhone),
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFC6134B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (StorageService.getValue(
                                        StorageService.keyEmpNo)
                                    .isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFECE8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'EMP#${StorageService.getValue(StorageService.keyEmpNo)}',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_isAlreadyTimeIn &&
                            _checkInTimeDisplay != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFA5D6A7),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Status: Checked In',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'You are checked in at $_checkInTimeDisplay.',
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1B5E20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Column(
                          children: [
                            GestureDetector(
                              onTap:
                                  _isAlreadyTimeIn ? null : _showLocationModal,
                              child: Container(
                                height: 44,
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBF6F3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE8DFE1),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFFC6134B),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        locationName,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1A1310),
                                          letterSpacing: -0.2,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                    if (!_isAlreadyTimeIn)
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFC6134B),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              height: 44,
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBF6F3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE8DFE1),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    color: Color(0xFF1A1310),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatDate(_now),
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1310),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              height: 44,
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBF6F3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE8DFE1),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: Color(0xFF1A1310),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    (_isAlreadyTimeIn &&
                                            _checkInTimeDisplay != null)
                                        ? _checkInTimeDisplay!
                                        : _formatTime(_now),
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1310),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Column(
                      children: [
                        const SizedBox(
                          width: 354,
                          child: Text(
                            'Note: Changes on submitted records only possible through HR Department',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B5D58),
                              height: 19.2 / 12,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: (_isSubmitting ||
                                    _isLoadingLocations ||
                                    _isAlreadyTimeIn ||
                                    !_isValidationComplete ||
                                    _loadError != null)
                                ? null
                                : _onTimeIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC6134B),
                              disabledBackgroundColor: Colors.grey.shade400,
                              elevation: 0,
                              padding: const EdgeInsets.fromLTRB(6, 1, 6, 1),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(26),
                                  topRight: Radius.circular(26),
                                  bottomRight: Radius.circular(26),
                                  bottomLeft: Radius.circular(6),
                                ),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isAlreadyTimeIn
                                            ? 'Checked In'
                                            : 'Time In',
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        softWrap: false,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0.16,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        _isAlreadyTimeIn
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  onTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.fromLTRB(6, 1, 6, 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
                child: Center(
                  child: Text(
                    'RECORD TIME IN',
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
