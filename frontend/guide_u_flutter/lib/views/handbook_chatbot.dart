import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../view_models/handbook_chatbot_view_model.dart';
import '../widgets/internet_required_notice.dart';

class HandbookChatbotScreen extends StatelessWidget {
  const HandbookChatbotScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HandbookChatbotViewModel(),
      child: const _HandbookChatbotBody(),
    );
  }
}

class _HandbookChatbotBody extends StatefulWidget {
  const _HandbookChatbotBody({Key? key}) : super(key: key);

  @override
  State<_HandbookChatbotBody> createState() => _HandbookChatbotBodyState();
}

class _HandbookChatbotBodyState extends State<_HandbookChatbotBody> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const Color _brandGreen = Color(0xFF1F7A5A);
  static const Color _brandSoft = Color(0xFFE8F4EE);
  static const List<String> _starterPrompts = [
    'What are the enrollment requirements?',
    'How do I apply for scholarships?',
    'Where can I find student services?',
    'What is the class schedule process?',
  ];

  bool _isPressed = false;
  bool _showScrollToLatest = false;
  int _lastMessageCount = 0;
  bool _lastLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _controller.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final bool shouldShow = position.maxScrollExtent - position.pixels > 140;
    if (shouldShow != _showScrollToLatest) {
      setState(() {
        _showScrollToLatest = shouldShow;
      });
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _syncAutoScroll(HandbookChatbotViewModel viewModel) {
    final bool messageCountChanged =
        viewModel.messages.length != _lastMessageCount;
    final bool responseFinished = _lastLoading && !viewModel.loading;
    if (messageCountChanged || responseFinished) {
      _scrollToBottom(animated: true);
    }
    _lastMessageCount = viewModel.messages.length;
    _lastLoading = viewModel.loading;
  }

  void _send({String? seededPrompt}) {
    final viewModel = Provider.of<HandbookChatbotViewModel>(
      context,
      listen: false,
    );

    final text = (seededPrompt ?? _controller.text).trim();
    if (text.isEmpty || viewModel.loading) return;

    HapticFeedback.lightImpact();
    _controller.clear();
    viewModel.sendPrompt(text);
    _scrollToBottom(animated: true);
  }

  Future<void> _confirmClearConversation() async {
    final viewModel = Provider.of<HandbookChatbotViewModel>(
      context,
      listen: false,
    );
    if (viewModel.messages.isEmpty) return;

    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear conversation?'),
          content: const Text(
            'This removes all messages in the current chat session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _brandGreen),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      viewModel.clearMessages();
      setState(() {
        _showScrollToLatest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HandbookChatbotViewModel>(context);
    _syncAutoScroll(viewModel);
    final bool canSend =
        _controller.text.trim().isNotEmpty && !viewModel.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F4),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _brandGreen,
          ),
          onPressed: () =>
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: _brandSoft,
              child: Icon(
                Icons.support_agent_rounded,
                size: 16,
                color: _brandGreen,
              ),
            ),
            SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Juan La Salle',
                  style: TextStyle(
                    color: _brandGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Online handbook assistant',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Clear conversation',
            icon: Icon(
              Icons.delete_outline_rounded,
              color: viewModel.messages.isEmpty ? Colors.black26 : _brandGreen,
            ),
            onPressed: viewModel.messages.isEmpty
                ? null
                : _confirmClearConversation,
          ),
        ],
      ),

      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: InternetRequiredNotice(featureName: 'Chatbot'),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: viewModel.messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessageList(viewModel),
                  ),
                ),
                if (viewModel.loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: TypingDots(),
                  ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'AI may make mistakes. Verify important information.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black38,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                _buildComposer(canSend),
              ],
            ),
            if (_showScrollToLatest && viewModel.messages.isNotEmpty)
              Positioned(
                right: 16,
                bottom: 115,
                child: FloatingActionButton.small(
                  heroTag: 'scrollToLatest',
                  backgroundColor: _brandGreen,
                  onPressed: () => _scrollToBottom(animated: true),
                  child: const Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      key: const ValueKey('empty_state'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ask me anything about the handbook',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Try one of these quick prompts to get started.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: _starterPrompts
                        .map(
                          (prompt) => ActionChip(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFCCE3D7)),
                            labelStyle: const TextStyle(
                              color: _brandGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            label: Text(prompt),
                            onPressed: () => _send(seededPrompt: prompt),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageList(HandbookChatbotViewModel viewModel) {
    return ListView.separated(
      key: const ValueKey('messages_list'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      physics: const BouncingScrollPhysics(),
      itemCount: viewModel.messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final msg = viewModel.messages[index];
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 16, end: 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: (1 - (value / 16)).clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, value),
                child: child,
              ),
            );
          },
          child: Align(
            alignment: msg.isUser
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: msg.isUser ? _brandGreen : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: msg.isUser
                        ? const Radius.circular(20)
                        : const Radius.circular(6),
                    bottomRight: msg.isUser
                        ? const Radius.circular(6)
                        : const Radius.circular(20),
                  ),
                  border: msg.isUser
                      ? null
                      : Border.all(color: const Color(0xFFDFEAE4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: msg.isUser
                      ? Text(
                          msg.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.support_agent_rounded,
                                  size: 14,
                                  color: _brandGreen,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Juan La Salle',
                                  style: TextStyle(
                                    color: _brandGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              msg.text,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                tooltip: 'Copy message',
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: msg.text),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: Text('Message copied'),
                                        duration: Duration(milliseconds: 1200),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  size: 17,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer(bool canSend) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFD7E4DC)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 8, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.edit_outlined, size: 20, color: Colors.black45),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Ask Juan La Salle...',
                    hintStyle: TextStyle(color: Colors.black45, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              GestureDetector(
                onTapDown: canSend
                    ? (_) => setState(() => _isPressed = true)
                    : null,
                onTapUp: canSend
                    ? (_) {
                        setState(() => _isPressed = false);
                        _send();
                      }
                    : null,
                onTapCancel: () => setState(() => _isPressed = false),
                child: AnimatedScale(
                  scale: _isPressed ? 0.88 : 1,
                  duration: const Duration(milliseconds: 120),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: canSend ? _brandGreen : const Color(0xFFBCD4C7),
                    ),
                    child: canSend
                        ? const Icon(
                            Icons.arrow_upward_rounded,
                            size: 18,
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.hourglass_top_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _dotAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _dotAnimation = List.generate(3, (index) {
      final start = index * 0.18;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.6, end: 1.1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final scale = _dotAnimation[index].value;
            return Transform.scale(
              scale: scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    const Color(0xFFB5C9BE),
                    _HandbookChatbotBodyState._brandGreen,
                    (scale - 0.6) / 0.5,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
