import '../../data/models/app_models.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AttendanceRepository {
  final ApiService _apiService;

  AttendanceRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // ignore: unused_element
  Map<String, dynamic> _defaultParams() => {
        "employee_number": StorageService.getValue(StorageService.keyEmpNo),
        "company_id": StorageService.getValue(StorageService.keyCompanyId),
        "api_token": StorageService.getValue(StorageService.keyAccessToken),
      };

  /// 1. Get Dashboard Data
  Future<DashboardData> getDashboardData() async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final response = await _apiService.getDashboardData(
      employeeNumber: empNo,
      companyId: companyId,
      apiToken: apiToken,
    );

    if (response.statusCode == 200 && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        return DashboardData.fromJson(response.data as Map<String, dynamic>);
      }
    }

    return DashboardData(
      success: false,
      company: '',
      joinDate: '',
      qidNumber: '',
      qidExpiry: '',
      passportNumber: '',
      passportExpiry: '',
      gender: '',
      nationality: '',
      workLocation: '',
      location: '',
      manager: '',
      error: 'Failed to fetch dashboard data',
    );
  }

  /// 2. Get Attendance List
  Future<List<AttendanceItem>> getAttendanceList({
    String? monthNo,
    String? year,
    String? startDate,
    String? endDate,
  }) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    String m = monthNo ?? '';
    String y = year ?? '';

    if (m.isEmpty && startDate != null && startDate.contains('-')) {
      final parts = startDate.split('-');
      if (parts.length >= 2) {
        y = parts[0];
        m = parts[1];
      }
    }

    if (m.isEmpty) {
      m = DateTime.now().month.toString().padLeft(2, '0');
    }
    if (y.isEmpty) {
      y = DateTime.now().year.toString();
    }

    final response = await _apiService.getAttendanceList(
      employeeNumber: empNo,
      companyId: companyId,
      apiToken: apiToken,
      monthNo: m,
      year: y,
    );

    if (response.statusCode == 200 && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        final result = response.data['result'];
        if (result is List) {
          return result
              .map((e) => AttendanceItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    }
    return [];
  }

  /// 3. Get All Work Locations List
  Future<List<WorkLocationItem>> getWorkLocationList() async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final response = await _apiService.getWorkLocationList(
      employeeNumber: empNo,
      companyId: companyId,
      apiToken: apiToken,
    );

    if (response.statusCode == 200 && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        final result = response.data['result'];
        if (result is List) {
          return result
              .map((e) => WorkLocationItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    }
    return [];
  }

  /// 4. Get Today's Work Location
  Future<TodayWorkLocation> getTodayWorkLocation() async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final response = await _apiService.getTodayWorkLocation(
      employeeNumber: empNo,
      companyId: companyId,
      apiToken: apiToken,
    );

    if (response.statusCode == 200 && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        return TodayWorkLocation.fromJson(
            response.data as Map<String, dynamic>);
      }
    }
    return TodayWorkLocation(id: -1, name: '');
  }

  /// 5. Update Today's Work Area
  Future<dynamic> updateTodayWorkLocation(dynamic timeInId, [dynamic areaId]) async {
    final tId = areaId != null ? timeInId : timeInId;
    final aId = areaId ?? timeInId;

    final response = await _apiService.updateTodayWorkLocation(
      timeInId: tId,
      areaId: aId,
    );
    if (response.data is Map<String, dynamic>) {
      final resMap = response.data as Map<String, dynamic>;
      final result = resMap['result'];
      if (result is Map<String, dynamic>) {
        return result;
      }
    }
    return response.data;
  }

  /// 6. Check Today's Time In/Out Status
  Future<TimeInOutStatus> getTodaysTimeInOut() async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final response = await _apiService.getTodaysTimeInOut(
      employeeNumber: empNo,
      companyId: companyId,
      apiToken: apiToken,
    );

    if (response.statusCode == 200 && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        return TimeInOutStatus.fromJson(response.data as Map<String, dynamic>);
      }
    }
    return TimeInOutStatus(isTimeIn: false, lastTimeInDatetime: '');
  }

  /// 7. Record Time In (Standard)
  Future<Map<String, dynamic>> recordTimeIn(Map<String, dynamic> extraParams) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final now = DateTime.now();
    final dateStr = extraParams['date']?.toString() ??
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final timeInStr = extraParams['time_in']?.toString() ??
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final lat = (extraParams['lat'] is num)
        ? (extraParams['lat'] as num).toDouble()
        : 0.0;
    final long = (extraParams['long'] is num)
        ? (extraParams['long'] as num).toDouble()
        : 0.0;
    final attendanceType =
        extraParams['attendance_type']?.toString() ?? 'present';

    final response = await _apiService.recordTimeIn(
      employeeNumber: empNo,
      companyId: companyId,
      apiToken: apiToken,
      date: dateStr,
      timeIn: timeInStr,
      lat: lat,
      long: long,
      attendanceType: attendanceType,
    );

    if (response.data is Map<String, dynamic>) {
      final resMap = response.data as Map<String, dynamic>;
      final result = resMap['result'];
      if (result is Map<String, dynamic>) {
        if (result['error'] != null && result['error'].toString().isNotEmpty) {
          return {'error': result['error'].toString()};
        }
        return result;
      }
    }
    return {'error': 'Failed to record Time In'};
  }

  /// Record Time In (Secure/GEO)
  Future<Map<String, dynamic>> recordTimeInSecure(Map<String, dynamic> extraParams) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final now = DateTime.now();
    final timeInStr = extraParams['time_in']?.toString() ??
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final lat = (extraParams['lat'] is num)
        ? (extraParams['lat'] as num).toDouble()
        : 0.0;
    final long = (extraParams['long'] is num)
        ? (extraParams['long'] as num).toDouble()
        : 0.0;
    final attendanceType =
        extraParams['attendance_type']?.toString() ?? 'present';

    final response = await _apiService.recordTimeInSecure(
      employeeNumber: empNo,
      companyId: companyId,
      apiToken: apiToken,
      timeIn: timeInStr,
      lat: lat,
      long: long,
      attendanceType: attendanceType,
    );

    if (response.data is Map<String, dynamic>) {
      final resMap = response.data as Map<String, dynamic>;
      final result = resMap['result'];
      if (result is Map<String, dynamic>) {
        if (result['error'] != null && result['error'].toString().isNotEmpty) {
          return {'error': result['error'].toString()};
        }
        return result;
      }
    }
    return {'error': 'Failed to record Secure Time In'};
  }

  /// 8. Record Time Out
  Future<Map<String, dynamic>> recordTimeOut(Map<String, dynamic> extraParams) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final now = DateTime.now();
    final dateStr = extraParams['date']?.toString() ??
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final timeOutStr = extraParams['time_out']?.toString() ??
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final lat = (extraParams['lat'] is num)
        ? (extraParams['lat'] as num).toDouble()
        : 0.0;
    final long = (extraParams['long'] is num)
        ? (extraParams['long'] as num).toDouble()
        : 0.0;
    final note = extraParams['note']?.toString() ?? '';

    final response = await _apiService.recordTimeOut(
      employeeNumber: empNo,
      companyId: companyId,
      apiToken: apiToken,
      date: dateStr,
      timeOut: timeOutStr,
      lat: lat,
      long: long,
      note: note,
    );

    if (response.data is Map<String, dynamic>) {
      final resMap = response.data as Map<String, dynamic>;
      final result = resMap['result'];
      if (result is Map<String, dynamic>) {
        if (result['error'] != null && result['error'].toString().isNotEmpty) {
          return {'error': result['error'].toString()};
        }
        return result;
      }
    }
    return {'error': 'Failed to record Time Out'};
  }

  /// 9. Get Employee Work Plan
  Future<List<WorkPlanItem>> getWorkPlan({
    String? startDate,
    String? endDate,
    String? monthNo,
    String? year,
  }) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    String m = monthNo ?? '';
    String y = year ?? '';

    if (m.isEmpty && startDate != null && startDate.contains('-')) {
      final parts = startDate.split('-');
      if (parts.length >= 2) {
        y = parts[0];
        m = parts[1];
      }
    }

    final response = await _apiService.getEmployeeWorkPlan(
      employeeNumber: empNo,
      companyId: companyId,
      apiToken: apiToken,
      monthNo: m,
      year: y,
      startDate: startDate,
      endDate: endDate,
    );

    if (response.statusCode == 200 && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        final result = response.data['result'];
        if (result is Map<String, dynamic> && result['planes'] is List) {
          return (result['planes'] as List)
              .map((e) => WorkPlanItem.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (result is List) {
          return result
              .map((e) => WorkPlanItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    }
    return [];
  }

  /// 10. Get Notification Logs
  Future<List<NotificationItem>> getNotifications() async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final response = await _apiService.getNotificationLogs(
      empNo: empNo,
      companyId: companyId,
      apiToken: apiToken,
    );

    if (response.statusCode == 200 && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        final result = response.data['result'];
        if (result is Map<String, dynamic>) {
          final logs = result['notification_logs'] ??
              result['notifications'] ??
              result['logs'] ??
              result['data'];
          if (logs is List) {
            return logs
                .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        } else if (result is List) {
          return result
              .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    }
    return [];
  }
}
