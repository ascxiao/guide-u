import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/saved_article.dart';

class SavedArticlesViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<SavedArticle> _savedArticles = [];
  bool _loading = false;
  String? _error;

  List<SavedArticle> get savedArticles => _savedArticles;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchSavedArticles(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _supabase
          .from('saved_articles')
          .select()
          .eq('user_id', userId);
      final List<dynamic> data = response as List<dynamic>;
      _savedArticles = data.map((item) => SavedArticle.fromJson(item)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addSavedArticle(String userId, String articleId) async {
    try {
      await _supabase.from('saved_articles').insert({
        'user_id': userId,
        'article_id': articleId,
      });
      // Optionally refresh the list
      await fetchSavedArticles(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeSavedArticle(String userId, String articleId) async {
    try {
      await _supabase.from('saved_articles')
          .delete()
          .eq('user_id', userId)
          .eq('article_id', articleId);
      await fetchSavedArticles(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool isArticleSaved(String articleId) {
    return _savedArticles.any((a) => a.articleId == articleId);
  }
}
