import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'handbook_bottom_nav_bar.dart';
import '../routes/app_routes.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const mainGreen = Color(0xFF1F7A5A);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      /// 🌿 CLEAN APP BAR
      appBar: AppBar(
        title: const Text(
          'Services',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: mainGreen,
        elevation: 0,
        centerTitle: false,
      ),

      /// 🌿 CONTENT
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ✨ SECTION TITLE (like your homepage style)
            const Text(
              'Student Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            _ServiceCard(
              icon: PhosphorIcons.fileMagnifyingGlass(PhosphorIconsStyle.fill),
              label: 'Lost and Found',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.lostAndFound),
            ),

            const SizedBox(height: 16),

            _ServiceCard(
              icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
              label: 'Incident Report',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.incident),
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          const HandbookBottomNavBar(currentIndex: 2),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const mainGreen = Color(0xFF1F7A5A);
    const softGreen = Color(0xFFE6F4EF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            /// 🌿 SOFT ICON CONTAINER (matches homepage cards)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: mainGreen,
                size: 26,
              ),
            ),

            const SizedBox(width: 16),

            /// TEXT
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),

            /// CHEVRON (Phosphor, not Material)
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              color: Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}