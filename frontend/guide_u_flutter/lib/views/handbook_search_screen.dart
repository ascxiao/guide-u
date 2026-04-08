import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/handbook_article.dart';
import '../routes/app_routes.dart';
import '../view_models/handbook_search_view_model.dart';
import '../widgets/handbook_chatbot_fab.dart';
import 'handbook_bottom_nav_bar.dart';

class HandbookSearchScreen extends StatelessWidget {
  const HandbookSearchScreen({Key? key}) : super(key: key);

  static const Color _brandMain = Color(0xFF1F7A5A);
  static const Color _brandAccent = Color(0xFF4FBF8F);
  static const Color _brandSoft = Color(0xFFE6F4EF);
  static const Color _pageBg = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HandbookSearchViewModel(),
      child: Consumer<HandbookSearchViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: _pageBg,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(68),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4BB285), _brandMain],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Row(
                    children: [
                      Icon(Icons.search_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Search Handbook',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  children: [
                    _SearchHeroCard(isOnline: viewModel.isOnline),
                    const SizedBox(height: 12),
                    _SearchInputCard(viewModel: viewModel),
                    if (viewModel.query.trim().isNotEmpty ||
                        viewModel.hasSearched) ...[
                      const SizedBox(height: 10),
                      _ResultMetaBar(viewModel: viewModel),
                    ],
                    const SizedBox(height: 12),
                    Expanded(child: _SearchResults(viewModel: viewModel)),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 4),
            floatingActionButton: const HandbookChatbotFAB(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }
}

class _SearchHeroCard extends StatelessWidget {
  final bool isOnline;

  const _SearchHeroCard({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            HandbookSearchScreen._brandSoft,
            HandbookSearchScreen._brandAccent.withValues(alpha: 0.20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: HandbookSearchScreen._brandAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: HandbookSearchScreen._brandMain,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find Articles Faster',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Try keywords like enrollment, attendance, scholarship, or grading.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? HandbookSearchScreen._brandMain.withValues(alpha: 0.9)
                        : Colors.orange.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOnline ? 'Online Search' : 'Offline Search (Cached)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchInputCard extends StatelessWidget {
  final HandbookSearchViewModel viewModel;

  const _SearchInputCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD8E5DE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: HandbookSearchScreen._brandMain,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: viewModel.controller,
                onChanged: viewModel.updateQuery,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search handbook articles...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.black45),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (viewModel.query.isNotEmpty)
              IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  viewModel.clearSearch();
                },
                icon: const Icon(Icons.close_rounded, color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultMetaBar extends StatelessWidget {
  final HandbookSearchViewModel viewModel;

  const _ResultMetaBar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final count = viewModel.results.length;
    final isQuerying = viewModel.query.trim().isNotEmpty;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCE8E2)),
          ),
          child: Text(
            isQuerying ? '$count result${count == 1 ? '' : 's'}' : 'No query',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: HandbookSearchScreen._brandMain,
            ),
          ),
        ),
        const Spacer(),
        Text(
          viewModel.isOnline ? 'Live data' : 'Cached data',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  final HandbookSearchViewModel viewModel;

  const _SearchResults({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.query.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (viewModel.loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: HandbookSearchScreen._brandMain),
            SizedBox(height: 12),
            Text(
              'Searching articles...',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    if (viewModel.error != null) {
      return const SizedBox.shrink();
    }

    if (viewModel.hasSearched && viewModel.results.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: viewModel.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _SearchResultCard(article: viewModel.results[index]);
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final HandbookArticle article;

  const _SearchResultCard({required this.article});

  String _displayTitle() {
    if (article.title != null && article.title!.trim().isNotEmpty) {
      return article.title!.trim();
    }
    if (article.subSectionTitle != null &&
        article.subSectionTitle!.trim().isNotEmpty &&
        article.subSectionTitle != 'N/A') {
      return article.subSectionTitle!.trim();
    }
    if (article.sectionTitle != null &&
        article.sectionTitle!.trim().isNotEmpty) {
      return article.sectionTitle!.trim();
    }
    return 'Article';
  }

  String _previewText() {
    final raw = article.bodyText ?? '';
    final normalized = raw
        .replaceAll('\\n', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) {
      return 'Open to read the full article.';
    }

    return normalized;
  }

  String? _chapterLabel() {
    if (article.chapterId != null && article.chapterId!.trim().isNotEmpty) {
      return 'Chapter ${article.chapterId!.trim()}';
    }
    if (article.chapterTitle != null &&
        article.chapterTitle!.trim().isNotEmpty) {
      return article.chapterTitle!.trim();
    }
    return null;
  }

  String? _sectionLabel() {
    if (article.sectionId != null && article.sectionId!.trim().isNotEmpty) {
      return 'Section ${article.sectionId!.trim()}';
    }
    if (article.sectionTitle != null &&
        article.sectionTitle!.trim().isNotEmpty) {
      return article.sectionTitle!.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final chapter = _chapterLabel();
    final section = _sectionLabel();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.article,
            arguments: {
              'id': article.id,
              'title': _displayTitle(),
              'content': article.bodyText ?? '',
              'chapter':
                  (article.chapterId != null && article.chapterId!.isNotEmpty)
                  ? article.chapterId
                  : article.chapterTitle,
              'section':
                  (article.sectionId != null && article.sectionId!.isNotEmpty)
                  ? article.sectionId
                  : article.sectionTitle,
            },
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDEBE3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: HandbookSearchScreen._brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: HandbookSearchScreen._brandMain,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayTitle(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF141414),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (chapter != null) _MetaChip(text: chapter),
                        if (section != null) _MetaChip(text: section),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _previewText(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black45,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;

  const _MetaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: HandbookSearchScreen._brandSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: HandbookSearchScreen._brandMain,
        ),
      ),
    );
  }
}
