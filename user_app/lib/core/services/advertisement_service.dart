import 'package:supabase_flutter/supabase_flutter.dart';
import '../../presentation/screens/advertisement_model.dart';
import 'supabase_service.dart';

class AdvertisementService {
  static const String _tableName = 'advertisements';

  // جلب جميع الإعلانات النشطة والصالحة
  static Future<List<Advertisement>> getActiveAdvertisements() async {
    try {
      // التحقق من أن Supabase متوفر
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }

      // جلب الإعلانات النشطة والصالحة من قاعدة البيانات
      final response = await SupabaseService.client!
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .order('priority', ascending: true)
          .order('created_at', ascending: false);

      if (response == null) return [];

      final advertisements = (response as List)
          .map((ad) => Advertisement.fromMap(ad))
          .where((ad) => ad.isValid) // فلترة الإعلانات الصالحة فقط
          .toList();

      return advertisements;
    } catch (e) {
      print('خطأ في جلب الإعلانات من قاعدة البيانات: $e');
      rethrow;
    }
  }

  // جلب إعلان واحد حسب المعرف
  static Future<Advertisement?> getAdvertisementById(String id) async {
    try {
      // التحقق من أن Supabase متوفر
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }

      final response = await SupabaseService.client!
          .from(_tableName)
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .single();

      if (response == null) return null;

      final advertisement = Advertisement.fromMap(response);
      return advertisement.isValid ? advertisement : null;
    } catch (e) {
      print('خطأ في جلب الإعلان من قاعدة البيانات: $e');
      return null;
    }
  }

  // جلب الإعلانات حسب الفئة (إذا أردنا إضافة فئات للإعلانات لاحقاً)
  static Future<List<Advertisement>> getAdvertisementsByCategory(
    String category,
  ) async {
    try {
      // التحقق من أن Supabase متوفر
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }

      // يمكن إضافة حقل category للإعلانات لاحقاً
      // حالياً نرجع جميع الإعلانات النشطة
      return await getActiveAdvertisements();
    } catch (e) {
      print('خطأ في جلب الإعلانات حسب الفئة: $e');
      rethrow;
    }
  }

  // إضافة إعلان جديد (للأدمن فقط)
  static Future<bool> addAdvertisement(Advertisement advertisement) async {
    try {
      // التحقق من أن Supabase متوفر
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }

      await SupabaseService.client!
          .from(_tableName)
          .insert(advertisement.toMap());

      return true;
    } catch (e) {
      print('خطأ في إضافة الإعلان: $e');
      return false;
    }
  }

  // تحديث إعلان موجود (للأدمن فقط)
  static Future<bool> updateAdvertisement(Advertisement advertisement) async {
    try {
      // التحقق من أن Supabase متوفر
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }

      await SupabaseService.client!
          .from(_tableName)
          .update(advertisement.toMap())
          .eq('id', advertisement.id);

      return true;
    } catch (e) {
      print('خطأ في تحديث الإعلان: $e');
      return false;
    }
  }

  // حذف إعلان (للأدمن فقط)
  static Future<bool> deleteAdvertisement(String id) async {
    try {
      // التحقق من أن Supabase متوفر
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }

      await SupabaseService.client!.from(_tableName).delete().eq('id', id);

      return true;
    } catch (e) {
      print('خطأ في حذف الإعلان: $e');
      return false;
    }
  }
}
