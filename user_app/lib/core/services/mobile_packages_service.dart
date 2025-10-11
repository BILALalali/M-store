import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../../presentation/screens/mobile_package_model.dart';

class MobilePackagesService {
  static const String _packagesTable = 'mobile_packages';
  static const String _operatorsTable = 'mobile_operators';

  // الحصول على جميع الباقات النشطة
  static Future<List<MobilePackage>> getAllPackages() async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        print('Supabase غير متصل، سيتم استخدام البيانات المحلية');
        return [];
      }

      print('محاولة جلب الباقات من جدول: $_packagesTable');

      // جلب الباقات أولاً
      final response = await client
          .from(_packagesTable)
          .select('*')
          .eq('is_active', true)
          .order('sort_order')
          .order('package_value');

      print('تم جلب ${response?.length ?? 0} باقة');

      if (response == null || response.isEmpty) {
        print('لا توجد باقات في قاعدة البيانات');
        return [];
      }

      List<MobilePackage> packages = [];
      for (var row in response) {
        try {
          final package = MobilePackage.fromJson(row);

          // جلب معلومات المشغل بشكل منفصل
          if (package.operatorId > 0) {
            try {
              final operatorResponse = await client
                  .from(_operatorsTable)
                  .select('*')
                  .eq('id', package.operatorId)
                  .eq('is_active', true)
                  .single();

              if (operatorResponse != null) {
                package.operator = MobileOperatorModel.fromJson(
                  operatorResponse,
                );
                print(
                  'تم جلب معلومات المشغل: ${package.operator?.displayNameAr}',
                );
              }
            } catch (operatorError) {
              print(
                'خطأ في جلب معلومات المشغل ${package.operatorId}: $operatorError',
              );
              // استمر بدون معلومات المشغل
            }
          }

          packages.add(package);
        } catch (packageError) {
          print('خطأ في معالجة الباقة: $packageError');
          // تخطى الباقة المعطوبة
        }
      }

      print('تم معالجة ${packages.length} باقة بنجاح');
      return packages;
    } catch (e) {
      print('خطأ في جلب جميع الباقات: $e');
      print('تفاصيل الخطأ: ${e.toString()}');
      rethrow;
    }
  }

  // الحصول على الباقات حسب المشغل
  static Future<List<MobilePackage>> getPackagesByOperator(
    String operatorName,
  ) async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        print('Supabase غير متصل، سيتم استخدام البيانات المحلية');
        return [];
      }

      print('محاولة جلب الباقات للمشغل: $operatorName');

      // أولاً: جلب معرف المشغل
      final operatorResponse = await client
          .from(_operatorsTable)
          .select('*')
          .eq('name', operatorName)
          .eq('is_active', true)
          .single();

      if (operatorResponse == null) {
        print('لم يتم العثور على المشغل: $operatorName');
        return [];
      }

      final operatorId = operatorResponse['id'];
      final operator = MobileOperatorModel.fromJson(operatorResponse);
      print(
        'تم العثور على المشغل: ${operator.displayNameAr} (ID: $operatorId)',
      );

      // ثم جلب الباقات حسب معرف المشغل
      final response = await client
          .from(_packagesTable)
          .select('*')
          .eq('is_active', true)
          .eq('operator_id', operatorId)
          .order('sort_order')
          .order('package_value');

      print('تم جلب ${response?.length ?? 0} باقة للمشغل $operatorName');

      if (response == null || response.isEmpty) {
        return [];
      }

      List<MobilePackage> packages = [];
      for (var row in response) {
        try {
          final package = MobilePackage.fromJson(row);
          package.operator = operator; // إضافة معلومات المشغل
          packages.add(package);
        } catch (packageError) {
          print('خطأ في معالجة الباقة: $packageError');
        }
      }

      return packages;
    } catch (e) {
      print('خطأ في جلب الباقات حسب المشغل: $e');
      print('تفاصيل الخطأ: ${e.toString()}');
      rethrow;
    }
  }

  // الحصول على جميع المشغلين النشطين
  static Future<List<MobileOperatorModel>> getAllOperators() async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      final response = await client
          .from(_operatorsTable)
          .select('*')
          .eq('is_active', true)
          .order('name');

      if (response == null) return [];

      return response.map((row) => MobileOperatorModel.fromJson(row)).toList();
    } catch (e) {
      print('خطأ في جلب المشغلين: $e');
      rethrow;
    }
  }

  // البحث في الباقات
  static Future<List<MobilePackage>> searchPackages(String query) async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      final response = await client
          .from(_packagesTable)
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
          .or('package_name.ilike.%$query%,description_ar.ilike.%$query%')
          .order('sort_order')
          .order('package_value');

      if (response == null) return [];

      List<MobilePackage> packages = [];
      for (var row in response) {
        final package = MobilePackage.fromJson(row);

        // إضافة معلومات المشغل
        if (row['mobile_operators'] != null) {
          package.operator = MobileOperatorModel.fromJson(
            row['mobile_operators'],
          );
        }

        packages.add(package);
      }

      return packages;
    } catch (e) {
      print('خطأ في البحث في الباقات: $e');
      rethrow;
    }
  }

  // الحصول على الباقات حسب نطاق السعر
  static Future<List<MobilePackage>> getPackagesByPriceRange(
    double minPrice,
    double maxPrice,
  ) async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      final response = await client
          .from(_packagesTable)
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
          .gte('package_price', minPrice)
          .lte('package_price', maxPrice)
          .order('package_price')
          .order('sort_order');

      if (response == null) return [];

      List<MobilePackage> packages = [];
      for (var row in response) {
        final package = MobilePackage.fromJson(row);

        // إضافة معلومات المشغل
        if (row['mobile_operators'] != null) {
          package.operator = MobileOperatorModel.fromJson(
            row['mobile_operators'],
          );
        }

        packages.add(package);
      }

      return packages;
    } catch (e) {
      print('خطأ في جلب الباقات حسب نطاق السعر: $e');
      rethrow;
    }
  }

  // الحصول على الباقات حسب القيمة
  static Future<List<MobilePackage>> getPackagesByValue(double value) async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      final response = await client
          .from(_packagesTable)
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
          .eq('package_value', value)
          .order('package_price')
          .order('sort_order');

      if (response == null) return [];

      List<MobilePackage> packages = [];
      for (var row in response) {
        final package = MobilePackage.fromJson(row);

        // إضافة معلومات المشغل
        if (row['mobile_operators'] != null) {
          package.operator = MobileOperatorModel.fromJson(
            row['mobile_operators'],
          );
        }

        packages.add(package);
      }

      return packages;
    } catch (e) {
      print('خطأ في جلب الباقات حسب القيمة: $e');
      rethrow;
    }
  }

  // إضافة باقة جديدة (للمشرفين فقط)
  static Future<MobilePackage> addPackage(
    Map<String, dynamic> packageData,
  ) async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      // التحقق من الصلاحيات (يمكن إضافة منطق التحقق هنا)

      final response = await client
          .from(_packagesTable)
          .insert(packageData)
          .select()
          .single();

      return MobilePackage.fromJson(response);
    } catch (e) {
      print('خطأ في إضافة الباقة: $e');
      rethrow;
    }
  }

  // تحديث باقة موجودة (للمشرفين فقط)
  static Future<MobilePackage> updatePackage(
    int packageId,
    Map<String, dynamic> packageData,
  ) async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      // التحقق من الصلاحيات (يمكن إضافة منطق التحقق هنا)

      final response = await client
          .from(_packagesTable)
          .update(packageData)
          .eq('id', packageId)
          .select()
          .single();

      return MobilePackage.fromJson(response);
    } catch (e) {
      print('خطأ في تحديث الباقة: $e');
      rethrow;
    }
  }

  // حذف باقة (للمشرفين فقط)
  static Future<void> deletePackage(int packageId) async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      // التحقق من الصلاحيات (يمكن إضافة منطق التحقق هنا)

      await client.from(_packagesTable).delete().eq('id', packageId);
    } catch (e) {
      print('خطأ في حذف الباقة: $e');
      rethrow;
    }
  }

  // تفعيل/إلغاء تفعيل باقة (للمشرفين فقط)
  static Future<void> togglePackageStatus(int packageId, bool isActive) async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      // التحقق من الصلاحيات (يمكن إضافة منطق التحقق هنا)

      await client
          .from(_packagesTable)
          .update({'is_active': isActive})
          .eq('id', packageId);
    } catch (e) {
      print('خطأ في تغيير حالة الباقة: $e');
      rethrow;
    }
  }

  // اختبار الاتصال بقاعدة البيانات
  static Future<bool> testConnection() async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        print('Supabase غير متصل');
        return false;
      }

      print('اختبار الاتصال بقاعدة البيانات...');
      // print('URL: ${client.supabaseUrl}'); // supabaseUrl غير متاح في API الجديد
      print('Table: $_packagesTable');

      // اختبار جلب جميع الباقات (بدون فلتر)
      try {
        final allPackages = await client.from(_packagesTable).select('*');
        print('إجمالي الباقات في قاعدة البيانات: ${allPackages?.length ?? 0}');
      } catch (e) {
        print('خطأ في جلب جميع الباقات: $e');
      }

      // اختبار جلب الباقات النشطة
      try {
        final activePackages = await client
            .from(_packagesTable)
            .select('*')
            .eq('is_active', true);
        print('الباقات النشطة: ${activePackages?.length ?? 0}');
      } catch (e) {
        print('خطأ في جلب الباقات النشطة: $e');
      }

      // اختبار جلب المشغلين
      try {
        final operators = await client.from(_operatorsTable).select('*');
        print('إجمالي المشغلين: ${operators?.length ?? 0}');
      } catch (e) {
        print('خطأ في جلب المشغلين: $e');
      }

      return true;
    } catch (e) {
      print('فشل في الاتصال: $e');
      print('نوع الخطأ: ${e.runtimeType}');
      print('تفاصيل الخطأ: ${e.toString()}');

      // محاولة جلب معلومات أكثر عن الخطأ
      if (e.toString().contains('permission denied')) {
        print('المشكلة: رفض الصلاحيات - تأكد من إعدادات RLS');
      } else if (e.toString().contains('table')) {
        print('المشكلة: جدول غير موجود - تأكد من اسم الجدول');
      } else if (e.toString().contains('connection')) {
        print('المشكلة: فشل في الاتصال - تأكد من الشبكة');
      }

      return false;
    }
  }

  // الحصول على إحصائيات الباقات
  static Future<Map<String, dynamic>> getPackagesStats() async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      // إجمالي عدد الباقات
      final totalPackages = await client.from(_packagesTable).select('*');

      // الباقات النشطة
      final activePackages = await client
          .from(_packagesTable)
          .select('*')
          .eq('is_active', true);

      // عدد المشغلين
      final totalOperators = await client.from(_operatorsTable).select('*');

      // المشغلين النشطين
      final activeOperators = await client
          .from(_operatorsTable)
          .select('*')
          .eq('is_active', true);

      return {
        'total_packages': totalPackages.length,
        'active_packages': activePackages.length,
        'total_operators': totalOperators.length,
        'active_operators': activeOperators.length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات الباقات: $e');
      rethrow;
    }
  }
}
