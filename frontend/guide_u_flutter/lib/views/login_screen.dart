import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/login_view_model.dart';
import 'handbook_main_page.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel()..checkSession(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          // Debug log: check session and login state
          debugPrint('[LoginScreen] loggedIn: ${viewModel.loggedIn}');
          // Listen for login state and navigate
          if (viewModel.loggedIn) {
            debugPrint('[LoginScreen] Navigating to MainPage');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HandbookMainPage()),
              );
            });
          }
          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 248, 251, 245),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 56,
                              color: Color(0xFF006633),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Welcome to GuideU',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF006633),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in with Google to access the handbook, search articles, and save your bookmarks.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: viewModel.loading
                                  ? null
                                  : () async {
                                      await viewModel.signInWithGoogle();
                                      viewModel.checkSession();
                                      debugPrint(
                                        '[LoginScreen] signInWithGoogle pressed',
                                      );
                                    },
                              icon: viewModel.loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login),
                              label: Text(
                                viewModel.loading
                                    ? 'Signing in...'
                                    : 'Continue with Google',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF006633),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                            if (viewModel.error != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                viewModel.error!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
