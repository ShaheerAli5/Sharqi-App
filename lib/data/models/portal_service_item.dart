class PortalServiceItem {
  final String id;
  final String title;
  final String description;
  final String? iconName;
  final String? imageUrl;
  final bool hasSeeManual;
  final String? manualUrl;
  final String primaryButtonLabel;
  final String? secondaryButtonLabel;
  final String actionType;

  PortalServiceItem({
    required this.id,
    required this.title,
    required this.description,
    this.iconName,
    this.imageUrl,
    this.hasSeeManual = false,
    this.manualUrl,
    required this.primaryButtonLabel,
    this.secondaryButtonLabel,
    required this.actionType,
  });

  factory PortalServiceItem.fromJson(Map<String, dynamic> json) {
    return PortalServiceItem(
      id: json['id']?.toString() ?? json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      description:
          json['description']?.toString() ?? json['subtitle']?.toString() ?? '',
      iconName: json['icon']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['icon_url']?.toString(),
      hasSeeManual:
          json['has_see_manual'] == true || json['see_manual'] == true,
      manualUrl: json['manual_url']?.toString(),
      primaryButtonLabel: json['primary_button_label']?.toString() ??
          json['button_text']?.toString() ??
          'Create Request',
      secondaryButtonLabel: json['secondary_button_label']?.toString() ??
          json['secondary_button_text']?.toString(),
      actionType:
          json['action_type']?.toString() ?? json['type']?.toString() ?? '',
    );
  }
}
