import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/handbook_article.dart';

class HandbookSearchViewModel extends ChangeNotifier {
  static const Duration _debounceDuration = Duration(milliseconds: 350);

  final SupabaseClient _supabase = Supabase.instance.client;

  Timer? _debounce;
  int _requestId = 0;

  String _query = '';
  bool _loading = false;
  bool _hasSearched = false;
  String? _error;
  List<HandbookArticle> _results = [];

  String get query => _query;
  bool get loading => _loading;
  bool get hasSearched => _hasSearched;
  String? get error => _error;
  List<HandbookArticle> get results => _results;

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

  Future<void> searchArticles(String rawQuery) async {
    final trimmedQuery = rawQuery.trim();
    if (trimmedQuery.isEmpty) {
      _loading = false;
      _hasSearched = false;
      _error = null;
      _results = [];
      notifyListeners();
      return;
    }

    final currentRequestId = ++_requestId;

    try {
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
    } catch (e) {
      if (currentRequestId != _requestId) return;
      _results = [];
      _error = e.toString();
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
    super.dispose();
  }
}
