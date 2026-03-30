import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/handbook_article.dart';

class LocalCacheService {
  static const String userBox = 'userBox';
  static const String articlesBox = 'articlesBox';
  static const String savedArticlesKey = 'savedArticles';
  static const String _savedArticlesKeyPrefix = 'savedArticles_';
  static const String _savedArticleOpsKeyPrefix = 'savedArticleOps_';

  String _savedArticlesKeyForUser(String userId) =>
      '$_savedArticlesKeyPrefix$userId';

  String _savedArticleOpsKeyForUser(String userId) =>
      '$_savedArticleOpsKeyPrefix$userId';

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
    await saveArticleForUser('default', articleId);
  }

  Future<void> removeSavedArticle(String articleId) async {
    await removeSavedArticleForUser('default', articleId);
  }

  Future<List<String>> getSavedArticles() async {
    return getSavedArticlesForUser('default');
  }

  Future<void> cacheSavedArticlesForUser(
    String userId,
    List<String> articleIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedArticlesKeyForUser(userId), articleIds);

    // Keep backwards compatibility with existing single-user key.
    if (userId == 'default') {
      await prefs.setStringList(savedArticlesKey, articleIds);
    }
  }

  Future<void> saveArticleForUser(String userId, String articleId) async {
    final saved = await getSavedArticlesForUser(userId);
    if (!saved.contains(articleId)) {
      saved.add(articleId);
      await cacheSavedArticlesForUser(userId, saved);
    }
  }

  Future<void> removeSavedArticleForUser(String userId, String articleId) async {
    final saved = await getSavedArticlesForUser(userId);
    saved.remove(articleId);
    await cacheSavedArticlesForUser(userId, saved);
  }

  Future<List<String>> getSavedArticlesForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final perUser = prefs.getStringList(_savedArticlesKeyForUser(userId));
    if (perUser != null) return perUser;

    if (userId == 'default') {
      return prefs.getStringList(savedArticlesKey) ?? [];
    }

    return [];
  }

  Future<void> queueSavedArticleOperation(
    String userId,
    String operation,
    String articleId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _savedArticleOpsKeyForUser(userId);
    final raw = prefs.getStringList(key) ?? [];

    final pending = raw
        .map((item) => Map<String, dynamic>.from(jsonDecode(item)))
        .where((item) => item['articleId']?.toString() != articleId)
        .toList();

    pending.add({
      'operation': operation,
      'articleId': articleId,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await prefs.setStringList(
      key,
      pending.map((item) => jsonEncode(item)).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> getQueuedSavedArticleOperations(
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_savedArticleOpsKeyForUser(userId)) ?? [];
    return raw
        .map((item) => Map<String, dynamic>.from(jsonDecode(item)))
        .toList();
  }

  Future<void> setQueuedSavedArticleOperations(
    String userId,
    List<Map<String, dynamic>> operations,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _savedArticleOpsKeyForUser(userId),
      operations.map((item) => jsonEncode(item)).toList(),
    );
  }

  Future<void> clearQueuedSavedArticleOperations(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedArticleOpsKeyForUser(userId));
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
