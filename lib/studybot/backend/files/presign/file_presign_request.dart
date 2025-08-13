class FilePresignRequest {
  final String filename;
  final String contentType;

  const FilePresignRequest({required this.filename, required this.contentType});

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'contentType': contentType,
      };
}
