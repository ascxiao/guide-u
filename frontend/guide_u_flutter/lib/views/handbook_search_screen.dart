import 'package:flutter/material.dart';
import 'handbook_bottom_nav_bar.dart';

class HandbookSearchScreen extends StatefulWidget {
  const HandbookSearchScreen({Key? key}) : super(key: key);

  @override
  State<HandbookSearchScreen> createState() => _HandbookSearchScreenState();
}

class _HandbookSearchScreenState extends State<HandbookSearchScreen> {
  String query = '';
  List<String> searchResults = [];

  void _onSearchChanged(String value) {
    setState(() {
      query = value;
      // Placeholder: filter dummy articles
      searchResults = [
        'Article 1',
        'Article 2',
        'Article 3',
      ].where((article) => article.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Handbook'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search articles',
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(searchResults[index]),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/article',
                        arguments: {
                          'title': searchResults[index],
                          'content': 'Content for ' + searchResults[index],
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 2),
    );
  }
}
