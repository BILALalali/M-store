import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;
  late final GoTrueClient _auth;

  // تهيئة Supabase
  Future<void> initialize() async {
    await dotenv.load(fileName: "assets/.env");

    // طباعة جميع المتغيرات المحملة للتشخيص
    print('المتغيرات المحملة: ${dotenv.env}');
    print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
    print('SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']}');

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null) {
      throw Exception('بيانات Supabase غير موجودة في ملف .env');
    }

    print('تهيئة Supabase مع URL: $url');
    print('مفتاح Anon: ${anonKey.substring(0, 20)}...');

    await Supabase.initialize(url: url, anonKey: anonKey);

    _client = Supabase.instance.client;
    _auth = _client.auth;
  }

  // الحصول على العميل
  SupabaseClient get client => _client;

  // الحصول على المصادقة
  GoTrueClient get auth => _auth;

  // تسجيل دخول ببيانات مخصصة
  Future<AuthResponse> signInWithCredentials(
    String email,
    String password,
  ) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('تم تسجيل الدخول بنجاح: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      print('خطأ في تسجيل الدخول: $e');
      rethrow;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('تم تسجيل الخروج بنجاح');
    } catch (e) {
      print('خطأ في تسجيل الخروج: $e');
      rethrow;
    }
  }

  // التحقق من حالة تسجيل الدخول
  bool get isAuthenticated => _auth.currentUser != null;

  // الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // التحقق من أن المستخدم مدير
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // التحقق من جدول admins
      final response = await _client
          .from('admins')
          .select('*')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .single();

      return response != null;
    } catch (e) {
      print('خطأ في التحقق من صلاحيات المدير: $e');
      return false;
    }
  }

  // الحصول على معلومات المدير
  Future<Map<String, dynamic>?> getAdminProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('admins')
          .select('*')
          .eq('user_id', user.id)
          .single();

      return response;
    } catch (e) {
      print('خطأ في جلب معلومات المدير: $e');
      return null;
    }
  }

  // تحديث معلومات المدير
  Future<void> updateAdminProfile({
    String? fullName,
    String? phone,
    String? avatar,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      final updates = <String, dynamic>{};

      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatar != null) updates['avatar'] = avatar;

      await _client.from('admins').update(updates).eq('user_id', user.id);

      print('تم تحديث الملف الشخصي بنجاح');
    } catch (e) {
      print('خطأ في تحديث الملف الشخصي: $e');
      rethrow;
    }
  }

  // تغيير كلمة المرور
  Future<void> changePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));

      print('تم تغيير كلمة المرور بنجاح');
    } catch (e) {
      print('خطأ في تغيير كلمة المرور: $e');
      rethrow;
    }
  }

  // الحصول على الطلبات
  Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, users!inner(*)')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب الطلبات: $e');
      return [];
    }
  }

  // الحصول على المنتجات
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await _client
          .from('products')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب المنتجات: $e');
      return [];
    }
  }

  // الحصول على المستخدمين
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _client
          .from('users')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب المستخدمين: $e');
      return [];
    }
  }

  // الحصول على الإحصائيات
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // جلب عدد الطلبات
      final ordersResponse = await _client.from('orders').select('id');
      final ordersCount = ordersResponse.length;

      // جلب عدد المنتجات
      final productsResponse = await _client.from('products').select('id');
      final productsCount = productsResponse.length;

      // جلب عدد المستخدمين
      final usersResponse = await _client.from('users').select('id');
      final usersCount = usersResponse.length;

      // جلب الطلبات المعلقة
      final pendingOrdersResponse = await _client
          .from('orders')
          .select('id')
          .eq('status', 'pending');
      final pendingOrders = pendingOrdersResponse.length;

      // جلب الطلبات المكتملة
      final completedOrdersResponse = await _client
          .from('orders')
          .select('id')
          .eq('status', 'completed');
      final completedOrders = completedOrdersResponse.length;

      // حساب الإيرادات
      final revenueResponse = await _client
          .from('orders')
          .select('total_amount')
          .eq('status', 'completed');

      double totalRevenue = 0.0;
      for (var order in revenueResponse) {
        totalRevenue += (order['total_amount'] ?? 0.0);
      }

      return {
        'orders_count': ordersCount,
        'products_count': productsCount,
        'users_count': usersCount,
        'total_revenue': totalRevenue,
        'pending_orders': pendingOrders,
        'completed_orders': completedOrders,
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

  // إنشاء حساب مدير جديد
  Future<void> createAdminAccount({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      // إنشاء المستخدم
      final authResponse = await _auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      if (authResponse.user != null) {
        // إضافة المستخدم كمدير
        await _client.from('admins').insert({
          'user_id': authResponse.user!.id,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'role': 'admin',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });

        print('تم إنشاء حساب المدير بنجاح');
      }
    } catch (e) {
      print('خطأ في إنشاء حساب المدير: $e');
      rethrow;
    }
  }
}
