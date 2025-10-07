class OrderThread {
  final String id;
  final String userId;
  final String title;
  final String? productNames;
  final String? summary;
  final String orderType;
  final String status;
  final String? imageUrl;
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
  
  // معلومات تفاعل المشرف
  final bool hasAdminMessage; // هل أرسل المشرف أي رسالة؟
  final DateTime? firstAdminMessageAt; // تاريخ أول رسالة من المشرف

  const OrderThread({
    required this.id,
    required this.userId,
    required this.title,
    this.productNames,
    this.summary,
    required this.orderType,
    required this.status,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userEmail,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.hasUnreadMessages = false,
    this.hasAdminMessage = false,
    this.firstAdminMessageAt,
  });

  // تحويل من JSON
  factory OrderThread.fromJson(Map<String, dynamic> json) {
    return OrderThread(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      productNames: json['product_names'] as String?,
      summary: json['summary'] as String?,
      orderType: json['order_type'] as String,
      status: json['status'] as String,
      imageUrl: json['image_url'] as String?,
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
      hasAdminMessage: json['has_admin_message'] as bool? ?? false,
      firstAdminMessageAt: json['first_admin_message_at'] != null
          ? DateTime.parse(json['first_admin_message_at'] as String)
          : null,
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'product_names': productNames,
      'summary': summary,
      'order_type': orderType,
      'status': status,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_name': userName,
      'user_email': userEmail,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'has_unread_messages': hasUnreadMessages,
      'has_admin_message': hasAdminMessage,
      'first_admin_message_at': firstAdminMessageAt?.toIso8601String(),
    };
  }

  // نسخ مع تعديل
  OrderThread copyWith({
    String? id,
    String? userId,
    String? title,
    String? productNames,
    String? summary,
    String? orderType,
    String? status,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userEmail,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? hasUnreadMessages,
    bool? hasAdminMessage,
    DateTime? firstAdminMessageAt,
  }) {
    return OrderThread(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      productNames: productNames ?? this.productNames,
      summary: summary ?? this.summary,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      hasAdminMessage: hasAdminMessage ?? this.hasAdminMessage,
      firstAdminMessageAt: firstAdminMessageAt ?? this.firstAdminMessageAt,
    );
  }

  // دوال مساعدة للواجهة
  String get displayTitle {
    return title.isNotEmpty ? title : 'طلب ${id.substring(0, 8)}';
  }

  String get displayUserName {
    return userName ?? 'مستخدم ${userId.substring(0, 8)}';
  }

  String get displayOrderType {
    switch (orderType) {
      case 'retail':
        return 'تجزئة';
      case 'delivery':
        return 'توصيل';
      case 'mobileCredit':
        return 'رصيد جوال';
      default:
        return orderType;
    }
  }

  String get displayStatus {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'processing':
        return 'قيد المعالجة';
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
      case 'processing':
        return 'info';
      case 'completed':
        return 'success';
      case 'cancelled':
        return 'error';
      default:
        return 'primary';
    }
  }

  // أيقونة النوع
  String get typeIcon {
    switch (orderType) {
      case 'retail':
        return 'shopping_cart';
      case 'delivery':
        return 'local_shipping';
      case 'mobileCredit':
        return 'phone_android';
      default:
        return 'shopping_bag';
    }
  }

  // تحديد ما إذا كان الطلب جديد (لم يرسل له المشرف رسالة)
  bool get isNewOrder {
    return !hasAdminMessage;
  }

  // تحديد ما إذا كان الطلب يحتاج إلى رد من المشرف
  bool get needsAdminResponse {
    return !hasAdminMessage && hasUnreadMessages;
  }
}
