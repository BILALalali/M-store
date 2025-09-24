class WholesaleMessage {
  final String id;
  final String conversationId; // يمكن أن يكون wholesale_request_id أو conversation_id
  final String senderType; // 'user' or 'admin'
  final String senderId;
  final String type; // 'text', 'image', 'file'
  final String message;
  final String? mediaUrl;
  final DateTime createdAt;
  final bool isRead;
  
  // معلومات إضافية للمرسل
  final String? senderName;
  final String? senderAvatar;

  const WholesaleMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.senderId,
    required this.type,
    required this.message,
    this.mediaUrl,
    required this.createdAt,
    required this.isRead,
    this.senderName,
    this.senderAvatar,
  });

  // تحويل من JSON
  factory WholesaleMessage.fromJson(Map<String, dynamic> json) {
    return WholesaleMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderType: json['sender_type'] as String,
      senderId: json['sender_id'] as String,
      type: json['type'] as String? ?? 'text',
      message: json['message'] as String,
      mediaUrl: json['media_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_type': senderType,
      'sender_id': senderId,
      'type': type,
      'message': message,
      'media_url': mediaUrl,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
    };
  }

  // نسخ مع تعديل
  WholesaleMessage copyWith({
    String? id,
    String? conversationId,
    String? senderType,
    String? senderId,
    String? type,
    String? message,
    String? mediaUrl,
    DateTime? createdAt,
    bool? isRead,
    String? senderName,
    String? senderAvatar,
  }) {
    return WholesaleMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderType: senderType ?? this.senderType,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      message: message ?? this.message,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }

  // دوال مساعدة
  bool get isFromAdmin => senderType == 'admin';
  bool get isFromUser => senderType == 'user';
  bool get isTextMessage => type == 'text';
  bool get isImageMessage => type == 'image';
  bool get isFileMessage => type == 'file';

  String get displaySenderName {
    if (senderName != null && senderName!.isNotEmpty) {
      return senderName!;
    }
    return isFromAdmin ? 'فريق المبيعات' : 'العميل';
  }

  // تنسيق الوقت للعرض
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  // تنسيق الوقت المفصل
  String get detailedTime {
    final localDateTime = createdAt.toLocal();
    final now = DateTime.now().toLocal();

    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');

    // إذا كانت الرسالة من اليوم نفسه، اعرض الوقت فقط
    if (localDateTime.year == now.year &&
        localDateTime.month == now.month &&
        localDateTime.day == now.day) {
      return '$hour:$minute';
    }
    // إذا كانت الرسالة من نفس السنة، اعرض التاريخ والوقت
    else if (localDateTime.year == now.year) {
      return '${localDateTime.day.toString().padLeft(2, '0')}/${localDateTime.month.toString().padLeft(2, '0')} $hour:$minute';
    }
    // إذا كانت الرسالة من سنة مختلفة، اعرض التاريخ الكامل والوقت
    else {
      return '${localDateTime.day.toString().padLeft(2, '0')}/${localDateTime.month.toString().padLeft(2, '0')}/${localDateTime.year} $hour:$minute';
    }
  }
}
