import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/student_government.dart';

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

class _DirectoriesPageState extends State<DirectoriesPage>
    with SingleTickerProviderStateMixin {
  void _showDetailsDialog({
    required String title,
    required IconData icon,
    required List<MapEntry<String, String>> details,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF1F7A5A), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: details
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 84,
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showOfficeDetails(DirectoryItem item) {
    final details = <MapEntry<String, String>>[
      MapEntry('Office', item.name),
      MapEntry('ICM', item.icm.isNotEmpty ? item.icm : 'Not available'),
      MapEntry('PLDT', item.pldt.isNotEmpty ? item.pldt : 'Not available'),
    ];

    _showDetailsDialog(
      title: 'Office Contact Details',
      icon: Icons.local_phone,
      details: details,
    );
  }

  void _showStudentGovDetails(StudentGovernmentMember member) {
    final details = <MapEntry<String, String>>[
      MapEntry('Name', member.name),
      MapEntry('Position', member.position),
      MapEntry('Branch', member.group),
    ];

    _showDetailsDialog(
      title: 'Student Government',
      icon: Icons.account_circle,
      details: details,
    );
  }

  Widget _buildTile({
    required Widget leading,
    required String title,
    required Widget subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    subtitle,
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentGovItem(StudentGovernmentMember member) {
    return _buildTile(
      onTap: () => _showStudentGovDetails(member),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F4EF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.account_circle,
          color: Color(0xFF1F7A5A),
          size: 18,
        ),
      ),
      title: member.name,
      subtitle: Text(
        member.position,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  String searchQuery = '';

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        DirectoryItem(
          name: "Library Circulation",
          icm: "131",
          pldt: "432-3626",
        ),
        DirectoryItem(name: "Science Lab", icm: "164", pldt: "434-1730"),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F4),

      // ✅ CLEAN APPBAR (gradient stays here ONLY)
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        title: const Text(
          'Directories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F7A5A), Color(0xFF4FBF8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // ✅ WHITE TAB BAR (separate from gradient)
          Material(
            color: Colors.white,
            elevation: 2,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF1F7A5A),
              indicatorWeight: 3,
              labelColor: const Color(0xFF1F7A5A),
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Campus Services'),
                Tab(text: 'Student Government'),
              ],
            ),
          ),

          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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

          // 📇 CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Campus Services
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: categories.map((category) {
                    final filtered = category.items.where((item) {
                      return item.name.toLowerCase().contains(searchQuery);
                    }).toList();

                    if (filtered.isEmpty) return const SizedBox();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        ...filtered.map((item) => _buildItem(item)),
                      ],
                    );
                  }).toList(),
                ),

                // Student Government
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: studentGovernmentGroups.map((group) {
                    final filtered = group.members.where((member) {
                      return member.name.toLowerCase().contains(searchQuery) ||
                          member.position.toLowerCase().contains(searchQuery);
                    }).toList();

                    if (filtered.isEmpty) return const SizedBox();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 8),
                          child: Text(
                            group.title,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ...filtered.map(
                          (member) => _buildStudentGovItem(member),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(DirectoryItem item) {
    return _buildTile(
      onTap: () => _showOfficeDetails(item),
      leading: Container(
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
      title: item.name,
      subtitle: Row(
        children: [
          if (item.icm.isNotEmpty)
            Text(
              'ICM ${item.icm}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          if (item.icm.isNotEmpty && item.pldt.isNotEmpty)
            const SizedBox(width: 8),
          if (item.pldt.isNotEmpty)
            Text(
              'PLDT ${item.pldt}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
        ],
      ),
    );
  }
}
