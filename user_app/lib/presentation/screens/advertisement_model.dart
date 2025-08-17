class Advertisement {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? linkUrl;
  final bool isActive;
  final int priority;
  final DateTime startDate;
  final DateTime? endDate;
  final String? adminId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Advertisement({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.linkUrl,
    required this.isActive,
    required this.priority,
    required this.startDate,
    this.endDate,
    this.adminId,
    required this.createdAt,
    required this.updatedAt,
  });

  // إنشاء إعلان من بيانات قاعدة البيانات
  factory Advertisement.fromMap(Map<String, dynamic> map) {
    return Advertisement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String,
      linkUrl: map['link_url'] as String?,
      isActive: map['is_active'] as bool,
      priority: map['priority'] as int,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      adminId: map['admin_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // تحويل الإعلان إلى map لحفظه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'is_active': isActive,
      'priority': priority,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'admin_id': adminId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // نسخ الإعلان مع تعديلات
  Advertisement copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? linkUrl,
    bool? isActive,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    String? adminId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Advertisement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // التحقق من أن الإعلان صالح (نشط وفي التاريخ المحدد)
  bool get isValid {
    if (!isActive) return false;

    final now = DateTime.now();
    if (now.isBefore(startDate)) return false;

    if (endDate != null && now.isAfter(endDate!)) return false;

    return true;
  }
}
