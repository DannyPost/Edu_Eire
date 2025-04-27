import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';


Future<String> fetchChatGPTResponse(String prompt) async {
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');

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
              'You are a helpful assistant for Irish secondary school students. Provide clear, friendly answers about college, CAO, SUSI, and grants.'
        },
        {'role': 'user', 'content': prompt}
      ]
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['choices'][0]['message']['content'];
  } else {
    throw Exception('Failed to get response: ${response.body}');
  }
}
