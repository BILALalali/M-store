import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  GoTrueClient? _auth;
  bool _isInitialized = false;

  // تهيئة Supabase
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await dotenv.load(fileName: "assets/env");

      // طباعة جميع المتغيرات المحملة للتشخيص
      print('المتغيرات المحملة: ${dotenv.env}');
      print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
      print('SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']}');

      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (url == null || anonKey == null) {
        throw Exception('بيانات Supabase غير موجودة في ملف env');
      }

      print('تهيئة Supabase مع URL: $url');
      print('مفتاح Anon: ${anonKey.substring(0, 20)}...');

      await Supabase.initialize(url: url, anonKey: anonKey);

      _client = Supabase.instance.client;
      _auth = _client!.auth;
      _isInitialized = true;

      print('تم تهيئة Supabase بنجاح');
    } catch (e) {
      print('خطأ في تهيئة Supabase: $e');
      rethrow;
    }
  }

  // التحقق من أن Supabase مهيأ
  bool get isReady => _isInitialized && _client != null && _auth != null;

  // الحصول على العميل
  SupabaseClient? get client => _client;

  // الحصول على المصادقة
  GoTrueClient? get auth => _auth;

  // التحقق من حالة تسجيل الدخول
  bool get isAuthenticated {
    try {
      if (!isReady) return false;
      return _auth?.currentUser != null;
    } catch (e) {
      print('خطأ في التحقق من حالة تسجيل الدخول: $e');
      return false;
    }
  }

  // الحصول على المستخدم الحالي
  User? get currentUser {
    try {
      if (!isReady) return null;
      return _auth?.currentUser;
    } catch (e) {
      print('خطأ في الحصول على المستخدم الحالي: $e');
      return null;
    }
  }

  // تسجيل دخول ببيانات مخصصة
  Future<AuthResponse> signInWithCredentials(
    String email,
    String password,
  ) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ. يرجى المحاولة مرة أخرى.');
      }

      final response = await _auth!.signInWithPassword(
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
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      await _auth!.signOut();
      print('تم تسجيل الخروج بنجاح');
    } catch (e) {
      print('خطأ في تسجيل الخروج: $e');
      rethrow;
    }
  }

  // التحقق من أن المستخدم مدير
  Future<bool> isAdmin() async {
    try {
      if (!isReady) return false;

      final user = _auth!.currentUser;
      if (user == null) return false;

      print('التحقق من صلاحيات المدير للمستخدم: ${user.email}');

      // محاولة التحقق من جدول admin_users باستخدام user_id
      try {
        final response = await _client!
            .from('admin_users')
            .select('*')
            .eq('user_id', user.id)
            .eq('is_active', true)
            .single();

        print('تم العثور على المستخدم في جدول admin_users: $response');
        return response != null;
      } catch (userIdError) {
        print('خطأ في البحث بـ user_id: $userIdError');

        // محاولة البحث باستخدام البريد الإلكتروني
        try {
          if (user.email != null) {
            final response = await _client!
                .from('admin_users')
                .select('*')
                .eq('email', user.email!)
                .eq('is_active', true)
                .single();

            print(
              'تم العثور على المستخدم في جدول admin_users باستخدام البريد الإلكتروني: $response',
            );
            return response != null;
          }
        } catch (emailError) {
          print('خطأ في البحث بـ البريد الإلكتروني: $emailError');

          // محاولة قراءة جميع البيانات في الجدول
          try {
            final allData = await _client!.from('admin_users').select('*');
            print('جميع البيانات في جدول admin_users: $allData');

            // البحث في البيانات المحملة
            for (var row in allData) {
              if ((row['email'] == user.email || row['user_id'] == user.id) &&
                  (row['is_active'] == true || row['is_active'] == null)) {
                print('تم العثور على المستخدم في البيانات المحملة: $row');
                return true;
              }
            }
          } catch (readError) {
            print('خطأ في قراءة جميع البيانات: $readError');
          }
        }
      }

      return false;
    } catch (e) {
      print('خطأ في التحقق من صلاحيات المدير: $e');
      return false;
    }
  }

  // الحصول على معلومات المدير
  Future<Map<String, dynamic>?> getAdminProfile() async {
    try {
      if (!isReady) return null;

      final user = _auth!.currentUser;
      if (user == null) return null;

      print('محاولة جلب معلومات المدير للمستخدم: ${user.email}');

      // محاولة البحث بـ user_id أولاً
      try {
        final response = await _client!
            .from('admin_users')
            .select('*')
            .eq('user_id', user.id)
            .single();

        print('تم العثور على معلومات المدير بـ user_id: $response');
        return response;
      } catch (userIdError) {
        print('خطأ في البحث بـ user_id: $userIdError');

        // محاولة البحث بـ البريد الإلكتروني
        try {
          if (user.email != null) {
            final response = await _client!
                .from('admin_users')
                .select('*')
                .eq('email', user.email!)
                .single();

            print(
              'تم العثور على معلومات المدير بـ البريد الإلكتروني: $response',
            );
            return response;
          }
        } catch (emailError) {
          print('خطأ في البحث بـ البريد الإلكتروني: $emailError');

          // محاولة قراءة جميع البيانات والبحث
          try {
            final allData = await _client!.from('admin_users').select('*');
            print('جميع البيانات في جدول admin_users: $allData');

            for (var row in allData) {
              if ((row['email'] == user.email || row['user_id'] == user.id)) {
                print('تم العثور على معلومات المدير في البيانات المحملة: $row');
                return row;
              }
            }
          } catch (readError) {
            print('خطأ في قراءة جميع البيانات: $readError');
          }
        }
      }

      return null;
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
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      final user = _auth!.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      final updates = <String, dynamic>{};

      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatar != null) updates['avatar'] = avatar;

      print('محاولة تحديث معلومات المدير للمستخدم: ${user.email}');

      // محاولة التحديث بـ user_id أولاً
      try {
        await _client!
            .from('admin_users')
            .update(updates)
            .eq('user_id', user.id);
        print('تم تحديث الملف الشخصي بـ user_id بنجاح');
      } catch (userIdError) {
        print('خطأ في التحديث بـ user_id: $userIdError');

        // محاولة التحديث بـ البريد الإلكتروني
        try {
          if (user.email != null) {
            await _client!
                .from('admin_users')
                .update(updates)
                .eq('email', user.email!);
            print('تم تحديث الملف الشخصي بـ البريد الإلكتروني بنجاح');
          }
        } catch (emailError) {
          print('خطأ في التحديث بـ البريد الإلكتروني: $emailError');
          rethrow;
        }
      }
    } catch (e) {
      print('خطأ في تحديث الملف الشخصي: $e');
      rethrow;
    }
  }

  // تغيير كلمة المرور
  Future<void> changePassword(String newPassword) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      await _auth!.updateUser(UserAttributes(password: newPassword));

      print('تم تغيير كلمة المرور بنجاح');
    } catch (e) {
      print('خطأ في تغيير كلمة المرور: $e');
      rethrow;
    }
  }

  // الحصول على الطلبات
  Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      if (!isReady) {
        return [];
      }

      final response = await _client!
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
      if (!isReady) {
        return [];
      }

      final response = await _client!
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
      if (!isReady) {
        return [];
      }

      final response = await _client!
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
      if (!isReady) {
        return _getDefaultStats();
      }

      Map<String, dynamic> stats = _getDefaultStats();

      // محاولة جلب عدد الطلبات
      try {
        final ordersResponse = await _client!.from('orders').select('id');
        stats['orders_count'] = ordersResponse.length;
      } catch (e) {
        print('جدول orders غير موجود أو غير قابل للوصول: $e');
      }

      // محاولة جلب عدد المنتجات
      try {
        final productsResponse = await _client!.from('products').select('id');
        stats['products_count'] = productsResponse.length;
      } catch (e) {
        print('جدول products غير موجود أو غير قابل للوصول: $e');
      }

      // محاولة جلب عدد المستخدمين
      try {
        final usersResponse = await _client!.from('users').select('id');
        stats['users_count'] = usersResponse.length;
      } catch (e) {
        print('جدول users غير موجود أو غير قابل للوصول: $e');
      }

      // محاولة جلب الطلبات المعلقة
      try {
        final pendingOrdersResponse = await _client!
            .from('orders')
            .select('id')
            .eq('status', 'pending');
        stats['pending_orders'] = pendingOrdersResponse.length;
      } catch (e) {
        print('لا يمكن جلب الطلبات المعلقة: $e');
      }

      // محاولة جلب الطلبات المكتملة
      try {
        final completedOrdersResponse = await _client!
            .from('orders')
            .select('id')
            .eq('status', 'completed');
        stats['completed_orders'] = completedOrdersResponse.length;
      } catch (e) {
        print('لا يمكن جلب الطلبات المكتملة: $e');
      }

      // محاولة حساب الإيرادات
      try {
        final revenueResponse = await _client!
            .from('orders')
            .select('total_amount')
            .eq('status', 'completed');

        double totalRevenue = 0.0;
        for (var order in revenueResponse) {
          totalRevenue += (order['total_amount'] ?? 0.0);
        }
        stats['total_revenue'] = totalRevenue;
      } catch (e) {
        print('لا يمكن حساب الإيرادات: $e');
      }

      return stats;
    } catch (e) {
      print('خطأ في جلب الإحصائيات: $e');
      return _getDefaultStats();
    }
  }

  // إحصائيات افتراضية
  Map<String, dynamic> _getDefaultStats() {
    return {
      'orders_count': 0,
      'products_count': 0,
      'users_count': 0,
      'total_revenue': 0.0,
      'pending_orders': 0,
      'completed_orders': 0,
    };
  }

  // إنشاء حساب مدير جديد
  Future<void> createAdminAccount({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      // إنشاء المستخدم
      final authResponse = await _auth!.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      if (authResponse.user != null) {
        print('تم إنشاء المستخدم في Authentication بنجاح');
        print('User ID: ${authResponse.user!.id}');

        // محاولة إضافة المستخدم كمدير في جدول admin_users
        try {
          await _client!.from('admin_users').insert({
            'id': authResponse.user!.id,
            'email': email,
            'full_name': fullName,
            'phone': phone,
            'role': 'super_admin',
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          print('تم إضافة المستخدم كمدير في جدول admin_users');
        } catch (tableError) {
          print('خطأ في إضافة المستخدم لجدول admin_users: $tableError');
          print('محاولة إنشاء صف ببيانات بسيطة...');

          // محاولة إنشاء صف ببيانات بسيطة
          try {
            await _client!.from('admin_users').insert({
              'email': email,
              'full_name': fullName,
              'role': 'super_admin',
              'is_active': true,
            });
            print('تم إنشاء صف ببيانات بسيطة بنجاح');
          } catch (simpleError) {
            print('خطأ في إنشاء صف بسيط: $simpleError');
            print('يبدو أن جدول admin_users غير موجود أو له هيكل مختلف');
          }
        }

        print('تم إنشاء حساب المدير بنجاح');
      }
    } catch (e) {
      print('خطأ في إنشاء حساب المدير: $e');
      rethrow;
    }
  }

  // فحص هيكل جدول admin_users
  Future<void> inspectTableStructure() async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('فحص هيكل جدول admin_users...');

      // محاولة قراءة جميع البيانات
      final allData = await _client!.from('admin_users').select('*');
      print('جميع البيانات في الجدول: $allData');

      // محاولة قراءة الأعمدة فقط
      try {
        final columns = await _client!.rpc(
          'get_table_columns',
          params: {'table_name': 'admin_users'},
        );
        print('أعمدة الجدول: $columns');
      } catch (e) {
        print('لا يمكن قراءة أعمدة الجدول: $e');
      }

      // محاولة قراءة معلومات الجدول
      try {
        final tableInfo = await _client!.rpc(
          'get_table_info',
          params: {'table_name': 'admin_users'},
        );
        print('معلومات الجدول: $tableInfo');
      } catch (e) {
        print('لا يمكن قراءة معلومات الجدول: $e');
      }
    } catch (e) {
      print('خطأ في فحص هيكل الجدول: $e');
    }
  }

  // إنشاء حساب مؤقت للتجربة
  Future<void> createTemporaryAccount() async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('إنشاء حساب مؤقت للتجربة...');

      // إنشاء المستخدم
      final authResponse = await _auth!.signUp(
        email: 'almostafa.0a1@gmail.com',
        password: '123456',
        data: {
          'full_name': 'عبد العزيز المصطفيي',
          'phone': '+90 531 746 89 50',
        },
      );

      if (authResponse.user != null) {
        print('تم إنشاء الحساب في Authentication بنجاح');
        print('User ID: ${authResponse.user!.id}');

        // فحص هيكل الجدول أولاً
        await inspectTableStructure();

        // محاولة تحديث جدول admin_users
        try {
          print('محاولة تحديث جدول admin_users...');

          // محاولة تحديث الصف الموجود
          await _client!
              .from('admin_users')
              .update({'updated_at': DateTime.now().toIso8601String()})
              .eq('email', 'almostafa.0a1@gmail.com');

          print('تم تحديث جدول admin_users بنجاح');
        } catch (e) {
          print('خطأ في تحديث جدول admin_users: $e');
          print('محاولة إنشاء صف جديد...');

          // محاولة إنشاء صف جديد
          try {
            await _client!.from('admin_users').insert({
              'email': 'almostafa.0a1@gmail.com',
              'full_name': 'عبد العزيز المصطفيي',
              'phone': '+90 531 746 89 50',
              'role': 'super_admin',
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
            print('تم إنشاء صف جديد في admin_users');
          } catch (insertError) {
            print('خطأ في إنشاء صف جديد: $insertError');
            print('يبدو أن هيكل الجدول مختلف عما هو متوقع');

            // محاولة إدراج بيانات بسيطة
            try {
              print('محاولة إدراج بيانات بسيطة...');
              await _client!.from('admin_users').insert({
                'full_name': 'عبد العزيز المصطفيي',
                'role': 'super_admin',
                'is_active': true,
              });
              print('تم إدراج بيانات بسيطة بنجاح');
            } catch (simpleInsertError) {
              print('خطأ في إدراج البيانات البسيطة: $simpleInsertError');
            }
          }
        }

        print('تم إنشاء الحساب المؤقت بنجاح!');
        print('يمكنك الآن تسجيل الدخول بـ:');
        print('Email: almostafa.0a1@gmail.com');
        print('Password: 123456');
      }
    } catch (e) {
      print('خطأ في إنشاء الحساب المؤقت: $e');
      rethrow;
    }
  }
}
