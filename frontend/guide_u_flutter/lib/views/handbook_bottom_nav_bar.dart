import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../routes/app_routes.dart';

// Nav button
class _NavBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isPrimary;
  final VoidCallback onTap;

  const _NavBarButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isPrimary = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainGreen = const Color(0xFF1F7A5A);
    final primaryGreen = const Color(0xFF00A86B);
    final inactiveColor = Colors.grey.shade500;

    /// 🔥 SEARCH (PRIMARY BUTTON)
    if (isPrimary) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 6),
                  const Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    /// 🧼 MINIMAL BUTTONS (HOME / SERVICES)
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? mainGreen : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? mainGreen : inactiveColor,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
            ),

            /// ✨ THIN INDICATOR (instead of full background)
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 18 : 0,
              decoration: BoxDecoration(
                color: mainGreen,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HandbookBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const HandbookBottomNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.main, (route) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.search, (route) => false);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.services, (route) => false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            _NavBarButton(
              icon: PhosphorIcons.house(PhosphorIconsStyle.fill),
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => _onItemTapped(context, 0),
            ),
            _NavBarButton(
              icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.fill),
              label: 'Search',
              selected: currentIndex == 1,
              isPrimary: true,
              onTap: () => _onItemTapped(context, 1),
            ),
            _NavBarButton(
              icon: PhosphorIcons.gridFour(PhosphorIconsStyle.fill),
              label: 'Services',
              selected: currentIndex == 2,
              onTap: () => _onItemTapped(context, 2),
            ),
          ],
        ),
      ),
    );
  }
}