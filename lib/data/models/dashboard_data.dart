class DashboardData {
  final bool success;
  final String company;
  final String joinDate;
  final String qidNumber;
  final String qidExpiry;
  final String passportNumber;
  final String passportExpiry;
  final String gender;
  final String nationality;
  final String workLocation;
  final String location;
  final String manager;
  final String? error;

  DashboardData({
    required this.success,
    required this.company,
    required this.joinDate,
    required this.qidNumber,
    required this.qidExpiry,
    required this.passportNumber,
    required this.passportExpiry,
    required this.gender,
    required this.nationality,
    required this.workLocation,
    required this.location,
    required this.manager,
    this.error,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final result = json['result'] is Map<String, dynamic> ? json['result'] : json;

    String parseSafe(dynamic val) => (val == null || val is bool) ? '' : val.toString();

    return DashboardData(
      success: result['success'] == true ||
          (result['success'] != null && result['success'].toString().isNotEmpty),
      company: parseSafe(result['company']),
      joinDate: parseSafe(result['join_date']),
      qidNumber: parseSafe(result['qid_number']),
      qidExpiry: parseSafe(result['qid_expiry']),
      passportNumber: parseSafe(result['passport_number']),
      passportExpiry: parseSafe(result['passport_expiry']),
      gender: parseSafe(result['gender']),
      nationality: parseSafe(result['nationality']),
      workLocation: parseSafe(result['work_location']),
      location: parseSafe(result['location']),
      manager: parseSafe(result['manager']),
      error: result['error']?.toString(),
    );
  }

  List<MapEntry<String, String>> toGridList() {
    final list = <MapEntry<String, String>>[];
    if (company.isNotEmpty) list.add(MapEntry('Company', company));
    if (joinDate.isNotEmpty) list.add(MapEntry('Join Date', joinDate));
    if (qidNumber.isNotEmpty) list.add(MapEntry('QID', qidNumber));
    if (qidExpiry.isNotEmpty) list.add(MapEntry('QID Expiry', qidExpiry));
    if (passportNumber.isNotEmpty) list.add(MapEntry('Passport No.', passportNumber));
    if (passportExpiry.isNotEmpty) list.add(MapEntry('Passport Exp.', passportExpiry));
    if (gender.isNotEmpty) list.add(MapEntry('Gender', gender));
    if (nationality.isNotEmpty) list.add(MapEntry('Nationality', nationality));
    if (workLocation.isNotEmpty) list.add(MapEntry('WorkLocation', workLocation));
    if (location.isNotEmpty) list.add(MapEntry('Location', location));
    if (manager.isNotEmpty) list.add(MapEntry('Manager', manager));
    return list;
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'success':
        return success;
      case 'company':
        return company;
      case 'join_date':
        return joinDate;
      case 'qid_number':
        return qidNumber;
      case 'qid_expiry':
        return qidExpiry;
      case 'passport_number':
        return passportNumber;
      case 'passport_expiry':
        return passportExpiry;
      case 'gender':
        return gender;
      case 'nationality':
        return nationality;
      case 'work_location':
        return workLocation;
      case 'location':
        return location;
      case 'manager':
        return manager;
      case 'error':
        return error;
      case 'result':
        return this;
      default:
        return null;
    }
  }
}
