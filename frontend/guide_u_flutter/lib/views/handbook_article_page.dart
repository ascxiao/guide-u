import 'package:flutter/material.dart';

class HandbookArticlePage extends StatelessWidget {
  final String articleTitle;
  final String articleContent;

  const HandbookArticlePage({
    Key? key,
    required this.articleTitle,
    required this.articleContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 251, 245),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF006633),
        centerTitle: false,
        title: Text(
          articleTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            articleContent,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}