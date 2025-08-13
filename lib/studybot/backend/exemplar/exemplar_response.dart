/// Used only if you choose a non-streaming response for exemplar.
/// For streaming, you won't use this—your stream handler will collect text.
class ExemplarResponse {
  final String text;

  const ExemplarResponse({required this.text});

  factory ExemplarResponse.fromJson(Map<String, dynamic> json) =>
      ExemplarResponse(text: json['text'] as String);
}
