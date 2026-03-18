import 'package:flutter/material.dart';
import '../models/handbook_article.dart';
import '../services/local_cache_service.dart';

class ArticleCacheViewModel extends ChangeNotifier {
  final LocalCacheService _cacheService = LocalCacheService();
  List<HandbookArticle> _cachedArticles = [];
  bool _loading = false;
  String? _error;

  List<HandbookArticle> get cachedArticles => _cachedArticles;
  bool get loading => _loading;
  String? get error => _error;

  ArticleCacheViewModel() {
    loadCachedArticles();
  }

  Future<void> loadCachedArticles() async {
    _loading = true;
    notifyListeners();
    try {
      final cached = await _cacheService.getCachedArticles();
      _cachedArticles = cached;
      _error = null;
    } catch (e) {
      _cachedArticles = [];
      _error = 'Failed to load cached articles: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cacheArticles(List<HandbookArticle> articles) async {
    await _cacheService.cacheArticles(articles);
    _cachedArticles = articles;
    notifyListeners();
  }

  Future<void> clearCachedArticles() async {
    await _cacheService.clearCachedArticles();
    _cachedArticles = [];
    notifyListeners();
  }
}
