import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'handbook_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../view_models/handbook_main_view_model.dart';

class HandbookMainPage extends StatefulWidget {
  const HandbookMainPage({Key? key}) : super(key: key);

  @override
  State<HandbookMainPage> createState() => _HandbookMainPageState();
}

class _HandbookMainPageState extends State<HandbookMainPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HandbookMainViewModel(),
      child: Consumer<HandbookMainViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 245, 244, 244),
            extendBody: true,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(75),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00A86B), Color(0xFF006633)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: AppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,

                  /// 🔹 TITLE
                  title: const Text(
                    'GuideU',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),

                  /// 🔹 ACTIONS (FIXED LAYOUT)
                  actions: [
                    /// 🔖 Bookmark (secondary action)
                    IconButton(
                      icon: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 255, 255, 255), // Gold
                              Color(0xFFFFF176), // Light yellow
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: const Icon(
                          Icons.bookmark,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.saved);
                      },
                    ),

                    const SizedBox(width: 6),

                    /// 👤 Profile (primary, more visual weight)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF006633),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: _buildBody(context, viewModel),
            bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 0),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, HandbookMainViewModel viewModel) {
    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
        child: Text(
          'Error: ${viewModel.error}',
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    final grouped = viewModel.groupedArticles;

    if (grouped.isEmpty) {
      return const Center(child: Text('No articles found.'));
    }

    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            /// 🔥 HEADER
            FadeTransition(
              opacity: _controller,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.1),
                  end: Offset.zero,
                ).animate(_controller),
                child: Container(
                  // Remove margin, use same horizontal as cards (16)
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/usls_header.jpg'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  // Match ListView horizontal padding
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.black.withOpacity(0.2),
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Welcome to GuideU",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "University of St. La Salle Handbook",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 📚 CONTENT
            ...grouped.entries.map((chapterEntry) {
              final chapterTitle = chapterEntry.key;
              final sections = chapterEntry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// CHAPTER TITLE
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      chapterTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  /// SECTIONS
                  ...sections.entries.map((sectionEntry) {
                    final articles = sectionEntry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6, bottom: 6),
                          child: Text(
                            'Section '
                            '${(articles.isNotEmpty && articles.first.sectionId != null && articles.first.sectionId.toString().isNotEmpty) ? articles.first.sectionId : sectionEntry.key}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        /// ARTICLES WITH STAGGER ANIMATION
                        ...articles.asMap().entries.map((entry) {
                          final index = entry.key;
                          final article = entry.value;

                          final animation = Tween<double>(begin: 0, end: 1)
                              .animate(
                                CurvedAnimation(
                                  parent: _controller,
                                  curve: Interval(
                                    (index * 0.05).clamp(0.0, 1.0),
                                    1.0,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              );

                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: animation.value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - animation.value)),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildAnimatedCard(context, article),
                          );
                        }),

                        const SizedBox(height: 10),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(BuildContext context, dynamic article) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.article,
          arguments: {
            'id': article.id,
            'title': article.title ?? article.sectionTitle ?? 'Article',
            'content': article.bodyText ?? '',
          },
        );
      },
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF006633).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: Color(0xFF006633),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  article.title ?? article.sectionTitle ?? 'Article',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
