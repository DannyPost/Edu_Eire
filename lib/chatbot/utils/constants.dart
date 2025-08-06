import 'package:flutter_dotenv/flutter_dotenv.dart';

final String openAIApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
