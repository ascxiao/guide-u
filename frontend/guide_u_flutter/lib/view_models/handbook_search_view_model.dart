import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/handbook_article.dart';
import '../services/local_cache_service.dart';

class HandbookSearchViewModel extends ChangeNotifier {
  final LocalCacheService _cacheService = LocalCacheService();
  final Connectivity _connectivity = Connectivity();

  HandbookSearchViewModel() {
    _initConnectivity();
    loadCachedArticles();
  }
  // Add TextEditingController for search bar
  final TextEditingController controller = TextEditingController();

  // Add clearSearch method
  void clearSearch() {
    controller.clear();
    updateQuery('');
  }

  static const Duration _debounceDuration = Duration(milliseconds: 350);

  final SupabaseClient _supabase = Supabase.instance.client;

  Timer? _debounce;
  StreamSubscription<dynamic>? _connectivitySubscription;
  int _requestId = 0;

  String _query = '';
  bool _loading = false;
  bool _hasSearched = false;
  bool _isOnline = true;
  String? _error;
  List<HandbookArticle> _results = [];
  List<HandbookArticle> _cachedArticles = [];

  String get query => _query;
  bool get loading => _loading;
  bool get hasSearched => _hasSearched;
  bool get isOnline => _isOnline;
  String? get error => _error;
  List<HandbookArticle> get results => _results;

