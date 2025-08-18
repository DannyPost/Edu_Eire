import '../backend/backend.dart';
import 'api_client.dart';

/// Two-step upload: presign -> PUT -> commit.
/// Repositories can compose these calls as needed.
class FileUploadService {
  final ApiClient _api;

  FileUploadService(this._api);

  Future<FilePresignResponse> presign(FilePresignRequest req) async {
    final json = await _api.postJson(ApiPaths.filePresign, req.toJson());
    return FilePresignResponse.fromJson(json);
  }

  Future<void> upload(String url, List<int> bytes, {Map<String, String>? headers}) {
    return _api.putPresigned(url, bytes, headers: headers);
  }

  Future<FileCommitResponse> commit(FileCommitRequest req) async {
    final json = await _api.postJson(ApiPaths.fileCommit, req.toJson());
    return FileCommitResponse.fromJson(json);
  }
}
