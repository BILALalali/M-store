import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'supabase_service.dart';

class UsersService {
  final SupabaseService _supabaseService = SupabaseService();

  // الحصول على جميع المستخدمين من جدول profiles
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      if (!_supabaseService.isReady) {
        return [];
      }

      print('جلب المستخدمين من جدول profiles...');

      final response = await _supabaseService.client!
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);

      print('تم جلب ${response.length} مستخدم');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب المستخدمين: $e');
      return [];
    }
  }

  // البحث في المستخدمين
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (!_supabaseService.isReady) {
        return [];
      }

      print('البحث في المستخدمين: $query');

      final response = await _supabaseService.client!
          .from('profiles')
          .select('*')
          .or(
            'name.ilike.%$query%,phone.ilike.%$query%,governorate.ilike.%$query%,address.ilike.%$query%',
          )
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في البحث في المستخدمين: $e');
      return [];
    }
  }

  // حذف مستخدم من جدول profiles ونظام المصادقة
  Future<bool> deleteUser(String userId) async {
    try {
      if (!_supabaseService.isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('حذف المستخدم: $userId');

      // حذف المستخدم من جدول profiles
      await _supabaseService.client!.from('profiles').delete().eq('id', userId);
      print('تم حذف المستخدم من جدول profiles');

      // حذف المستخدم من نظام المصادقة
      try {
        await _supabaseService.client!.auth.admin.deleteUser(userId);
        print('تم حذف المستخدم من نظام المصادقة');
      } catch (authError) {
        print('تحذير: فشل حذف المستخدم من نظام المصادقة: $authError');
        // لا نرمي الخطأ هنا لأن المستخدم تم حذفه من profiles
        // قد يكون المستخدم غير موجود في نظام المصادقة أو لا توجد صلاحيات كافية
      }

      print('تم حذف المستخدم بنجاح');
      return true;
    } catch (e) {
      print('خطأ في حذف المستخدم: $e');
      rethrow;
    }
  }

  // حذف مستخدم باستخدام service_role (للمدراء)
  Future<bool> deleteUserWithServiceRole(String userId) async {
    try {
      final serviceClient = _supabaseService.serviceRoleClient;
      if (serviceClient == null) {
        throw Exception('عميل service_role غير متاح');
      }

      print('حذف المستخدم باستخدام service_role: $userId');

      // حذف المستخدم من جدول profiles
      await serviceClient.from('profiles').delete().eq('id', userId);
      print('تم حذف المستخدم من جدول profiles');

      // حذف المستخدم من نظام المصادقة باستخدام service_role
      try {
        await serviceClient.auth.admin.deleteUser(userId);
        print('تم حذف المستخدم من نظام المصادقة');
      } catch (authError) {
        print('تحذير: فشل حذف المستخدم من نظام المصادقة: $authError');
        // لا نرمي الخطأ هنا لأن المستخدم تم حذفه من profiles
      }

      print('تم حذف المستخدم بنجاح');
      return true;
    } catch (e) {
      print('خطأ في حذف المستخدم: $e');
      rethrow;
    }
  }

  // الحصول على تفاصيل مستخدم محدد
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      if (!_supabaseService.isReady) {
        return null;
      }

      print('جلب تفاصيل المستخدم: $userId');

      final response = await _supabaseService.client!
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('خطأ في جلب تفاصيل المستخدم: $e');
      return null;
    }
  }

  // الحصول على إحصائيات المستخدمين
  Future<Map<String, dynamic>> getUsersStats() async {
    try {
      if (!_supabaseService.isReady) {
        return _getDefaultStats();
      }

      // جلب إجمالي المستخدمين
      final totalUsers = await _supabaseService.client!
          .from('profiles')
          .select('id');

      // جلب المستخدمين المسجلين هذا الشهر
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final newUsersThisMonth = await _supabaseService.client!
          .from('profiles')
          .select('id')
          .gte('created_at', startOfMonth.toIso8601String());

      // جلب المستخدمين حسب المحافظة
      final usersByGovernorate = await _supabaseService.client!
          .from('profiles')
          .select('governorate')
          .not('governorate', 'is', null);

      Map<String, int> governorateCount = {};
      for (var user in usersByGovernorate) {
        final governorate = user['governorate'] as String?;
        if (governorate != null) {
          governorateCount[governorate] =
              (governorateCount[governorate] ?? 0) + 1;
        }
      }

      return {
        'total_users': totalUsers.length,
        'new_users_this_month': newUsersThisMonth.length,
        'users_by_governorate': governorateCount,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات المستخدمين: $e');
      return _getDefaultStats();
    }
  }

  // تغيير كلمة مرور المستخدم باستخدام service_role
  Future<bool> resetUserPassword(String userId, String newPassword) async {
    try {
      // التأكد من تحميل dotenv
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: "assets/env");
      }

      final url = dotenv.env['SUPABASE_URL'];
      final serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];

      if (url == null || serviceRoleKey == null) {
        throw Exception('بيانات service_role غير موجودة في ملف env');
      }

      print('🔑 إعداد عميل service_role...');
      print('🔑 URL: $url');
      print('🔑 Service Role Key موجود: ${serviceRoleKey.isNotEmpty}');
      print('🔑 Service Role Key (أول 20 حرف): ${serviceRoleKey.substring(0, serviceRoleKey.length > 20 ? 20 : serviceRoleKey.length)}...');

      // إنشاء عميل service_role جديد
      final serviceClient = SupabaseClient(url, serviceRoleKey);

      print('✅ تم إنشاء عميل service_role بنجاح');
      print('🔐 تغيير كلمة مرور المستخدم: $userId');

      // التحقق من أن userId موجود في profiles
      final userProfile = await getUserById(userId);
      if (userProfile == null) {
        throw Exception('المستخدم غير موجود في جدول profiles');
      }

      print('📋 بيانات المستخدم من profiles: $userProfile');

      // البحث عن المستخدم في Authentication باستخدام userId
      // userId من profiles هو نفسه user_id في auth.users
      print('🔍 البحث عن المستخدم في Authentication...');
      final usersResponse = await serviceClient.auth.admin.listUsers();
      print('📊 عدد المستخدمين في Authentication: ${usersResponse.length}');

      // البحث عن المستخدم باستخدام userId
      final authUser = usersResponse.firstWhere(
        (user) => user.id == userId,
        orElse: () => throw Exception('المستخدم غير موجود في Authentication'),
      );

      print('✅ تم العثور على المستخدم في Authentication');
      print('📧 البريد الإلكتروني: ${authUser.email}');
      print('🆔 User ID: ${authUser.id}');

      // تحديث كلمة المرور
      print('🔐 تحديث كلمة المرور...');
      await serviceClient.auth.admin.updateUserById(
        authUser.id,
        attributes: AdminUserAttributes(password: newPassword),
      );

      print('✅ تم تغيير كلمة مرور المستخدم بنجاح');
      return true;
    } catch (e) {
      print('❌ خطأ في تغيير كلمة مرور المستخدم: $e');
      print('❌ نوع الخطأ: ${e.runtimeType}');
      print('❌ تفاصيل الخطأ: ${e.toString()}');
      
      // رسالة خطأ أوضح
      if (e.toString().contains('Invalid API key') || 
          e.toString().contains('401')) {
        throw Exception('مفتاح API غير صحيح أو منتهي الصلاحية. يرجى التحقق من SUPABASE_SERVICE_ROLE_KEY في ملف env');
      } else if (e.toString().contains('not found') || 
                 e.toString().contains('غير موجود')) {
        throw Exception('المستخدم غير موجود في نظام المصادقة');
      } else {
        rethrow;
      }
    }
  }

  // إحصائيات افتراضية
  Map<String, dynamic> _getDefaultStats() {
    return {
      'total_users': 0,
      'new_users_this_month': 0,
      'users_by_governorate': <String, int>{},
    };
  }
}
