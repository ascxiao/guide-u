import 'package:flutter/material.dart';
import '../views/handbook_chatbot.dart';

Route createChatbotRoute() {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),

    pageBuilder: (context, animation, secondaryAnimation) =>
        const HandbookChatbotScreen(),

    transitionsBuilder:
        (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack, // 🔥 POP effect
      );

      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1), // FROM BOTTOM
            end: Offset.zero,
          ).animate(curvedAnimation),

          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(curvedAnimation),

            child: child,
          ),
        ),
      );
    },
  );
}