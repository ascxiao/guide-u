import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'handbook_bottom_nav_bar.dart';
// ...existing code...
import 'package:provider/provider.dart';
import '../view_models/handbook_main_view_model.dart';

class HandbookMainPage extends StatelessWidget {
  const HandbookMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HandbookMainViewModel(),
      child: Consumer<HandbookMainViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'GuideU',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  tooltip: 'Saved',
                  color: const Color(0xFF006633),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.saved);
                  },
                ),
              ],
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF006633),
            ),
            body: () {
              if (viewModel.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (viewModel.error != null) {
                return Center(child: Text('Error: \\${viewModel.error}'));
              }
              final grouped = viewModel.groupedArticles;
              if (grouped.isEmpty) {
                return const Center(child: Text('No articles found.'));
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: grouped.entries.map((chapterEntry) {
                  final chapterTitle = chapterEntry.key;
                  final sections = chapterEntry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          chapterTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      ...sections.entries.map((sectionEntry) {
                        final articles = sectionEntry.value;
                        // Use the sectionId from the first article in the group, fallback to the key if needed
                        final sectionId = (articles.isNotEmpty && articles.first.sectionId != null && articles.first.sectionId!.isNotEmpty)
                          ? articles.first.sectionId!
                          : sectionEntry.key;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 6),
                              child: Text(
                                'Section $sectionId',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            ...articles.map((article) => Container(
                              margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
                              child: Material(
                                elevation: 2,
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.article,
                                      arguments: {
                                        'id': article.id,
                                        'title': article.title ?? article.sectionTitle ?? 'Article',
                                        'content': article.bodyText ?? '',
                                      },
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.article_outlined,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                article.title ?? article.sectionTitle ?? 'Article',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (article.subSectionTitle != null && article.subSectionTitle!.isNotEmpty)
                                                Text(
                                                  article.subSectionTitle!,
                                                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList(),
              );
            }(),
            bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 0),
            floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 50.0, right: 4.0),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.chatbot);
                },
                backgroundColor: Colors.green.shade700,
                shape: const CircleBorder(),
                child: const Icon(Icons.chat_bubble, color: Colors.white, size: 32),
                tooltip: 'Chatbot',
              ),
            ),
          );
        },
      ),
    );
  }
}