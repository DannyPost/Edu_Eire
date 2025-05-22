import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart'; // If you use constants here, otherwise remove
import '../utils/logger.dart';   // Import the logger to access the log

final String openAIApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

Future<String> fetchChatGPTResponse(String prompt) async {
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');

  // Step 1: Load chat log and trim last 15 lines
  String context = await ChatLogger.getLog();
  List<String> lines = context.trim().split('\n');

  final lastFewLines = lines.length > 15 ? lines.sublist(lines.length - 15) : lines;
  final historyContext = lastFewLines.join('\n');

  // Step 2: Send context + user prompt to OpenAI
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $openAIApiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'gpt-4',
      'messages': [
        {
          'role': 'system',
          'content':
              "You are a helpful assistant for Irish secondary school students."
              "You have access to part of the previous chat history."
              "Use it to provide continuity where useful. Keep meesages brief." 
              "When giving  user information   always give  facts and figures on any grant or program if it is relevant"
              "If somene asks for college recomandations give a list of colleges relevant to them"
        },
        {
          'role': 'user',
          'content': 'Previous chat log:\n$historyContext'
        },
        {
          'role': 'user',
          'content': prompt
        }
      ]
    }),
  );

  // Step 3: Handle response
  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['choices'][0]['message']['content'];
  } else {
    throw Exception('Failed to get response: ${response.body}');
  }
}
