class SupportMessage {
  final String id;
  final String conversationId;
  final String senderType; // 'user' or 'admin'
  final String senderId;
  final String type; // 'text' or 'image'
  final String message;
  final String? mediaUrl;
  final DateTime createdAt;
  final String? senderName;
  final String? senderAvatar;
  final bool isRead; // true = مقروءة, false = غير مقروءة

  SupportMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.senderId,
    required this.type,
    required this.message,
    this.mediaUrl,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
    this.isRead = false, // افتراضياً غير مقروءة
  });

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      id: map['id'] ?? '',
      conversationId: map['conversation_id'] ?? '',
      senderType: map['sender_type'] ?? 'user',
      senderId: map['sender_id'] ?? '',
      type: map['type'] ?? 'text',
      message: map['message'] ?? '',
      mediaUrl: map['media_url'],
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      senderName: map['sender_name'],
      senderAvatar: map['sender_avatar'],
      isRead: map['is_read'] ?? false, // افتراضياً غير مقروءة
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_type': senderType,
      'sender_id': senderId,
      'type': type,
      'message': message,
      'media_url': mediaUrl,
      'created_at': createdAt.toIso8601String(),
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'is_read': isRead,
    };
  }

  SupportMessage copyWith({
    String? id,
    String? conversationId,
    String? senderType,
    String? senderId,
    String? type,
    String? message,
    String? mediaUrl,
    DateTime? createdAt,
    String? senderName,
    String? senderAvatar,
    bool? isRead,
  }) {
    return SupportMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderType: senderType ?? this.senderType,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      message: message ?? this.message,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      isRead: isRead ?? this.isRead,
    );
  }

  bool get isFromUser => senderType == 'user';
  bool get isFromAdmin => senderType == 'admin';
  bool get isTextMessage => type == 'text';
  bool get isImageMessage => type == 'image';

  @override
  String toString() {
    return 'SupportMessage(id: $id, conversationId: $conversationId, senderType: $senderType, senderId: $senderId, type: $type, message: $message, mediaUrl: $mediaUrl, createdAt: $createdAt, senderName: $senderName, senderAvatar: $senderAvatar, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupportMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
