import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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

  // ✅ NEW SMART FORMATTER
  Widget _buildFormattedContent(String content) {
    // Preserve line breaks properly
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
        continue;
      }

      // 🔹 BULLET POINTS
      if (RegExp(r'^[-•*]\s+').hasMatch(line)) {
        final text = line.replaceFirst(RegExp(r'^[-•*]\s+'), '');

        currentBullets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ",
                    style: TextStyle(fontSize: 16, height: 1.6)),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // 🔹 NUMBERED LIST
      else if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
        final text = line.replaceFirst(RegExp(r'^\d+\.\s+'), '');

        currentNumbers.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$numberIndex. ",
                    style: const TextStyle(fontSize: 16, height: 1.6)),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        numberIndex++;
      }

      // 🔹 PARAGRAPH
      else {
        flushLists();
        numberIndex = 1;

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              line,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 16,
                height: 1.8,
                color: Colors.black87,
              ),
            ),
          ),
        );
      }
    }

    flushLists();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainGreen = Color(0xFF1F7A5A);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: mainGreen,
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
                        ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)
                        : PhosphorIcons.bookmarkSimple(),
                  ),
            tooltip: _isSaved ? 'Remove Bookmark' : 'Save Article',
            color: mainGreen,
            onPressed: _loading ? null : _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.articleTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: mainGreen,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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