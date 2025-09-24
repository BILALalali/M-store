class SupportConversation {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userEmail;
  final String? userName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool hasUnreadMessages; // إضافة حقل للرسائل غير المقروءة

  SupportConversation({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.userEmail,
    this.userName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.hasUnreadMessages = false, // افتراضياً لا توجد رسائل غير مقروءة
  });

  factory SupportConversation.fromMap(Map<String, dynamic> map) {
    return SupportConversation(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      userEmail: map['user_email'],
      userName: map['user_name'],
      lastMessage: map['last_message'],
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'])
          : null,
      unreadCount: map['unread_count'] ?? 0,
      hasUnreadMessages:
          (map['unread_count'] ?? 0) > 0, // تحديد وجود رسائل غير مقروءة
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_email': userEmail,
      'user_name': userName,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'has_unread_messages': hasUnreadMessages,
    };
  }

  SupportConversation copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userEmail,
    String? userName,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? hasUnreadMessages,
  }) {
    return SupportConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
    );
  }

  @override
  String toString() {
    return 'SupportConversation(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, userEmail: $userEmail, userName: $userName, lastMessage: $lastMessage, lastMessageAt: $lastMessageAt, unreadCount: $unreadCount, hasUnreadMessages: $hasUnreadMessages)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupportConversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
