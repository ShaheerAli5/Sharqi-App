class WorkPlanItem {
  final String employee;
  final String area;
  final int areaId;
  final String location;
  final int locationId;
  final String date;
  final String dayOfWeek;
  final String dayPeriod;
  final String workType;
  final double workFrom;
  final double workTo;
  final double totalHours;
  final double overtimeHours;

  WorkPlanItem({
    required this.employee,
    required this.area,
    required this.areaId,
    required this.location,
    required this.locationId,
    required this.date,
    required this.dayOfWeek,
    required this.dayPeriod,
    required this.workType,
    required this.workFrom,
    required this.workTo,
    required this.totalHours,
    required this.overtimeHours,
  });

  factory WorkPlanItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return WorkPlanItem(
      employee: json['employee']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      areaId: parseInt(json['area_id']),
      location: json['location']?.toString() ?? '',
      locationId: parseInt(json['location_id']),
      date: json['date']?.toString() ?? '',
      dayOfWeek: json['dayofweek']?.toString() ?? '',
      dayPeriod: json['day_period']?.toString() ?? '',
      workType: json['work_type']?.toString() ?? '',
      workFrom: parseDouble(json['work_from']),
      workTo: parseDouble(json['work_to']),
      totalHours: parseDouble(json['total_hours']),
      overtimeHours: parseDouble(json['overtime_hours']),
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'employee':
        return employee;
      case 'area':
        return area;
      case 'area_id':
        return areaId;
      case 'location':
        return location;
      case 'location_id':
        return locationId;
      case 'date':
        return date;
      case 'dayofweek':
        return dayOfWeek;
      case 'day_period':
        return dayPeriod;
      case 'work_type':
        return workType;
      case 'work_from':
        return workFrom;
      case 'work_to':
        return workTo;
      case 'total_hours':
      case 'work_hours':
        return totalHours;
      case 'overtime_hours':
        return overtimeHours;
      default:
        return null;
    }
  }
}
