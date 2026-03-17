
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../view_models/saved_articles_view_model.dart';
import 'handbook_bottom_nav_bar.dart';

class HandbookSavedArticlesPage extends StatelessWidget {
  const HandbookSavedArticlesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedArticlesViewModel>(
      builder: (context, savedVM, _) {
        final userId = Supabase.instance.client.auth.currentUser?.id ?? 'demo-user';
        if (userId.isNotEmpty && savedVM.savedArticles.isEmpty && !savedVM.loading) {
          savedVM.fetchSavedArticles(userId);
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Saved Articles'),
          ),
          body: savedVM.loading
              ? const Center(child: CircularProgressIndicator())
              : savedVM.savedArticles.isEmpty
                  ? const Center(child: Text('No saved articles.'))
                  : ListView.builder(
                      itemCount: savedVM.savedArticles.length,
                      itemBuilder: (context, index) {
                        final saved = savedVM.savedArticles[index];
                        return ListTile(
                          title: Text(saved.articleId ?? 'Unknown Article'),
                          subtitle: saved.createdAt != null
                              ? Text('Saved on: \\${saved.createdAt}')
                              : null,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/article',
                              arguments: {
                                'id': saved.articleId,
                                'title': 'Saved Article',
                                'content': '',
                              },
                            );
                          },
                        );
                      },
                    ),
        );
      },
    );
  }
}
