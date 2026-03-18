import 'package:flutter/material.dart';
import '../views/handbook_main_page.dart';
import '../views/handbook_article_page.dart';
import '../views/handbook_saved_articles_page.dart';
import '../views/handbook_search_screen.dart';
import '../views/handbook_chatbot.dart';
import '../views/handbook_incident_page.dart';
import '../views/handbook_lost_and_found_page.dart';

class AppRoutes {
  static const String main = '/';
  static const String article = '/article';
  static const String saved = '/saved';
  static const String search = '/search';
  static const String chatbot = '/chatbot';
  static const String incident = '/incident';
  static const String lostAndFound = '/lost';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case main:
        return MaterialPageRoute(builder: (_) => const HandbookMainPage());
      case article:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => HandbookArticlePage(
            articleTitle: args?['title']?.toString() ?? 'Article',
            articleContent: args?['content']?.toString() ?? 'No content.',
            articleId: args?['id']?.toString(),
          ),
        );
      case saved:
        return MaterialPageRoute(
          builder: (_) => const HandbookSavedArticlesPage(),
        );
      case search:
        return MaterialPageRoute(builder: (_) => const HandbookSearchScreen());
      case chatbot:
        return MaterialPageRoute(builder: (_) => const HandbookChatbotScreen());
      case incident:
        return MaterialPageRoute(builder: (_) => const HandbookIncidentPage());
      case lostAndFound:
        return MaterialPageRoute(
          builder: (_) => const HandbookLostAndFoundPage(),
        );
      default:
        return null;
    }
  }
}
