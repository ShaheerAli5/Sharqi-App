import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;

  static const String baseUrl = "https://erp.alsharqiholding.qa/alsharqi/";

  ApiService({Dio? dio}) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            // Match the native OkHttp client. Some valid employees take more
            // than a few seconds to complete OTP verification.
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
            headers: {
              'accept': 'application/json',
              'content-type': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        requestHeader: false,
        responseBody: false,
        responseHeader: false,
      ),
    );
  }

  /// Helper method that automatically encapsulates payloads inside `{"params": params}`
  Future<Response> _postRpc(String endpoint, dynamic params) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: {'params': params},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Helper method that tries a list of candidate endpoints until one returns a valid non-404 response
  Future<Response> _postRpcWithFallback(
      List<String> endpoints, dynamic params) async {
    Response? lastResponse;

    for (int i = 0; i < endpoints.length; i++) {
      final endpoint = endpoints[i];
      try {
        final response = await _dio.post(
          endpoint,
          data: {'params': params},
          options: Options(
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        lastResponse = response;

        if (response.statusCode == 200 && response.data != null) {
          bool isOdoo404 = false;
          if (response.data is Map<String, dynamic>) {
            final dataMap = response.data as Map<String, dynamic>;
            if (dataMap.containsKey('error') && dataMap['error'] != null) {
              final errStr = dataMap['error'].toString().toLowerCase();
              if (errStr.contains('404') ||
                  errStr.contains('not found') ||
                  errStr.contains('notfound') ||
                  errStr.contains('werkzeug.exceptions.notfound')) {
                isOdoo404 = true;
              }
            }
          }

          if (!isOdoo404) {
            return response;
          }
        }
      } catch (_) {}
    }

    return lastResponse ?? await _postRpc(endpoints.last, params);
  }

  // ---------------------------------------------------------------------------
  // Strongly-Typed Endpoints
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
      'geo_location': 'lat,long',
      'lat': lat,
      'long': long,
      'attendance_type': attendanceType,
    });
  }

  /// 11. Record Time Out -> POST attendance/check/out
  Future<Response> recordTimeOut({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    required String date,
    required String timeOut,
    double? lat,
    double? long,
    String note = '',
  }) {
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'date': date,
      'time_out': timeOut,
      'note': note,
    };
    if (lat != null && lat != 0.0) payload['lat'] = lat;
    if (long != null && long != 0.0) payload['long'] = long;

    return _postRpc('attendance/check/out', payload);
  }

  /// 12. Update Today's Work Area -> POST attendance/update_area
  Future<Response> updateTodayWorkLocation({
    required dynamic timeInId,
    required dynamic areaId,
  }) {
    return _postRpc('attendance/update_area', {
      'time_in_id': timeInId,
      'area_id': areaId,
    });
  }

  /// 13. Get Attendance List -> POST attendance/list
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
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    };
    if (monthNo != null) payload['month_no'] = monthNo;
    if (year != null) payload['year'] = year;
    if (startDate != null) payload['start_date'] = startDate;
    if (endDate != null) payload['end_date'] = endDate;

    return _postRpc('employee/work_plan', payload);
  }

  /// 15. Get Notification Logs -> POST notification/logs
  Future<Response> getNotificationLogs({
    required String empNo,
    required dynamic companyId,
    required String apiToken,
  }) {
    return _postRpc('notification/logs', {
      'emp_no': empNo,
      'company_id': companyId,
      'api_token': apiToken,
    });
  }

  /// 16. Get Self Service Portal List -> POST self_service/portal
  Future<Response> getSelfServicePortal({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
  }) {
    return _postRpcWithFallback([
      'self_service/portal',
      'self_service/list',
      'self/service/portal',
    ], {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    });
  }

  /// 16.1 Check Employee Attendance -> POST get/employee/attendance
  Future<Response> checkEmployeeAttendance({
    required String employeeNumber,
    required dynamic companyId,
    String attendanceType = 'present',
  }) {
    return _postRpcWithFallback([
      'get/employee/attendance',
      'employee/attendance',
      'self_service/check_attendance',
    ], {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'attendance_type': attendanceType,
    });
  }

  /// 16.2 Register Employee Phone -> POST employee/registered/phone
  Future<Response> registerEmployeePhone({
    required String employeeNumber,
    required dynamic companyId,
    required String workPhone,
  }) {
    return _postRpcWithFallback([
      'employee/registered/phone',
      'self_service/register_phone',
    ], {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'work_phone': workPhone,
    });
  }

  /// 16.3 Submit Attendance Form -> POST attendance/form/submit
  Future<Response> submitAttendanceForm({
    required String employeeNumber,
    required dynamic companyId,
    required String otp,
    required Map<String, dynamic> formData,
  }) {
    return _postRpcWithFallback([
      'attendance/form/submit',
      'self_service/form_submit',
    ], {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'otp': otp,
      ...formData,
    });
  }

  /// 16.4 Convert Work Plan XLSX -> POST wp/convert
  Future<Response> convertWorkPlanXlsx({
    required String filePath,
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
  }) async {
    final formData = FormData.fromMap({
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'file': await MultipartFile.fromFile(filePath),
    });

    return _dio.post(
      'wp/convert',
      data: formData,
      options: Options(
        headers: {
          'api-token': apiToken,
        },
      ),
    );
  }

  /// 16.5 Get Work Plan Download URL -> GET wp/download?file=
  String getWorkPlanDownloadUrl(String filename) {
    final token = StorageService.getValue(StorageService.keyAccessToken);
    return '${baseUrl}wp/download?file=$filename&token=$token';
  }

  /// 17. Get Complaint Categories -> POST complaint/categories
  Future<Response> getComplaintCategories({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
  }) {
    final payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    };
    return _postRpcWithFallback([
      'complaint/categories',
      'self_service/complaint/categories',
      'self_service/categories',
      'attendance/complaint/categories',
    ], payload);
  }

  /// 18. Submit Complaint Request -> POST complaint/create
  Future<Response> submitComplaint({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    required Map<String, dynamic> data,
  }) {
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'type': 'complaint',
      'request_type': 'complaint',
      ...data,
    };
    return _postRpcWithFallback([
      'attendance/form/submit',
      'self_service/form/submit',
      'complaint/create',
      'self_service/complaint/create',
      'selfservice/complaint/create',
      'attendance/complaint/create',
      'self_service/create',
    ], payload);
  }

  /// 19. Get Employee Request Categories -> POST employee_request/categories
  Future<Response> getEmployeeRequestCategories({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
  }) {
    final payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    };
    return _postRpcWithFallback([
      'employee_request/categories',
      'self_service/employee_request/categories',
      'self_service/categories',
      'attendance/request/categories',
    ], payload);
  }

  /// 20. Submit Employee Request -> POST employee_request/create
  Future<Response> submitEmployeeRequest({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    required Map<String, dynamic> data,
  }) {
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'type': 'employee_request',
      'request_type': 'employee_request',
      ...data,
    };
    return _postRpcWithFallback([
      'employee_request/create',
      'self_service/employee_request/create',
      'self_service/create',
      'attendance/employee_request/create',
      'self/service/employee_request/create',
    ], payload);
  }

  /// 21. Get Leave Types -> POST leave/types
  Future<Response> getLeaveTypes({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
  }) {
    final payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    };
    return _postRpcWithFallback([
      'leave/types',
      'self_service/leave/types',
      'attendance/leave/types',
      'leave/categories',
    ], payload);
  }

  /// 22. Submit Leave Request -> POST leave/create
  Future<Response> submitLeaveRequest({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    required Map<String, dynamic> data,
  }) {
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'type': 'leave_request',
      'request_type': 'leave',
      ...data,
    };
    return _postRpcWithFallback([
      'leave/create',
      'self_service/leave/create',
      'self_service/create',
      'attendance/leave/create',
      'self/service/leave/create',
    ], payload);
  }

  /// 23. Submit Bright Idea -> POST bright_idea/create
  Future<Response> submitBrightIdea({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    required Map<String, dynamic> data,
  }) {
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'type': 'bright_idea',
      'request_type': 'bright_idea',
      ...data,
    };
    return _postRpcWithFallback([
      'bright_idea/create',
      'self_service/bright_idea/create',
      'self_service/create',
      'attendance/bright_idea/create',
    ], payload);
  }

  /// 24. Submit Salary Slip Request -> POST salary_slip/create
  Future<Response> submitSalarySlipRequest({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    required Map<String, dynamic> data,
  }) {
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'type': 'salary_slip',
      'request_type': 'salary_slip',
      ...data,
    };
    return _postRpcWithFallback([
      'salary_slip/create',
      'self_service/salary_slip/create',
      'self_service/create',
      'attendance/salary_slip/create',
    ], payload);
  }

  /// 25. Track Case -> POST self_service/track_case or complaint/track / leave/track
  Future<Response> trackCase({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    required String code,
  }) {
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'code': code,
      'reference': code,
      'incident_code': code,
      'cms_code': code,
      'leave_code': code,
      'request_code': code,
    };

    final codeUpper = code.trim().toUpperCase();
    final List<String> endpoints = [];

    if (codeUpper.startsWith('CMS') || codeUpper.startsWith('INC')) {
      endpoints.addAll([
        'complaint/track',
        'self_service/complaint/track',
        'self_service/track_case',
        'complaint/list',
        'case/track',
      ]);
    } else if (codeUpper.startsWith('LV') || codeUpper.startsWith('LEAVE')) {
      endpoints.addAll([
        'leave/track',
        'self_service/leave/track',
        'self_service/track_case',
        'leave/list',
        'case/track',
      ]);
    } else if (codeUpper.startsWith('REQ') || codeUpper.startsWith('EMP')) {
      endpoints.addAll([
        'employee_request/track',
        'self_service/employee_request/track',
        'self_service/track_case',
        'employee_request/list',
        'case/track',
      ]);
    } else {
      endpoints.addAll([
        'self_service/track_case',
        'complaint/track',
        'employee_request/track',
        'leave/track',
        'case/track',
        'self_service/cases',
      ]);
    }

    return _postRpcWithFallback(endpoints, payload);
  }

  Future<Response> trackCaseAlternative({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    required String code,
  }) {
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
      'code': code,
      'reference': code,
      'incident_code': code,
      'cms_code': code,
      'leave_code': code,
      'request_code': code,
    };

    return _postRpcWithFallback([
      'case/track',
      'self_service/track_case',
      'complaint/track',
    ], payload);
  }

  /// 26. Get All Self Service Cases -> POST self_service/cases
  Future<Response> getSelfServiceCases({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    String? code,
  }) {
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    };
    if (code != null && code.trim().isNotEmpty) {
      payload['code'] = code.trim();
      payload['reference'] = code.trim();
      payload['cms_code'] = code.trim();
    }
    return _postRpcWithFallback([
      'self_service/cases',
      'self_service/list',
      'self_service/track_case',
    ], payload);
  }

  /// 27. Get Complaint List -> POST complaint/list
  Future<Response> getComplaintList({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    String? code,
  }) {
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    };
    if (code != null && code.trim().isNotEmpty) {
      payload['code'] = code.trim();
      payload['reference'] = code.trim();
      payload['incident_code'] = code.trim();
      payload['cms_code'] = code.trim();
    }
    return _postRpcWithFallback([
      'complaint/list',
      'self_service/complaint/list',
      'self_service/list',
      'complaint/track',
    ], payload);
  }

  /// 28. Get Employee Request List -> POST employee_request/list
  Future<Response> getEmployeeRequestList({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    String? code,
  }) {
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    };
    if (code != null && code.trim().isNotEmpty) {
      payload['code'] = code.trim();
      payload['reference'] = code.trim();
      payload['request_code'] = code.trim();
    }
    return _postRpcWithFallback([
      'employee_request/list',
      'self_service/employee_request/list',
      'self_service/list',
    ], payload);
  }

  /// 29. Get Leave Request List -> POST leave/list
  Future<Response> getLeaveList({
    required String employeeNumber,
    required dynamic companyId,
    required String apiToken,
    String? code,
  }) {
    final Map<String, dynamic> payload = {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    };
    if (code != null && code.trim().isNotEmpty) {
      payload['code'] = code.trim();
      payload['reference'] = code.trim();
      payload['leave_code'] = code.trim();
    }
    return _postRpcWithFallback([
      'leave/list',
      'self_service/leave/list',
      'self_service/list',
    ], payload);
  }
}
