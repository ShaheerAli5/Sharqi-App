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

        if (verifyRes.isSuccess && verifyRes.apiToken.isNotEmpty) {
          await _saveUserSession(verifyRes, companyId);
          return verifyRes;
        }

        if (verifyRes.isSuccess && verifyRes.apiToken.isEmpty) {
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
            error: 'Invalid login response. Please try again.',
          );
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
        error: 'Verification timed out or failed. Please try again.',
      );
    } catch (e) {
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
        error: 'Verification error: $e',
      );
    }
  }

  Future<void> _clearPreviousSession() async {
    await StorageService.removeValue(StorageService.keyAccessToken);
    await StorageService.removeValue(StorageService.keyFullName);
    await StorageService.removeValue(StorageService.keyEmpId);
    await StorageService.removeValue(StorageService.keyProfileImage);
    await StorageService.removeValue(StorageService.keyPhone);
    await StorageService.removeValue(StorageService.keyWhatsAppPhone);
    await StorageService.removeValue(StorageService.keyEmail);
    await StorageService.removeValue(StorageService.keyQid);
    await StorageService.removeValue(StorageService.keyQidExpiry);
  }

  Future<void> _saveUserSession(
      VerifyOtpResponse verifyRes, dynamic companyId) async {
    await _clearPreviousSession();

    if (verifyRes.apiToken.isNotEmpty) {
      await StorageService.addValue(
          StorageService.keyAccessToken, verifyRes.apiToken);
    }
    if (verifyRes.name.isNotEmpty) {
      await StorageService.addValue(StorageService.keyFullName, verifyRes.name);
    }
    if (verifyRes.employeeId > 0) {
      await StorageService.addInt(
          StorageService.keyEmpId, verifyRes.employeeId);
    }
    if (verifyRes.empNo.isNotEmpty) {
      await StorageService.addValue(StorageService.keyEmpNo, verifyRes.empNo);
    }
    if (verifyRes.profileImageBase64.isNotEmpty &&
        verifyRes.profileImageBase64 != 'N/A') {
      await StorageService.addValue(
          StorageService.keyProfileImage, verifyRes.profileImageBase64);
    }
    if (verifyRes.company.isNotEmpty) {
      await StorageService.addValue(
          StorageService.keyCompanyName, verifyRes.company);
    }
    if (verifyRes.phone.isNotEmpty) {
      await StorageService.addValue(StorageService.keyPhone, verifyRes.phone);
    }
    if (verifyRes.whatsappPhone.isNotEmpty) {
      await StorageService.addValue(
          StorageService.keyWhatsAppPhone, verifyRes.whatsappPhone);
    }
    if (verifyRes.email.isNotEmpty) {
      await StorageService.addValue(StorageService.keyEmail, verifyRes.email);
    }
    if (verifyRes.qidNumber.isNotEmpty) {
      await StorageService.addValue(StorageService.keyQid, verifyRes.qidNumber);
    }
    if (verifyRes.qidExpiry.isNotEmpty) {
      await StorageService.addValue(
          StorageService.keyQidExpiry, verifyRes.qidExpiry);
    }
    if (companyId != null) {
      await StorageService.addValue(
          StorageService.keyCompanyId, companyId.toString());
    }
  }
}
