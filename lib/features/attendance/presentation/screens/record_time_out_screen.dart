import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../data/models/app_models.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';

class RecordTimeOutScreen extends StatefulWidget {
  const RecordTimeOutScreen({super.key});

  @override
  State<RecordTimeOutScreen> createState() => _RecordTimeOutScreenState();
}

class _RecordTimeOutScreenState extends State<RecordTimeOutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isSubmitting = false;
  bool _isNotCheckedIn = false;
  bool _isAlreadyTimeOut = false;
  DateTime? _lastTimeInDatetime;
  String? _checkOutTimeDisplay;
  String _totalWorkHoursText = 'Loading...';

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
    _fetchTodaysTimeInOut();
  }

  Future<void> _fetchTodaysTimeInOut() async {
    try {
      final status = await _attendanceRepository.getTodaysTimeInOut();
      if (!status.isTimeIn) {
        _isNotCheckedIn = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No previous TIME IN was recorded today. Please check in first.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        setState(() {
          _totalWorkHoursText = '0 Hours 0 Minutes';
        });
        await _detectCurrentLocation();
        return;
      }

      if (status.lastTimeInDatetime.isNotEmpty) {
        try {
          final checkInDate = DateTime.tryParse(status.lastTimeInDatetime);
          if (checkInDate != null) {
            _lastTimeInDatetime = checkInDate;
            final diff = DateTime.now().difference(checkInDate);
            final h = diff.inHours;
            final m = diff.inMinutes.remainder(60);
            if (mounted) {
              setState(() {
                _totalWorkHoursText = '$h Hours $m Minutes';
              });
            }
          }
        } catch (_) {}
      } else {
        if (mounted) {
          setState(() {
            _totalWorkHoursText = '0 Hours 0 Minutes';
          });
        }
      }

      await _detectCurrentLocation();
    } catch (_) {
      if (mounted) {
        setState(() {
          _totalWorkHoursText = '0 Hours 0 Minutes';
        });
      }
      await _detectCurrentLocation();
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
        if (!_isNotCheckedIn && locResult.errorMessage != null) {
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

  String _formatTotalHours(dynamic val) {
    if (val is num) {
      final double hoursNum = val.toDouble();
      final int h = hoursNum.floor();
      final int m = ((hoursNum - h) * 60).round();
      if (m == 0) return '$h Hours';
      return '$h Hours $m Minutes';
    } else if (val is String && val.trim().isNotEmpty) {
      final parsed = double.tryParse(val.trim());
      if (parsed != null) {
        final int h = parsed.floor();
        final int m = ((parsed - h) * 60).round();
        if (m == 0) return '$h Hours';
        return '$h Hours $m Minutes';
      }
      return val.trim();
    }
    return '0 Hours 0 Minutes';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _onTimeOut() async {
    if (_isAlreadyTimeOut) {
      final timeStr = _checkOutTimeDisplay ?? _formatCheckInTime(null, _now);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are already checked out at $timeStr.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    if (_isNotCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No previous TIME IN was recorded. Please check in first.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 1. Acquire accurate GPS coordinates at time of check-out
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

    // 2. Evaluate 2-Hour Early Checkout Rule
    String reason = '';
    final timeElapsed = _lastTimeInDatetime != null
        ? DateTime.now().difference(_lastTimeInDatetime!)
        : Duration.zero;

    if (timeElapsed.inMinutes <= 120 && _lastTimeInDatetime != null) {
      if (!mounted) return;
      final String? enteredReason = await _showEarlyCheckoutDialog();
      if (enteredReason == null || enteredReason.trim().isEmpty) {
        setState(() => _isSubmitting = false);
        return; // Aborted by user
      }
      reason = enteredReason.trim();
    }

    // 3. Prompt Confirmation Dialog
    if (!mounted) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Check-Out',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to record time out at ${_detectedLocationName ?? "current location"}?',
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

    // 4. Dispatch Record Time Out API Call (POST /alsharqi/attendance/check/out)
    try {
      final dateStr =
          "${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}";
      final timeOutStr =
          "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}";

      final res = await _attendanceRepository.recordTimeOut({
        "date": dateStr,
        "time_out": timeOutStr,
        "lat": locationResult.latitude,
        "long": locationResult.longitude,
        "note": reason,
      });

      if (!mounted) return;

      // Check if backend returned an error
      if (res['error'] != null && res['error'].toString().isNotEmpty) {
        final errText = res['error'].toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errText),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final serverTimeOut = res['time_out']?.toString();
      final checkOutTimeFormatted =
          _formatCheckInTime(serverTimeOut ?? timeOutStr, _now);

      if (res['total_hours'] != null) {
        _totalWorkHoursText = _formatTotalHours(res['total_hours']);
      }

      if (mounted) {
        setState(() {
          _isAlreadyTimeOut = true;
          _isNotCheckedIn = true;
          _checkOutTimeDisplay = checkOutTimeFormatted;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are checked out at $checkOutTimeFormatted.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record Time Out: $e'),
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

  Future<String?> _showEarlyCheckoutDialog() async {
    final TextEditingController reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Early Checkout Justification',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You are making checkout before 2 Hours. Please specify a reason:',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: Color(0xFF1A1310),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason...',
                  hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE8DFE1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final text = reasonController.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a reason for early checkout'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, text);
              },
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white, fontFamily: 'Outfit'),
              ),
            ),
          ],
        );
      },
    );
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

    String locationName = 'Current Location';
    if (_isDetectingLocation) {
      locationName = 'Detecting current location...';
    } else if (_detectedLocationName != null &&
        _detectedLocationName!.trim().isNotEmpty) {
      locationName = _detectedLocationName!;
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: Column(
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
                    if (_isAlreadyTimeOut && _checkOutTimeDisplay != null) ...[
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status: Checked Out',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'You are checked out at $_checkOutTimeDisplay.',
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
                        children: [
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
                                  Icons.location_on_outlined,
                                  color: Color(0xFFC6134B),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    locationName,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1310),
                                    ),
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
                                  (_isAlreadyTimeOut && _checkOutTimeDisplay != null)
                                      ? _checkOutTimeDisplay!
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
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        const Text(
                          'Total Work Hours',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFC6134B),
                            letterSpacing: -0.2,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _totalWorkHoursText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1310),
                            letterSpacing: -0.2,
                            height: 1.0,
                          ),
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
                            onPressed: (_isSubmitting || _isNotCheckedIn || _isAlreadyTimeOut)
                                ? null
                                : _onTimeOut,
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
                                        _isAlreadyTimeOut ? 'Checked Out' : 'Time Out',
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
                                        _isAlreadyTimeOut
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.arrow_back_rounded,
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
                    'RECORD TIME OUT',
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
