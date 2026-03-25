import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../view_models/saved_articles_view_model.dart';
import '../widgets/handbook_chatbot_fab.dart';

class HandbookArticlePage extends StatefulWidget {
  final String articleTitle;
  final String articleContent;
  final String? articleId;

  const HandbookArticlePage({
    Key? key,
    required this.articleTitle,
    required this.articleContent,
    this.articleId,
  }) : super(key: key);

  @override
  State<HandbookArticlePage> createState() => _HandbookArticlePageState();
}

class _HandbookArticlePageState extends State<HandbookArticlePage> {
  bool _isSaved = false;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final savedArticlesVM =
        Provider.of<SavedArticlesViewModel>(context, listen: false);

    if (widget.articleId != null) {
      _isSaved = savedArticlesVM.isArticleSaved(widget.articleId!);
    }
  }

  Future<void> _toggleBookmark() async {
    if (widget.articleId == null) return;

    setState(() => _loading = true);

    final savedArticlesVM =
        Provider.of<SavedArticlesViewModel>(context, listen: false);

    final userId =
        Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';

    if (_isSaved) {
      await savedArticlesVM.removeSavedArticle(userId, widget.articleId!);
    } else {
      await savedArticlesVM.addSavedArticle(userId, widget.articleId!);
    }

    setState(() {
      _isSaved = !_isSaved;
      _loading = false;
    });
  }

  Widget _buildFormattedContent(String content) {
    // Normalize line breaks just in case
    content = content
        .replaceAll(r'\n', ' ')
        .replaceAll('\r\n', ' ')
        .trim();

    final sentences = content.split(RegExp(r'(?<=[.?!])\s+'));

    List<String> paragraphs = [];
    String buffer = '';

    for (int i = 0; i < sentences.length; i++) {
      buffer += sentences[i] + ' ';
      if ((i + 1) % 3 == 0 || i == sentences.length - 1) {
        paragraphs.add(buffer.trim());
        buffer = '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final para in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                children: [
                  const WidgetSpan(
                    child: SizedBox(width: 24),
                  ),
                  TextSpan(
                    text: para,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 251, 245),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF006633),
        centerTitle: false,
        actions: [
          IconButton(
            icon: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                  ),
            tooltip:
                _isSaved ? 'Remove Bookmark' : 'Save Article',
            color: const Color(0xFF006633),
            onPressed: _loading ? null : _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👑 Article Heading
            Text(
              widget.articleTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006633),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            // 📝 Content Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildFormattedContent(widget.articleContent),
            ),
          ],
        ),
      ),
      floatingActionButton: const HandbookChatbotFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}