  void _initConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) async {
      final online = _isOnlineFromConnectivityResult(result);
      if (online == _isOnline) return;

      _isOnline = online;

      if (_isOnline) {
        await _primeCacheFromServer(force: true);
      }

      // Re-run current query when status changes so results switch data source.
      final activeQuery = _query.trim();
      if (activeQuery.isNotEmpty) {
        searchArticles(activeQuery);
      } else {
        notifyListeners();
      }
    });

    _connectivity.checkConnectivity().then((result) async {
      _isOnline = _isOnlineFromConnectivityResult(result);
      if (_isOnline) {
        await _primeCacheFromServer();
      }
      notifyListeners();
    });
  }

  Future<void> _primeCacheFromServer({bool force = false}) async {
    if (!_isOnline) return;
    if (!force && _cachedArticles.isNotEmpty) return;

    try {
      final response = await _supabase
          .from('articles')
          .select()
          .order('chapter_id', ascending: true)
          .order('section_id', ascending: true)
          .order('sub_section_id', ascending: true);

      if (response is! List) return;

      final articles =
          response
              .map(
                (item) =>
                    HandbookArticle.fromJson(item as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) {
              return _compareHierarchicalIds(a.chapterId, b.chapterId) != 0
                  ? _compareHierarchicalIds(a.chapterId, b.chapterId)
                  : _compareHierarchicalIds(a.sectionId, b.sectionId) != 0
                  ? _compareHierarchicalIds(a.sectionId, b.sectionId)
                  : _compareHierarchicalIds(a.subSectionId, b.subSectionId);
            });

      _cachedArticles = articles;
      await _cacheService.cacheArticles(articles);
      debugPrint(
        '[HandbookSearchViewModel] Primed cache with ${articles.length} articles.',
      );
    } catch (e) {
      debugPrint('[HandbookSearchViewModel] Failed to prime cache: $e');
    }
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

  List<HandbookArticle> _filterCachedArticles(String query) {
    final loweredQuery = query.toLowerCase();

    final filtered =
        _cachedArticles.where((article) {
          final haystack = [
            article.title,
            article.chapterTitle,
            article.sectionTitle,
            article.subSectionTitle,
            article.bodyText,
          ].whereType<String>().map((text) => text.toLowerCase()).join(' ');

          return haystack.contains(loweredQuery);
        }).toList()..sort((a, b) {
          return _compareHierarchicalIds(a.chapterId, b.chapterId) != 0
              ? _compareHierarchicalIds(a.chapterId, b.chapterId)
              : _compareHierarchicalIds(a.sectionId, b.sectionId) != 0
              ? _compareHierarchicalIds(a.sectionId, b.sectionId)
              : _compareHierarchicalIds(a.subSectionId, b.subSectionId);
        });

    return filtered;
  }

  Future<void> loadCachedArticles() async {
    _loading = true;
    debugPrint('[HandbookSearchViewModel] Loading cached articles...');
    notifyListeners();
    try {
      final cached = await _cacheService.getCachedArticles();
      _cachedArticles = cached;
      if (cached.isNotEmpty) {
        debugPrint(
          '[HandbookSearchViewModel] Loaded ${cached.length} articles from cache.',
        );
      } else {
        debugPrint('[HandbookSearchViewModel] No cached articles found.');
      }
      if (_query.trim().isNotEmpty) {
        _results = _filterCachedArticles(_query.trim());
      }
      _error = null;
      _hasSearched = true;
    } catch (e) {
      debugPrint('[HandbookSearchViewModel] Error loading cached articles: $e');
      _cachedArticles = [];
      _results = [];
      _error = 'Failed to load cached articles: $e';
      _hasSearched = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cacheAllArticles(List<HandbookArticle> articles) async {
    await _cacheService.cacheArticles(articles);
    _cachedArticles = articles;
  }

  void updateQuery(String value) {
    _query = value;
    _debounce?.cancel();

    final trimmedQuery = value.trim();
    if (trimmedQuery.isEmpty) {
      _loading = false;
      _hasSearched = false;
      _error = null;
      _results = [];
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    _debounce = Timer(_debounceDuration, () {
      searchArticles(trimmedQuery);
    });
  }

  Future<void> searchArticles(
    String rawQuery, {
    bool cacheResults = false,
  }) async {
    final trimmedQuery = rawQuery.trim();
    if (trimmedQuery.isEmpty) {
      _loading = false;
      _hasSearched = false;
      _error = null;
      _results = [];
      debugPrint('[HandbookSearchViewModel] Search query is empty.');
      notifyListeners();
      return;
    }

    final currentRequestId = ++_requestId;

    if (!_isOnline) {
      debugPrint(
        '[HandbookSearchViewModel] Offline detected. Using cached articles only.',
      );
      _results = _filterCachedArticles(trimmedQuery);
      _error = null;
      _hasSearched = true;
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      debugPrint(
        '[HandbookSearchViewModel] Searching articles for "$trimmedQuery"...',
      );
      final response = await _supabase
          .from('articles')
          .select()
          .or(
            [
              'title.ilike.%$trimmedQuery%',
              'chapter_title.ilike.%$trimmedQuery%',
              'section_title.ilike.%$trimmedQuery%',
              'sub_section_title.ilike.%$trimmedQuery%',
              'body_text.ilike.%$trimmedQuery%',
            ].join(','),
          )
          .order('chapter_id', ascending: true)
          .order('section_id', ascending: true)
          .order('sub_section_id', ascending: true);

      if (currentRequestId != _requestId) return;

      if (response is! List) {
        debugPrint(
          '[HandbookSearchViewModel] Supabase response is not a List: $response',
        );
        _results = [];
        _error = 'Unexpected response from server.';
        _hasSearched = true;
        notifyListeners();
        return;
      }

      final data = response as List<dynamic>;
      final articles =
          data
              .map(
                (item) =>
                    HandbookArticle.fromJson(item as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) {
              return _compareHierarchicalIds(a.chapterId, b.chapterId) != 0
                  ? _compareHierarchicalIds(a.chapterId, b.chapterId)
                  : _compareHierarchicalIds(a.sectionId, b.sectionId) != 0
                  ? _compareHierarchicalIds(a.sectionId, b.sectionId)
                  : _compareHierarchicalIds(a.subSectionId, b.subSectionId);
            });

      _results = articles;
      _error = null;
      _hasSearched = true;
      debugPrint(
        '[HandbookSearchViewModel] Found ${articles.length} articles.',
      );
      if (cacheResults) {
        await _cacheService.cacheArticles(articles);
        debugPrint(
          '[HandbookSearchViewModel] Cached ${articles.length} articles.',
        );
      }
    } catch (e, stack) {
      if (currentRequestId != _requestId) return;
      debugPrint('[HandbookSearchViewModel] Error during search: $e\n$stack');
      _results = _filterCachedArticles(trimmedQuery);
      _error = _results.isEmpty ? e.toString() : null;
      _hasSearched = true;
    } finally {
      if (currentRequestId != _requestId) return;
      _loading = false;
      notifyListeners();
    }
  }

  int _compareHierarchicalIds(String? a, String? b) {
    final aParts = (a ?? '')
        .split('.')
        .map((part) => int.tryParse(part) ?? -1)
        .toList();
    final bParts = (b ?? '')
        .split('.')
        .map((part) => int.tryParse(part) ?? -1)
        .toList();

    final maxLength = aParts.length > bParts.length
        ? aParts.length
        : bParts.length;
    for (var i = 0; i < maxLength; i++) {
      final aPart = i < aParts.length ? aParts[i] : -1;
      final bPart = i < bParts.length ? bParts[i] : -1;
      if (aPart != bPart) return aPart.compareTo(bPart);
    }

    return (a ?? '').compareTo(b ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
