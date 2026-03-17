import 'package:flutter/foundation.dart';
import 'package:guide_u_flutter/services/rag_service.dart';

class ChatMessage {
	final String text;
	final bool isUser;
	ChatMessage({required this.text, required this.isUser});
}

class HandbookChatbotViewModel extends ChangeNotifier {
	final GuideURagService _ragService = GuideURagService();

	final List<ChatMessage> _messages = [];
	List<ChatMessage> get messages => List.unmodifiable(_messages);

	bool _loading = false;
	bool get loading => _loading;

	Future<void> sendPrompt(String prompt) async {
		if (prompt.trim().isEmpty) return;
		_messages.add(ChatMessage(text: prompt, isUser: true));
		_loading = true;
		notifyListeners();
		try {
			final res = await _ragService.askQuestion(prompt);
			if (_isQuotaError(res)) {
				// Print the error to the console for debugging
				debugPrint('Quota/rate-limit error intercepted:');
				debugPrint(res);
				_messages.add(
					ChatMessage(
						text:
								"I'm thinking a lot right now! Please wait a moment before asking another question so I can give you my best answer.",
						isUser: false,
					),
				);
			} else {
				_messages.add(ChatMessage(text: res, isUser: false));
			}
		} catch (e) {
			_messages.add(
				ChatMessage(
					text: 'Sorry, I need a short break. Please try again soon!',
					isUser: false,
				),
			);
		} finally {
			_loading = false;
			notifyListeners();
		}
	}

	bool _isQuotaError(String res) {
		final lower = res.toLowerCase();
		return lower.contains('quota exceeded') ||
				lower.contains('rate-limits') ||
				lower.contains('please retry in') ||
				lower.contains('plan and billing details') ||
				lower.contains('limit: 20, model: gemini');
	}
}
