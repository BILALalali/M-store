import '../../presentation/screens/advertisement_model.dart';
import 'supabase_service.dart';

class AdvertisementService {
  static const String _tableName = 'advertisements';

  static Future<List<Advertisement>> getActiveAdvertisements() async {
    try {
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }
      final response = await SupabaseService.client!
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .order('priority', ascending: true)
          .order('created_at', ascending: false);

      if (response.isEmpty) return [];

      final advertisements = (response as List)
          .map((ad) => Advertisement.fromMap(ad))
          .where((ad) => ad.isValid)
          .toList();

      return advertisements;
    } catch (e) {
      print('خطأ في جلب الإعلانات من قاعدة البيانات: $e');
      rethrow;
    }
  }

  static Future<Advertisement?> getAdvertisementById(String id) async {
    try {
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

      final advertisement = Advertisement.fromMap(response);
      return advertisement.isValid ? advertisement : null;
    } catch (e) {
      print('خطأ في جلب الإعلان من قاعدة البيانات: $e');
      return null;
    }
  }

  static Future<List<Advertisement>> getAdvertisementsByCategory(
    String category,
  ) async {
    try {
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }

      return await getActiveAdvertisements();
    } catch (e) {
      print('خطأ في جلب الإعلانات حسب الفئة: $e');
      rethrow;
    }
  }

  static Future<bool> addAdvertisement(Advertisement advertisement) async {
    try {
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

  static Future<bool> updateAdvertisement(Advertisement advertisement) async {
    try {
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

  static Future<bool> deleteAdvertisement(String id) async {
    try {
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
