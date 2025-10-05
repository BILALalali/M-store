class WholesaleRequest {
  final String id;
  final String userId;
  final String productName;
  final String description;
  final int quantity;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // معلومات إضافية للمستخدم
  final String? userName;
  final String? userEmail;

  // معلومات المحادثة
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool hasUnreadMessages;

  const WholesaleRequest({
    required this.id,
    required this.userId,
    required this.productName,
    required this.description,
    required this.quantity,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userEmail,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.hasUnreadMessages = false,
  });

  // تحويل من JSON
  factory WholesaleRequest.fromJson(Map<String, dynamic> json) {
    return WholesaleRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productName: json['product_name'] as String,
      description: json['description'] as String,
      quantity: json['quantity'] as int? ?? 1,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      hasUnreadMessages: json['has_unread_messages'] as bool? ?? false,
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_name': productName,
      'description': description,
      'quantity': quantity,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_name': userName,
      'user_email': userEmail,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'has_unread_messages': hasUnreadMessages,
    };
  }

  // نسخ مع تعديل
  WholesaleRequest copyWith({
    String? id,
    String? userId,
    String? productName,
    String? description,
    int? quantity,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userEmail,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? hasUnreadMessages,
  }) {
    return WholesaleRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
    );
  }

  // دوال مساعدة للواجهة
  String get displayTitle {
    return productName.isNotEmpty
        ? productName
        : 'طلب جملة ${id.substring(0, 8)}';
  }

  String get displayUserName {
    return userName ?? 'مستخدم ${userId.substring(0, 8)}';
  }

  String get displayDescription {
    return description.isNotEmpty ? description : 'لا يوجد وصف';
  }

  String get displayQuantity {
    return 'الكمية: $quantity قطعة';
  }

  String get displayStatus {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'under_review':
        return 'قيد الدراسة';
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغى';
      default:
        return status;
    }
  }

  // ألوان الحالة
  String get statusColor {
    switch (status) {
      case 'pending':
        return 'warning';
      case 'under_review':
        return 'info';
      case 'approved':
        return 'success';
      case 'rejected':
        return 'error';
      case 'completed':
        return 'success';
      case 'cancelled':
        return 'error';
      default:
        return 'primary';
    }
  }

  // أيقونة الحالة
  String get statusIcon {
    switch (status) {
      case 'pending':
        return 'hourglass_empty';
      case 'under_review':
        return 'search';
      case 'approved':
        return 'check_circle';
      case 'rejected':
        return 'cancel';
      case 'completed':
        return 'check_circle_outline';
      case 'cancelled':
        return 'highlight_off';
      default:
        return 'help_outline';
    }
  }

  // تحديد أولوية العرض
  int get priority {
    switch (status) {
      case 'pending':
        return 1; // أعلى أولوية
      case 'under_review':
        return 2;
      case 'approved':
        return 3;
      case 'rejected':
        return 4;
      case 'completed':
        return 5;
      case 'cancelled':
        return 6; // أقل أولوية
      default:
        return 7;
    }
  }

  // تنسيق موجز للطلب
  String get summary {
    return 'طلب $quantity قطعة من $productName';
  }
}
