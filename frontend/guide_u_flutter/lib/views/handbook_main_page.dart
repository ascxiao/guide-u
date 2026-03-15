import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'handbook_bottom_nav_bar.dart';

class HandbookMainPage extends StatelessWidget {
  const HandbookMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sampleArticles = [
      {'title': 'Sample Article 1', 'content': 'Content'},
      {'title': 'Sample Article 2', 'content': 'Content'},
      {'title': 'Sample Article 3', 'content': 'Content'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GuideU',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF006633),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: sampleArticles.length,
        itemBuilder: (context, index) {
          final article = sampleArticles[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
                      'title': article['title'],
                      'content': article['content'],
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
                              article['title']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              article['content']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),

      bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 0),
    );
  }
}