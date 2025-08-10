class FileCommitResponse {
  final String status; // "committed"
  final bool ingestionQueued;

  const FileCommitResponse({required this.status, required this.ingestionQueued});

  factory FileCommitResponse.fromJson(Map<String, dynamic> json) =>
      FileCommitResponse(
        status: json['status'] as String,
        ingestionQueued: json['ingestionQueued'] as bool,
      );
}
