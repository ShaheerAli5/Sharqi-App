import 'package:dio/dio.dart';

class ApiService {
  late final Dio _dio;

  static const String baseUrl = "https://erp.alsharqiholding.qa/alsharqi/";

  ApiService({Dio? dio}) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
            headers: {
              'accept': 'application/json',
              'content-type': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  /// Helper method that automatically encapsulates payloads inside `{"params": params}`
  Future<Response> _postRpc(String endpoint, dynamic params) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: {'params': params},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Strongly-Typed 15 Confirmed Endpoints
  // ---------------------------------------------------------------------------

  /// 1. Get Company List -> POST company/list with params: ""
  Future<Response> getCompanyList() => _postRpc('company/list', '');

  /// 2. Send / Resend OTP -> POST attendance/sign/in
  Future<Response> sendOtp({
    required String employeeNumber,
    required dynamic companyId,
  }) {
    return _postRpc('attendance/sign/in', {
      'employee_number': employeeNumber,
      'company_id': companyId,
    });
  }

  /// 3. Add WhatsApp Number -> POST attendance/add/whatsapp_number
  Future<Response> addWhatsAppNumber({
    required String employeeNumber,
    required dynamic companyId,
    required String whatsappNumber,
  }) {
    return _postRpc('attendance/add/whatsapp_number', {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'whatsapp_number': whatsappNumber,
    });
  }

  /// 4. Verify OTP -> POST attendance/otp/verify
  Future<Response> verifyOtp({
    required String employeeNumber,
    required dynamic companyId,
    required String otp,
    required String deviceToken,
    String? deviceInfo,
    String deviceType = 'android',
  }) {
    return _postRpc('attendance/otp/verify', {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'otp': otp,
      'device_token': deviceToken,
      'device_type': deviceType,
      'device_info': deviceInfo ?? 'Flutter App',
    });
  }

  /// 5. Get Dashboard Data -> POST attendance/dashboard
  Future<Response> getDashboardData({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
  }) {
    return _postRpc('attendance/dashboard', {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    });
  }

  /// 6. Check Time In/Out Status -> POST attendance/check_time_in_out
  Future<Response> getTodaysTimeInOut({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
  }) {
    return _postRpc('attendance/check_time_in_out', {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    });
  }

  /// 7. Get Today's Work Location -> POST plan/location/today
  Future<Response> getTodayWorkLocation({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
  }) {
    return _postRpc('plan/location/today', {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    });
  }

  /// 8. Get All Work Locations List -> POST location/update/list
  Future<Response> getWorkLocationList({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
  }) {
    return _postRpc('location/update/list', {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    });
  }

  /// 9. Record Time In (Standard) -> POST attendance/check/in
  Future<Response> recordTimeIn({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    required String date,
    required String timeIn,
    required double lat,
    required double long,
    String attendanceType = 'present',
  }) {
    return _postRpc('attendance/check/in', {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'date': date,
      'time_in': timeIn,
      'geo_location': '$lat,$long',
      'lat': lat,
      'long': long,
      'attendance_type': attendanceType,
    });
  }

  /// 10. Record Time In (Secure/Geo) -> POST attendance/check/in/secure
  Future<Response> recordTimeInSecure({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    required String timeIn,
    required double lat,
    required double long,
    String attendanceType = 'present',
  }) {
    return _postRpc('attendance/check/in/secure', {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'time_in': timeIn,
      'geo_location': '$lat,$long',
      'lat': lat,
      'long': long,
      'attendance_type': attendanceType,
    });
  }

  /// 11. Update Work Area -> POST attendance/update_area
  Future<Response> updateTodayWorkLocation({
    required dynamic timeInId,
    required dynamic areaId,
  }) {
    return _postRpc('attendance/update_area', {
      'time_in_id': timeInId,
      'area_id': areaId,
    });
  }

  /// 12. Record Time Out -> POST attendance/check/out
  Future<Response> recordTimeOut({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    required String date,
    required String timeOut,
    required double lat,
    required double long,
    String note = '',
  }) {
    return _postRpc('attendance/check/out', {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'date': date,
      'time_out': timeOut,
      'geo_location': '$lat,$long',
      'lat': lat,
      'long': long,
      'note': note,
    });
  }

  /// 13. Get Monthly Attendance List -> POST attendance/list
  Future<Response> getAttendanceList({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    required String monthNo,
    required String year,
  }) {
    return _postRpc('attendance/list', {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'month_no': monthNo,
      'year': year,
    });
  }

  /// 14. Get Employee Work Plan -> POST employee/work_plan
  Future<Response> getEmployeeWorkPlan({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    String? monthNo,
    String? year,
    String? startDate,
    String? endDate,
  }) {
    final Map<String, dynamic> params = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    };
    if (monthNo != null && monthNo.isNotEmpty) params['month_no'] = monthNo;
    if (year != null && year.isNotEmpty) params['year'] = year;
    if (startDate != null && startDate.isNotEmpty) params['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) params['end_date'] = endDate;

    return _postRpc('employee/work_plan', params);
  }

  /// 15. Get Notification Logs -> POST notification/logs
  Future<Response> getNotificationLogs({
    required String empNo,
    required dynamic companyId,
    required String apiToken,
  }) {
    return _postRpc('notification/logs', {
      'emp_no': empNo,
      'employee_number': empNo,
      'company_id': companyId,
      'api_token': apiToken,
    });
  }

  // ---------------------------------------------------------------------------
  // Backward-Compatibility Helpers (Map Payload Overloads)
  // ---------------------------------------------------------------------------

  dynamic _extractParams(dynamic data) {
    if (data is Map && data.containsKey('params')) {
      return data['params'];
    }
    return data;
  }

  Future<Response> callGetCompanyList([dynamic map]) => getCompanyList();

  Future<Response> sendOTP([dynamic map]) {
    if (map is Map) {
      final p = _extractParams(map);
      if (p is Map) {
        return sendOtp(
          employeeNumber: (p['employee_number'] ?? '').toString(),
          companyId: p['company_id'],
        );
      }
    }
    return _postRpc('attendance/sign/in', _extractParams(map));
  }

  Future<Response> callVerifyOTP([dynamic map]) {
    if (map is Map) {
      final p = _extractParams(map);
      if (p is Map) {
        return verifyOtp(
          employeeNumber: (p['employee_number'] ?? '').toString(),
          companyId: p['company_id'],
          otp: (p['otp'] ?? '').toString(),
          deviceToken: (p['device_token'] ?? '').toString(),
          deviceType: (p['device_type'] ?? 'android').toString(),
          deviceInfo: p['device_info']?.toString(),
        );
      }
    }
    return _postRpc('attendance/otp/verify', _extractParams(map));
  }

  Future<Response> callGetDashBoardData([dynamic map]) {
    if (map is Map) {
      final p = _extractParams(map);
      if (p is Map) {
        return getDashboardData(
          employeeNumber: (p['employee_number'] ?? p['emp_no'] ?? '').toString(),
          companyId: p['company_id'],
          apiToken: (p['api_token'] ?? '').toString(),
        );
      }
    }
    return _postRpc('attendance/dashboard', _extractParams(map));
  }

  Future<Response> addCheckIN([dynamic map]) => _postRpc('attendance/check/in', _extractParams(map));

  Future<Response> addCheckOUT([dynamic map]) => _postRpc('attendance/check/out', _extractParams(map));

  Future<Response> getNotificationList([dynamic map]) => _postRpc('notification/logs', _extractParams(map));

  Future<Response> employeeWorkPlan([dynamic map]) => _postRpc('employee/work_plan', _extractParams(map));

  Future<Response> login(Map<String, dynamic> map) => _postRpc('login', _extractParams(map));
}
