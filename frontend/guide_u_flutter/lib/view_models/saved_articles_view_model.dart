import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/saved_article.dart';
import '../services/local_cache_service.dart';

class SavedArticlesViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final LocalCacheService _cacheService = LocalCacheService();
  final Connectivity _connectivity = Connectivity();

  List<SavedArticle> _savedArticles = [];
  bool _loading = false;
  bool _isOnline = true;
  bool _syncInProgress = false;
  String? _error;
  StreamSubscription<dynamic>? _connectivitySubscription;

  List<SavedArticle> get savedArticles => _savedArticles;
  bool get loading => _loading;
  bool get isOnline => _isOnline;
  String? get error => _error;

  SavedArticlesViewModel() {
    _initConnectivity();
  }

  void _initConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) async {
      final online = _isOnlineFromConnectivityResult(result);
      if (online == _isOnline) return;

      _isOnline = online;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (_isOnline && userId != null) {
        await _syncPendingSavedArticles(userId);
        await fetchSavedArticles(userId);
      } else {
        notifyListeners();
      }
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

  Future<void> _refreshOnlineStatus() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline = _isOnlineFromConnectivityResult(connectivityResult);
  }

  Future<void> _loadSavedArticlesFromLocal(String userId) async {
    final articleIds = await _cacheService.getSavedArticlesForUser(userId);
    _savedArticles = articleIds
        .map(
          (articleId) =>
              SavedArticle(id: articleId, userId: userId, articleId: articleId),
        )
        .toList();
  }

  Future<void> _cacheCurrentSavedArticles(String userId) async {
    final ids = _savedArticles
        .map((item) => item.articleId)
        .whereType<String>()
        .toList();
    await _cacheService.cacheSavedArticlesForUser(userId, ids);
  }

  Future<void> _syncPendingSavedArticles(String userId) async {
    if (_syncInProgress || !_isOnline) return;

    _syncInProgress = true;
    try {
      final pending = await _cacheService.getQueuedSavedArticleOperations(
        userId,
      );

      if (pending.isEmpty) return;

      final remaining = <Map<String, dynamic>>[];
      for (final operation in pending) {
        final op = operation['operation']?.toString();
        final articleId = operation['articleId']?.toString();
        if (op == null || articleId == null || articleId.isEmpty) {
          continue;
        }

        try {
          if (op == 'add') {
            await _supabase.from('saved_articles').upsert({
              'user_id': userId,
              'article_id': articleId,
            }, onConflict: 'user_id,article_id');
          } else if (op == 'remove') {
            await _supabase
                .from('saved_articles')
                .delete()
                .eq('user_id', userId)
                .eq('article_id', articleId);
          }
        } catch (_) {
          remaining.add(operation);
        }
      }

      await _cacheService.setQueuedSavedArticleOperations(userId, remaining);
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> fetchSavedArticles(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Always load local cache first so offline users get immediate results.
      await _loadSavedArticlesFromLocal(userId);
      notifyListeners();

      await _refreshOnlineStatus();

      if (!_isOnline) {
        await _loadSavedArticlesFromLocal(userId);
        return;
      }

      await _syncPendingSavedArticles(userId);

      final response = await _supabase
          .from('saved_articles')
          .select()
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 8));
      final List<dynamic> data = response as List<dynamic>;
      _savedArticles = data.map((item) => SavedArticle.fromJson(item)).toList();
      await _cacheCurrentSavedArticles(userId);
    } catch (e) {
      await _loadSavedArticlesFromLocal(userId);
      _error = _savedArticles.isEmpty ? e.toString() : null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addSavedArticle(String userId, String articleId) async {
    await _refreshOnlineStatus();

    if (!isArticleSaved(articleId)) {
      _savedArticles = [
        ..._savedArticles,
        SavedArticle(id: articleId, userId: userId, articleId: articleId),
      ];
      notifyListeners();
    }

    await _cacheCurrentSavedArticles(userId);

    if (!_isOnline) {
      await _cacheService.queueSavedArticleOperation(userId, 'add', articleId);
      return;
    }

    try {
      await _supabase.from('saved_articles').upsert({
        'user_id': userId,
        'article_id': articleId,
      }, onConflict: 'user_id,article_id');
      // Optionally refresh the list
      await fetchSavedArticles(userId);
    } catch (e) {
      await _cacheService.queueSavedArticleOperation(userId, 'add', articleId);
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeSavedArticle(String userId, String articleId) async {
    await _refreshOnlineStatus();

    _savedArticles = _savedArticles
        .where((a) => a.articleId != articleId)
        .toList();
    notifyListeners();

    await _cacheCurrentSavedArticles(userId);

    if (!_isOnline) {
      await _cacheService.queueSavedArticleOperation(
        userId,
        'remove',
        articleId,
      );
      return;
    }

    try {
      await _supabase
          .from('saved_articles')
          .delete()
          .eq('user_id', userId)
          .eq('article_id', articleId);
      await fetchSavedArticles(userId);
    } catch (e) {
      await _cacheService.queueSavedArticleOperation(
        userId,
        'remove',
        articleId,
      );
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> fetchArticlesForSavedDetails(
    List<SavedArticle> savedArticles,
  ) async {
    final articleIds = savedArticles
        .map((s) => s.articleId)
        .whereType<String>()
        .toList();

    if (articleIds.isEmpty) return [];

    final cachedArticles = await _cacheService.getCachedArticles();
    final cachedById = {
      for (final article in cachedArticles) article.id: article.toJson(),
    };

    final connectivityResult = await _connectivity.checkConnectivity();
    final online = _isOnlineFromConnectivityResult(connectivityResult);

    if (online) {
      try {
        final response = await _supabase
            .from('articles')
            .select()
            .filter('id', 'in', articleIds)
            .timeout(const Duration(seconds: 8));

        final serverArticles = List<Map<String, dynamic>>.from(
          response as List,
        );

        final serverById = {
          for (final article in serverArticles)
            article['id']?.toString(): article,
        };

        return articleIds
            .map(
              (id) =>
                  serverById[id] ??
                  cachedById[id] ??
                  {'id': id, 'title': 'Article', 'body_text': ''},
            )
            .toList();
      } catch (_) {
        // Fall back to local cache below.
      }
    }

    return articleIds
        .map(
          (id) =>
              cachedById[id] ?? {'id': id, 'title': 'Article', 'body_text': ''},
        )
        .toList();
  }

  bool isArticleSaved(String articleId) {
    return _savedArticles.any((a) => a.articleId == articleId);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
