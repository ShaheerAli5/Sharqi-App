class NotificationItem {
  final int notificationId;
  final String subject;
  final String message;
  final String notificationTag;
  final String state;
  final String timestamp;
  final String attachmentUrl;

  NotificationItem({
    required this.notificationId,
    required this.subject,
    required this.message,
    required this.notificationTag,
    required this.state,
    required this.timestamp,
    required this.attachmentUrl,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return NotificationItem(
      notificationId: parseInt(json['notification_id'] ?? json['id']),
      subject: json['subject']?.toString() ?? json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? json['description']?.toString() ?? '',
      notificationTag: json['notification_tag']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? json['date']?.toString() ?? '',
      attachmentUrl: json['attachment_url']?.toString() ?? '',
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'notification_id':
      case 'id':
        return notificationId;
      case 'subject':
      case 'title':
        return subject;
      case 'message':
      case 'description':
        return message;
      case 'notification_tag':
        return notificationTag;
      case 'state':
        return state;
      case 'timestamp':
      case 'date':
        return timestamp;
      case 'attachment_url':
        return attachmentUrl;
      default:
        return null;
    }
  }
}
