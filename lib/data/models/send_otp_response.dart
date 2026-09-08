class SendOtpResponse {
  final String? success;
  final String? error;
  final String? status;
  final String? registerMobile;

  SendOtpResponse({
    this.success,
    this.error,
    this.status,
    this.registerMobile,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] is Map<String, dynamic> ? json['result'] : json;
    return SendOtpResponse(
      success: result['success']?.toString(),
      error: result['error']?.toString(),
      status: result['status']?.toString(),
      registerMobile: result['register_mobile']?.toString(),
    );
  }

  bool get isStatus101 => status == '101';
  bool get isSuccess => success != null && success!.isNotEmpty;
  bool get hasError => error != null && error!.isNotEmpty;

  dynamic operator [](String key) {
    switch (key) {
      case 'success':
        return success;
      case 'error':
        return error;
      case 'status':
        return status;
      case 'register_mobile':
        return registerMobile;
      case 'result':
        return this;
      default:
        return null;
    }
  }
}
