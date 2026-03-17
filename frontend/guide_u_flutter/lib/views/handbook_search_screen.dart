import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/handbook_article.dart';
import '../routes/app_routes.dart';
import '../view_models/handbook_search_view_model.dart';
import 'handbook_bottom_nav_bar.dart';

class HandbookSearchScreen extends StatelessWidget {
  const HandbookSearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HandbookSearchViewModel(),
      child: Consumer<HandbookSearchViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Search Handbook')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search articles',
                      hintText: 'Search by title, chapter, section, or content',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: viewModel.updateQuery,
                    textInputAction: TextInputAction.search,
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _SearchResults(viewModel: viewModel)),
                ],
              ),
            ),
            bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 3),
          );
        },
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final HandbookSearchViewModel viewModel;

  const _SearchResults({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.query.trim().isEmpty) {
      return const Center(
        child: Text(
          'Start typing to search handbook articles.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Failed to search articles.\n${viewModel.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (viewModel.hasSearched && viewModel.results.isEmpty) {
      return const Center(
        child: Text('No matching articles found.', textAlign: TextAlign.center),
      );
    }

    return ListView.separated(
      itemCount: viewModel.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final article = viewModel.results[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              article.title ?? article.sectionTitle ?? 'Article',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _ArticleSubtitle(article: article),
            ),
            trailing: const Icon(Icons.chevron_right),
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
          ),
        );
      },
    );
  }
}

class _ArticleSubtitle extends StatelessWidget {
  final HandbookArticle article;

  const _ArticleSubtitle({required this.article});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (article.chapterTitle != null && article.chapterTitle!.isNotEmpty)
        article.chapterTitle!,
      if (article.sectionTitle != null && article.sectionTitle!.isNotEmpty)
        article.sectionTitle!,
      if (article.subSectionTitle != null &&
          article.subSectionTitle!.isNotEmpty)
        article.subSectionTitle!,
    ];

    final preview = article.bodyText?.replaceAll('\n', ' ').trim();
    final previewText = (preview != null && preview.isNotEmpty)
        ? preview
        : 'Open to read the full article.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts.isNotEmpty)
          Text(parts.join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(previewText, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
