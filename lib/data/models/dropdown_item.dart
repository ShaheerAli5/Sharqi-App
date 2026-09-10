class DropdownItem {
  final dynamic id;
  final String name;

  DropdownItem({
    required this.id,
    required this.name,
  });

  factory DropdownItem.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      dynamic idVal = json['id'] ?? json['code'] ?? json['key'] ?? json['category_id'] ?? json['type_id'];
      String nameVal = (json['name'] ?? json['title'] ?? json['label'] ?? json['category'] ?? json['type'] ?? json['display_name'] ?? idVal ?? '').toString();
      idVal ??= nameVal;
      return DropdownItem(id: idVal, name: nameVal);
    } else if (json is String) {
      return DropdownItem(id: json, name: json);
    } else {
      final str = json?.toString() ?? '';
      return DropdownItem(id: str, name: str);
    }
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropdownItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => name;
}
