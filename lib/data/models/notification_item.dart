class NotificationItem {
  final int notificationId;
  final String subject;
  final String message;
  final String notificationTag;
  final String state;
  final String timestamp;
  final String attachmentUrl;
  final String attachmentName;

  NotificationItem({
    required this.notificationId,
    required this.subject,
    required this.message,
    required this.notificationTag,
    required this.state,
    required this.timestamp,
    required this.attachmentUrl,
    this.attachmentName = '',
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    String parseAttachmentUrl(Map<String, dynamic> json) {
      final url = json['attachment_url'] ??
          json['attachment'] ??
          json['file_url'] ??
          json['attachment_path'] ??
          json['file'] ??
          '';
      return url == null || url is bool ? '' : url.toString();
    }

    String parseAttachmentName(Map<String, dynamic> json, String url) {
      if (json['attachment_name'] != null &&
          json['attachment_name'] is! bool &&
          json['attachment_name'].toString().isNotEmpty) {
        return json['attachment_name'].toString();
      }
      if (json['file_name'] != null &&
          json['file_name'] is! bool &&
          json['file_name'].toString().isNotEmpty) {
        return json['file_name'].toString();
      }
      if (url.isNotEmpty) {
        final uri = Uri.tryParse(url);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          return uri.pathSegments.last;
        }
      }
      return url.isNotEmpty ? 'Attachment File' : '';
    }

    final url = parseAttachmentUrl(json);
    final name = parseAttachmentName(json, url);

    return NotificationItem(
      notificationId: parseInt(json['notification_id'] ?? json['id']),
      subject: json['subject']?.toString() ?? json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? json['description']?.toString() ?? '',
      notificationTag: json['notification_tag']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? json['date']?.toString() ?? '',
      attachmentUrl: url,
      attachmentName: name,
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
      case 'attachment':
        return attachmentUrl;
      case 'attachment_name':
      case 'file_name':
        return attachmentName;
      default:
        return null;
    }
  }
}
