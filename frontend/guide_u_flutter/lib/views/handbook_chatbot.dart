import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../view_models/handbook_chatbot_view_model.dart';
import 'handbook_bottom_nav_bar.dart';

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
		final viewModel = Provider.of<HandbookChatbotViewModel>(context, listen: false);
		final text = _controller.text;
		_controller.clear();
		viewModel.sendPrompt(text);
		// Scroll to bottom after a short delay to allow UI update
		Future.delayed(const Duration(milliseconds: 300), () {
			if (_scrollController.hasClients) {
				_scrollController.animateTo(
					_scrollController.position.maxScrollExtent,
					duration: const Duration(milliseconds: 300),
					curve: Curves.easeOut,
				);
			}
		});
	}

	@override
	Widget build(BuildContext context) {
		final viewModel = Provider.of<HandbookChatbotViewModel>(context);
		return Scaffold(
			appBar: AppBar(
				title: const Text('Handbook Chatbot'),
			),
			body: Column(
				children: [
					Expanded(
						child: ListView.builder(
							controller: _scrollController,
							padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
											maxWidth: MediaQuery.of(context).size.width * 0.7,
										),
										decoration: BoxDecoration(
											color: msg.isUser
													? Theme.of(
															context,
														).colorScheme.primary.withOpacity(0.8)
													: Colors.grey.shade300,
											borderRadius: BorderRadius.circular(12),
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
														crossAxisAlignment: CrossAxisAlignment.start,
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
																	icon: const Icon(Icons.copy, size: 18),
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
																					content: Text('Copied to clipboard!'),
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
					if (viewModel.loading)
						const Padding(
							padding: EdgeInsets.all(8.0),
							child: CircularProgressIndicator(),
						),
					Padding(
						padding: const EdgeInsets.all(8.0),
						child: Row(
							children: [
								Expanded(
									child: TextField(
										controller: _controller,
										onSubmitted: (_) => _send(),
										decoration: const InputDecoration(
											labelText: 'Type your message',
											border: OutlineInputBorder(),
										),
									),
								),
								const SizedBox(width: 8),
								IconButton(
									icon: const Icon(Icons.send),
									onPressed: viewModel.loading ? null : _send,
								),
							],
						),
					),
				],
			),
			// Remove the navigation bar from the chatbot screen for a cleaner UX
			// bottomNavigationBar: const HandbookBottomNavBar(currentIndex: 3),
			);
	}
}
