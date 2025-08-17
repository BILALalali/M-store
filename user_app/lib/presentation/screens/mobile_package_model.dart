import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';

enum MobileOperator { syriatel, mtn, other, all }

class MobileOperatorModel {
  final int id;
  final String name;
  final String displayNameAr;
  final String displayNameEn;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MobileOperatorModel({
    required this.id,
    required this.name,
    required this.displayNameAr,
    required this.displayNameEn,
    this.logoUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MobileOperatorModel.fromJson(Map<String, dynamic> json) {
    return MobileOperatorModel(
      id: json['id'],
      name: json['name'],
      displayNameAr: json['display_name_ar'],
      displayNameEn: json['display_name_en'],
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name_ar': displayNameAr,
      'display_name_en': displayNameEn,
      'logo_url': logoUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class MobilePackage {
  final int id;
  final int operatorId;
  final String packageName;
  final double packageValue;
  final double packagePrice;
  final String? descriptionAr;
  final String? descriptionEn;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // معلومات إضافية من جدول المشغلين
  MobileOperatorModel? operator;

  MobilePackage({
    required this.id,
    required this.operatorId,
    required this.packageName,
    required this.packageValue,
    required this.packagePrice,
    this.descriptionAr,
    this.descriptionEn,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.operator,
  });

  factory MobilePackage.fromJson(Map<String, dynamic> json) {
    return MobilePackage(
      id: json['id'],
      operatorId: json['operator_id'],
      packageName: json['package_name'],
      packageValue: double.parse(json['package_value'].toString()),
      packagePrice: double.parse(json['package_price'].toString()),
      descriptionAr: json['description_ar'],
      descriptionEn: json['description_en'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operator_id': operatorId,
      'package_name': packageName,
      'package_value': packageValue,
      'package_price': packagePrice,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // الحصول على الباقات من قاعدة البيانات
  static Future<List<MobilePackage>> getPackagesFromDatabase() async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        print('Supabase غير متصل، سيتم استخدام البيانات المحلية');
        return getMockPackages();
      }

      final response = await client
          .from('mobile_packages')
          .select('''
            *,
            mobile_operators (
              id,
              name,
              display_name_ar,
              display_name_en,
              logo_url,
              is_active
            )
          ''')
          .eq('is_active', true)
          .order('sort_order')
          .order('package_value');

      if (response == null) return [];

      List<MobilePackage> packages = [];
      for (var row in response) {
        final package = MobilePackage.fromJson(row);
        
        // إضافة معلومات المشغل
        if (row['mobile_operators'] != null) {
          package.operator = MobileOperatorModel.fromJson(row['mobile_operators']);
        }
        
        packages.add(package);
      }

      return packages;
    } catch (e) {
      print('خطأ في جلب الباقات من قاعدة البيانات: $e');
      return getMockPackages();
    }
  }

  // الحصول على الباقات حسب المشغل
  static Future<List<MobilePackage>> getPackagesByOperatorFromDatabase(MobileOperator operator) async {
    try {
      final allPackages = await getPackagesFromDatabase();
      
      if (operator == MobileOperator.all) {
        return allPackages;
      }

      return allPackages.where((package) {
        if (package.operator == null) return false;
        
        switch (operator) {
          case MobileOperator.syriatel:
            return package.operator!.name == 'syriatel';
          case MobileOperator.mtn:
            return package.operator!.name == 'mtn';
          case MobileOperator.other:
            return !['syriatel', 'mtn'].contains(package.operator!.name);
          default:
            return true;
        }
      }).toList();
    } catch (e) {
      print('خطأ في تصفية الباقات حسب المشغل: $e');
      return getMockPackages().where((package) {
        if (operator == MobileOperator.all) return true;
        return package.operator == operator;
      }).toList();
    }
  }

  // الحصول على المشغلين من قاعدة البيانات
  static Future<List<MobileOperatorModel>> getOperatorsFromDatabase() async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        print('Supabase غير متصل');
        return [];
      }

      final response = await client
          .from('mobile_operators')
          .select('*')
          .eq('is_active', true)
          .order('name');

      if (response == null) return [];

      return response
          .map((row) => MobileOperatorModel.fromJson(row))
          .toList();
    } catch (e) {
      print('خطأ في جلب المشغلين من قاعدة البيانات: $e');
      return [];
    }
  }

  // بيانات وهمية للعرض (سيتم استخدامها كاحتياطي)
  static List<MobilePackage> getMockPackages() => [
    // SyriaTel packages
    MobilePackage(
      id: 1,
      operatorId: 1,
      packageName: 'SyriaTel',
      packageValue: 50.0,
      packagePrice: 52.50,
      descriptionAr: 'قيمة الباقة: 50 ليرة سورية',
      descriptionEn: 'Package Value: 50 Syrian Lira',
      sortOrder: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MobilePackage(
      id: 2,
      operatorId: 1,
      packageName: 'SyriaTel',
      packageValue: 100.0,
      packagePrice: 105.00,
      descriptionAr: 'قيمة الباقة: 100 ليرة سورية',
      descriptionEn: 'Package Value: 100 Syrian Lira',
      sortOrder: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MobilePackage(
      id: 3,
      operatorId: 1,
      packageName: 'SyriaTel',
      packageValue: 200.0,
      packagePrice: 210.00,
      descriptionAr: 'قيمة الباقة: 200 ليرة سورية',
      descriptionEn: 'Package Value: 200 Syrian Lira',
      sortOrder: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MobilePackage(
      id: 4,
      operatorId: 1,
      packageName: 'SyriaTel',
      packageValue: 500.0,
      packagePrice: 525.00,
      descriptionAr: 'قيمة الباقة: 500 ليرة سورية',
      descriptionEn: 'Package Value: 500 Syrian Lira',
      sortOrder: 4,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // MTN packages
    MobilePackage(
      id: 5,
      operatorId: 2,
      packageName: 'MTN Syria',
      packageValue: 50.0,
      packagePrice: 52.00,
      descriptionAr: 'قيمة الباقة: 50 ليرة سورية',
      descriptionEn: 'Package Value: 50 Syrian Lira',
      sortOrder: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MobilePackage(
      id: 6,
      operatorId: 2,
      packageName: 'MTN Syria',
      packageValue: 100.0,
      packagePrice: 104.00,
      descriptionAr: 'قيمة الباقة: 100 ليرة سورية',
      descriptionEn: 'Package Value: 100 Syrian Lira',
      sortOrder: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MobilePackage(
      id: 7,
      operatorId: 2,
      packageName: 'MTN Syria',
      packageValue: 200.0,
      packagePrice: 208.00,
      descriptionAr: 'قيمة الباقة: 200 ليرة سورية',
      descriptionEn: 'Package Value: 200 Syrian Lira',
      sortOrder: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MobilePackage(
      id: 8,
      operatorId: 2,
      packageName: 'MTN Syria',
      packageValue: 500.0,
      packagePrice: 520.00,
      descriptionAr: 'قيمة الباقة: 500 ليرة سورية',
      descriptionEn: 'Package Value: 500 Syrian Lira',
      sortOrder: 4,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // الحصول على الباقات حسب المشغل (للتوافق مع الكود القديم)
  static List<MobilePackage> getPackagesByOperator(MobileOperator operator) {
    final packages = getMockPackages();
    if (operator == MobileOperator.all) {
      return packages;
    }
    return packages.where((package) {
      switch (operator) {
        case MobileOperator.syriatel:
          return package.operatorId == 1;
        case MobileOperator.mtn:
          return package.operatorId == 2;
        case MobileOperator.other:
          return package.operatorId > 2;
        default:
          return true;
      }
    }).toList();
  }

  // الحصول على اسم المشغل بالعربية
  String get operatorName {
    if (operator != null) {
      return operator!.displayNameAr;
    }
    
    // احتياطي للبيانات القديمة
    switch (operatorId) {
      case 1:
        return 'SyriaTel';
      case 2:
        return 'MTN Syria';
      default:
        return packageName;
    }
  }

  // الحصول على أيقونة المشغل
  IconData get operatorIcon {
    return Icons.phone_android;
  }

  // الحصول على وصف الباقة
  String get description {
    return descriptionAr ?? 'قيمة الباقة: ${packageValue.toInt()} ليرة سورية';
  }

  // الحصول على السعر
  double get price => packagePrice;

  // الحصول على القيمة
  double get value => packageValue;

  // الحصول على معرف الباقة
  String get idString => id.toString();

  // الحصول على صورة الباقة
  String get imageUrl {
    if (operator?.logoUrl != null) {
      return operator!.logoUrl!;
    }
    return 'assets/phone_icon.png';
  }
}
