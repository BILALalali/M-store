import '../models/mobile_package.dart';
import 'supabase_service.dart';

class MobilePackagesService {
  static const String _packagesTable = 'mobile_packages';
  static const String _operatorsTable = 'mobile_operators';

  // الحصول على جميع الباقات
  static Future<List<MobilePackage>> getAllPackages() async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('جلب جميع الباقات من جدول: $_packagesTable');

      final response = await client
          .from(_packagesTable)
          .select('*')
          .order('sort_order')
          .order('package_value');

      print('تم جلب ${response.length} باقة');

      return response.map((row) => MobilePackage.fromMap(row)).toList();
    } catch (e) {
      print('خطأ في جلب الباقات: $e');
      rethrow;
    }
  }

  // الحصول على الباقات النشطة فقط
  static Future<List<MobilePackage>> getActivePackages() async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      final response = await client
          .from(_packagesTable)
          .select('*')
          .eq('is_active', true)
          .order('sort_order')
          .order('package_value');

      return response.map((row) => MobilePackage.fromMap(row)).toList();
    } catch (e) {
      print('خطأ في جلب الباقات النشطة: $e');
      rethrow;
    }
  }

  // الحصول على الباقات حسب المشغل
  static Future<List<MobilePackage>> getPackagesByOperator(
    int operatorId,
  ) async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      final response = await client
          .from(_packagesTable)
          .select('*')
          .eq('operator_id', operatorId)
          .order('sort_order')
          .order('package_value');

      return response.map((row) => MobilePackage.fromMap(row)).toList();
    } catch (e) {
      print('خطأ في جلب الباقات حسب المشغل: $e');
      rethrow;
    }
  }

  // إضافة باقة جديدة
  static Future<MobilePackage> addPackage(MobilePackage package) async {
    try {
      final supabaseService = SupabaseService();
      final client =
          supabaseService.serviceRoleClient ?? supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('إضافة باقة جديدة: ${package.packageName}');

      final packageData = package.toMap();
      packageData.remove('id'); // إزالة ID للإنشاء
      packageData['created_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from(_packagesTable)
          .insert(packageData)
          .select()
          .single();

      print('تم إضافة الباقة بنجاح: $response');
      return MobilePackage.fromMap(response);
    } catch (e) {
      print('خطأ في إضافة الباقة: $e');
      rethrow;
    }
  }

  // تحديث باقة موجودة
  static Future<MobilePackage> updatePackage(MobilePackage package) async {
    try {
      final supabaseService = SupabaseService();
      final client =
          supabaseService.serviceRoleClient ?? supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      if (package.id == null) {
        throw Exception('معرف الباقة مطلوب للتحديث');
      }

      print('تحديث الباقة: ${package.packageName}');

      final packageData = package.toMap();
      packageData.remove('created_at'); // عدم تحديث تاريخ الإنشاء

      final response = await client
          .from(_packagesTable)
          .update(packageData)
          .eq('id', package.id!)
          .select()
          .single();

      print('تم تحديث الباقة بنجاح: $response');
      return MobilePackage.fromMap(response);
    } catch (e) {
      print('خطأ في تحديث الباقة: $e');
      rethrow;
    }
  }

  // حذف باقة
  static Future<bool> deletePackage(int packageId) async {
    try {
      final supabaseService = SupabaseService();
      final client =
          supabaseService.serviceRoleClient ?? supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('حذف الباقة: $packageId');

      await client.from(_packagesTable).delete().eq('id', packageId);

      print('تم حذف الباقة بنجاح');
      return true;
    } catch (e) {
      print('خطأ في حذف الباقة: $e');
      rethrow;
    }
  }

  // تغيير حالة الباقة (نشط/غير نشط)
  static Future<bool> togglePackageStatus(int packageId, bool isActive) async {
    try {
      final supabaseService = SupabaseService();
      final client =
          supabaseService.serviceRoleClient ?? supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('تغيير حالة الباقة $packageId إلى: $isActive');

      await client
          .from(_packagesTable)
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', packageId);

      print('تم تغيير حالة الباقة بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تغيير حالة الباقة: $e');
      rethrow;
    }
  }

  // البحث في الباقات
  static Future<List<MobilePackage>> searchPackages(String query) async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('البحث في الباقات: $query');

      final response = await client
          .from(_packagesTable)
          .select('*')
          .or(
            'package_name.ilike.%$query%,description_ar.ilike.%$query%,description_en.ilike.%$query%',
          )
          .order('sort_order')
          .order('package_value');

      return response.map((row) => MobilePackage.fromMap(row)).toList();
    } catch (e) {
      print('خطأ في البحث في الباقات: $e');
      rethrow;
    }
  }

  // الحصول على جميع المشغلين
  static Future<List<MobileOperator>> getAllOperators() async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('جلب جميع المشغلين من جدول: $_operatorsTable');

      final response = await client
          .from(_operatorsTable)
          .select('*')
          .order('name');

      print('تم جلب ${response.length} مشغل');

      return response.map((row) => MobileOperator.fromMap(row)).toList();
    } catch (e) {
      print('خطأ في جلب المشغلين: $e');
      rethrow;
    }
  }

  // الحصول على المشغلين النشطين فقط
  static Future<List<MobileOperator>> getActiveOperators() async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      final response = await client
          .from(_operatorsTable)
          .select('*')
          .eq('is_active', true)
          .order('name');

      return response.map((row) => MobileOperator.fromMap(row)).toList();
    } catch (e) {
      print('خطأ في جلب المشغلين النشطين: $e');
      rethrow;
    }
  }

  // إضافة مشغل جديد
  static Future<MobileOperator> addOperator(MobileOperator operator) async {
    try {
      final supabaseService = SupabaseService();
      final client =
          supabaseService.serviceRoleClient ?? supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('إضافة مشغل جديد: ${operator.name}');

      final operatorData = operator.toMap();
      operatorData.remove('id'); // إزالة ID للإنشاء
      operatorData['created_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from(_operatorsTable)
          .insert(operatorData)
          .select()
          .single();

      print('تم إضافة المشغل بنجاح: $response');
      return MobileOperator.fromMap(response);
    } catch (e) {
      print('خطأ في إضافة المشغل: $e');
      rethrow;
    }
  }

  // تحديث مشغل موجود
  static Future<MobileOperator> updateOperator(MobileOperator operator) async {
    try {
      final supabaseService = SupabaseService();
      final client =
          supabaseService.serviceRoleClient ?? supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      if (operator.id == null) {
        throw Exception('معرف المشغل مطلوب للتحديث');
      }

      print('تحديث المشغل: ${operator.name}');

      final operatorData = operator.toMap();
      operatorData.remove('created_at'); // عدم تحديث تاريخ الإنشاء

      final response = await client
          .from(_operatorsTable)
          .update(operatorData)
          .eq('id', operator.id!)
          .select()
          .single();

      print('تم تحديث المشغل بنجاح: $response');
      return MobileOperator.fromMap(response);
    } catch (e) {
      print('خطأ في تحديث المشغل: $e');
      rethrow;
    }
  }

  // حذف مشغل
  static Future<bool> deleteOperator(int operatorId) async {
    try {
      final supabaseService = SupabaseService();
      final client =
          supabaseService.serviceRoleClient ?? supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('حذف المشغل: $operatorId');

      // التحقق من وجود باقات مرتبطة بالمشغل
      final packages = await getPackagesByOperator(operatorId);
      if (packages.isNotEmpty) {
        throw Exception('لا يمكن حذف المشغل لأنه يحتوي على باقات مرتبطة');
      }

      await client.from(_operatorsTable).delete().eq('id', operatorId);

      print('تم حذف المشغل بنجاح');
      return true;
    } catch (e) {
      print('خطأ في حذف المشغل: $e');
      rethrow;
    }
  }

  // تغيير حالة المشغل (نشط/غير نشط)
  static Future<bool> toggleOperatorStatus(
    int operatorId,
    bool isActive,
  ) async {
    try {
      final supabaseService = SupabaseService();
      final client =
          supabaseService.serviceRoleClient ?? supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('تغيير حالة المشغل $operatorId إلى: $isActive');

      await client
          .from(_operatorsTable)
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', operatorId);

      print('تم تغيير حالة المشغل بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تغيير حالة المشغل: $e');
      rethrow;
    }
  }

  // الحصول على إحصائيات الباقات
  static Future<Map<String, dynamic>> getPackagesStats() async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      // جلب عدد الباقات الإجمالي
      final totalPackages = await client.from(_packagesTable).select('id');

      // جلب عدد الباقات النشطة
      final activePackages = await client
          .from(_packagesTable)
          .select('id')
          .eq('is_active', true);

      // جلب عدد المشغلين
      final totalOperators = await client.from(_operatorsTable).select('id');

      // جلب عدد المشغلين النشطين
      final activeOperators = await client
          .from(_operatorsTable)
          .select('id')
          .eq('is_active', true);

      return {
        'total_packages': totalPackages.length,
        'active_packages': activePackages.length,
        'total_operators': totalOperators.length,
        'active_operators': activeOperators.length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات الباقات: $e');
      return {
        'total_packages': 0,
        'active_packages': 0,
        'total_operators': 0,
        'active_operators': 0,
      };
    }
  }
}
