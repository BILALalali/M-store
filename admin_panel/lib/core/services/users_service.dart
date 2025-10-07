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

  // إحصائيات افتراضية
  Map<String, dynamic> _getDefaultStats() {
    return {
      'total_users': 0,
      'new_users_this_month': 0,
      'users_by_governorate': <String, int>{},
    };
  }
}
