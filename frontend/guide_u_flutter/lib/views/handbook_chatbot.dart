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

class _HandbookChatbotBodyState extends State<_HandbookChatbotBody>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isPressed = false;

  void _send() {
    final viewModel = Provider.of<HandbookChatbotViewModel>(
      context,
      listen: false,
    );

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    viewModel.sendPrompt(text);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HandbookChatbotViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,

      /// 🤍 APPBAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF27AE60),
          ),
          onPressed: () =>
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
        ),
        title: const Text(
          'Juan La Salle',
          style: TextStyle(
            color: Color(0xFF27AE60),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Clear conversation',
            icon: const Icon(Icons.delete_outline, color: Color(0xFF27AE60)),
            onPressed: () {
              Provider.of<HandbookChatbotViewModel>(context, listen: false).clearMessages();
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: InternetRequiredNotice(featureName: 'Chatbot'),
            ),

            /// 💬 CHAT AREA
            Expanded(
              child: viewModel.messages.isEmpty
                  ? const Center(
                      child: Text(
                        "Ask me anything",
                        style: TextStyle(color: Colors.black38, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: viewModel.messages.length,
                      itemBuilder: (context, index) {
                        final msg = viewModel.messages[index];

                        return TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 300),
                          tween: Tween<double>(begin: 30, end: 0),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: (1 - (value / 30)).clamp(0, 1),
                              child: Transform.translate(
                                offset: Offset(0, value),
                                child: Transform.scale(
                                  scale: 0.98 + (0.02 * (1 - value / 30)),
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: Align(
                            alignment: msg.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.72,
                              ),
                              decoration: BoxDecoration(
                                color: msg.isUser
                                    ? const Color(0xFF27AE60)
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: msg.isUser
                                      ? const Radius.circular(16)
                                      : const Radius.circular(4),
                                  bottomRight: msg.isUser
                                      ? const Radius.circular(4)
                                      : const Radius.circular(16),
                                ),
                                border: msg.isUser
                                    ? null
                                    : Border.all(color: Colors.black12),
                                boxShadow: [
                                  if (!msg.isUser)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: msg.isUser
                                  ? Text(
                                      msg.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.text,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: GestureDetector(
                                            onTap: () async {
                                              await Clipboard.setData(
                                                ClipboardData(text: msg.text),
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Copied'),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Icon(
                                              Icons.copy_rounded,
                                              size: 16,
                                              color: Colors.black38,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            /// ⏳ TYPING DOTS (enhanced, repeating)
            if (viewModel.loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: TypingDots(),
              ),

            /// ⚠️ MINI DISCLAIMER
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                "AI may make mistakes. Verify important information.",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black38,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            /// ✏️ INPUT FIELD
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Colors.black38,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask Juan La Salle...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTapDown: (_) => setState(() => _isPressed = true),
                      onTapUp: (_) {
                        setState(() => _isPressed = false);
                        _send();
                      },
                      onTapCancel: () => setState(() => _isPressed = false),
                      child: AnimatedScale(
                        scale: _isPressed ? 0.85 : 1,
                        duration: const Duration(milliseconds: 120),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF27AE60),
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
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
          ],
        ),
      ),
    );
  }
}

/// 🔵 Repeating bouncing typing dots widget
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            double offset = (_animation.value - 0.5).abs() * -12; // bounce
            double colorValue = (_animation.value + index * 0.3) % 1; // phased color
            return Transform.translate(
              offset: Offset(0, offset),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    const Color(0xFFBDBDBD),
                    const Color(0xFF27AE60),
                    colorValue,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}