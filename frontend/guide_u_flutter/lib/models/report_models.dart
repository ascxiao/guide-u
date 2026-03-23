class IncidentReportItem {
  IncidentReportItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.createdAt,
    required this.imageUrls,
    this.adminNote,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final String status;
  final DateTime? createdAt;
  final List<String> imageUrls;
  final String? adminNote;

  factory IncidentReportItem.fromJson(Map<String, dynamic> json) {
    return IncidentReportItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: _parseDate(json['created_at']),
      imageUrls: _stringList(json['image_urls']),
      adminNote: _extractAdminNote(json),
    );
  }
}

class LostFoundReportItem {
  LostFoundReportItem({
    required this.id,
    required this.itemName,
    required this.description,
    required this.location,
    required this.reportType,
    required this.status,
    required this.createdAt,
    required this.imageUrls,
    this.adminNote,
  });

  final String id;
  final String itemName;
  final String description;
  final String location;
  final String reportType;
  final String status;
  final DateTime? createdAt;
  final List<String> imageUrls;
  final String? adminNote;

  factory LostFoundReportItem.fromJson(Map<String, dynamic> json) {
    return LostFoundReportItem(
      id: (json['id'] ?? '').toString(),
      itemName: (json['item_name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      reportType: (json['report_type'] ?? '').toString(),
      status: (json['status'] ?? 'open').toString(),
      createdAt: _parseDate(json['created_at']),
      imageUrls: _stringList(json['image_urls']),
      adminNote: _extractAdminNote(json),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value.toString()).toLocal();
  } catch (_) {
    return null;
  }
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
}

String? _extractAdminNote(Map<String, dynamic> json) {
  final candidates = [
    json['admin_note'],
    json['admin_notes'],
    json['status_note'],
    json['notes'],
  ];

  for (final candidate in candidates) {
    final text = (candidate ?? '').toString().trim();
    if (text.isNotEmpty) return text;
  }

  return null;
}
