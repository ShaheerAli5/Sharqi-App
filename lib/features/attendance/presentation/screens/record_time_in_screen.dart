import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../data/models/app_models.dart';
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
  TodayWorkLocation? _todayWorkLocation;
  bool _isLoadingLocations = false;
  bool _isSubmitting = false;
  bool _isAlreadyTimeIn = false;
  String? _checkInTimeDisplay;

  bool _isDetectingLocation = false;
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
    setState(() => _isLoadingLocations = true);
    try {
      final results = await Future.wait([
        _attendanceRepository.getTodaysTimeInOut(),
        _attendanceRepository.getWorkLocationList(),
        _attendanceRepository.getTodayWorkLocation(),
      ]);

      final status = results[0] as TimeInOutStatus;
      final locList = results[1] as List<WorkLocationItem>;
      final todayLoc = results[2] as TodayWorkLocation;

      if (status.isTimeIn) {
        _isAlreadyTimeIn = true;
        _checkInTimeDisplay = _formatCheckInTime(status.lastTimeInDatetime, _now);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You are already checked in at $_checkInTimeDisplay.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }

      _locations = locList;
      _todayWorkLocation = todayLoc;
      if (todayLoc.id > 0) {
        _selectedLocation = todayLoc;
      }

      if (_selectedLocation == null && _locations.isNotEmpty) {
        _selectedLocation = _locations.first;
      }

      // Automatically detect user's current GPS location on screen open
      await _detectCurrentLocation();
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Future<void> _detectCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isDetectingLocation = true);
    try {
      final locResult = await LocationService.getCurrentLocation();
      if (!mounted) return;
      if (locResult.isSuccess) {
        if (locResult.address != null && locResult.address!.trim().isNotEmpty) {
          setState(() {
            _detectedLocationName = locResult.address;
          });
        } else {
          setState(() {
            _detectedLocationName =
                '${locResult.latitude.toStringAsFixed(6)}, ${locResult.longitude.toStringAsFixed(6)}';
          });
        }
      } else {
        if (!_isAlreadyTimeIn && locResult.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locResult.errorMessage!),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isDetectingLocation = false);
      }
    }
  }

  String _formatCheckInTime(String? rawTime, DateTime fallbackDateTime) {
    if (rawTime != null && rawTime.trim().isNotEmpty) {
      final trimmed = rawTime.trim();

      if (trimmed.toUpperCase().contains('AM') || trimmed.toUpperCase().contains('PM')) {
        return trimmed;
      }

      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        return _format12HourTime(parsed);
      }

      final spaceSplit = trimmed.split(' ');
      final timeStr = spaceSplit.length > 1 ? spaceSplit.last : spaceSplit.first;
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

  void _showLocationModal() {
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
                ListTile(
                  leading: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                  title: const Text(
                    'Detect My Current Location',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _detectCurrentLocation();
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                Flexible(
                  child: _isLoadingLocations
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary))
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

    // 1. Acquire accurate GPS coordinates at exact time of check-in
    setState(() => _isSubmitting = true);
    final locationResult = await LocationService.getCurrentLocation();
    if (!locationResult.isSuccess) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationResult.errorMessage ??
                'Unable to detect your current location. Please enable GPS and try again.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }

    if (locationResult.address != null &&
        locationResult.address!.trim().isNotEmpty) {
      _detectedLocationName = locationResult.address;
    } else {
      _detectedLocationName =
          '${locationResult.latitude.toStringAsFixed(6)}, ${locationResult.longitude.toStringAsFixed(6)}';
    }

    // 2. Prompt confirmation dialog
    if (!mounted) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Check-In',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to record time in at ${_detectedLocationName ?? "current GPS location"}?',
          style: const TextStyle(fontFamily: 'Outfit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) {
      setState(() => _isSubmitting = false);
      return;
    }

    // 3. Dispatch Secure Geo Check In API call (Section 5.2 POST /alsharqi/attendance/check/in/secure)
    try {
      final timeInStr =
          "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}";

      final res = await _attendanceRepository.recordTimeInSecure({
        "time_in": timeInStr,
        "lat": locationResult.latitude,
        "long": locationResult.longitude,
        "attendance_type": "present",
      });

      if (!mounted) return;

      // Check if backend returned an error (e.g. 400m distance error, no area configured, already checked in)
      if (res['error'] != null && res['error'].toString().isNotEmpty) {
        final errText = res['error'].toString();

        if (errText.toLowerCase().contains('already checked in')) {
          final checkInTimeFormatted = _formatCheckInTime(timeInStr, _now);
          setState(() {
            _isAlreadyTimeIn = true;
            _checkInTimeDisplay = checkInTimeFormatted;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You are already checked in at $checkInTimeFormatted.'),
              backgroundColor: AppColors.primary,
            ),
          );
        } else {
          // Display actual backend error (e.g. 850 meters away / no area configured)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errText),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

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
              : (_selectedLocation['id'] ?? -1));

      if (timeInId != null &&
          _todayWorkLocation != null &&
          selectedId > 0 &&
          selectedId != _todayWorkLocation!.id) {
        await _attendanceRepository.updateTodayWorkLocation(timeInId, selectedId);
      }

      if (mounted) {
        setState(() {
          _isAlreadyTimeIn = true;
          _checkInTimeDisplay = checkInTimeFormatted;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are checked in at $checkInTimeFormatted.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record Time In: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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

    String locationName = 'Select Work Location';
    if (_isDetectingLocation) {
      locationName = 'Detecting current location...';
    } else if (_detectedLocationName != null && _detectedLocationName!.trim().isNotEmpty) {
      locationName = _detectedLocationName!;
    } else if (_selectedLocation != null) {
      if (_selectedLocation is WorkLocationItem) {
        locationName = _selectedLocation.name;
      } else if (_selectedLocation is TodayWorkLocation) {
        locationName = _selectedLocation.name;
      } else if (_selectedLocation is Map) {
        locationName = _selectedLocation['name'] ?? _selectedLocation.toString();
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
                              StorageService.getValue(StorageService.keyFullName)
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
                        if (_isAlreadyTimeIn && _checkInTimeDisplay != null) ...[
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
                              onTap: _isAlreadyTimeIn ? null : _showLocationModal,
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
                                    (_isAlreadyTimeIn && _checkInTimeDisplay != null)
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
                            onPressed: (_isSubmitting || _isAlreadyTimeIn)
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
                                        _isAlreadyTimeIn ? 'Checked In' : 'Time In',
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
