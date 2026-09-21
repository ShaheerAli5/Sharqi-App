import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sharqi/core/services/api_service.dart';
import 'package:sharqi/core/services/auth_repository.dart';
import 'package:sharqi/core/services/storage_service.dart';

class _FakeApiService extends ApiService {
  _FakeApiService(this.response, {this.delay = Duration.zero});

  final Response<dynamic> response;
  final Duration delay;

  @override
  Future<Response<dynamic>> verifyOtp({
    required String employeeNumber,
    required dynamic companyId,
    required String otp,
    required String deviceToken,
    String? deviceInfo,
    String deviceType = 'android',
  }) async {
    await Future<void>.delayed(delay);
    return response;
  }
}

Response<dynamic> _response(Map<String, dynamic> result) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: 'attendance/otp/verify'),
    statusCode: 200,
    data: <String, dynamic>{'result': result},
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageService.init();
  });

  test('waits for and saves a delayed valid backend OTP response', () async {
    final repository = AuthRepository(
      apiService: _FakeApiService(
        _response(<String, dynamic>{
          'success': 'Login Successful',
          'employee_id': 2225,
          'name': 'Backend Employee',
          'emp_no': '2225',
          'api_token': 'real_backend_token',
        }),
        delay: const Duration(milliseconds: 50),
      ),
    );

    final result = await repository.verifyOTP(
      employeeNumber: '2225',
      companyId: '1',
      otp: '3285',
      deviceToken: 'device-token',
    );

    expect(result.isSuccess, isTrue);
    expect(result.empNo, '2225');
    expect(
      StorageService.getValue(StorageService.keyAccessToken),
      'real_backend_token',
    );
  });

  test('does not create a local session when backend rejects OTP', () async {
    final repository = AuthRepository(
      apiService: _FakeApiService(
        _response(<String, dynamic>{'error': 'Invalid OTP'}),
      ),
    );

    final result = await repository.verifyOTP(
      employeeNumber: '2225',
      companyId: '1',
      otp: '3285',
      deviceToken: 'device-token',
    );

    expect(result.isSuccess, isFalse);
    expect(result.error, 'Invalid OTP');
    expect(StorageService.getValue(StorageService.keyAccessToken), isEmpty);
  });
}
