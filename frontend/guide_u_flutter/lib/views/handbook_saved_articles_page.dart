import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../view_models/saved_articles_view_model.dart';
import '../services/local_cache_service.dart';
import '../widgets/handbook_chatbot_fab.dart';

/// Title case with abbreviation support (copied from main page)
String titleCaseWithAbbr(String text) {
  if (text.isEmpty) return text;

  final regex = RegExp(r'\([^)]+\)');
  final matches = regex.allMatches(text).toList();

  // Replace abbreviations with placeholders
  var modified = text;
  for (int i = 0; i < matches.length; i++) {
    modified = modified.replaceFirst(matches[i].group(0)!, '<<$i>>');
  }

  // Title-case the rest
  modified = modified.split(' ').map((word) {
    if (word.isEmpty) return word;
    if (word.startsWith('<<') && word.endsWith('>>')) return word; // skip placeholders
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');

  // Restore abbreviations
  for (int i = 0; i < matches.length; i++) {
    modified = modified.replaceFirst('<<$i>>', matches[i].group(0)!);
  }

  return modified;
}

class HandbookSavedArticlesPage extends StatefulWidget {
  const HandbookSavedArticlesPage({Key? key}) : super(key: key);

  @override
  State<HandbookSavedArticlesPage> createState() =>
      _HandbookSavedArticlesPageState();
}

class _HandbookSavedArticlesPageState
    extends State<HandbookSavedArticlesPage> {
  final LocalCacheService _cacheService = LocalCacheService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final savedVM =
          Provider.of<SavedArticlesViewModel>(context, listen: false);

      final userId =
          Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';

      if (userId.isNotEmpty &&
          savedVM.savedArticles.isEmpty &&
          !savedVM.loading) {
        savedVM.fetchSavedArticles(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedArticlesViewModel>(
      builder: (context, savedVM, _) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(75),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F7A5A), Color(0xFF4FBF8F)],
                  stops: [0.2, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: AppBar(
                automaticallyImplyLeading: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'Saved Articles',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          body: Container(
            color: const Color(0xFFF5F4F4),
            child: savedVM.loading
                ? const Center(child: CircularProgressIndicator())
                : savedVM.savedArticles.isEmpty
                    ? const Center(child: Text('No saved articles.'))
                    : FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchArticlesForSaved(savedVM.savedArticles),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No articles found.'));
                          }
                          final articles = snapshot.data!;
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: articles.length,
                            itemBuilder: (context, index) {
                              final article = articles[index];
                              String displayTitle = (article['sub_section_title'] != null && article['sub_section_title'] != 'N/A')
                                  ? article['sub_section_title']
                                  : (article['title'] ?? article['section_title'] ?? 'Article');
                              return GestureDetector(
                                onTap: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    '/article',
                                    arguments: {
                                      'id': article['id'],
                                      'title': titleCaseWithAbbr(displayTitle),
                                      'content': article['body_text'] ?? '',
                                    },
                                  );
                                  if (!mounted) return;
                                  final userId = Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';
                                  await savedVM.fetchSavedArticles(userId);
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  color: Colors.white,
                                  margin: const EdgeInsets.only(bottom: 14),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF006633).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.article_outlined,
                                            color: Color(0xFF006633),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                titleCaseWithAbbr(displayTitle),
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if ((article['body_text'] ?? '').isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 6),
                                                  child: Text(
                                                    article['body_text'],
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
          floatingActionButton: const HandbookChatbotFAB(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  /// 🔹 FIXED: moved OUTSIDE build()
  Future<List<Map<String, dynamic>>> _fetchArticlesForSaved(
      List savedArticles) async {
    final articleIds = savedArticles
        .map((s) => s.articleId)
        .whereType<String>()
        .toList();

    if (articleIds.isEmpty) return [];

    final cachedArticles = await _cacheService.getCachedArticles();
    final cachedById = {
      for (final article in cachedArticles) article.id: article.toJson(),
    };

    bool online = true;
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult is ConnectivityResult) {
      online = connectivityResult != ConnectivityResult.none;
    } else if (connectivityResult is List<ConnectivityResult>) {
      online = connectivityResult.any((entry) => entry != ConnectivityResult.none);
    }

    if (online) {
      try {
        final response = await Supabase.instance.client
            .from('articles')
            .select()
            .filter('id', 'in', articleIds)
            .timeout(const Duration(seconds: 8));

        final serverArticles = List<Map<String, dynamic>>.from(response as List);

        // Keep card rendering stable by preserving saved order.
        final serverById = {
          for (final article in serverArticles) article['id']?.toString(): article,
        };

        return articleIds
            .map((id) => serverById[id] ?? cachedById[id] ?? {'id': id, 'title': 'Article', 'body_text': ''})
            .toList();
      } catch (_) {
        // Fall back to local cache below.
      }
    }

    return articleIds
        .map((id) => cachedById[id] ?? {'id': id, 'title': 'Article', 'body_text': ''})
        .toList();
  }
}