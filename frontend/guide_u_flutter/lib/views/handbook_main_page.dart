import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'handbook_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../view_models/handbook_main_view_model.dart';
import '../widgets/handbook_chatbot_fab.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HandbookMainPage extends StatefulWidget {
  const HandbookMainPage({Key? key}) : super(key: key);

  @override
  State<HandbookMainPage> createState() => _HandbookMainPageState();
}

class _HandbookMainPageState extends State<HandbookMainPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🔹 Helper: Title case but retain abbreviations in parentheses
  String titleCaseWithAbbr(String text) {
    if (text.isEmpty) return text;

    final regex = RegExp(r'\([^\)]+\)');
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HandbookMainViewModel(),
      child: Consumer<HandbookMainViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 245, 244, 244),
            extendBody: true,

            /// 🔹 APP BAR
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
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: SizedBox(
                    height: 25,
                    child: Image.asset(
                      'assets/images/TypoguideU.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  actions: [
                    const SizedBox(width: 6),

                    /// PROFILE
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.profile);
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF006633),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            body: _buildBody(context, viewModel),
            bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 0),
            floatingActionButton: const HandbookChatbotFAB(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, HandbookMainViewModel viewModel) {
    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
        child: Text(
          'Error: ${viewModel.error}',
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    final grouped = viewModel.groupedArticles;

    if (grouped.isEmpty) {
      return const Center(child: Text('No articles found.'));
    }

    // Ensure chapters are in order by sorting keys (numeric-aware)
    final sortedChapterEntries = grouped.entries.toList()
      ..sort((a, b) {
        String aIdStr =
            (a.value.values.first.isNotEmpty &&
                a.value.values.first.first.chapterId != null)
            ? a.value.values.first.first.chapterId.toString()
            : a.key.toString();
        String bIdStr =
            (b.value.values.first.isNotEmpty &&
                b.value.values.first.first.chapterId != null)
            ? b.value.values.first.first.chapterId.toString()
            : b.key.toString();
        int? aId = int.tryParse(aIdStr);
        int? bId = int.tryParse(bIdStr);
        if (aId != null && bId != null) {
          return aId.compareTo(bId);
        } else {
          return aIdStr.compareTo(bIdStr);
        }
      });

    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            /// HEADER
            FadeTransition(
              opacity: _controller,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.1),
                  end: Offset.zero,
                ).animate(_controller),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/usls_header.jpg'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.black.withOpacity(0.2),
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Welcome to GuideU",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "University of St. La Salle Handbook",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Card Buttons (Saved Articles | Directories)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Saved Articles Card
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                    color: Colors.transparent, // IMPORTANT
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.saved);
                      },
                      child: Container(
                        height: 70,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFF4FBF8F).withOpacity(0.15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.bookmarkSimple(
                                PhosphorIconsStyle.fill,
                              ),
                              color: const Color(0xFF1F7A5A), // dark green icon
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Saved Articles',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF1F7A5A), // match icon
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),

                // Directories Card
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.directories);
                      },
                      child: Container(
                        height: 70,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFF4FBF8F).withOpacity(0.15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.folderSimple(
                                PhosphorIconsStyle.fill,
                              ),
                              color: const Color(0xFF1F7A5A),
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Directories',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF1F7A5A),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            /// CONTENT
            for (var i = 0; i < sortedChapterEntries.length; i++)
              (() {
                final chapterEntry = sortedChapterEntries[i];
                final chapterTitle = chapterEntry.key;
                final sections = chapterEntry.value;
                final chapterId =
                    (sections.values.first.isNotEmpty &&
                        sections.values.first.first.chapterId != null)
                    ? sections.values.first.first.chapterId
                    : '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Chapter ${(chapterId != null && chapterId.toString().isNotEmpty) ? chapterId.toString() + ' - ' : ''}${titleCaseWithAbbr(chapterTitle)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sections
                    ...sections.entries.map((sectionEntry) {
                      final articles = sectionEntry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 6, bottom: 6),
                            child: Text(
                              'Section ${(articles.isNotEmpty && articles.first.sectionId != null && articles.first.sectionId.toString().isNotEmpty) ? articles.first.sectionId : sectionEntry.key}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          // Articles
                          ...articles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final article = entry.value;
                            final animation = Tween<double>(begin: 0, end: 1)
                                .animate(
                                  CurvedAnimation(
                                    parent: _controller,
                                    curve: Interval(
                                      (index * 0.05).clamp(0.0, 1.0),
                                      1.0,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                );
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: animation.value,
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      20 * (1 - animation.value),
                                    ),
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildAnimatedCard(context, article),
                            );
                          }),
                          const SizedBox(height: 10),
                        ],
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                );
              })(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(BuildContext context, dynamic article) {
  String displayTitle =
      (article.subSectionTitle != null && article.subSectionTitle != 'N/A')
      ? article.subSectionTitle
      : (article.title ?? article.sectionTitle ?? 'Article');

  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(
        context,
        AppRoutes.article,
        arguments: {
          'id': article.id,
          'title': titleCaseWithAbbr(displayTitle),
          'content': article.bodyText ?? '',
        },
      );
    },
    child: AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 150),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7), // ✨ glass effect
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            /// ICON CONTAINER
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4FBF8F).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PhosphorIcon(
                PhosphorIcons.fileText(PhosphorIconsStyle.fill),
                color: const Color(0xFF1F7A5A),
                size: 20,
              ),
            ),

            const SizedBox(width: 14),

            /// TEXT
            Expanded(
              child: Text(
                titleCaseWithAbbr(displayTitle),
                maxLines: 2, // ✅ prevents overflow
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F7A5A),
                ),
              ),
            ),

            /// CHEVRON (adds polish)
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}
}