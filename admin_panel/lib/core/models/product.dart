class Product {
  final String? id;
  final String name;
  final List<String> images;
  final double price;
  final int quantity;
  final String category;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isActive;
  final String? adminId;
  final String? currency;

  Product({
    this.id,
    required this.name,
    required this.images,
    required this.price,
    required this.quantity,
    required this.category,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.adminId,
    this.currency = 'SYP',
  });

  // إنشاء منتج من Map (من قاعدة البيانات)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      category: map['category'] ?? '',
      description: map['description'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      isActive: map['is_active'] ?? true,
      adminId: map['admin_id'],
      currency: map['currency'] ?? 'SYP',
    );
  }

  // تحويل المنتج إلى Map (لحفظه في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'images': images,
      'price': price,
      'quantity': quantity,
      'category': category,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'is_active': isActive ?? true,
      if (adminId != null) 'admin_id': adminId,
      'currency': currency ?? 'SYP',
    };
  }

  // نسخ المنتج مع تحديث بعض الحقول
  Product copyWith({
    String? id,
    String? name,
    List<String>? images,
    double? price,
    int? quantity,
    String? category,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? adminId,
    String? currency,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      images: images ?? this.images,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      adminId: adminId ?? this.adminId,
      currency: currency ?? this.currency,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, quantity: $quantity, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
