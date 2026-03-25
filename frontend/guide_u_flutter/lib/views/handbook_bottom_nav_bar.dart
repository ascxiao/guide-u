import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../routes/app_routes.dart';
import '../routes/chatbot_routes.dart';


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
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.lostAndFound, (route) => false);
        break;
      case 2:
        Navigator.push(context, createChatbotRoute());
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.incident, (route) => false);
        break;
      case 4:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.search, (route) => false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF5F7FA),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
          // No borderRadius, fill bottom and sides
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            /// 🔹 NAV ITEMS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                  selected: currentIndex == 0,
                  onTap: () => _onItemTapped(context, 0),
                  isPhosphor: true,
                ),
                _NavItem(
                  icon: PhosphorIcons.fileMagnifyingGlass(PhosphorIconsStyle.fill),
                  selected: currentIndex == 1,
                  onTap: () => _onItemTapped(context, 1),
                  isPhosphor: true,
                ),

                const SizedBox(width: 60),

                _NavItem(
                  icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                  selected: currentIndex == 3,
                  onTap: () => _onItemTapped(context, 3),
                  isPhosphor: true,
                ),
                _NavItem(
                  icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.fill),
                  selected: currentIndex == 4,
                  onTap: () => _onItemTapped(context, 4),
                  isPhosphor: true,
                ),
              ],
            ),

            // Chatbot FAB will be handled by parent Scaffold, not here.
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final dynamic icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isPhosphor;

  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isPhosphor = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [
        Color(0xFF00A86B),
        Color(0xFF006633),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF00A86B).withOpacity(0.15),
                    const Color(0xFF006633).withOpacity(0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => selected
              ? gradient.createShader(bounds)
              : const LinearGradient(
                  colors: [Colors.grey, Colors.grey],
                ).createShader(bounds),
          child: isPhosphor
              ? PhosphorIcon(
                  icon,
                  size: 26,
                  color: Colors.white,
                )
              : Icon(
                  icon,
                  size: 26,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}