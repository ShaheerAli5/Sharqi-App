class TimeInOutStatus {
  final bool isTimeIn;
  final String lastTimeInDatetime;
  final String? error;

  TimeInOutStatus({
    required this.isTimeIn,
    required this.lastTimeInDatetime,
    this.error,
  });

  factory TimeInOutStatus.fromJson(Map<String, dynamic> json) {
    final result = json['result'] is Map<String, dynamic> ? json['result'] : json;
    return TimeInOutStatus(
      isTimeIn: result['is_time_in'] == true,
      lastTimeInDatetime: result['last_time_in_datetime']?.toString() ?? '',
      error: result['error']?.toString(),
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'is_time_in':
        return isTimeIn;
      case 'last_time_in_datetime':
        return lastTimeInDatetime;
      case 'error':
        return error;
      case 'result':
        return this;
      default:
        return null;
    }
  }
}
