import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../views/handbook_main_page.dart';
import '../views/handbook_article_page.dart';
import '../views/handbook_saved_articles_page.dart';
import '../views/handbook_search_screen.dart';
import '../views/handbook_chatbot.dart';
import '../views/login_screen.dart';

class AppRoutes {
  static const String main = '/';
  static const String login = '/login';
  static const String article = '/article';
  static const String saved = '/saved';
  static const String search = '/search';
  static const String chatbot = '/chatbot';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    final routeName = settings.name ?? main;

    if (!hasSession && routeName != login) {
      return MaterialPageRoute(
        builder: (_) => const LoginScreen(),
        settings: const RouteSettings(name: login),
      );
    }

    if (hasSession && routeName == login) {
      return MaterialPageRoute(
        builder: (_) => const HandbookMainPage(),
        settings: const RouteSettings(name: main),
      );
    }

    switch (routeName) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
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
      default:
        return null;
    }
  }
}
