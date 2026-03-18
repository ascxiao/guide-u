import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/handbook_article.dart';

class LocalCacheService {
  static const String userBox = 'userBox';
  static const String articlesBox = 'articlesBox';
  static const String savedArticlesKey = 'savedArticles';

  // User info
  Future<void> saveUser(Map<String, dynamic> user) async {
    final box = await Hive.openBox(userBox);
    await box.put('user', user);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final box = await Hive.openBox(userBox);
    return box.get('user');
  }

  Future<void> clearUser() async {
    final box = await Hive.openBox(userBox);
    await box.delete('user');
  }

  // Saved articles (IDs)
  Future<void> saveArticle(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(savedArticlesKey) ?? [];
    if (!saved.contains(articleId)) {
      saved.add(articleId);
      await prefs.setStringList(savedArticlesKey, saved);
    }
  }

  Future<void> removeSavedArticle(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(savedArticlesKey) ?? [];
    saved.remove(articleId);
    await prefs.setStringList(savedArticlesKey, saved);
  }

  Future<List<String>> getSavedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(savedArticlesKey) ?? [];
  }

  // Cache all articles
  Future<void> cacheArticles(List<HandbookArticle> articles) async {
    final box = await Hive.openBox(articlesBox);
    await box.put('all', articles.map((a) => a.toJson()).toList());
  }

  Future<List<HandbookArticle>> getCachedArticles() async {
    final box = await Hive.openBox(articlesBox);
    final data = box.get('all') as List<dynamic>?;
    if (data == null) return [];
    return data
        .map(
          (item) => HandbookArticle.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> clearCachedArticles() async {
    final box = await Hive.openBox(articlesBox);
    await box.delete('all');
  }
}
