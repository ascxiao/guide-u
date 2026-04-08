import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_service.dart';

class ArticleEventsService {
  ArticleEventsService({SupabaseClient? client, SessionService? sessionService})
    : _client = client ?? Supabase.instance.client,
      _sessionService = sessionService ?? SessionService(client: client);

  final SupabaseClient _client;
  final SessionService _sessionService;

  Future<void> trackArticleOpen({
    required String articleId,
    String source = 'mobile_app',
  }) async {
    final user = _sessionService.currentUser;
    if (user == null) return;

    try {
      await _client.from('article_view_events').insert({
        'article_id': articleId,
        'user_id': user.id,
        'source': source,
      });
    } catch (_) {
      // Keep reading flow uninterrupted if tracking fails.
    }
  }
}
