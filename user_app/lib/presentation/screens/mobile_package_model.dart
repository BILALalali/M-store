import 'package:flutter/material.dart';

enum MobileOperator { syriatel, mtn, other, all }

class MobilePackage {
  final String id;
  final String name;
  final double price;
  final double value;
  final MobileOperator operator;
  final String description;
  final String imageUrl;
  final bool isActive;

  MobilePackage({
    required this.id,
    required this.name,
    required this.price,
    required this.value,
    required this.operator,
    required this.description,
    required this.imageUrl,
    this.isActive = true,
  });

  // بيانات وهمية للعرض (سيتم استبدالها بقاعدة البيانات لاحقاً)
  static List<MobilePackage> get mockPackages => [
    // SyriaTel packages
    MobilePackage(
      id: 'syriatel_50',
      name: 'SyriaTel',
      price: 52.50,
      value: 50.0,
      operator: MobileOperator.syriatel,
      description: 'قيمة الباقة: 50 ليرة سورية',
      imageUrl: 'assets/syriatel_icon.png',
    ),
    MobilePackage(
      id: 'syriatel_100',
      name: 'SyriaTel',
      price: 105.00,
      value: 100.0,
      operator: MobileOperator.syriatel,
      description: 'قيمة الباقة: 100 ليرة سورية',
      imageUrl: 'assets/syriatel_icon.png',
    ),
    MobilePackage(
      id: 'syriatel_200',
      name: 'SyriaTel',
      price: 210.00,
      value: 200.0,
      operator: MobileOperator.syriatel,
      description: 'قيمة الباقة: 200 ليرة سورية',
      imageUrl: 'assets/syriatel_icon.png',
    ),
    MobilePackage(
      id: 'syriatel_500',
      name: 'SyriaTel',
      price: 525.00,
      value: 500.0,
      operator: MobileOperator.syriatel,
      description: 'قيمة الباقة: 500 ليرة سورية',
      imageUrl: 'assets/syriatel_icon.png',
    ),

    // MTN packages
    MobilePackage(
      id: 'mtn_50',
      name: 'MTN Syria',
      price: 52.00,
      value: 50.0,
      operator: MobileOperator.mtn,
      description: 'قيمة الباقة: 50 ليرة سورية',
      imageUrl: 'assets/mtn_icon.png',
    ),
    MobilePackage(
      id: 'mtn_100',
      name: 'MTN Syria',
      price: 104.00,
      value: 100.0,
      operator: MobileOperator.mtn,
      description: 'قيمة الباقة: 100 ليرة سورية',
      imageUrl: 'assets/mtn_icon.png',
    ),
    MobilePackage(
      id: 'mtn_200',
      name: 'MTN Syria',
      price: 208.00,
      value: 200.0,
      operator: MobileOperator.mtn,
      description: 'قيمة الباقة: 200 ليرة سورية',
      imageUrl: 'assets/mtn_icon.png',
    ),
    MobilePackage(
      id: 'mtn_500',
      name: 'MTN Syria',
      price: 520.00,
      value: 500.0,
      operator: MobileOperator.mtn,
      description: 'قيمة الباقة: 500 ليرة سورية',
      imageUrl: 'assets/mtn_icon.png',
    ),

    // Other operators - Wafa Telecom
    MobilePackage(
      id: 'wafa_50',
      name: 'Wafa Telecom',
      price: 53.00,
      value: 50.0,
      operator: MobileOperator.other,
      description: 'قيمة الباقة: 50 ليرة سورية',
      imageUrl: 'assets/wafa_icon.png',
    ),
    MobilePackage(
      id: 'wafa_100',
      name: 'Wafa Telecom',
      price: 106.00,
      value: 100.0,
      operator: MobileOperator.other,
      description: 'قيمة الباقة: 100 ليرة سورية',
      imageUrl: 'assets/wafa_icon.png',
    ),
    MobilePackage(
      id: 'wafa_200',
      name: 'Wafa Telecom',
      price: 212.00,
      value: 200.0,
      operator: MobileOperator.other,
      description: 'قيمة الباقة: 200 ليرة سورية',
      imageUrl: 'assets/wafa_icon.png',
    ),
    
    // Other operators - Areeba
    MobilePackage(
      id: 'areeba_50',
      name: 'Areeba',
      price: 54.00,
      value: 50.0,
      operator: MobileOperator.other,
      description: 'قيمة الباقة: 50 ليرة سورية',
      imageUrl: 'assets/areeba_icon.png',
    ),
    MobilePackage(
      id: 'areeba_100',
      name: 'Areeba',
      price: 108.00,
      value: 100.0,
      operator: MobileOperator.other,
      description: 'قيمة الباقة: 100 ليرة سورية',
      imageUrl: 'assets/areeba_icon.png',
    ),
    MobilePackage(
      id: 'areeba_300',
      name: 'Areeba',
      price: 324.00,
      value: 300.0,
      operator: MobileOperator.other,
      description: 'قيمة الباقة: 300 ليرة سورية',
      imageUrl: 'assets/areeba_icon.png',
    ),
    
    // Other operators - Syriatel Plus
    MobilePackage(
      id: 'syriatel_plus_50',
      name: 'Syriatel Plus',
      price: 55.00,
      value: 50.0,
      operator: MobileOperator.other,
      description: 'قيمة الباقة: 50 ليرة سورية',
      imageUrl: 'assets/syriatel_plus_icon.png',
    ),
    MobilePackage(
      id: 'syriatel_plus_150',
      name: 'Syriatel Plus',
      price: 165.00,
      value: 150.0,
      operator: MobileOperator.other,
      description: 'قيمة الباقة: 150 ليرة سورية',
      imageUrl: 'assets/syriatel_plus_icon.png',
    ),
  ];

  // الحصول على الباقات حسب المشغل
  static List<MobilePackage> getPackagesByOperator(MobileOperator operator) {
    if (operator == MobileOperator.all) {
      return mockPackages;
    }
    return mockPackages
        .where((package) => package.operator == operator)
        .toList();
  }

  // الحصول على اسم المشغل بالعربية
  String get operatorName {
    switch (operator) {
      case MobileOperator.syriatel:
        return 'SyriaTel';
      case MobileOperator.mtn:
        return 'MTN Syria';
      case MobileOperator.other:
        return name; // استخدام اسم المشغل المحدد في البيانات
      case MobileOperator.all:
        return 'الكل';
    }
  }

  // الحصول على أيقونة المشغل
  IconData get operatorIcon {
    switch (operator) {
      case MobileOperator.syriatel:
        return Icons.phone_android;
      case MobileOperator.mtn:
        return Icons.phone_android;
      case MobileOperator.other:
        return Icons.phone_android;
      case MobileOperator.all:
        return Icons.all_inclusive;
    }
  }
}
