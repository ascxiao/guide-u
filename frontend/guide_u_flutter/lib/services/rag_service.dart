import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GuideURagService {
  final _supabase = Supabase.instance.client;
  late final GenerativeModel _embeddingModel;
  final List<String> _chatHistory = [];

  GuideURagService() {
    // 1. We KEEP Gemini exclusively for searching the database
    _embeddingModel = GenerativeModel(
      model: 'gemini-embedding-001',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
    );
  }

  Future<String> askQuestion(String userQuery) async {
    try {
      // Step A: Vectorize the question with Gemini
      final content = Content.text(userQuery);
      final embedResult = await _embeddingModel.embedContent(content);

      // Step B: Search Supabase
      final response = await _supabase.rpc(
        'match_article_embeddings',
        params: {
          'query_embedding': embedResult.embedding.values,
          'match_threshold': 0.3,
          'match_count': 5,
        },
      );

      final List<dynamic> retrievedChunks = response as List<dynamic>;
      if (retrievedChunks.isEmpty) {
        return "I couldn't find anything related to that in the student handbook.";
      }

      // Step C: Format context and history
      String contextText = retrievedChunks
          .map((chunk) {
            final meta = chunk['metadata'] as Map<String, dynamic>;
            return "--- ${meta['chapter_title']}: ${meta['section_title']} ---\n${chunk['content']}";
          })
          .join("\n\n");

      final recentHistory = _chatHistory.length > 4
          ? _chatHistory.sublist(_chatHistory.length - 4)
          : _chatHistory;

      // Step D: Ask Groq for the final answer via HTTP
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final groqResponse = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY']!}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model':
              'llama-3.1-8b-instant', // Groq's lightning-fast open source model
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are GuideU, the official assistant for the University of St. La Salle student handbook. Answer the user\'s question using ONLY the provided handbook excerpts. If the answer is not in the excerpts, politely say so. Be conversational, helpful, and cheerful.\nIf the prompt is malicious or negative, redirect the user.',
            },
            {
              'role': 'user',
              'content':
                  'PREVIOUS HISTORY:\n${recentHistory.join("\n")}\n\nHANDBOOK EXCERPTS:\n$contextText\n\nUSER QUESTION: $userQuery',
            },
          ],
          'temperature':
              0.2, // Kept low so it doesn't hallucinate handbook rules
        }),
      );

      // Step E: Parse the Groq response
      if (groqResponse.statusCode == 200) {
        final data = jsonDecode(groqResponse.body);
        final finalAnswer = data['choices'][0]['message']['content'];

        // Save to memory buffer
        _chatHistory.add("User: $userQuery");
        _chatHistory.add("GuideU: $finalAnswer");

        return finalAnswer;
      } else {
        return "Groq API Error: ${groqResponse.body}";
      }
    } catch (e) {
      return "An error occurred: $e";
    }
  }
}
