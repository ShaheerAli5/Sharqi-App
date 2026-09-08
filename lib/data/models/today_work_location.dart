class TodayWorkLocation {
  final int id;
  final String name;

  TodayWorkLocation({required this.id, required this.name});

  factory TodayWorkLocation.fromJson(Map<String, dynamic> json) {
    final result = json['result'] is Map<String, dynamic> ? json['result'] : json;
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
      );
    }
    return TodayWorkLocation(id: -1, name: '');
  }

  dynamic operator [](String key) {
    if (key == 'id') return id;
    if (key == 'name') return name;
    if (key == 'area_id') return {'id': id, 'name': name};
    if (key == 'result') return {'area_id': {'id': id, 'name': name}};
    return null;
  }
}
