class FilePresignResponse {
  final String url;
  final Map<String, String> headers;

  const FilePresignResponse({required this.url, required this.headers});

  factory FilePresignResponse.fromJson(Map<String, dynamic> json) =>
      FilePresignResponse(
        url: json['url'] as String,
        headers: (json['headers'] as Map)
            .map((k, v) => MapEntry(k.toString(), v.toString())),
      );
}
