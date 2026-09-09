class VerifyOtpResponse {
  final String? success;
  final String? error;
  final int employeeId;
  final String name;
  final String empNo;
  final String phone;
  final String email;
  final String company;
  final String apiToken;
  final String profileImageBase64;
  final String whatsappPhone;
  final String qidNumber;
  final String qidExpiry;

  VerifyOtpResponse({
    this.success,
    this.error,
    required this.employeeId,
    required this.name,
    required this.empNo,
    required this.phone,
    required this.email,
    required this.company,
    required this.apiToken,
    required this.profileImageBase64,
    required this.whatsappPhone,
    this.qidNumber = '',
    this.qidExpiry = '',
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] is Map<String, dynamic> ? json['result'] : json;

    int parseEmpId(dynamic val) {
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    String parseStringSafe(dynamic val) {
      if (val == null || val is bool) return '';
      return val.toString();
    }

    return VerifyOtpResponse(
      success: result['success']?.toString(),
      error: result['error']?.toString(),
      employeeId: parseEmpId(result['employee_id']),
      name: parseStringSafe(result['name']),
      empNo: parseStringSafe(result['emp_no']),
      phone: parseStringSafe(result['phone']),
      email: parseStringSafe(result['email']),
      company: parseStringSafe(result['company']),
      apiToken: parseStringSafe(result['api_token']),
      profileImageBase64: parseStringSafe(result['profile']),
      whatsappPhone: parseStringSafe(result['whatsapp_phone']),
      qidNumber: parseStringSafe(result['qid_number'] ?? result['qid'] ?? result['qid_no']),
      qidExpiry: parseStringSafe(result['qid_expiry'] ?? result['qid_exp']),
    );
  }

  bool get isSuccess => (success != null && success!.isNotEmpty) || apiToken.isNotEmpty;

  dynamic operator [](String key) {
    switch (key) {
      case 'success':
        return success;
      case 'error':
        return error;
      case 'employee_id':
      case 'emp_id':
        return employeeId;
      case 'name':
      case 'full_name':
        return name;
      case 'emp_no':
      case 'employee_number':
        return empNo;
      case 'phone':
        return phone;
      case 'email':
        return email;
      case 'company':
        return company;
      case 'api_token':
      case 'access_token':
        return apiToken;
      case 'profile':
      case 'profile_image':
        return profileImageBase64;
      case 'whatsapp_phone':
      case 'whatsapp':
        return whatsappPhone;
      case 'result':
        return this;
      default:
        return null;
    }
  }
}
