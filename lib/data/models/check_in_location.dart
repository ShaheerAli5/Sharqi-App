class CheckInLocation {
  final String employeeNumber;
  final String companyId;
  final String date;
  final String name;
  final int? workLocationId;
  final String? attendanceId;
  final double latitude;
  final double longitude;
  final double? allowedRadiusMeters;
  final double? checkInAccuracyMeters;
  final String coordinateSource;

  const CheckInLocation({
    required this.employeeNumber,
    required this.companyId,
    required this.date,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.workLocationId,
    this.attendanceId,
    this.allowedRadiusMeters,
    this.checkInAccuracyMeters,
    this.coordinateSource = '',
  });

  bool get hasValidCoordinates =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      (latitude != 0 || longitude != 0);

  bool get hasValidRadius =>
      allowedRadiusMeters != null && allowedRadiusMeters! > 0;

  bool get hasUsableAccuracy =>
      checkInAccuracyMeters != null && checkInAccuracyMeters! > 0;

  double? validationRadius(double? currentAccuracyMeters) =>
      hasValidRadius ? allowedRadiusMeters : null;

  Map<String, dynamic> toJson() => {
        'employee_number': employeeNumber,
        'company_id': companyId,
        'date': date,
        'name': name,
        'work_location_id': workLocationId,
        'attendance_id': attendanceId,
      };

  factory CheckInLocation.fromJson(Map<String, dynamic> json) =>
      CheckInLocation(
        employeeNumber: json['employee_number']?.toString() ?? '',
        companyId: json['company_id']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        workLocationId: _intValue(json['work_location_id']),
        attendanceId: json['attendance_id']?.toString(),
        latitude: _doubleValue(json['latitude']) ?? 0,
        longitude: _doubleValue(json['longitude']) ?? 0,
        allowedRadiusMeters: _positiveDouble(json['allowed_radius_meters']),
        checkInAccuracyMeters:
            _positiveDouble(json['check_in_accuracy_meters']),
        coordinateSource: json['coordinate_source']?.toString() ?? '',
      );

  static double? _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static double? _positiveDouble(dynamic value) {
    final parsed = _doubleValue(value);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static int? _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
