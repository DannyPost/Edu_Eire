class FileCommitRequest {
  final String filename;
  final String s3Key;
  final Map<String, dynamic>? meta;

  const FileCommitRequest({
    required this.filename,
    required this.s3Key,
    this.meta,
  });

  Map<String, dynamic> toJson() => {
        'filename': filename,
        's3Key': s3Key,
        if (meta != null) 'meta': meta,
      };
}
