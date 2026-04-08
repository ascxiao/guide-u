import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../services/user_profile_service.dart';
import '../view_models/handbook_main_view_model.dart';
import '../widgets/handbook_chatbot_fab.dart';
import 'handbook_bottom_nav_bar.dart';

class HandbookMainPage extends StatefulWidget {
  const HandbookMainPage({Key? key}) : super(key: key);

  @override
  State<HandbookMainPage> createState() => _HandbookMainPageState();
}

class _HandbookMainPageState extends State<HandbookMainPage>
    with SingleTickerProviderStateMixin {
  static const Color _brandMain = Color(0xFF1F7A5A);
  static const Color _brandAccent = Color(0xFF4FBF8F);
  static const Color _brandSoft = Color(0xFFE6F4EF);
  static const Color _pageBg = Color(0xFFF5F7FA);

  Timer? _autoSlideTimer;
  final PageController _headerPageController = PageController();
  static const List<String> _headerImagePaths = [
    'assets/images/usls_header.jpg',
    'assets/images/usls_header2.jpg',
    'assets/images/usls_header3.jpg',
  ];

  int _headerPageIndex = 0;
  late final AnimationController _controller;
  bool _needsInitialContentAnimation = true;
  bool _seenLoadingState = false;
  bool _animationQueued = false;
  final UserProfileService _userProfileService = UserProfileService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      if (!_headerPageController.hasClients) return;
      if (_headerImagePaths.isEmpty) return;

      final nextPage = (_headerPageIndex + 1) % _headerImagePaths.length;
      _headerPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      setState(() {
        _headerPageIndex = nextPage;
      });
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _controller.dispose();
    _headerPageController.dispose();
    super.dispose();
  }

  void _queueEntryAnimation() {
    if (_animationQueued) return;
    _animationQueued = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationQueued = false;
      if (!mounted) return;
      _controller.forward(from: 0);
    });
  }

  Widget _buildStaggeredCardReveal({
    required int index,
    required Widget child,
  }) {
    final start = (index * 0.07).clamp(0.0, 0.85).toDouble();
    final end = (start + 0.32).clamp(0.0, 1.0).toDouble();
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, revealChild) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - animation.value)),
            child: revealChild,
          ),
        );
      },
    );
  }

  Widget _buildAppBarAvatar(String? avatarUrl) {
    const accent = Color(0xFF006633);

    if (avatarUrl == null) {
      return const Icon(Icons.person, color: accent, size: 20);
    }

    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: 34,
        height: 34,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Icon(Icons.person, color: accent, size: 20);
        },
      ),
    );
  }

  String titleCaseWithAbbr(String text) {
    if (text.isEmpty) return text;

    final regex = RegExp(r'\([^\)]+\)');
    final matches = regex.allMatches(text).toList();

    var modified = text;
    for (int i = 0; i < matches.length; i++) {
      modified = modified.replaceFirst(matches[i].group(0)!, '<<$i>>');
    }

    modified = modified
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          if (word.startsWith('<<') && word.endsWith('>>')) {
            return word;
          }
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');

    for (int i = 0; i < matches.length; i++) {
      modified = modified.replaceFirst('<<$i>>', matches[i].group(0)!);
    }

    return modified;
  }

  int _compareNumericToken(String a, String b) {
    final normalizedA = a.replaceFirst(RegExp(r'^0+'), '');
    final normalizedB = b.replaceFirst(RegExp(r'^0+'), '');
    final safeA = normalizedA.isEmpty ? '0' : normalizedA;
    final safeB = normalizedB.isEmpty ? '0' : normalizedB;

    if (safeA.length != safeB.length) {
      return safeA.length.compareTo(safeB.length);
    }

    final valueCompare = safeA.compareTo(safeB);
    if (valueCompare != 0) return valueCompare;

    return a.length.compareTo(b.length);
  }

  List<String> _naturalTokens(String input) {
    return RegExp(
      r'\d+|\D+',
    ).allMatches(input).map((m) => m.group(0)!).toList();
  }

  int _compareOrderTokens(String a, String b) {
    final aValue = a.trim();
    final bValue = b.trim();

    final aTokens = _naturalTokens(aValue);
    final bTokens = _naturalTokens(bValue);
    final count = aTokens.length < bTokens.length
        ? aTokens.length
        : bTokens.length;
    final digitPattern = RegExp(r'^\d+$');

    for (var i = 0; i < count; i++) {
      final aToken = aTokens[i];
      final bToken = bTokens[i];
      final aIsNumber = digitPattern.hasMatch(aToken);
      final bIsNumber = digitPattern.hasMatch(bToken);

      if (aIsNumber && bIsNumber) {
        final numberCompare = _compareNumericToken(aToken, bToken);
        if (numberCompare != 0) return numberCompare;
        continue;
      }

      if (aIsNumber != bIsNumber) {
        return aIsNumber ? -1 : 1;
      }

      final textCompare = aToken.toLowerCase().compareTo(bToken.toLowerCase());
      if (textCompare != 0) return textCompare;
    }

    return aTokens.length.compareTo(bTokens.length);
  }

  String _chapterSortToken(MapEntry<String, Map<String, List<dynamic>>> entry) {
    for (final articles in entry.value.values) {
      if (articles.isEmpty) continue;
      final chapterId = articles.first.chapterId?.toString().trim();
      if (chapterId != null && chapterId.isNotEmpty) {
        return chapterId;
      }
    }

    return entry.key;
  }

  String _sectionSortToken(MapEntry<String, List<dynamic>> entry) {
    final articles = entry.value;
    if (articles.isNotEmpty) {
      final sectionId = articles.first.sectionId?.toString().trim();
      if (sectionId != null && sectionId.isNotEmpty) {
        return sectionId;
      }
    }

    return entry.key;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HandbookMainViewModel(),
      child: Consumer<HandbookMainViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: _pageBg,
            extendBody: true,
            appBar: _buildAppBar(context),
            body: _buildBody(context, viewModel),
            bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 0),
            floatingActionButton: const HandbookChatbotFAB(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final avatarUrl = _userProfileService.currentAvatarUrl();

    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4BB285), _brandMain],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: SizedBox(
            height: 22,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Image.asset(
                'assets/images/TypoguideU.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildAppBarAvatar(avatarUrl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HandbookMainViewModel viewModel) {
    final grouped = viewModel.groupedArticles;
    final firstName = _userProfileService.currentFirstName();

    if (viewModel.loading) {
      _seenLoadingState = true;
    }

    if (!viewModel.loading && grouped.isEmpty) {
      _needsInitialContentAnimation = true;
    }

    if (!viewModel.loading &&
        grouped.isNotEmpty &&
        (_needsInitialContentAnimation || _seenLoadingState)) {
      _needsInitialContentAnimation = false;
      _seenLoadingState = false;
      _queueEntryAnimation();
    }

    if (viewModel.loading && grouped.isEmpty) {
      return _buildLoadingState();
    }

    if (viewModel.error != null && grouped.isEmpty) {
      return _buildErrorState(viewModel);
    }

    if (grouped.isEmpty) {
      return _buildEmptyState(viewModel);
    }

    final sortedChapterEntries = grouped.entries.toList()
      ..sort(
        (a, b) =>
            _compareOrderTokens(_chapterSortToken(a), _chapterSortToken(b)),
      );

    final int chapterCount = sortedChapterEntries.length;
    final int totalArticleCount = sortedChapterEntries.fold(0, (sum, chapter) {
      final int inChapter = chapter.value.values.fold(
        0,
        (inner, articles) => inner + articles.length,
      );
      return sum + inChapter;
    });

    return RefreshIndicator(
      color: _brandMain,
      onRefresh: viewModel.fetchGroupedHandbookArticles,
      child: FadeTransition(
        opacity: _controller,
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOut),
              ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              _buildHeaderCarousel(
                isOnline: viewModel.isOnline,
                chapterCount: chapterCount,
                articleCount: totalArticleCount,
                firstName: firstName,
              ),
              const SizedBox(height: 16),
              _buildStaggeredCardReveal(
                index: 0,
                child: _buildQuickActions(context),
              ),
              const SizedBox(height: 18),
              const Text(
                'Browse Handbook',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1B1B),
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < sortedChapterEntries.length; i++)
                _buildStaggeredCardReveal(
                  index: i + 1,
                  child: _buildChapterCard(
                    context,
                    sortedChapterEntries[i],
                    chapterIndex: i,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(color: _brandMain),
          SizedBox(height: 12),
          Text('Loading handbook...', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildErrorState(HandbookMainViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFDEAEA),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFD32F2F),
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Unable to load handbook',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              viewModel.error ?? 'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _brandMain),
              onPressed: viewModel.fetchGroupedHandbookArticles,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(HandbookMainViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _brandSoft,
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                color: _brandMain,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No articles found yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pull down to refresh or tap below to reload handbook data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _brandMain),
              onPressed: viewModel.fetchGroupedHandbookArticles,
              child: const Text('Reload'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCarousel({
    required bool isOnline,
    required int chapterCount,
    required int articleCount,
    required String firstName,
  }) {
    return Column(
      children: [
        SizedBox(
          height: 196,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _headerPageController,
                  itemCount: _headerImagePaths.length,
                  onPageChanged: (index) {
                    setState(() {
                      _headerPageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(_headerImagePaths[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.62),
                              Colors.black.withValues(alpha: 0.28),
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 18,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? _brandAccent.withValues(alpha: 0.9)
                          : Colors.orange.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      isOnline ? 'Online' : 'Offline cache mode',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 56,
                  child: Text(
                    'Welcome to GuideU, $firstName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$chapterCount chapters',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$articleCount articles',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _headerImagePaths.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _headerPageIndex == index ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _headerPageIndex == index
                    ? _brandMain
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickActionTile(
            title: 'Saved Articles',
            subtitle: 'Your bookmarks',
            icon: PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
            onTap: () => Navigator.pushNamed(context, AppRoutes.saved),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickActionTile(
            title: 'Directories',
            subtitle: 'Campus contacts',
            icon: PhosphorIcons.folderSimple(PhosphorIconsStyle.fill),
            onTap: () => Navigator.pushNamed(context, AppRoutes.directories),
          ),
        ),
      ],
    );
  }

  Widget _quickActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [_brandSoft, _brandAccent.withValues(alpha: 0.20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _brandAccent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: PhosphorIcon(icon, color: _brandMain, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _brandMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterCard(
    BuildContext context,
    MapEntry<String, Map<String, List<dynamic>>> chapterEntry, {
    required int chapterIndex,
  }) {
    final String chapterTitle = chapterEntry.key;
    final Map<String, List<dynamic>> sections = chapterEntry.value;

    final dynamic chapterId =
        (sections.values.first.isNotEmpty &&
            sections.values.first.first.chapterId != null)
        ? sections.values.first.first.chapterId
        : null;

    final String heading =
        'Chapter ${(chapterId != null && chapterId.toString().isNotEmpty) ? '${chapterId.toString()} - ' : ''}${titleCaseWithAbbr(chapterTitle)}';

    final sortedSectionEntries = sections.entries.toList()
      ..sort(
        (a, b) =>
            _compareOrderTokens(_sectionSortToken(a), _sectionSortToken(b)),
      );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2ECE6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sortedSectionEntries.map((sectionEntry) {
            final articles = sectionEntry.value;
            final dynamic sectionLabel =
                (articles.isNotEmpty &&
                    articles.first.sectionId != null &&
                    articles.first.sectionId.toString().isNotEmpty)
                ? articles.first.sectionId
                : sectionEntry.key;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _brandSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Section $sectionLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _brandMain,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...articles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final article = entry.value;
                  final animation = Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Interval(
                        ((index + chapterIndex) * 0.045).clamp(0.0, 1.0),
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
                          offset: Offset(0, 14 * (1 - animation.value)),
                          child: child,
                        ),
                      );
                    },
                    child: _buildAnimatedCard(context, article),
                  );
                }),
                const SizedBox(height: 6),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(BuildContext context, dynamic article) {
    final String displayTitle =
        (article.subSectionTitle != null && article.subSectionTitle != 'N/A')
        ? article.subSectionTitle
        : (article.title ?? article.sectionTitle ?? 'Article');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.article,
            arguments: {
              'id': article.id,
              'title': titleCaseWithAbbr(displayTitle),
              'content': article.bodyText ?? '',
              'chapter':
                  (article.chapterId != null &&
                      article.chapterId.toString().isNotEmpty)
                  ? article.chapterId.toString()
                  : (article.chapterTitle?.toString() ?? ''),
              'section':
                  (article.sectionId != null &&
                      article.sectionId.toString().isNotEmpty)
                  ? article.sectionId.toString()
                  : (article.sectionTitle?.toString() ?? ''),
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF9FCFA),
              border: Border.all(color: const Color(0xFFDDEBE3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _brandAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: PhosphorIcon(
                    PhosphorIcons.fileText(PhosphorIconsStyle.fill),
                    color: _brandMain,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titleCaseWithAbbr(displayTitle),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF131313),
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFDFE7E1)),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black45,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
