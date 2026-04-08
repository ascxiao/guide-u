import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/article_events_service.dart';
import '../services/session_service.dart';
import '../view_models/saved_articles_view_model.dart';
import '../widgets/handbook_chatbot_fab.dart';

class HandbookArticlePage extends StatefulWidget {
  final String articleTitle;
  final String articleContent;
  final String? articleId;
  final String? chapter;
  final String? section;

  const HandbookArticlePage({
    Key? key,
    required this.articleTitle,
    required this.articleContent,
    this.articleId,
    this.chapter,
    this.section,
  }) : super(key: key);

  @override
  State<HandbookArticlePage> createState() => _HandbookArticlePageState();
}

class _HandbookArticlePageState extends State<HandbookArticlePage> {
  static const Color _brandMain = Color(0xFF1F7A5A);
  static const Color _brandAccent = Color(0xFF4FBF8F);
  static const Color _brandSoft = Color(0xFFE6F4EF);

  bool _isSaved = false;
  bool _loading = false;
  bool _hasTrackedOpen = false;
  bool _showJumpToTop = false;
  double _readingProgress = 0;

  final ScrollController _scrollController = ScrollController();
  final SessionService _sessionService = SessionService();
  final ArticleEventsService _articleEventsService = ArticleEventsService();

  @override
  void initState() {
    super.initState();
    Future.microtask(_trackArticleOpen);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final savedArticlesVM = Provider.of<SavedArticlesViewModel>(
      context,
      listen: false,
    );

    if (widget.articleId != null) {
      _isSaved = savedArticlesVM.isArticleSaved(widget.articleId!);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark() async {
    if (widget.articleId == null) return;

    setState(() => _loading = true);

    final savedArticlesVM = Provider.of<SavedArticlesViewModel>(
      context,
      listen: false,
    );

    final userId = _sessionService.currentUserIdOrDemo;

    if (_isSaved) {
      await savedArticlesVM.removeSavedArticle(userId, widget.articleId!);
    } else {
      await savedArticlesVM.addSavedArticle(userId, widget.articleId!);
    }

    if (!mounted) return;

    setState(() {
      _isSaved = !_isSaved;
      _loading = false;
    });
  }

  Future<void> _trackArticleOpen() async {
    if (_hasTrackedOpen || widget.articleId == null) return;

    _hasTrackedOpen = true;

    await _articleEventsService.trackArticleOpen(articleId: widget.articleId!);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final bool shouldShow = _scrollController.offset > 260;
    if (shouldShow != _showJumpToTop) {
      setState(() {
        _showJumpToTop = shouldShow;
      });
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final nextProgress = maxScroll <= 0
        ? 0.0
        : (_scrollController.offset / maxScroll).clamp(0.0, 1.0);

    if ((nextProgress - _readingProgress).abs() > 0.01) {
      setState(() {
        _readingProgress = nextProgress;
      });
    }
  }

  Future<void> _copyArticle() async {
    await Clipboard.setData(
      ClipboardData(text: '${widget.articleTitle}\n\n${widget.articleContent}'),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1200),
        content: Text('Article copied'),
      ),
    );
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  bool _isHeadingLine(String line) {
    final normalized = line.trim();
    if (normalized.isEmpty) return false;

    final looksLikeSection = RegExp(
      r'^(section|chapter|article)\b',
      caseSensitive: false,
    ).hasMatch(normalized);
    final endsWithColon = normalized.endsWith(':');
    final isCapsHeading =
        normalized.length <= 70 &&
        normalized == normalized.toUpperCase() &&
        RegExp(r'[A-Z]').hasMatch(normalized);

    return looksLikeSection || endsWithColon || isCapsHeading;
  }

  String _estimateReadTime(String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .length;
    final minutes = (words / 210).ceil();
    return '${minutes <= 1 ? 1 : minutes} min read';
  }

  String _chapterSectionLabel() {
    final chapterArg = widget.chapter?.trim();
    final sectionArg = widget.section?.trim();

    final hasChapterArg = chapterArg != null && chapterArg.isNotEmpty;
    final hasSectionArg = sectionArg != null && sectionArg.isNotEmpty;

    String formatChapter(String value) {
      return value.toLowerCase().startsWith('chapter')
          ? value
          : 'Chapter $value';
    }

    String formatSection(String value) {
      return value.toLowerCase().startsWith('section')
          ? value
          : 'Section $value';
    }

    if (hasChapterArg && hasSectionArg) {
      return '${formatChapter(chapterArg)} • ${formatSection(sectionArg)}';
    }
    if (hasChapterArg) {
      return formatChapter(chapterArg);
    }
    if (hasSectionArg) {
      return formatSection(sectionArg);
    }

    final source = '${widget.articleTitle}\n${widget.articleContent}';

    final chapterMatch = RegExp(
      r'chapter\s*([A-Za-z0-9.-]+)',
      caseSensitive: false,
    ).firstMatch(source);

    final sectionMatch = RegExp(
      r'section\s*([A-Za-z0-9.-]+)',
      caseSensitive: false,
    ).firstMatch(source);

    final chapter = chapterMatch?.group(1);
    final section = sectionMatch?.group(1);

    if (chapter != null && section != null) {
      return 'Chapter $chapter • Section $section';
    }
    if (chapter != null) {
      return 'Chapter $chapter';
    }
    if (section != null) {
      return 'Section $section';
    }
    return 'Chapter and Section';
  }

  Widget _buildFormattedContent(String content) {
    content = content.replaceAll(r'\n', '\n').replaceAll('\r\n', '\n');

    final lines = content.split('\n');

    List<Widget> widgets = [];
    List<Widget> currentBullets = [];
    List<Widget> currentNumbers = [];

    int numberIndex = 1;

    void flushLists() {
      if (currentBullets.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: currentBullets,
            ),
          ),
        );
        currentBullets = [];
      }

      if (currentNumbers.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: currentNumbers,
            ),
          ),
        );
        currentNumbers = [];
      }
    }

    for (var line in lines) {
      line = line.trim();

      if (line.isEmpty) {
        flushLists();
        numberIndex = 1;
        continue;
      }

      if (_isHeadingLine(line)) {
        flushLists();
        numberIndex = 1;

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 17,
                height: 1.4,
                color: _brandMain,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        continue;
      }

      if (RegExp(r'^[-•*]\s+').hasMatch(line)) {
        final text = line.replaceFirst(RegExp(r'^[-•*]\s+'), '');

        currentBullets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _brandMain,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15.5,
                      height: 1.65,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
        final text = line.replaceFirst(RegExp(r'^\d+\.\s+'), '');

        currentNumbers.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _brandSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '$numberIndex',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _brandMain,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15.5,
                      height: 1.65,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        numberIndex++;
      } else {
        flushLists();
        numberIndex = 1;

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SelectableText(
              line,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 15.5,
                height: 1.72,
                color: Colors.black87,
              ),
            ),
          ),
        );
      }
    }

    flushLists();

    if (widgets.isEmpty) {
      return const Text(
        'No content available.',
        style: TextStyle(color: Colors.black54),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canBookmark = widget.articleId != null;
    final readTime = _estimateReadTime(widget.articleContent);
    final chapterSectionLabel = _chapterSectionLabel();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _brandMain,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Handbook Article',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              readTime,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: 'Copy Article',
            color: _brandMain,
            onPressed: _copyArticle,
          ),
          IconButton(
            icon: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isSaved
                        ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)
                        : PhosphorIcons.bookmarkSimple(),
                  ),
            tooltip: _isSaved ? 'Remove Bookmark' : 'Save Article',
            color: _brandMain,
            onPressed: _loading || !canBookmark ? null : _toggleBookmark,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(
            minHeight: 2,
            value: _readingProgress,
            backgroundColor: const Color(0xFFE7EFEB),
            valueColor: const AlwaysStoppedAnimation<Color>(_brandMain),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brandMain, _brandAccent.withValues(alpha: 0.94)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          chapterSectionLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (canBookmark && _isSaved)
                        const Text(
                          'Saved',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.articleTitle,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2ECE6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: _brandMain,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Article Content',
                        style: TextStyle(
                          color: _brandMain,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _brandSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          readTime,
                          style: const TextStyle(
                            color: _brandMain,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SelectionArea(
                    child: _buildFormattedContent(widget.articleContent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_showJumpToTop)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.small(
                heroTag: 'articleTopButton',
                backgroundColor: _brandMain,
                onPressed: _scrollToTop,
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          const HandbookChatbotFAB(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
