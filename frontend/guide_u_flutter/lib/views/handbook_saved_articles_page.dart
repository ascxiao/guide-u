import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/saved_articles_view_model.dart';
import '../services/session_service.dart';
import '../widgets/handbook_chatbot_fab.dart';
import '../routes/app_routes.dart';

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
  modified = modified
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        if (word.startsWith('<<') && word.endsWith('>>'))
          return word; // skip placeholders
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');

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

class _HandbookSavedArticlesPageState extends State<HandbookSavedArticlesPage> {
  static const Color _brandMain = Color(0xFF1F7A5A);
  static const Color _brandAccent = Color(0xFF4FBF8F);
  static const Color _brandSoft = Color(0xFFE6F4EF);

  final SessionService _sessionService = SessionService();

  String _userId() {
    return _sessionService.currentUserIdOrDemo;
  }

  Future<void> _refreshSaved(SavedArticlesViewModel savedVM) async {
    await savedVM.fetchSavedArticles(_userId());
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final savedVM = Provider.of<SavedArticlesViewModel>(
        context,
        listen: false,
      );

      final userId = _userId();

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
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(68),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brandMain, _brandAccent],
                  stops: [0.2, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: AppBar(
                automaticallyImplyLeading: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: 68,
                title: const Text(
                  'Saved Articles',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
                foregroundColor: Colors.white,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      width: 34,
                      height: 34,
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      child: IconButton(
                        tooltip: 'Refresh saved articles',
                        padding: EdgeInsets.zero,
                        onPressed: () => _refreshSaved(savedVM),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: RefreshIndicator(
            color: _brandMain,
            onRefresh: () => _refreshSaved(savedVM),
            child: savedVM.loading && savedVM.savedArticles.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 220),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
                : savedVM.savedArticles.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 110),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2ECE6)),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.bookmark_border_rounded,
                              color: _brandMain,
                              size: 40,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No saved articles yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Bookmark an article from the handbook and it will appear here for quick access.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: savedVM.fetchArticlesForSavedDetails(
                      savedVM.savedArticles,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 220),
                            Center(child: CircularProgressIndicator()),
                          ],
                        );
                      }

                      final articles =
                          snapshot.data ?? <Map<String, dynamic>>[];
                      if (articles.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 80, 24, 110),
                          children: const [
                            Center(
                              child: Text(
                                'No articles found.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                        itemCount: articles.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_brandSoft, Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFDDEBE3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _brandMain.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.bookmark_added_rounded,
                                      color: _brandMain,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${savedVM.savedArticles.length} saved articles${savedVM.isOnline ? '' : ' (offline mode)'}',
                                      style: const TextStyle(
                                        color: _brandMain,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final article = articles[index - 1];
                          String displayTitle =
                              (article['sub_section_title'] != null &&
                                  article['sub_section_title'] != 'N/A')
                              ? article['sub_section_title']
                              : (article['title'] ??
                                    article['section_title'] ??
                                    'Article');

                          final String chapterLabel =
                              ((article['chapter_id']?.toString() ?? '')
                                  .isNotEmpty)
                              ? 'Chapter ${article['chapter_id']}'
                              : (article['chapter_title']?.toString() ?? '');

                          final String sectionLabel =
                              ((article['section_id']?.toString() ?? '')
                                  .isNotEmpty)
                              ? 'Section ${article['section_id']}'
                              : (article['section_title']?.toString() ?? '');

                          final String preview = (article['body_text'] ?? '')
                              .toString()
                              .replaceAll(r'\n', ' ')
                              .replaceAll('\n', ' ')
                              .replaceAll('\r', ' ')
                              .replaceAll(RegExp(r'\s+'), ' ')
                              .trim();

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.article,
                                  arguments: {
                                    'id': article['id'],
                                    'title': titleCaseWithAbbr(displayTitle),
                                    'content': article['body_text'] ?? '',
                                    'chapter':
                                        (article['chapter_id']?.toString() ??
                                                '')
                                            .isNotEmpty
                                        ? article['chapter_id']?.toString()
                                        : article['chapter_title']?.toString(),
                                    'section':
                                        (article['section_id']?.toString() ??
                                                '')
                                            .isNotEmpty
                                        ? article['section_id']?.toString()
                                        : article['section_title']?.toString(),
                                  },
                                );
                                if (!mounted) return;
                                await _refreshSaved(savedVM);
                              },
                              child: Ink(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2ECE6),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _brandSoft,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.article_outlined,
                                        color: _brandMain,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            titleCaseWithAbbr(displayTitle),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14.5,
                                              color: Color(0xFF1B1B1B),
                                              height: 1.25,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (chapterLabel.isNotEmpty ||
                                              sectionLabel.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 7,
                                              ),
                                              child: Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: [
                                                  if (chapterLabel.isNotEmpty)
                                                    _MetaChip(
                                                      label: chapterLabel,
                                                    ),
                                                  if (sectionLabel.isNotEmpty)
                                                    _MetaChip(
                                                      label: sectionLabel,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          if (preview.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Text(
                                                preview,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 12.5,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFE0E9E3),
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: Colors.black45,
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
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1F7A5A),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
