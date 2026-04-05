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
  static const Color _brandMain = Color(0xFF1F7A5A);
  static const Color _brandAccent = Color(0xFF4FBF8F);
  static const Color _brandSoft = Color(0xFFE6F4EF);

  final TextEditingController _searchController = TextEditingController();

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
                  color: _brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _brandMain, size: 18),
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
          content: SingleChildScrollView(
            child: ListBody(
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
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
          color: _brandSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.account_circle, color: _brandMain, size: 18),
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
    _searchController.dispose();
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
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        toolbarHeight: 68,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Directories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_brandMain, _brandAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brandSoft, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDDEBE3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    color: _brandMain,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap any card to view complete contact details for offices and student government officers.',
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
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E9E3)),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: _brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: _brandMain,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Campus Services'),
                  Tab(text: 'Student Government'),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E9E3)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => searchQuery = value.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search by office, name, or position...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildCampusTab(), _buildStudentGovernmentTab()],
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
          color: _brandSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: PhosphorIcon(
          PhosphorIcons.phone(PhosphorIconsStyle.fill),
          color: _brandMain,
          size: 18,
        ),
      ),
      title: item.name,
      subtitle: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (item.icm.isNotEmpty)
            Text(
              'ICM ${item.icm}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          if (item.pldt.isNotEmpty)
            Text(
              'PLDT ${item.pldt}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
        ],
      ),
    );
  }

  Widget _buildCampusTab() {
    final visibleCategories = categories
        .map((category) {
          final filtered = category.items.where((item) {
            final q = searchQuery.trim();
            if (q.isEmpty) return true;
            return item.name.toLowerCase().contains(q) ||
                item.icm.toLowerCase().contains(q) ||
                item.pldt.toLowerCase().contains(q);
          }).toList();

          return DirectoryCategory(title: category.title, items: filtered);
        })
        .where((category) => category.items.isNotEmpty)
        .toList();

    if (visibleCategories.isEmpty) {
      return _buildEmptyResults(
        icon: Icons.search_off_rounded,
        title: 'No office found',
        subtitle: 'Try searching with a different office name or number.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
      physics: const BouncingScrollPhysics(),
      children: visibleCategories.map((category) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${category.items.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ...category.items.map((item) => _buildItem(item)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStudentGovernmentTab() {
    final visibleGroups = studentGovernmentGroups
        .map((group) {
          final filtered = group.members.where((member) {
            final q = searchQuery.trim();
            if (q.isEmpty) return true;
            return member.name.toLowerCase().contains(q) ||
                member.position.toLowerCase().contains(q) ||
                member.group.toLowerCase().contains(q);
          }).toList();

          return MapEntry(group.title, filtered);
        })
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    if (visibleGroups.isEmpty) {
      return _buildEmptyResults(
        icon: Icons.group_off_rounded,
        title: 'No student leader found',
        subtitle: 'Try searching by name, position, or branch.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
      physics: const BouncingScrollPhysics(),
      children: visibleGroups.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.key,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${group.value.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ...group.value.map((member) => _buildStudentGovItem(member)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyResults({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1EAE4)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 34, color: _brandMain),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1B1B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
