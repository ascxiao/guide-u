class SavedArticle {
  final String id;
  final String? userId;
  final String? articleId;
  final DateTime? createdAt;

  SavedArticle({
    required this.id,
    this.userId,
    this.articleId,
    this.createdAt,
  });

  factory SavedArticle.fromJson(Map<String, dynamic> json) {
    return SavedArticle(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      articleId: json['article_id']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
