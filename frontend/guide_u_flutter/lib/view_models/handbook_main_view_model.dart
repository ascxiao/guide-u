import 'package:flutter/material.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/handbook_article.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_cache_service.dart';

class HandbookMainViewModel extends ChangeNotifier {
  final LocalCacheService _cacheService = LocalCacheService();
  final Connectivity _connectivity = Connectivity();

  bool _loading = false;
  String? _error;
  bool _isOnline = true;
  StreamSubscription<dynamic>? _connectivitySubscription;
  Map<String, Map<String, List<HandbookArticle>>> _groupedArticles = {};

  bool get loading => _loading;
  String? get error => _error;
  bool get isOnline => _isOnline;
  Map<String, Map<String, List<HandbookArticle>>> get groupedArticles =>
      _groupedArticles;

  HandbookMainViewModel() {
    _initConnectivity();
    fetchGroupedHandbookArticles();
  }

  void _initConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) async {
      final online = _isOnlineFromConnectivityResult(result);
      if (online == _isOnline) return;

      _isOnline = online;
      await fetchGroupedHandbookArticles();
    });

    _connectivity.checkConnectivity().then((result) {
      _isOnline = _isOnlineFromConnectivityResult(result);
      notifyListeners();
    });
  }

  bool _isOnlineFromConnectivityResult(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }

    if (result is List<ConnectivityResult>) {
      return result.any((entry) => entry != ConnectivityResult.none);
    }

    return true;
  }

  Map<String, Map<String, List<HandbookArticle>>> _groupArticles(
    List<HandbookArticle> articles,
  ) {
    final Map<String, Map<String, List<HandbookArticle>>> grouped = {};

    for (final article in articles) {
      final chapter =
          (article.chapterTitle != null && article.chapterTitle!.isNotEmpty)
          ? article.chapterTitle!
          : 'Unknown Chapter';
      final section =
          (article.sectionTitle != null && article.sectionTitle!.isNotEmpty)
          ? article.sectionTitle!
          : (article.sectionId != null && article.sectionId!.isNotEmpty)
          ? article.sectionId!
          : 'Unknown Section';

      grouped.putIfAbsent(chapter, () => {});
      grouped[chapter]!.putIfAbsent(section, () => []);
      grouped[chapter]![section]!.add(article);
    }

    return grouped;
  }

  Future<void> fetchGroupedHandbookArticles() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (!_isOnline) {
        final cached = await _cacheService.getCachedArticles();
        _groupedArticles = _groupArticles(cached);
        _error = null;
        return;
      }

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('articles')
          .select()
          .order('chapter_id', ascending: true)
          .order('section_id', ascending: true)
          .order('sub_section_id', ascending: true);

      if (response is! List) {
        _groupedArticles = {};
        _error = 'Unexpected response from server.';
        return;
      }

      final List<dynamic> data = response;
      final articles = data
          .map((item) => HandbookArticle.fromJson(item as Map<String, dynamic>))
          .toList();

      _groupedArticles = _groupArticles(articles);
      await _cacheService.cacheArticles(articles);
    } catch (e) {
      final cached = await _cacheService.getCachedArticles();
      _groupedArticles = _groupArticles(cached);
      _error = cached.isEmpty ? e.toString() : null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
