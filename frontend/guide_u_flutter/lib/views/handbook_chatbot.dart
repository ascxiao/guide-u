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

  void _send() {
    final viewModel = Provider.of<HandbookChatbotViewModel>(
      context,
      listen: false,
    );

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    viewModel.sendPrompt(text);

    // Smooth auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HandbookChatbotViewModel>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
          tooltip: 'Back',
        ),
        title: const Text(
          'Handbook Chatbot',
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
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: InternetRequiredNotice(featureName: 'Chatbot'),
            ),

            /// 💬 CHAT AREA
            Expanded(
              child: viewModel.messages.isEmpty
                  ? const Center(
                      child: Text(
                        "Ask me anything about the handbook",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      physics: const BouncingScrollPhysics(),
                      itemCount: viewModel.messages.length,
                      itemBuilder: (context, index) {
                        final msg = viewModel.messages[index];

                        return Align(
                          alignment: msg.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: msg.isUser
                                  ? const Color(0xFF006633)
                                  : Colors.grey.shade200,
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
                            ),
                            child: msg.isUser
                                ? Text(
                                    msg.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
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
                                          fontSize: 16,
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.copy,
                                            size: 18,
                                          ),
                                          tooltip: 'Copy',
                                          onPressed: () async {
                                            await Clipboard.setData(
                                              ClipboardData(text: msg.text),
                                            );

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Copied to clipboard!',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
            ),

            /// ⏳ TYPING INDICATOR
            if (viewModel.loading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    SizedBox(width: 8),
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(width: 12),
                    Text("Thinking..."),
                  ],
                ),
              ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Text(
                'Disclaimer: The chatbot can make mistakes. Please verify important information.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            /// ✏️ INPUT FIELD
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask something...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF006633)),
                      onPressed: viewModel.loading ? null : _send,
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
