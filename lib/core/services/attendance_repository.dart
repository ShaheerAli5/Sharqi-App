import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/app_models.dart';
import '../../data/models/portal_service_item.dart';
import '../constants/app_strings.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AttendanceRequestException implements Exception {
  final String message;
  final bool isAuthenticationError;
  final bool isNetworkError;

  const AttendanceRequestException(
    this.message, {
    this.isAuthenticationError = false,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

class NoPlanForTodayException extends AttendanceRequestException {
  const NoPlanForTodayException() : super('No plan found for today');
}

class AttendanceRepository {
  final ApiService _apiService;

  AttendanceRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Map<String, dynamic> _attendanceSession() {
    final employeeNumber =
        StorageService.getValue(StorageService.keyEmpNo).trim();
    final companyId =
        StorageService.getValue(StorageService.keyCompanyId).trim();
    final apiToken =
        StorageService.getValue(StorageService.keyAccessToken).trim();
    if (employeeNumber.isEmpty || companyId.isEmpty || apiToken.isEmpty) {
      throw const AttendanceRequestException(
        'Your session is incomplete. Please sign in again.',
        isAuthenticationError: true,
      );
    }
    return {
      'employee_number': employeeNumber,
      'company_id': companyId,
      'api_token': apiToken,
    };
  }

  Future<T> _attendanceRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on AttendanceRequestException {
      rethrow;
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      if (code == 401 || code == 403) {
        throw const AttendanceRequestException(
          'Your session has expired. Please sign in again.',
          isAuthenticationError: true,
        );
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const AttendanceRequestException(
          'Unable to connect to the server. Please check your internet connection.',
          isNetworkError: true,
        );
      }
      if (code != null && code >= 500) {
        throw const AttendanceRequestException(
          'The server is temporarily unavailable. Please try again later.',
        );
      }
      throw const AttendanceRequestException(
        'Unable to complete the request. Please try again.',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[RecordTimeIn] Unexpected request error: $error');
      }
      throw const AttendanceRequestException(
        'Something went wrong. Please try again.',
      );
    }
  }

  Map<String, dynamic> _resultMap(dynamic data, String operation) {
    if (data is Map && data['result'] is Map) {
      return Map<String, dynamic>.from(data['result'] as Map);
    }
    if (kDebugMode) {
      debugPrint('[RecordTimeIn] Invalid $operation response: $data');
    }
    throw const AttendanceRequestException(
      'The server returned an unexpected response. Please try again.',
    );
  }

  Never _throwResultError(
    Map<String, dynamic> result, {
    bool allowNoPlan = false,
  }) {
    final message = result['error']?.toString().trim() ?? '';
    if (allowNoPlan && message.toLowerCase() == 'no plan found for today') {
      throw const NoPlanForTodayException();
    }
    throw AttendanceRequestException(
      message.isEmpty
          ? 'The server returned an unexpected response. Please try again.'
          : message,
      isAuthenticationError: message == 'Employee not found in system',
    );
  }

  // ignore: unused_element
  Map<String, dynamic> _defaultParams() => {
        "employee_number": StorageService.getValue(StorageService.keyEmpNo),
        "company_id": StorageService.getValue(StorageService.keyCompanyId),
        "api_token": StorageService.getValue(StorageService.keyAccessToken),
      };

  /// 1. Get Dashboard Data
  Future<DashboardData> getDashboardData({String? employeeNumber}) async {
    final empNo = (employeeNumber != null && employeeNumber.trim().isNotEmpty)
        ? employeeNumber.trim()
        : StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final response = await _apiService.getDashboardData(
      employeeNumber: empNo,
      companyId: companyId,
      apiToken: apiToken,
    );

    if (response.statusCode == 200 && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        final dashData =
            DashboardData.fromJson(response.data as Map<String, dynamic>);
        if (employeeNumber == null ||
            employeeNumber ==
                StorageService.getValue(StorageService.keyEmpNo)) {
          if (dashData.qidNumber.isNotEmpty) {
            await StorageService.addValue(
                StorageService.keyQid, dashData.qidNumber);
          }
          if (dashData.qidExpiry.isNotEmpty) {
            await StorageService.addValue(
                StorageService.keyQidExpiry, dashData.qidExpiry);
          }
        }
        return dashData;
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
    return _attendanceRequest(() async {
      final session = _attendanceSession();
      final response = await _apiService.getWorkLocationList(
        employeeNumber: session['employee_number'],
        companyId: session['company_id'],
        apiToken: session['api_token'],
      );
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AttendanceRequestException(
          'Your session has expired. Please sign in again.',
          isAuthenticationError: true,
        );
      }
      if (response.statusCode != 200 || response.data is! Map) {
        throw const AttendanceRequestException(
          'Unable to load work locations. Please try again.',
        );
      }
      final result = (response.data as Map)['result'];
      if (result is! List) {
        throw const AttendanceRequestException(
          'The server returned an unexpected work-location response.',
        );
      }
      return result
          .whereType<Map>()
          .map((item) => WorkLocationItem.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    });
  }

  /// 4. Get Today's Work Location
  Future<TodayWorkLocation> getTodayWorkLocation() =>
      _attendanceRequest(() async {
        final session = _attendanceSession();
        final response = await _apiService.getTodayWorkLocation(
          employeeNumber: session['employee_number'],
          companyId: session['company_id'],
          apiToken: session['api_token'],
        );
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw const AttendanceRequestException(
            'Your session has expired. Please sign in again.',
            isAuthenticationError: true,
          );
        }
        if (response.statusCode != 200) {
          throw const AttendanceRequestException(
            'Unable to load today\'s work plan. Please try again.',
          );
        }
        final result = _resultMap(response.data, "today's work plan");
        if (result.containsKey('error')) {
          _throwResultError(result, allowNoPlan: true);
        }
        final area = result['area_id'];
        if (area is! Map || area['id'] == null) {
          throw const AttendanceRequestException(
            'The work plan is missing required location information.',
          );
        }
        final plan = TodayWorkLocation.fromJson({'result': result});
        if (plan.id <= 0 || plan.name.trim().isEmpty) {
          throw const AttendanceRequestException(
            'The work plan contains invalid location information.',
          );
        }
        return plan;
      });

  /// 5. Update Today's Work Area
  Future<dynamic> updateTodayWorkLocation(
    dynamic timeInId,
    dynamic areaId,
  ) =>
      _attendanceRequest(() async {
        final response = await _apiService.updateTodayWorkLocation(
          timeInId: timeInId,
          areaId: areaId,
        );
        if (response.statusCode != 200) {
          throw const AttendanceRequestException(
            'Time In was recorded, but the work location could not be updated.',
          );
        }
        final result = _resultMap(response.data, 'work-location update');
        if (result.containsKey('error')) _throwResultError(result);
        return result;
      });

  /// 6. Check Today's Time In/Out Status
  Future<TimeInOutStatus> getTodaysTimeInOut() => _attendanceRequest(() async {
        final session = _attendanceSession();
        final response = await _apiService.getTodaysTimeInOut(
          employeeNumber: session['employee_number'],
          companyId: session['company_id'],
          apiToken: session['api_token'],
        );
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw const AttendanceRequestException(
            'Your session has expired. Please sign in again.',
            isAuthenticationError: true,
          );
        }
        if (response.statusCode != 200) {
          throw const AttendanceRequestException(
            'Unable to load attendance status. Please try again.',
          );
        }
        final result = _resultMap(response.data, 'attendance status');
        if (result.containsKey('error')) _throwResultError(result);
        if (!result.containsKey('success')) {
          throw const AttendanceRequestException(
            'The server returned an invalid attendance status.',
          );
        }
        return TimeInOutStatus.fromJson({'result': result});
      });

  /// 7. Record Time In using the endpoint and payload used by the Kotlin app.
  Future<Map<String, dynamic>> recordTimeIn({
    required String date,
    required String timeIn,
    required double latitude,
    required double longitude,
    String attendanceType = 'present',
  }) =>
      _attendanceRequest(() async {
        final session = _attendanceSession();
        final response = await _apiService.recordTimeIn(
          employeeNumber: session['employee_number'],
          companyId: session['company_id'],
          apiToken: session['api_token'],
          date: date,
          timeIn: timeIn,
          lat: latitude,
          long: longitude,
          attendanceType: attendanceType,
        );
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw const AttendanceRequestException(
            'Your session has expired. Please sign in again.',
            isAuthenticationError: true,
          );
        }
        if (response.statusCode != 200) {
          throw const AttendanceRequestException(
            'Unable to record Time In. Please try again.',
          );
        }
        final result = _resultMap(response.data, 'check-in');
        if (result.containsKey('error')) _throwResultError(result);
        if (result['success'] == null) {
          throw const AttendanceRequestException(
            'The server returned an invalid check-in response.',
          );
        }
        return result;
      });

  /// 8. Record Time Out
  Future<Map<String, dynamic>> recordTimeOut(
      Map<String, dynamic> extraParams) async {
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
                .map(
                    (e) => NotificationItem.fromJson(e as Map<String, dynamic>))
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

  /// 11. Get Self Service Portal List
  Future<List<PortalServiceItem>> getSelfServicePortalItems() async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    try {
      final response = await _apiService.getSelfServicePortal(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final result = response.data['result'];
          if (result is List) {
            return result
                .map((e) =>
                    PortalServiceItem.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      }
    } catch (_) {}

    return [
      PortalServiceItem(
        id: '1',
        title: AppStrings.complaintTitle,
        description: AppStrings.complaintDesc,
        hasSeeManual: true,
        primaryButtonLabel: AppStrings.createRequest,
        secondaryButtonLabel: AppStrings.trackCase,
        actionType: 'complaint',
      ),
      PortalServiceItem(
        id: '2',
        title: AppStrings.employeeRequestTitle,
        description: AppStrings.employeeRequestDesc,
        hasSeeManual: true,
        primaryButtonLabel: AppStrings.createRequest,
        secondaryButtonLabel: AppStrings.trackCase,
        actionType: 'employee_request',
      ),
      PortalServiceItem(
        id: '3',
        title: AppStrings.leaveRequestTitle,
        description: AppStrings.leaveRequestDesc,
        hasSeeManual: false,
        primaryButtonLabel: AppStrings.leaveRequestButton,
        secondaryButtonLabel: AppStrings.trackCase,
        actionType: 'leave_request',
      ),
      PortalServiceItem(
        id: '4',
        title: AppStrings.brightIdeaTitle,
        description: AppStrings.brightIdeaDesc,
        hasSeeManual: false,
        primaryButtonLabel: AppStrings.brightIdeaButton,
        actionType: 'bright_idea',
      ),
      PortalServiceItem(
        id: '5',
        title: AppStrings.salarySlipTitle,
        description: AppStrings.salarySlipDesc,
        hasSeeManual: false,
        primaryButtonLabel: AppStrings.getSalarySlip,
        actionType: 'salary_slip',
      ),
    ];
  }

  /// Check Employee Attendance (POST /get/employee/attendance)
  Future<bool> checkEmployeeAttendance(
      {String attendanceType = 'present'}) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);

    try {
      final response = await _apiService.checkEmployeeAttendance(
        employeeNumber: empNo,
        companyId: companyId,
        attendanceType: attendanceType,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final res = response.data['result'];
          if (res is bool) return res;
          if (res is String) return res.toLowerCase() == 'true';
        } else if (response.data is bool) {
          return response.data as bool;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Register Employee Phone (POST /employee/registered/phone)
  Future<Map<String, dynamic>> registerEmployeePhone(String workPhone) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);

    try {
      final response = await _apiService.registerEmployeePhone(
        employeeNumber: empNo,
        companyId: companyId,
        workPhone: workPhone,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final res = response.data['result'];
          if (res is Map<String, dynamic>) {
            if (res['error'] != null && res['error'].toString().isNotEmpty) {
              return {'error': res['error'].toString()};
            }
            return res;
          } else if (res != null) {
            return {'success': res.toString()};
          }
        }
      }
    } catch (e) {
      return {'error': 'Failed to register phone: $e'};
    }
    return {'error': 'Failed to register phone'};
  }

  /// Convert Work Plan XLSX (POST /wp/convert)
  Future<Map<String, dynamic>> convertWorkPlanXlsx(String filePath) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    try {
      final response = await _apiService.convertWorkPlanXlsx(
        filePath: filePath,
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
      }
    } catch (e) {
      return {'error': 'Work plan conversion error: $e'};
    }
    return {'error': 'Failed to convert work plan XLSX'};
  }

  /// Get Work Plan Download URL (GET /wp/download?file=)
  String getWorkPlanDownloadUrl(String filename) {
    return _apiService.getWorkPlanDownloadUrl(filename);
  }

  /// 12. Get Complaint Categories
  Future<List<DropdownItem>> getComplaintCategories() async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    try {
      final response = await _apiService.getComplaintCategories(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final result = response.data['result'];
          if (result is List && result.isNotEmpty) {
            return result.map((e) => DropdownItem.fromJson(e)).toList();
          }
        }
      }
    } catch (_) {}

    return [
      DropdownItem(id: '1', name: 'Salary Issue'),
      DropdownItem(id: '2', name: 'QID/Passport Issue'),
      DropdownItem(id: '3', name: 'Health Card Issue'),
      DropdownItem(id: '4', name: 'Complain Against Employee'),
      DropdownItem(id: '5', name: 'Complain Against Management'),
      DropdownItem(id: '6', name: 'Work Conditions Issue'),
      DropdownItem(id: '7', name: 'Transportation Issue'),
      DropdownItem(id: '8', name: 'Maintenance Issue'),
      DropdownItem(id: '9', name: 'Accommodation Issue'),
      DropdownItem(id: '10', name: 'Other Issue/Complaint'),
      DropdownItem(id: '11', name: 'Theft'),
    ];
  }

  Map<String, dynamic> parseSubmitResponse(
      dynamic responseData, String requestType) {
    if (responseData is Map<String, dynamic>) {
      if (responseData['error'] != null &&
          responseData['error'].toString().isNotEmpty) {
        final errMap = responseData['error'];
        String errStr = errMap.toString();
        if (errMap is Map) {
          if (errMap['message'] != null &&
              errMap['message'].toString().isNotEmpty) {
            errStr = errMap['message'].toString();
          }
        }
        if (errStr.contains('404') ||
            errStr.toLowerCase().contains('not found')) {
          errStr =
              'Self-service submission endpoint is not registered on the server (404 Not Found). Please verify backend deployment.';
        }
        return {
          'success': false,
          'error': errStr,
        };
      }

      final result = responseData['result'] ?? responseData;

      if (result is Map<String, dynamic>) {
        if (result['error'] != null && result['error'].toString().isNotEmpty) {
          return {
            'success': false,
            'error': result['error'].toString(),
          };
        }

        final ref = result['reference'] ??
            result['code'] ??
            result['name'] ??
            result['number'] ??
            result['id'] ??
            result['incident_code'] ??
            result['request_code'] ??
            result['leave_code'];

        final refStr = ref?.toString().trim() ?? '';

        return {
          'success': true,
          'reference': refStr,
          'code': refStr,
          'name': refStr,
          'message': result['message']?.toString() ??
              result['success']?.toString() ??
              '$requestType submitted successfully!',
          'result': result,
        };
      } else if (result is String && result.trim().isNotEmpty) {
        final str = result.trim();
        if (str.toLowerCase().contains('error') ||
            str.toLowerCase().contains('failed')) {
          return {'success': false, 'error': str};
        }
        return {
          'success': true,
          'reference': str,
          'code': str,
          'name': str,
          'message': '$requestType submitted successfully!',
        };
      } else if (result is num) {
        final numStr = result.toString();
        return {
          'success': true,
          'reference': numStr,
          'code': numStr,
          'name': numStr,
          'message': '$requestType submitted successfully!',
        };
      }
    }

    return {
      'success': false,
      'error':
          'Failed to submit $requestType. Server returned an invalid response.',
    };
  }

  /// 13. Submit Complaint
  Future<Map<String, dynamic>> submitComplaint(
      Map<String, dynamic> data) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyIdStr = StorageService.getValue(StorageService.keyCompanyId);
    final companyId = int.tryParse(companyIdStr) ?? companyIdStr;
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final payload = Map<String, dynamic>.from(data);
    payload['employee_number'] = empNo;
    payload['emp_no'] = empNo;
    payload['company_id'] = companyId;
    payload['api_token'] = apiToken;

    try {
      final response = await _apiService.submitComplaint(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
        data: payload,
      );

      if (response.data != null) {
        final parsed = parseSubmitResponse(response.data, 'Complaint');
        if (parsed['success'] == true ||
            (parsed.containsKey('error') &&
                parsed['error'].toString().isNotEmpty)) {
          return parsed;
        }
      }

      if (response.statusCode != 200) {
        return {
          'success': false,
          'error':
              'Server returned HTTP ${response.statusCode}. Please check server connection.'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Failed to submit Complaint: $e'};
    }

    return {
      'success': false,
      'error': 'Failed to submit Complaint. Invalid server response.'
    };
  }

  /// 14. Get Employee Request Categories
  Future<List<DropdownItem>> getEmployeeRequestCategories() async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    try {
      final response = await _apiService.getEmployeeRequestCategories(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final result = response.data['result'];
          if (result is List && result.isNotEmpty) {
            return result.map((e) => DropdownItem.fromJson(e)).toList();
          }
        }
      }
    } catch (_) {}

    return [
      DropdownItem(id: '1', name: 'New/Renew Health Card'),
      DropdownItem(id: '2', name: 'Renew Driving License'),
      DropdownItem(id: '3', name: 'Replacement Salary Card'),
      DropdownItem(id: '4', name: 'Replacement Uniform'),
      DropdownItem(id: '5', name: 'Salary Slip'),
      DropdownItem(id: '6', name: 'Salary Certificate'),
      DropdownItem(id: '7', name: 'Experience Certificate'),
      DropdownItem(id: '8', name: 'Change Accommodation'),
      DropdownItem(id: '9', name: 'Allowance Request'),
      DropdownItem(id: '10', name: 'Other Request'),
      DropdownItem(id: '11', name: 'Update Personal Data'),
    ];
  }

  /// 15. Submit Employee Request
  Future<Map<String, dynamic>> submitEmployeeRequest(
      Map<String, dynamic> data) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyIdStr = StorageService.getValue(StorageService.keyCompanyId);
    final companyId = int.tryParse(companyIdStr) ?? companyIdStr;
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final payload = Map<String, dynamic>.from(data);
    payload['employee_number'] = empNo;
    payload['emp_no'] = empNo;
    payload['company_id'] = companyId;
    payload['api_token'] = apiToken;

    try {
      final response = await _apiService.submitEmployeeRequest(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
        data: payload,
      );

      if (response.data != null) {
        final parsed = parseSubmitResponse(response.data, 'Employee Request');
        if (parsed['success'] == true ||
            (parsed.containsKey('error') &&
                parsed['error'].toString().isNotEmpty)) {
          return parsed;
        }
      }

      if (response.statusCode != 200) {
        return {
          'success': false,
          'error':
              'Server returned HTTP ${response.statusCode}. Please check server connection.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to submit Employee Request: $e'
      };
    }

    return {
      'success': false,
      'error': 'Failed to submit Employee Request. Invalid server response.'
    };
  }

  /// 16. Get Leave Types
  Future<List<DropdownItem>> getLeaveTypes() async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    try {
      final response = await _apiService.getLeaveTypes(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final result = response.data['result'];
          if (result is List && result.isNotEmpty) {
            return result.map((e) => DropdownItem.fromJson(e)).toList();
          }
        }
      }
    } catch (_) {}

    return [
      DropdownItem(id: '1', name: 'Annual Leave'),
      DropdownItem(id: '2', name: 'Emergency Leave'),
      DropdownItem(id: '3', name: 'Sick Leave'),
      DropdownItem(id: '4', name: 'Unpaid Leave'),
      DropdownItem(id: '5', name: 'Short Leave / Permission'),
      DropdownItem(id: '6', name: 'Official Business / Out of Office'),
    ];
  }

  /// 17. Submit Leave Request
  Future<Map<String, dynamic>> submitLeaveRequest(
      Map<String, dynamic> data) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyIdStr = StorageService.getValue(StorageService.keyCompanyId);
    final companyId = int.tryParse(companyIdStr) ?? companyIdStr;
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final payload = Map<String, dynamic>.from(data);
    payload['employee_number'] = empNo;
    payload['emp_no'] = empNo;
    payload['company_id'] = companyId;
    payload['api_token'] = apiToken;

    try {
      final response = await _apiService.submitLeaveRequest(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
        data: payload,
      );

      if (response.data != null) {
        final parsed = parseSubmitResponse(response.data, 'Leave Request');
        if (parsed['success'] == true ||
            (parsed.containsKey('error') &&
                parsed['error'].toString().isNotEmpty)) {
          return parsed;
        }
      }

      if (response.statusCode != 200) {
        return {
          'success': false,
          'error':
              'Server returned HTTP ${response.statusCode}. Please check server connection.'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Failed to submit Leave Request: $e'};
    }

    return {
      'success': false,
      'error': 'Failed to submit Leave Request. Invalid server response.'
    };
  }

  /// 18. Submit Bright Idea
  Future<Map<String, dynamic>> submitBrightIdea(
      Map<String, dynamic> data) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyIdStr = StorageService.getValue(StorageService.keyCompanyId);
    final companyId = int.tryParse(companyIdStr) ?? companyIdStr;
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final payload = Map<String, dynamic>.from(data);
    payload['employee_number'] = empNo;
    payload['emp_no'] = empNo;
    payload['company_id'] = companyId;
    payload['api_token'] = apiToken;

    try {
      final response = await _apiService.submitBrightIdea(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
        data: payload,
      );

      if (response.data != null) {
        final parsed = parseSubmitResponse(response.data, 'Bright Idea');
        if (parsed['success'] == true ||
            (parsed.containsKey('error') &&
                parsed['error'].toString().isNotEmpty)) {
          return parsed;
        }
      }

      if (response.statusCode != 200) {
        return {
          'success': false,
          'error':
              'Server returned HTTP ${response.statusCode}. Please check server connection.'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Failed to submit Bright Idea: $e'};
    }

    return {
      'success': false,
      'error': 'Failed to submit Bright Idea. Invalid server response.'
    };
  }

  /// 19. Submit Salary Slip Request
  Future<Map<String, dynamic>> submitSalarySlipRequest(
      Map<String, dynamic> data) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyIdStr = StorageService.getValue(StorageService.keyCompanyId);
    final companyId = int.tryParse(companyIdStr) ?? companyIdStr;
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final payload = Map<String, dynamic>.from(data);
    payload['employee_number'] = empNo;
    payload['emp_no'] = empNo;
    payload['company_id'] = companyId;
    payload['api_token'] = apiToken;

    try {
      final response = await _apiService.submitSalarySlipRequest(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
        data: payload,
      );

      if (response.data != null) {
        final parsed =
            parseSubmitResponse(response.data, 'Salary Slip Request');
        if (parsed['success'] == true ||
            (parsed.containsKey('error') &&
                parsed['error'].toString().isNotEmpty)) {
          return parsed;
        }
      }

      if (response.statusCode != 200) {
        return {
          'success': false,
          'error':
              'Server returned HTTP ${response.statusCode}. Please check server connection.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to submit Salary Slip Request: $e'
      };
    }

    return {
      'success': false,
      'error': 'Failed to submit Salary Slip Request. Invalid server response.'
    };
  }

  /// 20. Track & Retrieve Cases directly from Backend API
  Future<List<Map<String, dynamic>>> getEmployeeCases(
      {String code = ''}) async {
    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);
    final apiToken = StorageService.getValue(StorageService.keyAccessToken);

    final cleanCode = code.trim();
    final List<Map<String, dynamic>> allCases = [];

    void addUniqueCases(List<Map<String, dynamic>> newCases) {
      for (var newCase in newCases) {
        final newCode = (newCase['code'] ??
                newCase['reference'] ??
                newCase['name'] ??
                newCase['id'] ??
                '')
            .toString();
        if (newCode.isNotEmpty) {
          final exists = allCases.any((c) {
            final existingCode =
                (c['code'] ?? c['reference'] ?? c['name'] ?? c['id'] ?? '')
                    .toString();
            return existingCode == newCode;
          });
          if (!exists) {
            allCases.add(newCase);
          }
        } else {
          allCases.add(newCase);
        }
      }
    }

    // Development logging for Track Case API execution (Requirement 12)
    // ignore: avoid_print
    print('--- Track Case API Execution ---');
    // ignore: avoid_print
    print('Employee Number: $empNo');
    // ignore: avoid_print
    print('Company ID: $companyId');
    // ignore: avoid_print
    print('Search Code: $cleanCode');

    // 1. Try trackCase specific lookup if code is provided
    if (cleanCode.isNotEmpty) {
      try {
        final response = await _apiService.trackCase(
          employeeNumber: empNo,
          companyId: companyId,
          apiToken: apiToken,
          code: cleanCode,
        );

        if (response.statusCode == 200 && response.data != null) {
          final parsed = parseCasesResponse(response.data);
          addUniqueCases(parsed);
        }
      } catch (_) {}

      try {
        final response = await _apiService.trackCaseAlternative(
          employeeNumber: empNo,
          companyId: companyId,
          apiToken: apiToken,
          code: cleanCode,
        );

        if (response.statusCode == 200 && response.data != null) {
          final parsed = parseCasesResponse(response.data);
          addUniqueCases(parsed);
        }
      } catch (_) {}
    }

    // 2. Fetch from self_service/cases endpoint
    try {
      final response = await _apiService.getSelfServiceCases(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
        code: cleanCode.isNotEmpty ? cleanCode : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final parsed = parseCasesResponse(response.data);
        addUniqueCases(parsed);
      }
    } catch (_) {}

    // 3. Fetch from complaint/list
    try {
      final response = await _apiService.getComplaintList(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
        code: cleanCode.isNotEmpty ? cleanCode : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final parsed = parseCasesResponse(response.data);
        addUniqueCases(parsed);
      }
    } catch (_) {}

    // 4. Fetch from employee_request/list
    try {
      final response = await _apiService.getEmployeeRequestList(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
        code: cleanCode.isNotEmpty ? cleanCode : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final parsed = parseCasesResponse(response.data);
        addUniqueCases(parsed);
      }
    } catch (_) {}

    // 5. Fetch from leave/list
    try {
      final response = await _apiService.getLeaveList(
        employeeNumber: empNo,
        companyId: companyId,
        apiToken: apiToken,
        code: cleanCode.isNotEmpty ? cleanCode : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final parsed = parseCasesResponse(response.data);
        addUniqueCases(parsed);
      }
    } catch (_) {}

    // Filter by code if user entered a specific search term
    if (cleanCode.isNotEmpty && allCases.isNotEmpty) {
      final filtered = allCases.where((c) {
        final cCode = (c['code'] ?? c['reference'] ?? c['name'] ?? '')
            .toString()
            .toUpperCase();
        return cCode.contains(cleanCode.toUpperCase());
      }).toList();

      if (filtered.isNotEmpty) {
        // ignore: avoid_print
        print('Parsed Cases Count: ${filtered.length}');
        return filtered;
      }
    }

    // ignore: avoid_print
    print('Parsed Cases Count: ${allCases.length}');
    return allCases;
  }

  /// Helper to parse cases array / map from Odoo JSON-RPC responses
  List<Map<String, dynamic>> parseCasesResponse(dynamic data) {
    final List<Map<String, dynamic>> cases = [];

    if (data is Map<String, dynamic>) {
      final result = data['result'] ?? data;

      if (result is List) {
        for (var item in result) {
          if (item is Map<String, dynamic>) {
            cases.add(item);
          }
        }
      } else if (result is Map<String, dynamic>) {
        final rawList = result['cases'] ??
            result['data'] ??
            result['records'] ??
            result['items'] ??
            result['requests'] ??
            result['complaints'] ??
            result['leaves'] ??
            result['list'];

        if (rawList is List) {
          for (var item in rawList) {
            if (item is Map<String, dynamic>) {
              cases.add(item);
            }
          }
        } else if (result.containsKey('code') ||
            result.containsKey('reference') ||
            result.containsKey('status') ||
            result.containsKey('id')) {
          cases.add(result);
        }
      }
    } else if (data is List) {
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          cases.add(item);
        }
      }
    }

    return cases;
  }
}
