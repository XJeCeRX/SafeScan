enum ChatRole { user, assistant, system }

enum ChatMessageStatus { sending, streaming, sent, error }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final ChatMessageStatus status;
  final bool includesSensorData;
  final String? errorMessage;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = ChatMessageStatus.sent,
    this.includesSensorData = false,
    this.errorMessage,
  });

  bool get isUser => role == ChatRole.user;
  bool get isAssistant => role == ChatRole.assistant;
  bool get isStreaming => status == ChatMessageStatus.streaming;
  bool get hasError => status == ChatMessageStatus.error;

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? createdAt,
    ChatMessageStatus? status,
    bool? includesSensorData,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      includesSensorData: includesSensorData ?? this.includesSensorData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'status': status.name,
    'includes_sensor_data': includesSensorData,
    if (errorMessage != null) 'error_message': errorMessage,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: ChatRole.values.byName(json['role'] as String),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      status: ChatMessageStatus.values.byName(
        json['status'] as String? ?? 'sent',
      ),
      includesSensorData: json['includes_sensor_data'] as bool? ?? false,
      errorMessage: json['error_message'] as String?,
    );
  }
}
