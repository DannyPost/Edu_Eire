/// lib/studybot/backend/common/api_paths.dart
/// Typed endpoints used by repositories.
class ApiPaths {
  static const chat        = "/chat";        // router → { decision: {route...}, ... }
  static const advice      = "/advice";      // → { text, model?, tokens? }
  static const exemplar    = "/exemplar";    // → { text, model?, tokens? }
  static const paper       = "/paper";       // → { text | sections | pdf?, model? }
  static const grade       = "/grade";       // → { score, comment, rubric?, model? }
  static const prediction  = "/prediction";  // (optional) → { label, confidence, ... }
}
