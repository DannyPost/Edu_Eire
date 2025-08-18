class AdviceRequest {
  final String subject;
  final int lookback; // number of recent graded items

  const AdviceRequest({required this.subject, this.lookback = 10});

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'lookback': lookback,
      };
}
