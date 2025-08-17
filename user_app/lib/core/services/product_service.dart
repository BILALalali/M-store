import 'package:supabase_flutter/supabase_flutter.dart';
import '../../presentation/screens/product_model.dart';
import 'supabase_service.dart';

class ProductService {
  static const String _tableName = 'products';

  // جلب جميع المنتجات النشطة
  static Future<List<Product>> getAllProducts() async {
    try {
      // التحقق من أن Supabase متوفر
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }

      // جلب المنتجات من قاعدة البيانات
      final response = await SupabaseService.client!
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (response == null) return [];

      return (response as List)
          .map((product) => Product.fromMap(product))
          .toList();
    } catch (e) {
      print('خطأ في جلب المنتجات من قاعدة البيانات: $e');
      rethrow; // إعادة رمي الخطأ بدلاً من استخدام البيانات المحلية
    }
  }

  // جلب المنتجات حسب الفئة
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      // التحقق من أن Supabase متوفر
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }

      final response = await SupabaseService.client!
          .from(_tableName)
          .select()
          .eq('category', category)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (response == null) return [];

      return (response as List)
          .map((product) => Product.fromMap(product))
          .toList();
    } catch (e) {
      print('خطأ في جلب المنتجات حسب الفئة من قاعدة البيانات: $e');
      rethrow; // إعادة رمي الخطأ بدلاً من استخدام البيانات المحلية
    }
  }

  // البحث في المنتجات
  static Future<List<Product>> searchProducts(String query) async {
    try {
      // التحقق من أن Supabase متوفر
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }

      final response = await SupabaseService.client!
          .from(_tableName)
          .select()
          .or(
            'name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%',
          )
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (response == null) return [];

      return (response as List)
          .map((product) => Product.fromMap(product))
          .toList();
    } catch (e) {
      print('خطأ في البحث في قاعدة البيانات: $e');
      rethrow; // إعادة رمي الخطأ بدلاً من استخدام البيانات المحلية
    }
  }

  // جلب منتج واحد حسب المعرف
  static Future<Product?> getProductById(String id) async {
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

      return Product.fromMap(response);
    } catch (e) {
      print('خطأ في جلب المنتج: $e');
      rethrow; // إعادة رمي الخطأ بدلاً من استخدام البيانات المحلية
    }
  }

  // جلب الفئات المتاحة
  static Future<List<String>> getCategories() async {
    try {
      // التحقق من أن Supabase متوفر
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر، استخدام الفئات المحلية');
        return _getLocalCategories();
      }

      // جلب الفئات من جدول categories
      final response = await SupabaseService.client!
          .from('categories') // جدول الفئات
          .select('name')
          .eq('is_active', true)
          .order('name');

      if (response == null) return [];

      final categories = (response as List)
          .map((item) => item['name'] as String)
          .toList();

      return categories;
    } catch (e) {
      print('خطأ في جلب الفئات من قاعدة البيانات: $e');
      print('استخدام الفئات المحلية كبديل...');

      // استخدام فئات محلية كبديل
      return _getLocalCategories();
    }
  }

  // فئات محلية كبديل (فارغة - نريد قاعدة البيانات فقط)
  static List<String> _getLocalCategories() {
    return [];
  }

  // تحديث كمية المنتج (مثلاً بعد عملية شراء)
  static Future<bool> updateProductQuantity(
    String productId,
    int newQuantity,
  ) async {
    try {
      // التحقق من أن Supabase متوفر
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر، لا يمكن تحديث الكمية');
        return false;
      }

      await SupabaseService.client!
          .from(_tableName)
          .update({
            'quantity': newQuantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      return true;
    } catch (e) {
      print('خطأ في تحديث كمية المنتج: $e');
      return false;
    }
  }

  // جلب المنتجات المميزة (يمكن إضافة حقل is_featured لاحقاً)
  static Future<List<Product>> getFeaturedProducts() async {
    try {
      // التحقق من أن Supabase متوفر
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }

      final response = await SupabaseService.client!
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(6); // جلب أول 6 منتجات

      if (response == null) return [];

      return (response as List)
          .map((product) => Product.fromMap(product))
          .toList();
    } catch (e) {
      print('خطأ في جلب المنتجات المميزة: $e');
      rethrow; // إعادة رمي الخطأ بدلاً من استخدام البيانات المحلية
    }
  }
}
