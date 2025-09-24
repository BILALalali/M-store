class MobilePackage {
  final int? id;
  final int operatorId;
  final String packageName;
  final double packageValue;
  final double packagePrice;
  final String? descriptionAr;
  final String? descriptionEn;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MobilePackage({
    this.id,
    required this.operatorId,
    required this.packageName,
    required this.packageValue,
    required this.packagePrice,
    this.descriptionAr,
    this.descriptionEn,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  // إنشاء باقة من Map (من قاعدة البيانات)
  factory MobilePackage.fromMap(Map<String, dynamic> map) {
    return MobilePackage(
      id: map['id'],
      operatorId: map['operator_id'] ?? 0,
      packageName: map['package_name'] ?? '',
      packageValue: (map['package_value'] ?? 0.0).toDouble(),
      packagePrice: (map['package_price'] ?? 0.0).toDouble(),
      descriptionAr: map['description_ar'],
      descriptionEn: map['description_en'],
      isActive: map['is_active'] ?? true,
      sortOrder: map['sort_order'] ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  // تحويل الباقة إلى Map (لحفظها في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'operator_id': operatorId,
      'package_name': packageName,
      'package_value': packageValue,
      'package_price': packagePrice,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      if (descriptionEn != null) 'description_en': descriptionEn,
      'is_active': isActive,
      'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // نسخ الباقة مع تحديث بعض الحقول
  MobilePackage copyWith({
    int? id,
    int? operatorId,
    String? packageName,
    double? packageValue,
    double? packagePrice,
    String? descriptionAr,
    String? descriptionEn,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MobilePackage(
      id: id ?? this.id,
      operatorId: operatorId ?? this.operatorId,
      packageName: packageName ?? this.packageName,
      packageValue: packageValue ?? this.packageValue,
      packagePrice: packagePrice ?? this.packagePrice,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'MobilePackage(id: $id, packageName: $packageName, packageValue: $packageValue, packagePrice: $packagePrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MobilePackage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class MobileOperator {
  final int? id;
  final String name;
  final String displayNameAr;
  final String displayNameEn;
  final String? logoUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MobileOperator({
    this.id,
    required this.name,
    required this.displayNameAr,
    required this.displayNameEn,
    this.logoUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // إنشاء مشغل من Map (من قاعدة البيانات)
  factory MobileOperator.fromMap(Map<String, dynamic> map) {
    return MobileOperator(
      id: map['id'],
      name: map['name'] ?? '',
      displayNameAr: map['display_name_ar'] ?? '',
      displayNameEn: map['display_name_en'] ?? '',
      logoUrl: map['logo_url'],
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  // تحويل المشغل إلى Map (لحفظه في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'display_name_ar': displayNameAr,
      'display_name_en': displayNameEn,
      if (logoUrl != null) 'logo_url': logoUrl,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // نسخ المشغل مع تحديث بعض الحقول
  MobileOperator copyWith({
    int? id,
    String? name,
    String? displayNameAr,
    String? displayNameEn,
    String? logoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MobileOperator(
      id: id ?? this.id,
      name: name ?? this.name,
      displayNameAr: displayNameAr ?? this.displayNameAr,
      displayNameEn: displayNameEn ?? this.displayNameEn,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'MobileOperator(id: $id, name: $name, displayNameAr: $displayNameAr)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MobileOperator && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
