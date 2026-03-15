import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'handbook_main_page.dart';
import 'handbook_saved_articles_page.dart';
import 'handbook_search_screen.dart';

class HandbookBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const HandbookBottomNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    String route = AppRoutes.main;
    switch (index) {
      case 1:
        route = AppRoutes.saved;
        break;
      case 2:
        route = AppRoutes.search;
        break;
      default:
        route = AppRoutes.main;
    }

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          switch (route) {
            case AppRoutes.saved:
              return const HandbookSavedArticlesPage();
            case AppRoutes.search:
              return const HandbookSearchScreen();
            case AppRoutes.main:
            default:
              return const HandbookMainPage();
          }
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      height: 65,
      backgroundColor: Colors.white,
      indicatorColor: Colors.green.shade100,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      onDestinationSelected: (index) => _onItemTapped(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: "Home",
        ),
        NavigationDestination(
          icon: Icon(Icons.search),
          label: "Search",
        ),
        NavigationDestination(
          icon: Icon(Icons.bookmark_border),
          selectedIcon: Icon(Icons.bookmark),
          label: "Saved",
        ),
      ],
    );
  }
}