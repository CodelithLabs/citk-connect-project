class AIResponse {
  final String text;
  final DateTime timestamp;
  final String? sessionId;
  final Map<String, dynamic>? metadata;

  AIResponse({
    required this.text,
    required this.timestamp,
    this.sessionId,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'sessionId': sessionId,
    'metadata': metadata,
  };
}