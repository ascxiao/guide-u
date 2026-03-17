import 'package:flutter/material.dart';
import '../models/handbook_article.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HandbookMainViewModel extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  Map<String, Map<String, List<HandbookArticle>>> _groupedArticles = {};

  bool get loading => _loading;
  String? get error => _error;
  Map<String, Map<String, List<HandbookArticle>>> get groupedArticles => _groupedArticles;

  HandbookMainViewModel() {
    fetchGroupedHandbookArticles();
  }

  Future<void> fetchGroupedHandbookArticles() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('articles').select();
      final List<dynamic> data = response as List<dynamic>;
      final articles = data.map((item) => HandbookArticle.fromJson(item)).toList();
      final Map<String, Map<String, List<HandbookArticle>>> grouped = {};
      for (final article in articles) {
        final chapter = (article.chapterTitle != null && article.chapterTitle!.isNotEmpty)
            ? article.chapterTitle!
            : 'Unknown Chapter';
        final section = (article.sectionTitle != null && article.sectionTitle!.isNotEmpty)
            ? article.sectionTitle!
            : (article.sectionId != null && article.sectionId!.isNotEmpty)
                ? article.sectionId!
                : 'Unknown Section';
        grouped.putIfAbsent(chapter, () => {});
        grouped[chapter]!.putIfAbsent(section, () => []);
        grouped[chapter]![section]!.add(article);
      }
      _groupedArticles = grouped;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
