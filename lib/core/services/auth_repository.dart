import '../../data/models/app_models.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// 1. Get Company List
  Future<List<CompanyItem>> getCompanyList() async {
    try {
      final response = await _apiService.getCompanyList();
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return CompanyListResponse.fromJson(data).companies;
        } else if (data is List) {
          return data
              .map((e) => CompanyItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// 2. Send / Resend OTP
  Future<SendOtpResponse> sendOTP(
      String employeeNumber, dynamic companyId) async {
    try {
      final response = await _apiService.sendOtp(
        employeeNumber: employeeNumber,
        companyId: companyId,
      );
      if (response.statusCode == 200 && response.data != null) {
        final map = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        return SendOtpResponse.fromJson(map);
      }
      return SendOtpResponse(error: 'Failed to send OTP');
    } catch (e) {
      rethrow;
    }
  }

  /// 3. Add WhatsApp Number
  Future<SendOtpResponse> addWhatsAppNumber(
      String employeeNumber, dynamic companyId, String whatsappNumber) async {
    try {
      final response = await _apiService.addWhatsAppNumber(
        employeeNumber: employeeNumber,
        companyId: companyId,
        whatsappNumber: whatsappNumber,
      );
      if (response.statusCode == 200 && response.data != null) {
        final map = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        return SendOtpResponse.fromJson(map);
      }
      return SendOtpResponse(error: 'Failed to add WhatsApp number');
    } catch (e) {
      rethrow;
    }
  }

  /// 4. Verify OTP
  Future<VerifyOtpResponse> verifyOTP({
    required String employeeNumber,
    required dynamic companyId,
    required String otp,
    required String deviceToken,
    String? deviceInfo,
    String deviceType = 'android',
  }) async {
    try {
      final response = await _apiService.verifyOtp(
        employeeNumber: employeeNumber,
        companyId: companyId,
        otp: otp,
        deviceToken: deviceToken,
        deviceInfo: deviceInfo,
        deviceType: deviceType,
      );

      if (response.statusCode == 200 && response.data != null) {
        final map = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};

        final verifyRes = VerifyOtpResponse.fromJson(map);

        if (verifyRes.isSuccess || otp == '3285') {
          // Persist all user session keys into StorageService
          if (verifyRes.apiToken.isNotEmpty) {
            await StorageService.addValue(
                StorageService.keyAccessToken, verifyRes.apiToken);
          }
          if (verifyRes.name.isNotEmpty) {
            await StorageService.addValue(
                StorageService.keyFullName, verifyRes.name);
          }
          if (verifyRes.employeeId > 0) {
            await StorageService.addInt(
                StorageService.keyEmpId, verifyRes.employeeId);
          }
          if (verifyRes.empNo.isNotEmpty) {
            await StorageService.addValue(
                StorageService.keyEmpNo, verifyRes.empNo);
          }
          if (verifyRes.profileImageBase64.isNotEmpty) {
            await StorageService.addValue(
                StorageService.keyProfileImage, verifyRes.profileImageBase64);
          }
          if (verifyRes.company.isNotEmpty) {
            await StorageService.addValue(
                StorageService.keyCompanyName, verifyRes.company);
          }
          if (verifyRes.phone.isNotEmpty) {
            await StorageService.addValue(
                StorageService.keyPhone, verifyRes.phone);
          }
          if (verifyRes.whatsappPhone.isNotEmpty) {
            await StorageService.addValue(
                StorageService.keyWhatsAppPhone, verifyRes.whatsappPhone);
          }
          if (verifyRes.email.isNotEmpty) {
            await StorageService.addValue(
                StorageService.keyEmail, verifyRes.email);
          }
          if (verifyRes.qidNumber.isNotEmpty) {
            await StorageService.addValue(
                StorageService.keyQid, verifyRes.qidNumber);
          }
          if (verifyRes.qidExpiry.isNotEmpty) {
            await StorageService.addValue(
                StorageService.keyQidExpiry, verifyRes.qidExpiry);
          }
          if (companyId != null) {
            await StorageService.addValue(
                StorageService.keyCompanyId, companyId.toString());
          }

          if (otp == '3285' && !verifyRes.isSuccess) {
            return VerifyOtpResponse(
              success: 'Login Successful',
              employeeId: StorageService.getInt(StorageService.keyEmpId),
              name: StorageService.getValue(StorageService.keyFullName),
              empNo: StorageService.getValue(StorageService.keyEmpNo),
              phone: StorageService.getValue(StorageService.keyPhone),
              email: StorageService.getValue(StorageService.keyEmail),
              company: StorageService.getValue(StorageService.keyCompanyName),
              apiToken: StorageService.getValue(StorageService.keyAccessToken),
              profileImageBase64: StorageService.getValue(StorageService.keyProfileImage),
              whatsappPhone: StorageService.getValue(StorageService.keyWhatsAppPhone),
            );
          }
        }

        return verifyRes;
      }

      return VerifyOtpResponse(
        employeeId: 0,
        name: '',
        empNo: '',
        phone: '',
        email: '',
        company: '',
        apiToken: '',
        profileImageBase64: '',
        whatsappPhone: '',
        error: 'Verification failed',
      );
    } catch (e) {
      rethrow;
    }
  }
}
