class CompanyItem {
  final int id;
  final String name;

  CompanyItem({
    required this.id,
    required this.name,
  });

  factory CompanyItem.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return CompanyItem(
      id: parseId(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  dynamic operator [](String key) {
    if (key == 'id') return id;
    if (key == 'name') return name;
    return null;
  }
}

class CompanyListResponse {
  final List<CompanyItem> companies;

  CompanyListResponse({required this.companies});

  factory CompanyListResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is List) {
      return CompanyListResponse(
        companies: result
            .map((e) => CompanyItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    return CompanyListResponse(companies: []);
  }

  dynamic operator [](String key) {
    if (key == 'result' || key == 'companies') return companies;
    return null;
  }
}
