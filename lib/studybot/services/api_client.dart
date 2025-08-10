import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../config/constants.dart';
import '../backend/common/api_paths.dart';
import 'auth_service.dart';

/// Single place for HTTP calls (JSON + streaming).
/// No business logic here: repositories should call these helpers.
class ApiClient {
  final http.Client _client;
  final AuthService _auth;

  ApiClient(this._auth, {http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path) {
    // Ensure no trailing slash issues
    final base = Env.apiBaseUrl.endsWith('/')
        ? Env.apiBaseUrl.substring(0, Env.apiBaseUrl.length - 1)
        : Env.apiBaseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final token = await _auth.getIdToken();
    final resp = await _client
        .post(
          _uri(path),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(Constants.connectTimeout + Constants.receiveTimeout);

    if (resp.statusCode == 401) {
      throw ApiUnauthorized('Unauthorized');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiHttpError('HTTP ${resp.statusCode}: ${resp.body}');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiParseError('Unexpected JSON: ${resp.body}');
  }

  /// Streaming POST for endpoints like /exemplar that return chunked text.
  /// Yields UTF-8 decoded text chunks as they arrive.
  Stream<String> postStream(String path, Map<String, dynamic> body) async* {
    final token = await _auth.getIdToken();
    final req = http.Request('POST', _uri(path));
    req.headers['Content-Type'] = 'application/json';
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.body = jsonEncode(body);

    final streamed = await _client.send(req).timeout(Constants.streamFirstByteDeadline);
    if (streamed.statusCode == 401) {
      throw ApiUnauthorized('Unauthorized');
    }
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final err = await streamed.stream.bytesToString();
      throw ApiHttpError('HTTP ${streamed.statusCode}: $err');
    }

    yield* streamed.stream.transform(utf8.decoder);
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