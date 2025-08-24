import 'package:flutter/material.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // بيانات المدير الأساسي
  static const String _adminEmail = 'almostafa.0a1@gmail.com';
  static const String _adminPassword = 'AB123/321';

  // حالة تسجيل الدخول
  bool _isAuthenticated = false;
  String? _currentUserEmail;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserEmail => _currentUserEmail;
  bool get isAdmin => _currentUserEmail == _adminEmail;

  // تسجيل دخول المدير
  Future<bool> signInAdmin() async {
    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(seconds: 1));

      _isAuthenticated = true;
      _currentUserEmail = _adminEmail;

      print('تم تسجيل دخول المدير بنجاح: $_adminEmail');
      return true;
    } catch (e) {
      print('خطأ في تسجيل دخول المدير: $e');
      return false;
    }
  }

  // تسجيل دخول ببيانات مخصصة
  Future<bool> signInWithCredentials(String email, String password) async {
    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(seconds: 1));

      // للاختبار: قبول أي بريد إلكتروني وكلمة مرور 6 أحرف على الأقل
      if (email.contains('@') && password.length >= 6) {
        _isAuthenticated = true;
        _currentUserEmail = email;

        print('تم تسجيل الدخول بنجاح: $email');
        return true;
      } else {
        throw Exception('بيانات تسجيل الدخول غير صحيحة');
      }
    } catch (e) {
      print('خطأ في تسجيل الدخول: $e');
      return false;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(milliseconds: 500));

      _isAuthenticated = false;
      _currentUserEmail = null;

      print('تم تسجيل الخروج بنجاح');
    } catch (e) {
      print('خطأ في تسجيل الخروج: $e');
      rethrow;
    }
  }

  // تحديث معلومات المستخدم
  Future<bool> updateUserProfile({String? fullName, String? phone}) async {
    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(seconds: 1));

      print('تم تحديث الملف الشخصي بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تحديث الملف الشخصي: $e');
      return false;
    }
  }

  // تغيير كلمة المرور
  Future<bool> changePassword(String newPassword) async {
    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(seconds: 1));

      print('تم تغيير كلمة المرور بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تغيير كلمة المرور: $e');
      return false;
    }
  }

  // الحصول على بيانات المستخدم
  Map<String, dynamic> getUserData() {
    if (!_isAuthenticated) {
      return {};
    }

    return {
      'email': _currentUserEmail,
      'full_name': 'أحمد محمد علي',
      'phone': '+966 50 123 4567',
      'role': 'مدير النظام',
      'avatar': 'أ',
    };
  }

  // الحصول على الإحصائيات
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(seconds: 1));

      // إحصائيات وهمية للاختبار
      return {
        'orders_count': 156,
        'products_count': 89,
        'users_count': 1247,
        'total_revenue': 45678.90,
        'pending_orders': 23,
        'completed_orders': 133,
      };
    } catch (e) {
      print('خطأ في جلب الإحصائيات: $e');
      return {
        'orders_count': 0,
        'products_count': 0,
        'users_count': 0,
        'total_revenue': 0.0,
        'pending_orders': 0,
        'completed_orders': 0,
      };
    }
  }

  // الحصول على الطلبات
  Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(seconds: 1));

      // بيانات وهمية للاختبار
      return [
        {
          'id': '1',
          'order_number': 'ORD-001',
          'customer_name': 'محمد أحمد',
          'customer_email': 'mohamed@example.com',
          'total_amount': 150.00,
          'status': 'pending',
          'created_at': DateTime.now().subtract(const Duration(days: 1)),
        },
        {
          'id': '2',
          'order_number': 'ORD-002',
          'customer_name': 'فاطمة علي',
          'customer_email': 'fatima@example.com',
          'total_amount': 89.50,
          'status': 'completed',
          'created_at': DateTime.now().subtract(const Duration(days: 2)),
        },
        {
          'id': '3',
          'order_number': 'ORD-003',
          'customer_name': 'علي حسن',
          'customer_email': 'ali@example.com',
          'total_amount': 234.75,
          'status': 'processing',
          'created_at': DateTime.now().subtract(const Duration(days: 3)),
        },
      ];
    } catch (e) {
      print('خطأ في جلب الطلبات: $e');
      return [];
    }
  }

  // الحصول على المنتجات
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(seconds: 1));

      // بيانات وهمية للاختبار
      return [
        {
          'id': '1',
          'name': 'بطاقة شحن فري فاير',
          'category': 'بطاقات الألعاب',
          'price': 50.00,
          'stock': 100,
          'status': 'active',
        },
        {
          'id': '2',
          'name': 'بطاقة شحن موبايل ليجندز',
          'category': 'بطاقات الألعاب',
          'price': 75.00,
          'stock': 75,
          'status': 'active',
        },
        {
          'id': '3',
          'name': 'رصيد جوال',
          'category': 'رصيد الجوال',
          'price': 100.00,
          'stock': 200,
          'status': 'active',
        },
      ];
    } catch (e) {
      print('خطأ في جلب المنتجات: $e');
      return [];
    }
  }
}
