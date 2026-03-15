import 'package:flutter/material.dart';
import 'handbook_bottom_nav_bar.dart';

class HandbookSavedArticlesPage extends StatelessWidget {
  const HandbookSavedArticlesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder list of saved articles
    final savedArticles = [
      'Article 1',
      'Article 2',
      'Article 3',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Articles'),
      ),
      body: ListView.builder(
        itemCount: savedArticles.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(savedArticles[index]),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/article',
                arguments: {
                  'title': savedArticles[index],
                  'content': 'Content for ' + savedArticles[index],
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 1),
    );
  }
}
