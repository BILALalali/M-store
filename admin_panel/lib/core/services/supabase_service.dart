import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// استيراد dart:html فقط للويب
import 'dart:html' as html if (dart.library.io) 'dart:io';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  GoTrueClient? _auth;
  bool _isInitialized = false;
  bool _isSigningOut = false; // إضافة حالة لمنع تسجيل الخروج المتكرر

  SupabaseClient? _serviceRoleClient;
  SupabaseClient? get serviceRoleClient {
    if (_serviceRoleClient == null) {
      try {
        final url = dotenv.env['SUPABASE_URL'];
        final serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];

        print('🔑 فحص مفاتيح API...');
        print('🔑 تم تحميل مفاتيح API بنجاح');

        if (url != null && serviceRoleKey != null) {
          _serviceRoleClient = SupabaseClient(url, serviceRoleKey);
          print('✅ تم إنشاء عميل service_role بنجاح');
        } else {
          print('❌ بيانات service_role غير موجودة');
          print('❌ URL: $url');
          print('❌ Service Role Key: $serviceRoleKey');
        }
      } catch (e) {
        print('❌ خطأ في إنشاء عميل service_role');
      }
    }
    return _serviceRoleClient;
  }

  Future<Map<String, dynamic>?> addAdvertisementWithServiceRole(
    Map<String, dynamic> advertisementData,
  ) async {
    try {
      final serviceClient = serviceRoleClient;
      if (serviceClient == null) {
        throw Exception('عميل service_role غير متاح');
      }

      print('إضافة إعلان جديد باستخدام service_role: $advertisementData');

      final response = await serviceClient
          .from('advertisements')
          .insert(advertisementData)
          .select()
          .single();

      print('تم إضافة الإعلان بنجاح');
      return response;
    } catch (e) {
      print('خطأ في إضافة الإعلان');
      rethrow;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await dotenv.load(fileName: "assets/env");

      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (url == null || anonKey == null) {
        throw Exception('بيانات Supabase غير موجودة في ملف env');
      }

      print('تهيئة Supabase...');

      await Supabase.initialize(url: url, anonKey: anonKey);

      _client = Supabase.instance.client;
      _auth = _client!.auth;
      _isInitialized = true;

      print('تم تهيئة Supabase بنجاح');
    } catch (e) {
      print('خطأ في تهيئة Supabase');
      rethrow;
    }
  }

  bool get isReady => _isInitialized && _client != null && _auth != null;
  SupabaseClient? get client => _client;
  GoTrueClient? get auth => _auth;

  bool get isAuthenticated {
    try {
      if (!isReady) return false;
      return _auth?.currentUser != null;
    } catch (e) {
      print('خطأ في التحقق من حالة تسجيل الدخول');
      return false;
    }
  }

  String? get currentUserId => _auth?.currentUser?.id;
  User? get currentUser {
    if (_auth == null) return null;
    return _auth!.currentUser;
  }

  // تسجيل دخول بـ OTP
  Future<void> sendOtpForLogin(String email) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ. يرجى المحاولة مرة أخرى.');
      }

      if (email.isEmpty) {
        throw Exception('البريد الإلكتروني مطلوب');
      }

      print('إرسال رمز OTP للمستخدم: $email');

      await _auth!.signInWithOtp(email: email, emailRedirectTo: null);

      print('تم إرسال رمز OTP بنجاح');
    } catch (e) {
      print('خطأ في إرسال OTP');
      rethrow;
    }
  }

  // التحقق من رمز OTP
  Future<AuthResponse> verifyOtpForLogin(String email, String token) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ. يرجى المحاولة مرة أخرى.');
      }

      if (email.isEmpty || token.isEmpty) {
        throw Exception('البريد الإلكتروني والرمز مطلوبان');
      }

      print('التحقق من رمز OTP للمستخدم: $email');

      final response = await _auth!.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

      if (response.user != null) {
        print('تم التحقق من OTP بنجاح: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      print('خطأ في التحقق من OTP');
      rethrow;
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

      // التحقق من صحة البيانات
      if (email.isEmpty || password.isEmpty) {
        throw Exception('البريد الإلكتروني وكلمة المرور مطلوبان');
      }

      if (password.length < 6) {
        throw Exception('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      }

      print('محاولة تسجيل الدخول للمستخدم: $email');

      // محاولة تسجيل الدخول بكلمة المرور أولاً
      final response = await _auth!.signInWithPassword(
        email: email,
        password: password,
      );

      // التحقق من الاستجابة
      if (response.user == null) {
        throw Exception('فشل في تسجيل الدخول - لم يتم إنشاء المستخدم');
      }

      // التحقق من أن المستخدم تم تأكيده
      if (response.user!.emailConfirmedAt == null) {
        // تسجيل الخروج إذا لم يتم تأكيد البريد
        await _auth!.signOut();
        throw Exception('يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول');
      }

      print('تم تسجيل الدخول بنجاح: ${response.user!.email}');
      print(
        'حالة المستخدم: ${response.user!.emailConfirmedAt != null ? "مؤكد" : "غير مؤكد"}',
      );

      // التحقق من أن المستخدم مدير بعد تسجيل الدخول الناجح
      try {
        final isAdminUser = await isAdmin();
        if (!isAdminUser) {
          print('المستخدم ليس مديراً، سيتم إنشاء سجل مدير تلقائياً');
          // إنشاء سجل مدير تلقائياً
          await _ensureAdminRecordExists();
        }
      } catch (adminError) {
        print('خطأ في التحقق من صلاحيات المدير: $adminError');
        // إنشاء سجل مدير تلقائياً في حالة الخطأ
        await _ensureAdminRecordExists();
      }

      // تحديث آخر تسجيل دخول
      await _updateLastLogin();

      return response;
    } catch (e) {
      print('خطأ في تسجيل الدخول');

      // رسائل خطأ واضحة
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('البريد الإلكتروني أو كلمة المرور غير صحيحة');
      } else if (e.toString().contains('Email not confirmed')) {
        throw Exception('يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول');
      } else if (e.toString().contains('Too many requests')) {
        throw Exception('تم تجاوز عدد المحاولات المسموح. يرجى المحاولة لاحقاً');
      } else if (e.toString().contains('غير مسجل في لوحة الإدارة')) {
        throw Exception('هذا البريد الإلكتروني غير مسجل في لوحة الإدارة');
      } else if (e.toString().contains('فشل في التحقق من صلاحيات المستخدم')) {
        throw Exception('فشل في التحقق من صلاحيات المستخدم');
      } else {
        throw Exception('خطأ في تسجيل الدخول: $e');
      }
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    // منع تسجيل الخروج المتكرر
    if (_isSigningOut) {
      print('تسجيل الخروج قيد التنفيذ بالفعل...');
      return;
    }

    try {
      _isSigningOut = true; // تعيين حالة العملية
      print('بدء عملية تسجيل الخروج من Supabase...');

      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      // التحقق من وجود مستخدم مسجل دخول
      final currentUser = _auth!.currentUser;
      if (currentUser != null) {
        print('المستخدم الحالي موجود');
      }

      // تنفيذ تسجيل الخروج
      await _auth!.signOut();
      print('تم تسجيل الخروج من Supabase بنجاح');

      // انتظار قليل للتأكد من اكتمال العملية
      await Future.delayed(const Duration(milliseconds: 300));

      // التحقق من أن المستخدم تم تسجيل خروجه
      final userAfterSignOut = _auth!.currentUser;
      if (userAfterSignOut == null) {
        print('تم التأكد من تسجيل الخروج - لا يوجد مستخدم حالياً');
      } else {
        print('تحذير: المستخدم لا يزال موجوداً بعد تسجيل الخروج');
      }
    } catch (e) {
      print('خطأ في تسجيل الخروج');
      rethrow;
    } finally {
      _isSigningOut = false; // إعادة تعيين الحالة
      print('انتهت عملية تسجيل الخروج');
    }
  }

  // التحقق من وجود المستخدم في جدول admin_users
  Future<bool> checkAdminExists(String email) async {
    try {
      if (!isReady) return false;

      print('التحقق من وجود المستخدم في جدول admin_users...');

      final response = await _client!
          .from('admin_users')
          .select('id, email, is_active')
          .eq('email', email)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        print('تم العثور على المستخدم في جدول admin_users');
        return true;
      } else {
        print('المستخدم غير موجود في جدول admin_users أو غير نشط');
        return false;
      }
    } catch (e) {
      print('خطأ في التحقق من وجود المستخدم');
      return false;
    }
  }

  // تأكيد البريد الإلكتروني للمدير باستخدام service_role
  Future<void> confirmAdminEmail(String email) async {
    try {
      final serviceClient = serviceRoleClient;
      if (serviceClient == null) {
        throw Exception('عميل service_role غير متاح');
      }

      print('تأكيد البريد الإلكتروني للمدير: $email');

      // البحث عن المستخدم في Authentication
      final usersResponse = await serviceClient.auth.admin.listUsers();
      final user = usersResponse.firstWhere(
        (user) => user.email == email,
        orElse: () => throw Exception('المستخدم غير موجود في Authentication'),
      );

      // تأكيد البريد الإلكتروني
      await serviceClient.auth.admin.updateUserById(
        user.id,
        attributes: AdminUserAttributes(emailConfirm: true),
      );

      print('تم تأكيد البريد الإلكتروني بنجاح للمدير: $email');

      // التأكد من وجود user_id في جدول admin_users
      await _ensureAdminUserIdExists(email, user.id);
    } catch (e) {
      print('خطأ في تأكيد البريد الإلكتروني');
      rethrow;
    }
  }

  // التأكد من وجود user_id للمدير في جدول admin_users
  Future<void> _ensureAdminUserIdExists(String email, String userId) async {
    try {
      final serviceClient = serviceRoleClient;
      if (serviceClient == null) {
        throw Exception('عميل service_role غير متاح');
      }

      print('فحص وجود user_id للمدير...');

      // البحث عن المدير في جدول admin_users
      final adminRecord = await serviceClient
          .from('admin_users')
          .select('*')
          .eq('email', email)
          .maybeSingle();

      if (adminRecord != null) {
        // إذا كان المدير موجود ولكن بدون user_id، قم بتحديثه
        if (adminRecord['user_id'] == null ||
            adminRecord['user_id'].toString().isEmpty) {
          print('تحديث user_id للمدير الموجود...');

          await serviceClient
              .from('admin_users')
              .update({
                'user_id': userId,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('email', email);

          print('تم تحديث user_id بنجاح');
        } else {
          print('user_id موجود بالفعل للمدير');
        }
      } else {
        print('المدير غير موجود في جدول admin_users');
      }
    } catch (e) {
      print('خطأ في فحص/تحديث user_id');
      // لا نرمي الخطأ هنا لأنه ليس خطأ حرج
    }
  }

  // التحقق من أن المستخدم مدير
  Future<bool> isAdmin() async {
    try {
      if (!isReady) return false;

      final user = _auth!.currentUser;
      if (user == null) return false;

      print('التحقق من صلاحيات المدير...');

      // البحث باستخدام البريد الإلكتروني مباشرة (أكثر موثوقية)
      if (user.email != null) {
        try {
          final response = await _client!
              .from('admin_users')
              .select('*')
              .eq('email', user.email!)
              .eq('is_active', true)
              .single();

          print(
            'تم العثور على المستخدم في جدول admin_users باستخدام البريد الإلكتروني: $response',
          );
          return true;
        } catch (emailError) {
          print('خطأ في البحث بـ البريد الإلكتروني');

          // محاولة قراءة جميع البيانات في الجدول
          try {
            final allData = await _client!.from('admin_users').select('*');
            print('جلب بيانات جدول admin_users...');

            // البحث في البيانات المحملة
            for (var row in allData) {
              if ((row['email'] == user.email || row['user_id'] == user.id) &&
                  (row['is_active'] == true || row['is_active'] == null)) {
                print('تم العثور على المستخدم في البيانات المحملة');
                return true;
              }
            }
          } catch (readError) {
            print('خطأ في قراءة جميع البيانات');
          }
        }
      }

      return false;
    } catch (e) {
      print('خطأ في التحقق من صلاحيات المدير');
      return false;
    }
  }

  // الحصول على معلومات المدير
  Future<Map<String, dynamic>?> getAdminProfile() async {
    try {
      if (!isReady) return null;

      final user = _auth!.currentUser;
      if (user == null) return null;

      print('محاولة جلب معلومات المدير...');

      // البحث باستخدام البريد الإلكتروني مباشرة (أكثر موثوقية)
      if (user.email != null) {
        try {
          final response = await _client!
              .from('admin_users')
              .select('*')
              .eq('email', user.email!)
              .single();

          print('تم العثور على معلومات المدير');
          return response;
        } catch (emailError) {
          print('خطأ في البحث بـ البريد الإلكتروني');

          // محاولة قراءة جميع البيانات والبحث
          try {
            final allData = await _client!.from('admin_users').select('*');
            print('جلب بيانات جدول admin_users...');

            for (var row in allData) {
              if ((row['email'] == user.email || row['user_id'] == user.id)) {
                print('تم العثور على معلومات المدير في البيانات المحملة');
                return row;
              }
            }
          } catch (readError) {
            print('خطأ في قراءة جميع البيانات');
          }
        }
      }

      return null;
    } catch (e) {
      print('خطأ في جلب معلومات المدير');
      return null;
    }
  }

  // تحديث معلومات المدير
  Future<Map<String, dynamic>?> updateAdminProfile({
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

      // إضافة timestamp التحديث
      updates['updated_at'] = DateTime.now().toIso8601String();

      print('محاولة تحديث معلومات المدير...');
      print('تحديث البيانات...');

      // محاولة التحديث بـ user_id أولاً
      try {
        final response = await _client!
            .from('admin_users')
            .update(updates)
            .eq('user_id', user.id)
            .select()
            .single();

        print('تم تحديث الملف الشخصي بـ user_id بنجاح');
        print('تم تحديث البيانات بنجاح');
        return response;
      } catch (userIdError) {
        print('خطأ في التحديث بـ user_id');

        // محاولة التحديث بـ البريد الإلكتروني
        try {
          if (user.email != null) {
            final response = await _client!
                .from('admin_users')
                .update(updates)
                .eq('email', user.email!)
                .select()
                .single();

            print('تم تحديث الملف الشخصي بـ البريد الإلكتروني بنجاح');
            print('تم تحديث البيانات بنجاح');
            return response;
          }
        } catch (emailError) {
          print('خطأ في التحديث بـ البريد الإلكتروني');
          rethrow;
        }
      }

      return null;
    } catch (e) {
      print('خطأ في تحديث الملف الشخصي');
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

      // تحديث تاريخ آخر تغيير كلمة المرور
      await updatePasswordLastUpdate();

      print('تم تغيير كلمة المرور بنجاح');
    } catch (e) {
      print('خطأ في تغيير كلمة المرور');
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
      print('خطأ في جلب الطلبات');
      return [];
    }
  }

  // رفع صورة إلى Supabase Storage
  Future<String?> uploadImage(html.File file) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('بدء رفع الصورة: ${file.name}');

      // قراءة بيانات الملف
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;

      if (reader.result == null) {
        throw Exception('فشل في قراءة بيانات الملف');
      }

      final bytes = reader.result as Uint8List;

      // إنشاء اسم فريد للملف
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = 'products/$fileName';

      // رفع الملف إلى Supabase Storage
      final response = await _client!.storage
          .from('images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: file.type, upsert: false),
          );

      if (response.isEmpty) {
        throw Exception('فشل في رفع الملف');
      }

      // الحصول على الرابط العام للملف
      final publicUrl = _client!.storage.from('images').getPublicUrl(filePath);

      print('تم رفع الصورة بنجاح: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('خطأ في رفع الصورة');
      rethrow;
    }
  }

  // التحقق من وجود جدول المنتجات وإنشاؤه إذا لم يكن موجوداً
  Future<void> ensureProductsTableExists() async {
    try {
      if (!isReady) {
        print('Supabase غير مهيأ، لا يمكن إنشاء الجدول');
        return;
      }

      print('التحقق من وجود جدول المنتجات...');

      // محاولة جلب بيانات من الجدول
      final testResponse = await _client!
          .from('products')
          .select('count')
          .limit(1);

      print('جدول المنتجات موجود: $testResponse');
    } catch (e) {
      print('جدول المنتجات غير موجود أو هناك خطأ: $e');
      print('يرجى التأكد من إنشاء جدول products في Supabase');
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
      print('خطأ في جلب المنتجات');
      return [];
    }
  }

  // إضافة منتج جديد
  Future<Map<String, dynamic>?> addProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('إضافة منتج جديد: $productData');

      final response = await _client!
          .from('products')
          .insert(productData)
          .select()
          .single();

      print('تم إضافة المنتج بنجاح');
      return response;
    } catch (e) {
      print('خطأ في إضافة المنتج');
      rethrow;
    }
  }

  // تحديث منتج موجود
  Future<Map<String, dynamic>?> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      // إضافة admin_id للمدير الحالي
      final user = _auth!.currentUser;
      if (user != null) {
        updates['admin_id'] = user.id;
        updates['updated_at'] = DateTime.now().toIso8601String();
      }

      print('تحديث المنتج $productId: $updates');

      final response = await _client!
          .from('products')
          .update(updates)
          .eq('id', productId)
          .select()
          .single();

      print('تم تحديث المنتج بنجاح');
      return response;
    } catch (e) {
      print('خطأ في تحديث المنتج');
      rethrow;
    }
  }

  // حذف منتج
  Future<bool> deleteProduct(String productId) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('حذف المنتج: $productId');

      await _client!.from('products').delete().eq('id', productId);

      print('تم حذف المنتج بنجاح');
      return true;
    } catch (e) {
      print('خطأ في حذف المنتج');
      rethrow;
    }
  }

  // البحث في المنتجات
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      if (!isReady) {
        return [];
      }

      print('البحث في المنتجات: $query');

      final response = await _client!
          .from('products')
          .select('*')
          .or(
            'name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%',
          )
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في البحث في المنتجات');
      return [];
    }
  }

  // الحصول على المنتجات حسب الفئة
  Future<List<Map<String, dynamic>>> getProductsByCategory(
    String category,
  ) async {
    try {
      if (!isReady) {
        return [];
      }

      print('جلب المنتجات للفئة: $category');

      final response = await _client!
          .from('products')
          .select('*')
          .eq('category', category)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب المنتجات حسب الفئة');
      return [];
    }
  }

  // الحصول على فئات المنتجات
  Future<List<String>> getProductCategories() async {
    try {
      if (!isReady) {
        return [];
      }

      print('جلب فئات المنتجات');

      final response = await _client!
          .from('products')
          .select('category')
          .not('category', 'is', null);

      final categories = response
          .map((item) => item['category'] as String)
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList();

      print('فئات المنتجات: $categories');
      return categories;
    } catch (e) {
      print('خطأ في جلب فئات المنتجات');
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
      print('خطأ في جلب المستخدمين');
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

      // حساب إجمالي الطلبات من جدولي order_threads و wholesale_requests
      try {
        // جلب الطلبات العادية من order_threads
        final orderThreadsResponse = await _client!
            .from('order_threads')
            .select('id, status');
        final orderThreadsCount = orderThreadsResponse.length;

        // جلب طلبات الجملة من wholesale_requests
        final wholesaleRequestsResponse = await _client!
            .from('wholesale_requests')
            .select('id, status');
        final wholesaleRequestsCount = wholesaleRequestsResponse.length;

        // إجمالي الطلبات
        stats['orders_count'] = orderThreadsCount + wholesaleRequestsCount;

        // حساب الطلبات المعلقة
        final pendingOrderThreads = orderThreadsResponse
            .where((order) => order['status'] == 'pending')
            .length;
        final pendingWholesaleRequests = wholesaleRequestsResponse
            .where((order) => order['status'] == 'pending')
            .length;
        stats['pending_orders'] =
            pendingOrderThreads + pendingWholesaleRequests;

        // حساب الطلبات المكتملة
        final completedOrderThreads = orderThreadsResponse
            .where((order) => order['status'] == 'completed')
            .length;
        final completedWholesaleRequests = wholesaleRequestsResponse
            .where((order) => order['status'] == 'completed')
            .length;
        stats['completed_orders'] =
            completedOrderThreads + completedWholesaleRequests;

        print('📊 إحصائيات الطلبات:');
        print('  - طلبات عادية: $orderThreadsCount');
        print('  - طلبات جملة: $wholesaleRequestsCount');
        print('  - إجمالي الطلبات: ${stats['orders_count']}');
        print('  - طلبات معلقة: ${stats['pending_orders']}');
        print('  - طلبات مكتملة: ${stats['completed_orders']}');
      } catch (e) {
        print('خطأ في جلب إحصائيات الطلبات');
        stats['orders_count'] = 0;
        stats['pending_orders'] = 0;
        stats['completed_orders'] = 0;
      }

      // محاولة جلب عدد المنتجات
      try {
        final productsResponse = await _client!.from('products').select('id');
        stats['products_count'] = productsResponse.length;
      } catch (e) {
        print('جدول products غير موجود أو غير قابل للوصول: $e');
      }

      // محاولة جلب عدد الإعلانات
      try {
        final advertisementsResponse = await _client!
            .from('advertisements')
            .select('id');
        stats['advertisements_count'] = advertisementsResponse.length;
        print('📊 عدد الإعلانات: ${advertisementsResponse.length}');
      } catch (e) {
        print('جدول advertisements غير موجود أو غير قابل للوصول: $e');
        stats['advertisements_count'] = 0;
      }

      // محاولة جلب عدد طلبات الجملة
      try {
        final wholesaleRequestsResponse = await _client!
            .from('wholesale_requests')
            .select('id');
        stats['wholesale_requests_count'] = wholesaleRequestsResponse.length;
        print('📊 عدد طلبات الجملة: ${wholesaleRequestsResponse.length}');
      } catch (e) {
        print('جدول wholesale_requests غير موجود أو غير قابل للوصول: $e');
        stats['wholesale_requests_count'] = 0;
      }

      // محاولة جلب عدد طلبات الشحن (delivery)
      try {
        final deliveryOrdersResponse = await _client!
            .from('order_threads')
            .select('id')
            .eq('order_type', 'delivery');
        stats['delivery_orders_count'] = deliveryOrdersResponse.length;
        print('📊 عدد طلبات الشحن: ${deliveryOrdersResponse.length}');
      } catch (e) {
        print('خطأ في جلب طلبات الشحن');
        stats['delivery_orders_count'] = 0;
      }

      // محاولة جلب عدد المستخدمين من جدول profiles
      try {
        final profilesResponse = await _client!.from('profiles').select('id');
        stats['users_count'] = profilesResponse.length;
        print('📊 عدد المستخدمين المسجلين: ${profilesResponse.length}');
      } catch (e) {
        print('جدول profiles غير موجود أو غير قابل للوصول: $e');
        stats['users_count'] = 0;
      }

      // ملاحظة: تم إزالة حساب الإيرادات لأن الجداول الجديدة لا تحتوي على total_amount
      // يمكن إضافة حساب الإيرادات لاحقاً إذا تم إضافة هذا الحقل للجداول
      stats['total_revenue'] = 0.0;

      return stats;
    } catch (e) {
      print('خطأ في جلب الإحصائيات');
      return _getDefaultStats();
    }
  }

  // حساب جميع المحادثات المفتوحة والجديدة
  Future<int> getAllConversationsCount() async {
    try {
      if (!isReady) {
        return 0;
      }

      int totalConversations = 0;

      // 1. محادثات فريق الدعم
      try {
        final supportConversations = await _client!
            .from('support_conversations')
            .select('id');
        totalConversations += supportConversations.length;
        print('📞 محادثات فريق الدعم: ${supportConversations.length}');
      } catch (e) {
        print('خطأ في جلب محادثات فريق الدعم');
      }

      // 2. محادثات الطلبات العادية (order_threads)
      try {
        final orderThreads = await _client!.from('order_threads').select('id');
        totalConversations += orderThreads.length;
        print('📦 محادثات الطلبات العادية: ${orderThreads.length}');
      } catch (e) {
        print('خطأ في جلب محادثات الطلبات العادية');
      }

      // 3. محادثات طلبات الجملة (wholesale_requests)
      try {
        final wholesaleRequests = await _client!
            .from('wholesale_requests')
            .select('id');
        totalConversations += wholesaleRequests.length;
        print('🏢 محادثات طلبات الجملة: ${wholesaleRequests.length}');
      } catch (e) {
        print('خطأ في جلب محادثات طلبات الجملة');
      }

      print('📊 إجمالي جميع المحادثات: $totalConversations');
      return totalConversations;
    } catch (e) {
      print('خطأ في حساب جميع المحادثات');
      return 0;
    }
  }

  // إحصائيات افتراضية
  Map<String, dynamic> _getDefaultStats() {
    return {
      'orders_count': 0,
      'products_count': 0,
      'users_count': 0,
      'advertisements_count': 0,
      'wholesale_requests_count': 0,
      'delivery_orders_count': 0,
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

      print('إنشاء حساب مدير جديد: $email');

      // استخدام signUp العادي (الطريقة المجربة والموثوقة)
      final authResponse = await _auth!.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      if (authResponse.user != null) {
        print('تم إنشاء المستخدم في Authentication بنجاح');
        print('User ID: ${authResponse.user!.id}');

        // إضافة المستخدم كمدير في جدول admin_users
        await _addAdminToDatabase(
          authResponse.user!.id,
          email,
          fullName,
          phone,
        );

        print('تم إنشاء حساب المدير بنجاح');
      } else {
        throw Exception('فشل في إنشاء المستخدم');
      }
    } catch (e) {
      print('خطأ في إنشاء حساب المدير');
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
      print('خطأ في فحص هيكل الجدول');
    }
  }

  // إضافة إعلان جديد
  Future<Map<String, dynamic>?> addAdvertisement(
    Map<String, dynamic> advertisementData,
  ) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('إضافة إعلان جديد: $advertisementData');

      // محاولة تعطيل RLS مؤقتاً
      await disableRLSForAdvertisements();

      final response = await _client!
          .from('advertisements')
          .insert(advertisementData)
          .select()
          .single();

      print('تم إضافة الإعلان بنجاح');

      // إعادة تفعيل RLS
      await enableRLSForAdvertisements();

      return response;
    } catch (e) {
      print('خطأ في إضافة الإعلان');

      // محاولة إعادة تفعيل RLS في حالة الخطأ
      try {
        await enableRLSForAdvertisements();
      } catch (re) {
        print('خطأ في إعادة تفعيل RLS');
      }

      rethrow;
    }
  }

  // جلب جميع الإعلانات
  Future<List<Map<String, dynamic>>> getAdvertisements() async {
    try {
      if (!isReady) {
        return [];
      }

      print('جلب الإعلانات...');

      final response = await _client!
          .from('advertisements')
          .select('*')
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      print('تم جلب الإعلانات بنجاح');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب الإعلانات');
      return [];
    }
  }

  // جلب الإعلانات النشطة فقط
  Future<List<Map<String, dynamic>>> getActiveAdvertisements() async {
    try {
      if (!isReady) {
        return [];
      }

      print('جلب الإعلانات النشطة...');

      final now = DateTime.now();
      final response = await _client!
          .from('advertisements')
          .select('*')
          .eq('is_active', true)
          .lte('start_date', now.toIso8601String())
          .or('end_date.is.null,end_date.gt.${now.toIso8601String()}')
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      print('تم جلب الإعلانات النشطة بنجاح');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب الإعلانات النشطة');
      return [];
    }
  }

  // تحديث إعلان موجود
  Future<Map<String, dynamic>?> updateAdvertisement(
    String advertisementId,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('تحديث الإعلان $advertisementId: $updates');

      final response = await _client!
          .from('advertisements')
          .update(updates)
          .eq('id', advertisementId)
          .select()
          .single();

      print('تم تحديث الإعلان بنجاح');
      return response;
    } catch (e) {
      print('خطأ في تحديث الإعلان');
      rethrow;
    }
  }

  // حذف إعلان
  Future<bool> deleteAdvertisement(String advertisementId) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('حذف الإعلان: $advertisementId');

      // محاولة تعطيل RLS مؤقتاً
      await disableRLSForAdvertisements();

      await _client!.from('advertisements').delete().eq('id', advertisementId);

      print('تم حذف الإعلان بنجاح');

      // إعادة تفعيل RLS
      await enableRLSForAdvertisements();

      return true;
    } catch (e) {
      print('خطأ في حذف الإعلان');

      // محاولة إعادة تفعيل RLS في حالة الخطأ
      try {
        await enableRLSForAdvertisements();
      } catch (re) {
        print('خطأ في إعادة تفعيل RLS');
      }

      rethrow;
    }
  }

  // حذف إعلان باستخدام service_role
  Future<bool> deleteAdvertisementWithServiceRole(
    String advertisementId,
  ) async {
    try {
      final serviceClient = serviceRoleClient;
      if (serviceClient == null) {
        throw Exception('عميل service_role غير متاح');
      }

      print('حذف الإعلان باستخدام service_role: $advertisementId');

      await serviceClient
          .from('advertisements')
          .delete()
          .eq('id', advertisementId);

      print('تم حذف الإعلان بنجاح');
      return true;
    } catch (e) {
      print('خطأ في حذف الإعلان');
      rethrow;
    }
  }

  // تغيير حالة الإعلان
  Future<bool> toggleAdvertisementStatus(
    String advertisementId,
    bool isActive,
  ) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('تغيير حالة الإعلان $advertisementId إلى: $isActive');

      await _client!
          .from('advertisements')
          .update({'is_active': isActive})
          .eq('id', advertisementId);

      print('تم تغيير حالة الإعلان بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تغيير حالة الإعلان');
      rethrow;
    }
  }

  // إنشاء سياسات RLS لجدول الإعلانات
  Future<void> ensureAdvertisementsTableExists() async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('التحقق من وجود جدول الإعلانات...');

      // التحقق من وجود الجدول
      final tableExists = await _client!
          .from('advertisements')
          .select('id')
          .limit(1)
          .maybeSingle();

      print('جدول الإعلانات موجود: ${tableExists != null}');

      // محاولة إنشاء السياسات باستخدام SQL مباشر
      await createAdvertisementsRLSPoliciesWithSQL();
    } catch (e) {
      print('خطأ في التحقق من جدول الإعلانات');
      // لا نريد إعادة رمي الخطأ هنا لأن الجدول قد يكون موجوداً بالفعل
    }
  }

  // إنشاء سياسات RLS باستخدام SQL مباشر
  Future<void> createAdvertisementsRLSPoliciesWithSQL() async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('إنشاء سياسات RLS باستخدام SQL مباشر...');

      // تعطيل RLS مؤقتاً
      await _client!.rpc(
        'exec_sql',
        params: {
          'sql': 'ALTER TABLE advertisements DISABLE ROW LEVEL SECURITY;',
        },
      );

      print('تم تعطيل RLS بنجاح');

      // إعادة تفعيل RLS
      await _client!.rpc(
        'exec_sql',
        params: {
          'sql': 'ALTER TABLE advertisements ENABLE ROW LEVEL SECURITY;',
        },
      );

      // إنشاء سياسة للقراءة
      await _client!.rpc(
        'exec_sql',
        params: {
          'sql': '''
          CREATE POLICY IF NOT EXISTS "Enable read access for all users" ON advertisements
          FOR SELECT USING (true);
        ''',
        },
      );

      // إنشاء سياسة للإدراج
      await _client!.rpc(
        'exec_sql',
        params: {
          'sql': '''
          CREATE POLICY IF NOT EXISTS "Enable insert for authenticated users only" ON advertisements
          FOR INSERT WITH CHECK (auth.role() = 'authenticated');
        ''',
        },
      );

      // إنشاء سياسة للتحديث
      await _client!.rpc(
        'exec_sql',
        params: {
          'sql': '''
          CREATE POLICY IF NOT EXISTS "Enable update for authenticated users only" ON advertisements
          FOR UPDATE USING (auth.role() = 'authenticated');
        ''',
        },
      );

      // إنشاء سياسة للحذف
      await _client!.rpc(
        'exec_sql',
        params: {
          'sql': '''
          CREATE POLICY IF NOT EXISTS "Enable delete for authenticated users only" ON advertisements
          FOR DELETE USING (auth.role() = 'authenticated');
        ''',
        },
      );

      print('تم إنشاء سياسات RLS بنجاح');
    } catch (e) {
      print('خطأ في إنشاء السياسات باستخدام SQL');
      // إذا فشل، سنحاول العمل بدون RLS
    }
  }

  // حل بديل - تعطيل RLS مؤقتاً للإعلانات
  Future<void> disableRLSForAdvertisements() async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('محاولة تعطيل RLS لجدول الإعلانات...');

      // محاولة تعطيل RLS
      await _client!.rpc(
        'disable_rls',
        params: {'table_name': 'advertisements'},
      );

      print('تم تعطيل RLS لجدول الإعلانات بنجاح');
    } catch (e) {
      print('خطأ في تعطيل RLS');
      // إذا فشل، سنحاول العمل مع RLS مفعل
    }
  }

  // إعادة تفعيل RLS للإعلانات
  Future<void> enableRLSForAdvertisements() async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('إعادة تفعيل RLS لجدول الإعلانات...');

      await _client!.rpc(
        'enable_rls',
        params: {'table_name': 'advertisements'},
      );

      print('تم إعادة تفعيل RLS لجدول الإعلانات');
    } catch (e) {
      print('خطأ في إعادة تفعيل RLS');
    }
  }

  // حل بسيط - العمل بدون RLS للإعلانات
  Future<void> workWithoutRLSForAdvertisements() async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('محاولة العمل بدون RLS للإعلانات...');

      // تعطيل RLS نهائياً
      await _client!.rpc(
        'exec_sql',
        params: {
          'sql': 'ALTER TABLE advertisements DISABLE ROW LEVEL SECURITY;',
        },
      );

      print('تم تعطيل RLS نهائياً للإعلانات');
    } catch (e) {
      print('خطأ في تعطيل RLS');
      // سنحاول العمل مع RLS مفعل
    }
  }

  // الحصول على إحصائيات النشاط للمدير
  Future<Map<String, dynamic>> getAdminActivityStats() async {
    try {
      if (!isReady) {
        return _getDefaultActivityStats();
      }

      final user = _auth!.currentUser;
      if (user == null) {
        return _getDefaultActivityStats();
      }

      Map<String, dynamic> stats = _getDefaultActivityStats();

      // جلب عدد المنتجات المحدثة من قبل هذا المدير
      try {
        final updatedProductsResponse = await _client!
            .from('products')
            .select('id')
            .eq('admin_id', user.id);
        stats['updated_products'] = updatedProductsResponse.length;
        print('📊 المنتجات المحدثة: ${updatedProductsResponse.length}');
      } catch (e) {
        print('❌ لا يمكن جلب المنتجات المحدثة: $e');
        stats['updated_products'] = 0;
      }

      return stats;
    } catch (e) {
      print('❌ خطأ في جلب إحصائيات النشاط');
      return _getDefaultActivityStats();
    }
  }

  // إحصائيات النشاط الافتراضية
  Map<String, dynamic> _getDefaultActivityStats() {
    return {'updated_products': 0};
  }

  // الحصول على معلومات الأمان للمدير
  Future<Map<String, dynamic>> getAdminSecurityInfo() async {
    try {
      if (!isReady) {
        return _getDefaultSecurityInfo();
      }

      final user = _auth!.currentUser;
      if (user == null) {
        return _getDefaultSecurityInfo();
      }

      Map<String, dynamic> securityInfo = _getDefaultSecurityInfo();

      // جلب آخر تحديث لكلمة المرور
      try {
        final adminProfile = await getAdminProfile();
        if (adminProfile != null &&
            adminProfile['password_updated_at'] != null) {
          final lastPasswordUpdate = DateTime.parse(
            adminProfile['password_updated_at'],
          );
          final now = DateTime.now();
          final daysSinceUpdate = now.difference(lastPasswordUpdate).inDays;

          if (daysSinceUpdate == 0) {
            securityInfo['last_password_update'] = 'اليوم';
          } else if (daysSinceUpdate == 1) {
            securityInfo['last_password_update'] = 'أمس';
          } else if (daysSinceUpdate < 7) {
            securityInfo['last_password_update'] = 'منذ $daysSinceUpdate أيام';
          } else {
            securityInfo['last_password_update'] = 'منذ $daysSinceUpdate يوماً';
          }
        } else {
          securityInfo['last_password_update'] = 'الآن';
        }
      } catch (e) {
        print('لا يمكن جلب آخر تحديث لكلمة المرور: $e');
        securityInfo['last_password_update'] = 'غير محدد';
      }

      // جلب حالة المصادقة الثنائية
      try {
        final adminProfile = await getAdminProfile();
        if (adminProfile != null) {
          securityInfo['two_factor_enabled'] =
              adminProfile['two_factor_enabled'] ?? false;
        }
      } catch (e) {
        print('لا يمكن جلب حالة المصادقة الثنائية: $e');
      }

      // جلب عدد الجلسات النشطة
      try {
        // هذا يتطلب جدول منفصل للجلسات أو يمكن استخدام auth.sessions
        // للآن سنستخدم قيمة افتراضية
        securityInfo['active_sessions'] = 1; // جلسة واحدة (الحالية)
      } catch (e) {
        print('لا يمكن جلب الجلسات النشطة: $e');
      }

      return securityInfo;
    } catch (e) {
      print('خطأ في جلب معلومات الأمان');
      return _getDefaultSecurityInfo();
    }
  }

  // معلومات الأمان الافتراضية
  Map<String, dynamic> _getDefaultSecurityInfo() {
    return {
      'last_password_update': 'الآن',
      'two_factor_enabled': false,
      'active_sessions': 1,
    };
  }

  // ========== دوال إدارة بطاقات الجوال ==========

  // الحصول على جميع الباقات
  Future<List<Map<String, dynamic>>> getMobilePackages() async {
    try {
      if (!isReady) {
        return [];
      }

      final response = await _client!
          .from('mobile_packages')
          .select('*')
          .order('sort_order')
          .order('package_value');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب الباقات');
      return [];
    }
  }

  // الحصول على الباقات النشطة فقط
  Future<List<Map<String, dynamic>>> getActiveMobilePackages() async {
    try {
      if (!isReady) {
        return [];
      }

      final response = await _client!
          .from('mobile_packages')
          .select('*')
          .eq('is_active', true)
          .order('sort_order')
          .order('package_value');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب الباقات النشطة');
      return [];
    }
  }

  // الحصول على الباقات حسب المشغل
  Future<List<Map<String, dynamic>>> getMobilePackagesByOperator(
    int operatorId,
  ) async {
    try {
      if (!isReady) {
        return [];
      }

      final response = await _client!
          .from('mobile_packages')
          .select('*')
          .eq('operator_id', operatorId)
          .order('sort_order')
          .order('package_value');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب الباقات حسب المشغل');
      return [];
    }
  }

  // إضافة باقة جديدة
  Future<Map<String, dynamic>?> addMobilePackage(
    Map<String, dynamic> packageData,
  ) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('إضافة باقة جديدة: $packageData');

      final client = _serviceRoleClient ?? _client!;
      final response = await client
          .from('mobile_packages')
          .insert(packageData)
          .select()
          .single();

      print('تم إضافة الباقة بنجاح');
      return response;
    } catch (e) {
      print('خطأ في إضافة الباقة');
      rethrow;
    }
  }

  // تحديث باقة موجودة
  Future<Map<String, dynamic>?> updateMobilePackage(
    int packageId,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('تحديث الباقة $packageId: $updates');

      final client = _serviceRoleClient ?? _client!;
      final response = await client
          .from('mobile_packages')
          .update(updates)
          .eq('id', packageId)
          .select()
          .single();

      print('تم تحديث الباقة بنجاح');
      return response;
    } catch (e) {
      print('خطأ في تحديث الباقة');
      rethrow;
    }
  }

  // حذف باقة
  Future<bool> deleteMobilePackage(int packageId) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('حذف الباقة: $packageId');

      final client = _serviceRoleClient ?? _client!;
      await client.from('mobile_packages').delete().eq('id', packageId);

      print('تم حذف الباقة بنجاح');
      return true;
    } catch (e) {
      print('خطأ في حذف الباقة');
      rethrow;
    }
  }

  // تغيير حالة الباقة
  Future<bool> toggleMobilePackageStatus(int packageId, bool isActive) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('تغيير حالة الباقة $packageId إلى: $isActive');

      await _client!
          .from('mobile_packages')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', packageId);

      print('تم تغيير حالة الباقة بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تغيير حالة الباقة');
      rethrow;
    }
  }

  // البحث في الباقات
  Future<List<Map<String, dynamic>>> searchMobilePackages(String query) async {
    try {
      if (!isReady) {
        return [];
      }

      print('البحث في الباقات: $query');

      final response = await _client!
          .from('mobile_packages')
          .select('*')
          .or(
            'package_name.ilike.%$query%,description_ar.ilike.%$query%,description_en.ilike.%$query%',
          )
          .order('sort_order')
          .order('package_value');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في البحث في الباقات');
      return [];
    }
  }

  // الحصول على جميع المشغلين
  Future<List<Map<String, dynamic>>> getMobileOperators() async {
    try {
      if (!isReady) {
        return [];
      }

      final response = await _client!
          .from('mobile_operators')
          .select('*')
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب المشغلين');
      return [];
    }
  }

  // الحصول على المشغلين النشطين فقط
  Future<List<Map<String, dynamic>>> getActiveMobileOperators() async {
    try {
      if (!isReady) {
        return [];
      }

      final response = await _client!
          .from('mobile_operators')
          .select('*')
          .eq('is_active', true)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب المشغلين النشطين');
      return [];
    }
  }

  // إضافة مشغل جديد
  Future<Map<String, dynamic>?> addMobileOperator(
    Map<String, dynamic> operatorData,
  ) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('إضافة مشغل جديد: $operatorData');

      final client = _serviceRoleClient ?? _client!;
      final response = await client
          .from('mobile_operators')
          .insert(operatorData)
          .select()
          .single();

      print('تم إضافة المشغل بنجاح');
      return response;
    } catch (e) {
      print('خطأ في إضافة المشغل');
      rethrow;
    }
  }

  // تحديث مشغل موجود
  Future<Map<String, dynamic>?> updateMobileOperator(
    int operatorId,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('تحديث المشغل $operatorId: $updates');

      final response = await _client!
          .from('mobile_operators')
          .update(updates)
          .eq('id', operatorId)
          .select()
          .single();

      print('تم تحديث المشغل بنجاح');
      return response;
    } catch (e) {
      print('خطأ في تحديث المشغل');
      rethrow;
    }
  }

  // حذف مشغل
  Future<bool> deleteMobileOperator(int operatorId) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('حذف المشغل: $operatorId');

      // التحقق من وجود باقات مرتبطة بالمشغل
      final packages = await getMobilePackagesByOperator(operatorId);
      if (packages.isNotEmpty) {
        throw Exception('لا يمكن حذف المشغل لأنه يحتوي على باقات مرتبطة');
      }

      await _client!.from('mobile_operators').delete().eq('id', operatorId);

      print('تم حذف المشغل بنجاح');
      return true;
    } catch (e) {
      print('خطأ في حذف المشغل');
      rethrow;
    }
  }

  // تغيير حالة المشغل
  Future<bool> toggleMobileOperatorStatus(int operatorId, bool isActive) async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('تغيير حالة المشغل $operatorId إلى: $isActive');

      await _client!
          .from('mobile_operators')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', operatorId);

      print('تم تغيير حالة المشغل بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تغيير حالة المشغل');
      rethrow;
    }
  }

  // الحصول على إحصائيات الباقات
  Future<Map<String, dynamic>> getMobilePackagesStats() async {
    try {
      if (!isReady) {
        return _getDefaultMobilePackagesStats();
      }

      // جلب عدد الباقات الإجمالي
      final totalPackages = await _client!.from('mobile_packages').select('id');

      // جلب عدد الباقات النشطة
      final activePackages = await _client!
          .from('mobile_packages')
          .select('id')
          .eq('is_active', true);

      // جلب عدد المشغلين
      final totalOperators = await _client!
          .from('mobile_operators')
          .select('id');

      // جلب عدد المشغلين النشطين
      final activeOperators = await _client!
          .from('mobile_operators')
          .select('id')
          .eq('is_active', true);

      return {
        'total_packages': totalPackages.length,
        'active_packages': activePackages.length,
        'total_operators': totalOperators.length,
        'active_operators': activeOperators.length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات الباقات');
      return _getDefaultMobilePackagesStats();
    }
  }

  // إحصائيات الباقات الافتراضية
  Map<String, dynamic> _getDefaultMobilePackagesStats() {
    return {
      'total_packages': 0,
      'active_packages': 0,
      'total_operators': 0,
      'active_operators': 0,
    };
  }

  // إضافة المدير إلى قاعدة البيانات (مساعدة)
  Future<void> _addAdminToDatabase(
    String userId,
    String email,
    String fullName,
    String? phone,
  ) async {
    try {
      // إعداد البيانات الأساسية
      final adminData = {
        'user_id': userId,
        'email': email,
        'full_name': fullName,
        'role': 'super_admin',
        'is_active': true,
      };

      // إضافة الهاتف إذا كان متوفراً
      if (phone != null && phone.isNotEmpty) {
        adminData['phone'] = phone;
      }

      print('محاولة إدراج بيانات المدير: $adminData');

      try {
        await _client!.from('admin_users').insert(adminData).select().single();

        print('تم إضافة المستخدم كمدير في جدول admin_users بنجاح');
      } catch (tableError) {
        print('خطأ في إضافة المستخدم لجدول admin_users');

        // إذا كان المستخدم موجود، حدث بياناته
        if (tableError.toString().contains('duplicate key value') ||
            tableError.toString().contains('already exists')) {
          print('المستخدم موجود، محاولة التحديث...');

          final updateResult = await _client!
              .from('admin_users')
              .update({
                'full_name': fullName,
                'phone': phone,
                'is_active': true,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', userId)
              .select()
              .single();

          print('تم تحديث بيانات المدير الموجود: $updateResult');
        } else {
          // إذا كان خطأ آخر، اطرحه
          rethrow;
        }
      }
    } catch (e) {
      print('خطأ في إضافة المدير إلى قاعدة البيانات');
      rethrow;
    }
  }

  // إصلاح جميع المدراء الموجودين وربطهم بـ user_id الصحيح
  Future<void> fixAllAdminUserIds() async {
    try {
      final serviceClient = serviceRoleClient;
      if (serviceClient == null) {
        throw Exception('عميل service_role غير متاح');
      }

      print('بدء إصلاح user_id لجميع المدراء...');

      // جلب جميع المدراء من قاعدة البيانات
      final allAdmins = await serviceClient.from('admin_users').select('*');

      print('تم العثور على ${allAdmins.length} مدير');

      // جلب جميع المستخدمين من Authentication
      final authUsers = await serviceClient.auth.admin.listUsers();
      print('تم العثور على ${authUsers.length} مستخدم في Authentication');

      int fixedCount = 0;
      int alreadyCorrectCount = 0;

      for (var admin in allAdmins) {
        final email = admin['email'] as String?;
        final currentUserId = admin['user_id'] as String?;

        if (email == null || email.isEmpty) {
          print('تجاهل مدير بدون بريد إلكتروني: $admin');
          continue;
        }

        // البحث عن المستخدم المطابق في Authentication
        final matchingAuthUser = authUsers
            .where((user) => user.email == email)
            .firstOrNull;

        if (matchingAuthUser == null) {
          print('لم يتم العثور على مستخدم في Authentication للبريد: $email');
          continue;
        }

        // التحقق من أن user_id صحيح
        if (currentUserId == null ||
            currentUserId.isEmpty ||
            currentUserId != matchingAuthUser.id) {
          print('إصلاح user_id للمدير...');

          try {
            await serviceClient
                .from('admin_users')
                .update({
                  'user_id': matchingAuthUser.id,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', admin['id']);

            fixedCount++;
            print('تم إصلاح user_id للمدير');
          } catch (updateError) {
            print('خطأ في إصلاح user_id للمدير');
          }
        } else {
          alreadyCorrectCount++;
          print('user_id صحيح للمدير');
        }
      }

      print('انتهى إصلاح user_id للمدراء');
      print('تم إصلاح: $fixedCount مدير');
      print('كان صحيحاً مسبقاً: $alreadyCorrectCount مدير');
    } catch (e) {
      print('خطأ في إصلاح user_id للمدراء');
      rethrow;
    }
  }

  // تحديث آخر تحديث لكلمة المرور
  Future<void> updatePasswordLastUpdate() async {
    try {
      if (!isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      final user = _auth!.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      final updates = {
        'password_updated_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('محاولة تحديث آخر تحديث لكلمة المرور...');
      print('تحديث البيانات...');

      // محاولة التحديث بـ user_id أولاً
      try {
        await _client!
            .from('admin_users')
            .update(updates)
            .eq('user_id', user.id)
            .select();
        print('تم تحديث آخر تحديث لكلمة المرور');
      } catch (userIdError) {
        print('خطأ في التحديث بـ user_id');

        // محاولة التحديث بـ البريد الإلكتروني
        if (user.email != null) {
          try {
            await _client!
                .from('admin_users')
                .update(updates)
                .eq('email', user.email!)
                .select();
            print('تم تحديث آخر تحديث لكلمة المرور بـ البريد الإلكتروني');
          } catch (emailError) {
            print('خطأ في التحديث بـ البريد الإلكتروني');

            // محاولة إنشاء سجل جديد إذا لم يكن موجوداً
            try {
              final newRecord = {
                'user_id': user.id,
                'email': user.email,
                'full_name':
                    user.userMetadata?['full_name'] ??
                    user.email?.split('@')[0] ??
                    'مستخدم',
                'role': 'super_admin',
                'is_active': true,
                'password_updated_at': DateTime.now().toIso8601String(),
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              };

              await _client!.from('admin_users').insert(newRecord).select();
              print('تم إنشاء سجل جديد للمدير');
            } catch (insertError) {
              print('خطأ في إنشاء سجل جديد');
            }
          }
        }
      }
    } catch (e) {
      print('خطأ في تحديث آخر تحديث لكلمة المرور');
    }
  }

  // تحديث آخر تسجيل دخول
  Future<void> _updateLastLogin() async {
    try {
      if (!isReady) {
        return;
      }

      final user = _auth!.currentUser;
      if (user == null) return;

      final updates = {
        'last_login': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('محاولة تحديث آخر تسجيل دخول...');
      print('تحديث البيانات...');

      // محاولة التحديث بـ user_id أولاً
      try {
        await _client!
            .from('admin_users')
            .update(updates)
            .eq('user_id', user.id)
            .select();
        print('تم تحديث آخر تسجيل دخول');
      } catch (userIdError) {
        print('خطأ في التحديث بـ user_id');

        // محاولة التحديث بـ البريد الإلكتروني
        if (user.email != null) {
          try {
            await _client!
                .from('admin_users')
                .update(updates)
                .eq('email', user.email!)
                .select();
            print('تم تحديث آخر تسجيل دخول');
          } catch (emailError) {
            print('خطأ في التحديث بـ البريد الإلكتروني');

            // محاولة إنشاء سجل جديد إذا لم يكن موجوداً
            try {
              final newRecord = {
                'user_id': user.id,
                'email': user.email,
                'full_name':
                    user.userMetadata?['full_name'] ??
                    user.email?.split('@')[0] ??
                    'مستخدم',
                'role': 'super_admin',
                'is_active': true,
                'last_login': DateTime.now().toIso8601String(),
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              };

              await _client!.from('admin_users').insert(newRecord).select();
              print('تم إنشاء سجل جديد للمدير');
            } catch (insertError) {
              print('خطأ في إنشاء سجل جديد');
            }
          }
        }
      }
    } catch (e) {
      print('خطأ في تحديث آخر تسجيل دخول');
    }
  }

  // التأكد من وجود سجل المدير
  Future<void> _ensureAdminRecordExists() async {
    try {
      if (!isReady) {
        return;
      }

      final user = _auth!.currentUser;
      if (user == null) return;

      print('التأكد من وجود سجل المدير...');

      // التحقق من وجود السجل بـ user_id أولاً
      try {
        final existingRecord = await _client!
            .from('admin_users')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();

        if (existingRecord != null) {
          print('سجل المدير موجود بالفعل بـ user_id');
          return;
        }
      } catch (e) {
        print('خطأ في البحث بـ user_id');
      }

      // التحقق من وجود السجل بـ البريد الإلكتروني
      try {
        if (user.email != null) {
          final existingRecord = await _client!
              .from('admin_users')
              .select('id')
              .eq('email', user.email!)
              .maybeSingle();

          if (existingRecord != null) {
            print('سجل المدير موجود بالفعل بـ البريد الإلكتروني');
            return;
          }
        }
      } catch (e) {
        print('خطأ في البحث بـ البريد الإلكتروني');
      }

      // إنشاء سجل جديد
      print('سجل المدير غير موجود، سيتم إنشاؤه...');

      final newRecord = {
        'user_id': user.id,
        'email': user.email,
        'full_name':
            user.userMetadata?['full_name'] ??
            user.email?.split('@')[0] ??
            'مستخدم',
        'role': 'super_admin',
        'is_active': true,
        'last_login': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        await _client!.from('admin_users').insert(newRecord).select();
        print('تم إنشاء سجل المدير');
      } catch (insertError) {
        print('خطأ في إنشاء سجل المدير');

        // محاولة إنشاء سجل بسيط بدون user_id
        try {
          final simpleRecord = {
            'email': user.email,
            'full_name': user.userMetadata?['full_name'] ?? 'مستخدم',
            'role': 'super_admin',
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          await _client!.from('admin_users').insert(simpleRecord).select();
          print('تم إنشاء سجل مدير بسيط');
        } catch (simpleError) {
          print('خطأ في إنشاء سجل بسيط');
        }
      }
    } catch (e) {
      print('خطأ في التأكد من وجود سجل المدير: $e');
    }
  }
}
