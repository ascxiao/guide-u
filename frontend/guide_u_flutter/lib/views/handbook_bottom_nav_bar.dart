import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class HandbookBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const HandbookBottomNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0: // Home
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
        break;
      case 1: // Lost (Placeholder 1)
        Navigator.pushNamedAndRemoveUntil(context, '/lost', (route) => false);
        break;
      case 2: // Incident (Placeholder 2)
        Navigator.pushNamedAndRemoveUntil(context, '/incident', (route) => false);
        break;
      case 3: // Search
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.search, (route) => false);
        break;
    }
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
          icon: Icon(Icons.circle_outlined),
          label: "Lost",
        ),
        NavigationDestination(
          icon: Icon(Icons.circle_outlined),
          label: "Incident",
        ),
        NavigationDestination(
          icon: Icon(Icons.search),
          label: "Search",
        ),
      ],
    );
  }
}