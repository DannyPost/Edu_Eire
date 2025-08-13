class AdviceItem {
  final String skill;
  final String reason;
  final String action;

  const AdviceItem({
    required this.skill,
    required this.reason,
    required this.action,
  });

  factory AdviceItem.fromJson(Map<String, dynamic> json) => AdviceItem(
        skill: json['skill'] as String,
        reason: json['reason'] as String,
        action: json['action'] as String,
      );

  Map<String, dynamic> toJson() => {
        'skill': skill,
        'reason': reason,
        'action': action,
      };
}

class AdviceResponse {
  final List<AdviceItem> advice;

  const AdviceResponse({required this.advice});

  factory AdviceResponse.fromJson(Map<String, dynamic> json) => AdviceResponse(
        advice: (json['advice'] as List)
            .map((e) => AdviceItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}
