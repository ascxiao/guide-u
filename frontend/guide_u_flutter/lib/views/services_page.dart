import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'handbook_bottom_nav_bar.dart';
import '../routes/app_routes.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const mainGreen = Color(0xFF1F7A5A);
    const softGreen = Color(0xFFE6F4EF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Student Services',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: mainGreen,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
          physics: const BouncingScrollPhysics(),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [softGreen, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDEBE3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: mainGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIcons.handHeart(PhosphorIconsStyle.fill),
                      color: mainGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help you today?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Choose a service below to report, request support, or follow up with student concerns.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.black54,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Available Services',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B1B1B),
              ),
            ),
            const SizedBox(height: 12),
            _ServiceCard(
              index: 0,
              icon: PhosphorIcons.fileMagnifyingGlass(PhosphorIconsStyle.fill),
              label: 'Lost and Found',
              description:
                  'Report lost items or check found belongings submitted around campus.',
              chipLabel: 'Student Support',
              onTap: () => Navigator.pushNamed(context, AppRoutes.lostAndFound),
            ),
            const SizedBox(height: 12),
            _ServiceCard(
              index: 1,
              icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
              label: 'Incident Report',
              description:
                  'File an incident report for safety, conduct, or urgent campus concerns.',
              chipLabel: 'Priority',
              onTap: () => Navigator.pushNamed(context, AppRoutes.incident),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4ECE7)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF1F7A5A),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Include clear details and contact information for faster assistance.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 2),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final String description;
  final String chipLabel;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.index,
    required this.icon,
    required this.label,
    required this.description,
    required this.chipLabel,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const mainGreen = Color(0xFF1F7A5A);
    const softGreen = Color(0xFFE6F4EF);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 220 + (index * 90)),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 14, end: 0),
      builder: (context, value, child) {
        return Opacity(
          opacity: (1 - (value / 14)).clamp(0, 1),
          child: Transform.translate(offset: Offset(0, value), child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDDEBE3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: softGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: mainGreen, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B1B1B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: softGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          chipLabel,
                          style: const TextStyle(
                            color: mainGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFDFE7E1)),
                  ),
                  child: Icon(
                    PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                    color: Colors.grey.shade500,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
