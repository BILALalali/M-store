class GameCard {
  final int? id;
  final int? providerId;
  final String? cardName;
  final double? cardValue;
  final double? cardPrice;
  final String? descriptionAr;
  final String? descriptionEn;
  final bool isActive;
  final int? sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GameCard({
    this.id,
    this.providerId,
    this.cardName,
    this.cardValue,
    this.cardPrice,
    this.descriptionAr,
    this.descriptionEn,
    this.isActive = true,
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  // إنشاء بطاقة من Map (من قاعدة البيانات)
  factory GameCard.fromMap(Map<String, dynamic> map) {
    return GameCard(
      id: map['id'],
      providerId: map['provider_id'],
      cardName: map['card_name'],
      cardValue: map['card_value'] != null
          ? (map['card_value']).toDouble()
          : null,
      cardPrice: map['card_price'] != null
          ? (map['card_price']).toDouble()
          : null,
      descriptionAr: map['description_ar'],
      descriptionEn: map['description_en'],
      isActive: map['is_active'] ?? true,
      sortOrder: map['sort_order'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  // تحويل البطاقة إلى Map (لحفظها في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (cardName != null) 'card_name': cardName,
      if (cardValue != null) 'card_value': cardValue,
      if (cardPrice != null) 'card_price': cardPrice,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      if (descriptionEn != null) 'description_en': descriptionEn,
      'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // نسخ البطاقة مع تحديث بعض الحقول
  GameCard copyWith({
    int? id,
    int? providerId,
    String? cardName,
    double? cardValue,
    double? cardPrice,
    String? descriptionAr,
    String? descriptionEn,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameCard(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      cardName: cardName ?? this.cardName,
      cardValue: cardValue ?? this.cardValue,
      cardPrice: cardPrice ?? this.cardPrice,
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
    return 'GameCard(id: $id, cardName: $cardName, cardValue: $cardValue, cardPrice: $cardPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameCard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class GameCardProvider {
  final int? id;
  final String? name;
  final String? displayNameAr;
  final String? displayNameEn;
  final String? logoUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GameCardProvider({
    this.id,
    this.name,
    this.displayNameAr,
    this.displayNameEn,
    this.logoUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // إنشاء مقدم خدمة من Map (من قاعدة البيانات)
  factory GameCardProvider.fromMap(Map<String, dynamic> map) {
    return GameCardProvider(
      id: map['id'],
      name: map['name'],
      displayNameAr: map['display_name_ar'],
      displayNameEn: map['display_name_en'],
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

  // تحويل مقدم الخدمة إلى Map (لحفظه في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (displayNameAr != null) 'display_name_ar': displayNameAr,
      if (displayNameEn != null) 'display_name_en': displayNameEn,
      if (logoUrl != null) 'logo_url': logoUrl,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // نسخ مقدم الخدمة مع تحديث بعض الحقول
  GameCardProvider copyWith({
    int? id,
    String? name,
    String? displayNameAr,
    String? displayNameEn,
    String? logoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameCardProvider(
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
    return 'GameCardProvider(id: $id, name: $name, displayNameAr: $displayNameAr)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameCardProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
