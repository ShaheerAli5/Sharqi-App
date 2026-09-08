class AttendanceItem {
  final int id;
  final String name;
  final String empNo;
  final String date;
  final String sTime;
  final String eTime;
  final double workHours;
  final double overtimeHours;

  AttendanceItem({
    required this.id,
    required this.name,
    required this.empNo,
    required this.date,
    required this.sTime,
    required this.eTime,
    required this.workHours,
    required this.overtimeHours,
  });

  factory AttendanceItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseId(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return AttendanceItem(
      id: parseId(json['id']),
      name: json['name']?.toString() ?? '',
      empNo: json['emp_no']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      sTime: json['s_time']?.toString() ?? '',
      eTime: json['e_time']?.toString() ?? '',
      workHours: parseDouble(json['work_hours']),
      overtimeHours: parseDouble(json['overtime_hours']),
    );
  }

  bool get isApproved => overtimeHours > 0;

  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'emp_no':
        return empNo;
      case 'date':
        return date;
      case 's_time':
        return sTime;
      case 'e_time':
        return eTime;
      case 'work_hours':
        return workHours;
      case 'overtime_hours':
        return overtimeHours;
      case 'is_approved':
        return isApproved;
      default:
        return null;
    }
  }
}
