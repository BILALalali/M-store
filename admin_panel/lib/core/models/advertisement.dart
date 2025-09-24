class Advertisement {
  final String id;
  final String title;
  final String description;
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
    required this.description,
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

  factory Advertisement.fromMap(Map<String, dynamic> map) {
    return Advertisement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['image_url'] ?? '',
      linkUrl: map['link_url'],
      isActive: map['is_active'] ?? false,
      priority: map['priority'] ?? 0,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'])
          : DateTime.now(),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      adminId: map['admin_id'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
    );
  }

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
}
