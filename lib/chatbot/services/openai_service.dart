import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

final String openAIApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

Future<String> fetchChatGPTResponse(String prompt) async {
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');

  // Load and trim last 15 lines of chat history for context
  String context = await ChatLogger.getLog();
  List<String> lines = context.trim().split('\n');
  final lastFewLines = lines.length > 15 ? lines.sublist(lines.length - 15) : lines;
  final historyContext = lastFewLines.join('\n');

  final systemPrompt = """
You are Eoin, a helpful assistant for Irish secondary school students planning their future.

Your role:
- Provide accurate, factual answers to questions about:
  • The CAO application process
  • SUSI grant and financial aid
  • Irish universities and courses
  • Points requirements and eligibility
  • PLCs and alternative pathways

Guidelines:
1. Always include facts and figures. (e.g., "Nursing at DCU requires around 480 CAO points.")
2. When possible, include exact websites to continue the search (e.g., cao.ie, susi.ie).
3. Keep answers brief but informative — no fluff.
4. If a student asks what to do next, provide clear next steps.
5. Never invent information — if unsure, say "Check on susi.ie or ask your guidance counselor."
6. Prioritize Irish context over general advice.
""";

  final requestPayload = {
    'model': 'gpt-4',
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': 'Previous chat log:\n$historyContext'},
      {'role': 'user', 'content': prompt},
    ]
  };

  final encodedBody = jsonEncode(requestPayload);

  // Optional: Estimate token usage (rough approximation)
  final estimatedTokens = (encodedBody.length / 4).ceil();
  print('[Token Estimate] Sending ~${estimatedTokens} tokens');

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $openAIApiKey',
      'Content-Type': 'application/json',
    },
    body: encodedBody,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['choices'][0]['message']['content'];
  } else {
    throw Exception('Failed to get response: ${response.body}');
  }
}
