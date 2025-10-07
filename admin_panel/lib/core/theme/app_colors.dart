import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية من تطبيق المستخدم
  static const Color primary = Color(0xFF23B3C6); // سماوي/تيفاني من الشعار
  static const Color secondary = Color(0xFFF6F3EA); // عاجي/كريمي من الشعار
  static const Color background = Color(
    0xFFFEFEF8,
  ); // سكري خفيف جداً للشاشة الرئيسية
  static const Color text = Color(0xFF222222); // أسود داكن للنصوص
  static const Color accent = Color(0xFF0097A7); // درجة أغمق من السماوي

  // ألوان إضافية للـ AdminPanel
  static const Color sidebar = Color(
    0xFFE8F6F8,
  ); // فيروزي خفيف للقائمة الجانبية
  static const Color sidebarHover = Color(
    0xFFD4F0F4,
  ); // فيروزي خفيف عند التمرير
  static const Color cardBackground = Colors.white; // أبيض للبطاقات
  static const Color success = Color(0xFF4CAF50); // أخضر للنجاح
  static const Color warning = Color(0xFF2196F3); // أزرق للرسائل غير المقروءة
  static const Color error = Color(0xFFF44336); // أحمر للأخطاء
  static const Color info = Color(0xFF2196F3); // أزرق للمعلومات
  static const Color border = Color(0xFFE0E0E0); // رمادي فاتح للحدود
}
