import 'package:flutter_test/flutter_test.dart';
import 'package:sharqi/core/services/location_service.dart';
import 'package:sharqi/core/services/storage_service.dart';
import 'package:sharqi/data/models/app_models.dart';

void main() {
  group('Odoo Models JSON-RPC Defensive Parsing Tests', () {
    test('CompanyItem & CompanyListResponse parsing', () {
      final json = {
        'result': [
          {'id': 1, 'name': 'Al Sharqi Holding LLC'},
          {'id': '2', 'name': 'Mr. Valet'}
        ]
      };
      final res = CompanyListResponse.fromJson(json);
      expect(res.companies.length, 2);
      expect(res.companies[0].id, 1);
      expect(res.companies[0].name, 'Al Sharqi Holding LLC');
      expect(res.companies[1].id, 2);
      expect(res.companies[1].name, 'Mr. Valet');
      expect(res.companies[0]['id'], 1);
      expect(res.companies[0]['name'], 'Al Sharqi Holding LLC');
    });

    test('SendOtpResponse parsing & getters', () {
      final json101 = {
        'result': {
          'status': '101',
          'error': 'Mobile number is not registered'
        }
      };
      final res101 = SendOtpResponse.fromJson(json101);
      expect(res101.isStatus101, true);
      expect(res101.isSuccess, false);
      expect(res101.hasError, true);

      final jsonSuccess = {
        'result': {
          'success': 'OTP sent successfully',
          'register_mobile': '97412345678'
        }
      };
      final resSuccess = SendOtpResponse.fromJson(jsonSuccess);
      expect(resSuccess.isStatus101, false);
      expect(resSuccess.isSuccess, true);
      expect(resSuccess.registerMobile, '97412345678');
    });

    test('VerifyOtpResponse Odoo false boolean handling', () {
      final json = {
        'result': {
          'success': 'Login Successful',
          'employee_id': 45,
          'name': 'Ahmed Al-Sharqi',
          'emp_no': '10091',
          'phone': false, // Odoo returns false when empty
          'email': false,
          'company': 'Al Sharqi Holding LLC',
          'api_token': 'token123',
          'profile': false, // Odoo returns false when no avatar
          'whatsapp_phone': false
        }
      };
      final res = VerifyOtpResponse.fromJson(json);
      expect(res.isSuccess, true);
      expect(res.employeeId, 45);
      expect(res.name, 'Ahmed Al-Sharqi');
      expect(res.empNo, '10091');
      expect(res.phone, '');
      expect(res.email, '');
      expect(res.profileImageBase64, '');
      expect(res.whatsappPhone, '');
      expect(res.apiToken, 'token123');
    });

    test('DashboardData parsing & toGridList', () {
      final json = {
        'result': {
          'success': true,
          'company': 'Al Sharqi Holding LLC',
          'join_date': '2021-03-15',
          'qid_number': '28835668261',
          'qid_expiry': '2026-11-20',
          'passport_number': 'N7845120',
          'passport_expiry': '2028-04-10',
          'gender': 'Male',
          'nationality': 'Qatari',
          'work_location': 'Doha Head Office',
          'location': 'Floor 4',
          'manager': 'Mohammed Al-Kuwari'
        }
      };
      final dash = DashboardData.fromJson(json);
      expect(dash.success, true);
      expect(dash.company, 'Al Sharqi Holding LLC');
      final grid = dash.toGridList();
      expect(grid.length, 11);
      expect(grid[0].key, 'Company');
      expect(grid[0].value, 'Al Sharqi Holding LLC');
    });

    test('TimeInOutStatus parsing', () {
      final jsonIn = {
        'result': {
          'success': true,
          'is_time_in': true,
          'last_time_in_datetime': '2026-09-08 08:15'
        }
      };
      final statusIn = TimeInOutStatus.fromJson(jsonIn);
      expect(statusIn.isTimeIn, true);
      expect(statusIn.lastTimeInDatetime, '2026-09-08 08:15');

      final jsonOut = {
        'result': {
          'success': true,
          'is_time_in': false,
          'last_time_in_datetime': ''
        }
      };
      final statusOut = TimeInOutStatus.fromJson(jsonOut);
      expect(statusOut.isTimeIn, false);
    });

    test('TodayWorkLocation & WorkLocationItem parsing', () {
      final jsonToday = {
        'result': {
          'area_id': {
            'id': 14,
            'name': 'Tower A - Construction Site'
          }
        }
      };
      final today = TodayWorkLocation.fromJson(jsonToday);
      expect(today.id, 14);
      expect(today.name, 'Tower A - Construction Site');

      final item = WorkLocationItem.fromJson({'id': 14, 'name': 'Tower A', 'code': false});
      expect(item.id, 14);
      expect(item.name, 'Tower A');
      expect(item.code, false);
    });

    test('AttendanceItem overtime approval getter', () {
      final itemApproved = AttendanceItem.fromJson({
        'id': 1,
        'name': 'AA001',
        'emp_no': '10091',
        'date': '2026-09-08',
        's_time': '08.15',
        'e_time': '17.00',
        'work_hours': 8.75,
        'overtime_hours': 0.75
      });
      expect(itemApproved.isApproved, true);

      final itemNoOt = AttendanceItem.fromJson({
        'id': 2,
        'name': 'AA002',
        'emp_no': '10091',
        'date': '2026-09-07',
        's_time': '08.00',
        'e_time': '16.00',
        'work_hours': 8.0,
        'overtime_hours': 0.0
      });
      expect(itemNoOt.isApproved, false);
    });

    test('LocationResult model test', () {
      final loc = LocationResult(
        latitude: 25.2867,
        longitude: 51.5333,
        geoLocationString: '25.2867,51.5333',
        isSuccess: true,
      );
      expect(loc.latitude, 25.2867);
      expect(loc.longitude, 51.5333);
      expect(loc.geoLocationString, '25.2867,51.5333');
      expect(loc.isSuccess, true);

      final err = LocationResult.error('GPS Disabled');
      expect(err.isSuccess, false);
      expect(err.errorMessage, 'GPS Disabled');
    });

    test('StorageService keys test', () {
      expect(StorageService.keyAccessToken, 'ACCESS_TOKEN');
      expect(StorageService.keyDeviceId, 'DEVICE_ID');
      expect(StorageService.keyEmpId, 'EMP_ID');
      expect(StorageService.keyCompanyId, 'COMPANY_ID');
      expect(StorageService.keyEmpNo, 'EMP_NO');
      expect(StorageService.keyFullName, 'FULL_NAME');
      expect(StorageService.keyEmail, 'EMAIL');
      expect(StorageService.keyPhone, 'PHONE');
      expect(StorageService.keyProfileImage, 'PROFILE_IMAGE');
      expect(StorageService.keyWhatsAppPhone, 'WHATS_APP_PHONE');
      expect(StorageService.keyCompanyName, 'COMPANY_NAME');
    });
  });
}
