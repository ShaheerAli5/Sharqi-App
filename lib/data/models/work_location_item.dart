class WorkLocationItem {
  final int id;
  final String name;
  final bool code;
  final double? latitude;
  final double? longitude;
  final double? allowedRadiusMeters;
  final bool overrideApiCoordinates;

  WorkLocationItem({
    required this.id,
    required this.name,
    required this.code,
    this.latitude,
    this.longitude,
    this.allowedRadiusMeters,
    this.overrideApiCoordinates = false,
  });

  factory WorkLocationItem.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return WorkLocationItem(
      id: parseId(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code'] == true,
      latitude: _doubleFrom(json, const ['latitude', 'lat']),
      longitude: _doubleFrom(json, const ['longitude', 'long', 'lng', 'lon']),
      allowedRadiusMeters: _doubleFrom(
        json,
        const [
          'allowed_radius',
          'allowed_radius_meters',
          'radius',
          'radius_meters',
          'geofence_radius',
        ],
        positiveOnly: true,
      ),
      overrideApiCoordinates: json['override_api_coordinates'] == true,
    );
  }

  static double? _doubleFrom(
    Map<String, dynamic> json,
    List<String> keys, {
    bool positiveOnly = false,
  }) {
    for (final key in keys) {
      final value = json[key];
      final parsed = value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '');
      if (parsed != null && (!positiveOnly || parsed > 0)) return parsed;
    }
    return null;
  }

  dynamic operator [](String key) {
    if (key == 'id') return id;
    if (key == 'name') return name;
    if (key == 'code') return code;
    if (key == 'latitude' || key == 'lat') return latitude;
    if (key == 'longitude' || key == 'long') return longitude;
    if (key == 'radius') return allowedRadiusMeters;
    if (key == 'override_api_coordinates') return overrideApiCoordinates;
    return null;
  }
}
