// lib/studybot/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class ApiClient {
  final http.Client _http = http.Client();

  ApiClient();

  Uri _uri(String keyOrPath) {
    final path = Env.resolvePath(keyOrPath);
    return Uri.parse('${Env.baseUrl}$path');
  }

  Future<Map<String, String>> _headers() async {
    final tok = await Env.token();
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (tok.isNotEmpty) h['Authorization'] = 'Bearer $tok';
    return h;
    }

  /// Primary JSON POST.
  Future<Map<String, dynamic>> post(String keyOrPath, Map<String, dynamic> body) async {
    final res = await _http.post(
      _uri(keyOrPath),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    if (res.body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      // Some Lambdas return plain text; normalize to { "text": ... }
      return {'text': res.body};
    }
  }

  /// Alias kept for backward compatibility with repository files.
  Future<Map<String, dynamic>> postJson(String keyOrPath, Map<String, dynamic> body) {
    return post(keyOrPath, body);
  }

  /// Simple GET if you need it later.
  Future<Map<String, dynamic>> get(String keyOrPath) async {
    final res = await _http.get(_uri(keyOrPath), headers: await _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    if (res.body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'text': res.body};
    }
  }
}