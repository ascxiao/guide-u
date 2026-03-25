import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'handbook_bottom_nav_bar.dart';

class DirectoryItem {
  final String name;
  final String icm;
  final String pldt;

  DirectoryItem({required this.name, this.icm = '', this.pldt = ''});
}

class DirectoryCategory {
  final String title;
  final List<DirectoryItem> items;

  DirectoryCategory({required this.title, required this.items});
}

class DirectoriesPage extends StatefulWidget {
  const DirectoriesPage({Key? key}) : super(key: key);

  @override
  State<DirectoriesPage> createState() => _DirectoriesPageState();
}

class _DirectoriesPageState extends State<DirectoriesPage> {
  String searchQuery = '';

  final List<DirectoryCategory> categories = [
    DirectoryCategory(
      title: "Administration",
      items: [
        DirectoryItem(name: "Security Office", icm: "139", pldt: "432-1187"),
        DirectoryItem(name: "Bookstore", icm: "175", pldt: "432-1183"),
        DirectoryItem(name: "Coliseum", icm: "153", pldt: "436-0083"),
      ],
    ),
    DirectoryCategory(
      title: "Student Services",
      items: [
        DirectoryItem(name: "OSA", icm: "134", pldt: "432-1184"),
        DirectoryItem(name: "Registrar", icm: "128", pldt: "432-1182"),
        DirectoryItem(name: "Guidance Office", icm: "145"),
      ],
    ),
    DirectoryCategory(
      title: "Libraries & Labs",
      items: [
        DirectoryItem(name: "Library Circulation", icm: "131", pldt: "432-3626"),
        DirectoryItem(name: "Science Lab", icm: "164", pldt: "434-1730"),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F4),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F7A5A), Color(0xFF4FBF8F)],
              stops: [0.2, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            automaticallyImplyLeading: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Directories',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search bar (matches your UI softness)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() => searchQuery = value.toLowerCase());
                },
                decoration: const InputDecoration(
                  hintText: "Search directory...",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // 📇 Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: categories.map((category) {
                final filtered = category.items.where((item) {
                  return item.name.toLowerCase().contains(searchQuery);
                }).toList();

                if (filtered.isEmpty) return const SizedBox();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🏷 Section title (like "Section 1.1")
                    Padding(
                      padding: const EdgeInsets.only(top: 18, bottom: 8),
                      child: Text(
                        category.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // 📄 Items
                    ...filtered.map((item) => _buildItem(item)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),

      bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildItem(DirectoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Icon bubble (matches your cards)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: PhosphorIcon(
              PhosphorIcons.phone(PhosphorIconsStyle.fill),
              color: const Color(0xFF1F7A5A),
              size: 18,
            ),
          ),

          const SizedBox(width: 14),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.icm.isNotEmpty)
                      Text(
                        "ICM ${item.icm}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    if (item.icm.isNotEmpty && item.pldt.isNotEmpty)
                      const SizedBox(width: 8),
                    if (item.pldt.isNotEmpty)
                      Text(
                        "PLDT ${item.pldt}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}