/// Common shared types & helpers used across backend contracts.
library;

/// Shorthand for JSON maps.
typedef Json = Map<String, dynamic>;

/// All routed task types the backend can return.
/// Keep this aligned with your router (`/chat`) and backend prompts.
enum TaskType {
  grade,
  exemplar,
  advice,
  prediction,
  paper,
  fallback,
}

extension TaskTypeString on TaskType {
  String get value {
    switch (this) {
      case TaskType.grade:
        return 'grade';
      case TaskType.exemplar:
        return 'exemplar';
      case TaskType.advice:
        return 'advice';
      case TaskType.prediction:
        return 'prediction';
      case TaskType.paper:
        return 'paper';
      case TaskType.fallback:
        return 'fallback';
    }
  }

  static TaskType from(String raw) {
    switch (raw) {
      case 'grade':
        return TaskType.grade;
      case 'exemplar':
        return TaskType.exemplar;
      case 'advice':
        return TaskType.advice;
      case 'prediction':
        return TaskType.prediction;
      case 'paper':
        return TaskType.paper;
      default:
        return TaskType.fallback;
    }
  }
}

/// Useful enums if you want to type metadata further.
/// (Optional — keep only what you’ll actually use.)
enum Level { HL, OL }

extension LevelString on Level {
  String get value => this == Level.HL ? 'HL' : 'OL';
  static Level? from(String? raw) {
    if (raw == null) return null;
    return raw.toUpperCase() == 'HL' ? Level.HL : Level.OL;
  }
}
