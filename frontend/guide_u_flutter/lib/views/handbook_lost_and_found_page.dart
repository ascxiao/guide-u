import 'package:flutter/material.dart';
import 'handbook_bottom_nav_bar.dart';

class HandbookLostAndFoundPage extends StatelessWidget {
  const HandbookLostAndFoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          'Lost and Found',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF006633),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
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
          child: const Text(
            'Lost and Found Page',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 1),
    );
  }
}
