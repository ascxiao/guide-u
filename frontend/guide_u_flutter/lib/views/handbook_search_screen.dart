import 'package:flutter/material.dart';
import 'handbook_bottom_nav_bar.dart';

class HandbookSearchScreen extends StatefulWidget {
  const HandbookSearchScreen({Key? key}) : super(key: key);

  @override
  State<HandbookSearchScreen> createState() =>
      _HandbookSearchScreenState();
}

class _HandbookSearchScreenState
    extends State<HandbookSearchScreen> {
  String query = '';
  List<String> searchResults = [];

  final TextEditingController _controller =
      TextEditingController();

  void _onSearchChanged(String value) {
    setState(() {
      query = value;

      searchResults = [
        'Student Code of Conduct',
        'Dress Code Policy',
        'Attendance Rules',
        'Grading System',
        'Library Guidelines',
      ]
          .where((article) => article
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      query = '';
      searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          'Search Handbook',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF006633),
      ),
      body: SafeArea(
        child: Column(
          children: [
            /// 🔍 SEARCH BAR
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search,
                        color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onSearchChanged,
                        decoration:
                            const InputDecoration(
                          hintText:
                              'Search articles...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                      ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: query.isEmpty
                  ? const Center(
                      child: Text(
                        "Start typing to search",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            "No results found",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12),
                          itemCount:
                              searchResults.length,
                          itemBuilder:
                              (context, index) {
                            final item =
                                searchResults[index];

                            return Container(
                              margin:
                                  const EdgeInsets
                                      .symmetric(
                                          vertical: 6),
                              decoration:
                                  BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius
                                        .circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(
                                            0.04),
                                    blurRadius: 8,
                                    offset:
                                        const Offset(
                                            0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                            horizontal:
                                                16,
                                            vertical:
                                                8),
                                leading: Container(
                                  padding:
                                      const EdgeInsets
                                          .all(8),
                                  decoration:
                                      BoxDecoration(
                                    color: const Color(
                                            0xFF006633)
                                        .withOpacity(
                                            0.1),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                10),
                                  ),
                                  child: const Icon(
                                    Icons.article,
                                    color: Color(
                                        0xFF006633),
                                  ),
                                ),
                                title: Text(
                                  item,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                                trailing:
                                    const Icon(
                                  Icons
                                      .arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/article',
                                    arguments: {
                                      'title': item,
                                      'content':
                                          'Content for $item',
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const HandbookBottomNavBar(currentIndex: 4),
    );
  }
}