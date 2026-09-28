class TodayWorkLocation {
  final int id;
  final String name;
  final double? latitude;
  final double? longitude;
  final double? allowedRadiusMeters;

  TodayWorkLocation({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.allowedRadiusMeters,
  });

  factory TodayWorkLocation.fromJson(Map<String, dynamic> json) {
    final result =
        json['result'] is Map<String, dynamic> ? json['result'] : json;
    final area = result['area_id'];
    if (area is Map<String, dynamic>) {
      int parseId(dynamic val) {
        if (val is int) return val;
        if (val is num) return val.toInt();
        if (val is String) return int.tryParse(val) ?? -1;
        return -1;
      }

      return TodayWorkLocation(
        id: parseId(area['id']),
        name: area['name']?.toString() ?? '',
        latitude: _coordinate(area, result, const ['latitude', 'lat']),
        longitude: _coordinate(
          area,
          result,
          const ['longitude', 'long', 'lng', 'lon'],
        ),
        allowedRadiusMeters: _coordinate(
          area,
          result,
          const [
            'allowed_radius',
            'allowed_radius_meters',
            'radius',
            'radius_meters',
            'geofence_radius',
          ],
          positiveOnly: true,
        ),
      );
    }
    return TodayWorkLocation(id: -1, name: '');
  }

  static double? _coordinate(
    Map area,
    Map result,
    List<String> keys, {
    bool positiveOnly = false,
  }) {
    for (final source in [area, result]) {
      for (final key in keys) {
        final value = source[key];
        final parsed = value is num
            ? value.toDouble()
            : double.tryParse(value?.toString() ?? '');
        if (parsed != null && (!positiveOnly || parsed > 0)) {
          return parsed;
        }
      }
    }
    return null;
  }

  dynamic operator [](String key) {
    if (key == 'id') return id;
    if (key == 'name') return name;
    if (key == 'latitude' || key == 'lat') return latitude;
    if (key == 'longitude' || key == 'long') return longitude;
    if (key == 'radius') return allowedRadiusMeters;
    if (key == 'area_id') return {'id': id, 'name': name};
    if (key == 'result') {
      return {
        'area_id': {'id': id, 'name': name}
      };
    }
    return null;
  }
}
