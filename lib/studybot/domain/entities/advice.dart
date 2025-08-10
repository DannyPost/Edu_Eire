/// Domain entity representing one actionable advice item for the student.
class AdviceItem {
  final String skill;   // e.g., "Theme Analysis"
  final String reason;  // e.g., "Low scores in last 4 answers"
  final String action;  // e.g., "Practice identifying themes with 2 sample essays"

  const AdviceItem({
    required this.skill,
    required this.reason,
    required this.action,
  });

  AdviceItem copyWith({
    String? skill,
    String? reason,
    String? action,
  }) {
    return AdviceItem(
      skill: skill ?? this.skill,
      reason: reason ?? this.reason,
      action: action ?? this.action,
    );
  }

  @override
  String toString() => 'AdviceItem(skill: $skill, reason: $reason, action: $action)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdviceItem &&
          runtimeType == other.runtimeType &&
          skill == other.skill &&
          reason == other.reason &&
          action == other.action;

  @override
  int get hashCode => skill.hashCode ^ reason.hashCode ^ action.hashCode;
}
