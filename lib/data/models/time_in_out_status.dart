class TimeInOutStatus {
  final bool isTimeIn;
  final String lastTimeInDatetime;
  final String? error;
  final String checkInLocationName;
  final int? checkInLocationId;
  final String? attendanceId;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? allowedRadiusMeters;
  final double? checkInAccuracyMeters;

  TimeInOutStatus({
    required this.isTimeIn,
    required this.lastTimeInDatetime,
    this.error,
    this.checkInLocationName = '',
    this.checkInLocationId,
    this.attendanceId,
    this.checkInLatitude,
    this.checkInLongitude,
    this.allowedRadiusMeters,
    this.checkInAccuracyMeters,
  });

  factory TimeInOutStatus.fromJson(Map<String, dynamic> json) {
    final result =
        json['result'] is Map<String, dynamic> ? json['result'] : json;
    final location = _locationMap(result);
    return TimeInOutStatus(
      isTimeIn: result['is_time_in'] == true,
      lastTimeInDatetime: result['last_time_in_datetime']?.toString() ?? '',
      error: result['error']?.toString(),
      checkInLocationName: _text(location, const [
            'name',
            'location_name',
            'area_name',
            'check_in_location_name'
          ]) ??
          '',
      checkInLocationId: _integer(
          location, const ['id', 'area_id', 'location_id', 'work_location_id']),
      attendanceId:
          (result['time_in_id'] ?? result['attendance_id'] ?? result['id'])
              ?.toString(),
      checkInLatitude:
          _number(location, const ['check_in_latitude', 'latitude', 'lat']),
      checkInLongitude: _number(location,
          const ['check_in_longitude', 'longitude', 'long', 'lng', 'lon']),
      allowedRadiusMeters: _positiveNumber(location, const [
        'allowed_radius',
        'allowed_radius_meters',
        'radius',
        'radius_meters',
        'geofence_radius'
      ]),
      checkInAccuracyMeters: _positiveNumber(
          location, const ['check_in_accuracy', 'accuracy', 'accuracy_meters']),
    );
  }

  static Map<String, dynamic> _locationMap(Map<String, dynamic> result) {
    for (final key in const [
      'check_in_location',
      'work_location',
      'location',
      'area',
      'area_id'
    ]) {
      final value = result[key];
      if (value is Map) return Map<String, dynamic>.from(value);
    }
    return result;
  }

  static double? _number(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      final parsed = value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  static double? _positiveNumber(
      Map<String, dynamic> source, List<String> keys) {
    final value = _number(source, keys);
    return value != null && value > 0 ? value : null;
  }

  static int? _integer(Map<String, dynamic> source, List<String> keys) {
    final value = _number(source, keys);
    return value?.toInt();
  }

  static String? _text(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
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
