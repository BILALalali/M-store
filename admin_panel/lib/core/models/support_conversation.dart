class SupportConversation {
  final String id;
  final String userId;
  final String status;
  final bool isOpen;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userEmail;
  final String? userName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  SupportConversation({
    required this.id,
    required this.userId,
    required this.status,
    required this.isOpen,
    required this.createdAt,
    required this.updatedAt,
    this.userEmail,
    this.userName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory SupportConversation.fromMap(Map<String, dynamic> map) {
    return SupportConversation(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      status: map['status'] ?? 'open',
      isOpen: map['is_open'] ?? true,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      userEmail: map['user_email'],
      userName: map['user_name'],
      lastMessage: map['last_message'],
      lastMessageAt: map['last_message_at'] != null 
          ? DateTime.parse(map['last_message_at']) 
          : null,
      unreadCount: map['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'is_open': isOpen,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_email': userEmail,
      'user_name': userName,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
    };
  }

  SupportConversation copyWith({
    String? id,
    String? userId,
    String? status,
    bool? isOpen,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userEmail,
    String? userName,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return SupportConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      isOpen: isOpen ?? this.isOpen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  String toString() {
    return 'SupportConversation(id: $id, userId: $userId, status: $status, isOpen: $isOpen, createdAt: $createdAt, updatedAt: $updatedAt, userEmail: $userEmail, userName: $userName, lastMessage: $lastMessage, lastMessageAt: $lastMessageAt, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupportConversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
