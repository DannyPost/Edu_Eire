// lib/studybot/services/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../config/constants.dart';
import 'auth_service.dart';

/// Single place for HTTP calls (JSON + streaming).
class ApiClient {
  final http.Client _client;
  final AuthService _auth;

  ApiClient(this._auth, {http.Client? client}) : _client = client ?? http.Client() {
    // Helpful at startup:
    // ignore: avoid_print
    print('ApiClient → Env.apiBaseUrl = ${Env.apiBaseUrl}');
  }

  Uri _uri(String path) {
    final base = Env.apiBaseUrl.endsWith('/')
        ? Env.apiBaseUrl.substring(0, Env.apiBaseUrl.length - 1)
        : Env.apiBaseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  // Lightweight request id (safe on web)
  String _requestId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rnd = Random().nextInt(0x7fffffff).toRadixString(16).padLeft(8, '0'); // <= 2^31-1
    return 'req_${ts}_$rnd';
  }

  Map<String, String> _baseHeaders({String? token}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'x-api-version': '2025-10-05',
      'x-client': 'studybot-flutter',
      'x-request-id': _requestId(),
    };
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Future<http.Response> _authedPost(Uri uri, Map<String, dynamic> body) async {
    String? token = await _auth.getIdToken();
    var resp = await _client
        .post(uri, headers: _baseHeaders(token: token), body: jsonEncode(body))
        .timeout(Constants.connectTimeout + Constants.receiveTimeout);

    // Retry once on 401 (fresh token fetch)
    if (resp.statusCode == 401) {
      token = await _auth.getIdToken();
      resp = await _client
          .post(uri, headers: _baseHeaders(token: token), body: jsonEncode(body))
          .timeout(Constants.connectTimeout + Constants.receiveTimeout);
    }
    return resp;
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final resp = await _authedPost(_uri(path), body);

    if (resp.statusCode == 401) throw ApiUnauthorized('Unauthorized');
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiHttpError('HTTP ${resp.statusCode}: ${resp.body}');
    }

    final raw = resp.body.isEmpty ? '{}' : resp.body;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiParseError('Unexpected JSON: ${resp.body}');
  }

  /// Streaming helper (kept for future SSE enablement).
  Stream<String> postStream(String path, Map<String, dynamic> body) async* {
    String? token = await _auth.getIdToken();
    final req = http.Request('POST', _uri(path));
    req.headers.addAll(_baseHeaders(token: token));
    req.body = jsonEncode(body);

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(req).timeout(Constants.streamFirstByteDeadline);
    } on TimeoutException {
      throw ApiHttpError('Stream start timeout');
    }

    if (streamed.statusCode == 401) {
      token = await _auth.getIdToken(); // retry once
      final retry = http.Request('POST', _uri(path));
      retry.headers.addAll(_baseHeaders(token: token));
      retry.body = jsonEncode(body);
      streamed = await _client.send(retry).timeout(Constants.streamFirstByteDeadline);
    }

    if (streamed.statusCode == 401) throw ApiUnauthorized('Unauthorized');
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final err = await streamed.stream.bytesToString();
      throw ApiHttpError('HTTP ${streamed.statusCode}: $err');
    }

    final contentType = streamed.headers['content-type'] ?? '';
    final textStream = streamed.stream.transform(utf8.decoder);

    if (contentType.contains('text/event-stream')) {
      // Minimal SSE parsing: emit concatenated data lines per event.
      await for (final chunk in textStream) {
        final events = chunk.split('\n\n');
        for (final evt in events) {
          if (evt.trim().isEmpty) continue;
          final dataLines = <String>[];
          for (final line in evt.split('\n')) {
            if (line.startsWith('data:')) {
              dataLines.add(line.substring(5).trimLeft());
            }
          }
          if (dataLines.isNotEmpty) yield dataLines.join('\n');
        }
      }
    } else {
      yield* textStream;
    }
  }

  /// PUT to a presigned URL for uploads (no auth header from us).
  Future<void> putPresigned(String url, List<int> bytes, {Map<String, String>? headers}) async {
    final resp = await _client
        .put(Uri.parse(url), headers: headers, body: bytes)
        .timeout(Constants.connectTimeout + Constants.receiveTimeout);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiHttpError('Upload failed: HTTP ${resp.statusCode} ${resp.body}');
    }
  }

  void close() => _client.close();
}

// Lightweight error types for better UI handling
class ApiUnauthorized implements Exception {
  final String message;
  ApiUnauthorized(this.message);
  @override
  String toString() => 'ApiUnauthorized: $message';
}

class ApiHttpError implements Exception {
  final String message;
  ApiHttpError(this.message);
  @override
  String toString() => 'ApiHttpError: $message';
}

class ApiParseError implements Exception {
  final String message;
  ApiParseError(this.message);
  @override
  String toString() => 'ApiParseError: $message';
}
