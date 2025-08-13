/// Single import point for all backend contracts and common types.
/// Usage:
///   import 'package:studybot/studybot/backend/backend.dart';

export 'common/api_paths.dart';
export 'common/types.dart';
export 'common/meta.dart';

// Chat (router)
export 'chat/chat_request.dart';
export 'chat/chat_response.dart';

// Grade
export 'grade/grade_request.dart';
export 'grade/grade_response.dart';

// Exemplar
export 'exemplar/exemplar_request.dart';
export 'exemplar/exemplar_response.dart'; // keep if you also support non-stream fallback

// Advice
export 'advice/advice_request.dart';
export 'advice/advice_response.dart';

// Prediction
export 'prediction/prediction_request.dart';
export 'prediction/prediction_response.dart';

// Paper
export 'paper/paper_request.dart';
export 'paper/paper_response.dart';

// Files - presign + commit
export 'files/presign/file_presign_request.dart';
export 'files/presign/file_presign_response.dart';
export 'files/commit/file_commit_request.dart';
export 'files/commit/file_commit_response.dart';
