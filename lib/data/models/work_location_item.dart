class WorkLocationItem {
  final int id;
  final String name;
  final bool code;

  WorkLocationItem({
    required this.id,
    required this.name,
    required this.code,
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
    );
  }

  dynamic operator [](String key) {
    if (key == 'id') return id;
    if (key == 'name') return name;
    if (key == 'code') return code;
    return null;
  }
}
