class Product {
  final String id;
  final String name;
  final List<String> images;
  final double price;
  final int quantity;
  final String category;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? adminId; // معرف الأدمن الذي أضاف المنتج

  Product({
    required this.id,
    required this.name,
    required this.images,
    required this.price,
    required this.quantity,
    required this.category,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.adminId,
  });

  // إنشاء منتج من Map (من قاعدة البيانات)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      isActive: map['is_active'] ?? true,
      adminId: map['admin_id'],
    );
  }

  // تحويل المنتج إلى Map (لحفظه في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'images': images,
      'price': price,
      'quantity': quantity,
      'category': category,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'admin_id': adminId,
    };
  }

  // نسخ المنتج مع تحديث حقول معينة
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
    );
  }
}
