class HandbookArticle {
  final String id;
  final String? chapterId;
  final String? chapterTitle;
  final String? sectionId;
  final String? sectionTitle;
  final String? subSectionId;
  final String? subSectionTitle;
  final String? title;
  final String? bodyText;
  final String? contentType;
  final int? pageApprox;
  final String? institution;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HandbookArticle({
    required this.id,
    this.chapterId,
    this.chapterTitle,
    this.sectionId,
    this.sectionTitle,
    this.subSectionId,
    this.subSectionTitle,
    this.title,
    this.bodyText,
    this.contentType,
    this.pageApprox,
    this.institution,
    this.createdAt,
    this.updatedAt,
  });

  factory HandbookArticle.fromJson(Map<String, dynamic> json) {
    return HandbookArticle(
      id: json['id']?.toString() ?? '',
      chapterId: json['chapter_id']?.toString(),
      chapterTitle: json['chapter_title']?.toString(),
      sectionId: json['section_id']?.toString(),
      sectionTitle: json['section_title']?.toString(),
      subSectionId: json['sub_section_id']?.toString(),
      subSectionTitle: json['sub_section_title']?.toString(),
      title: json['title']?.toString(),
      bodyText: json['body_text']?.toString(),
      contentType: json['content_type']?.toString(),
      pageApprox: json['page_approx'] is int ? json['page_approx'] : int.tryParse(json['page_approx']?.toString() ?? ''),
      institution: json['institution']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }
}
