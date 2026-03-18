import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../view_models/saved_articles_view_model.dart';
// Removed unused import
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

  @override
  void initState() {
    super.initState();

    final savedVM =
        Provider.of<SavedArticlesViewModel>(context, listen: false);

    final userId =
        Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';

    if (userId.isNotEmpty &&
        savedVM.savedArticles.isEmpty &&
        !savedVM.loading) {
      savedVM.fetchSavedArticles(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedArticlesViewModel>(
      builder: (context, savedVM, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Saved Articles',                 
            style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF006633),
          ),
          body: savedVM.loading
              ? const Center(child: CircularProgressIndicator())
              : savedVM.savedArticles.isEmpty
                  ? const Center(child: Text('No saved articles.'))
                  : FutureBuilder<List<Map<String, dynamic>>>(
                      future:
                          _fetchArticlesForSaved(savedVM.savedArticles),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          final savedIds = savedVM.savedArticles.map((s) => s.articleId).toList();
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('No articles found.'),
                                const SizedBox(height: 12),
                                Text('Saved IDs: $savedIds'),
                                const SizedBox(height: 12),
                                Text('Fetched articles: ${snapshot.data}'),
                              ],
                            ),
                          );
                        }

                        final articles = snapshot.data!;

                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
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
                                final savedVM = Provider.of<SavedArticlesViewModel>(context, listen: false);
                                final userId = Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';
                                await savedVM.fetchSavedArticles(userId);
                                setState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
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
                                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
        );
      },
    );
  }

  /// 🔹 FIXED: moved OUTSIDE build()
  Future<List<Map<String, dynamic>>> _fetchArticlesForSaved(
      List savedArticles) async {
    final supabase = Supabase.instance.client;

    final articleIds = savedArticles
        .map((s) => s.articleId)
        .whereType<String>()
        .toList();

    if (articleIds.isEmpty) return [];

    final response = await supabase
      .from('articles')
      .select()
      .filter('id', 'in', articleIds);

    return List<Map<String, dynamic>>.from(response as List);
  }
}