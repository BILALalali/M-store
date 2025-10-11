import '../../presentation/screens/product_model.dart';
import 'supabase_service.dart';

class ProductService {
  static const String _tableName = 'products';

  static Future<List<Product>> getAllProducts() async {
    try {
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }
      final response = await SupabaseService.client!
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (response.isEmpty) return [];

      return (response as List)
          .map((product) => Product.fromMap(product))
          .toList();
    } catch (e) {
      print('خطأ في جلب المنتجات من قاعدة البيانات: $e');
      rethrow;
    }
  }

  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
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

      if (response.isEmpty) return [];

      return (response as List)
          .map((product) => Product.fromMap(product))
          .toList();
    } catch (e) {
      print('خطأ في جلب المنتجات حسب الفئة من قاعدة البيانات: $e');
      rethrow;
    }
  }

  static Future<List<Product>> searchProducts(String query) async {
    try {
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

      if (response.isEmpty) return [];

      return (response as List)
          .map((product) => Product.fromMap(product))
          .toList();
    } catch (e) {
      print('خطأ في البحث في قاعدة البيانات: $e');
      rethrow;
    }
  }

  static Future<Product?> getProductById(String id) async {
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

      return Product.fromMap(response);
    } catch (e) {
      print('خطأ في جلب المنتج: $e');
      rethrow;
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر، استخدام الفئات المحلية');
        return _getLocalCategories();
      }

      final response = await SupabaseService.client!
          .from('categories')
          .select('name')
          .eq('is_active', true)
          .order('name');

      if (response.isEmpty) return [];

      final categories = (response as List)
          .map((item) => item['name'] as String)
          .toList();

      return categories;
    } catch (e) {
      print('خطأ في جلب الفئات من قاعدة البيانات: $e');
      print('استخدام الفئات المحلية كبديل...');
      return _getLocalCategories();
    }
  }

  static List<String> _getLocalCategories() {
    return [];
  }

  static Future<bool> updateProductQuantity(
    String productId,
    int newQuantity,
  ) async {
    try {
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

  static Future<List<Product>> getFeaturedProducts() async {
    try {
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        print('Supabase غير متوفر');
        throw Exception('لا يمكن الاتصال بقاعدة البيانات');
      }

      final response = await SupabaseService.client!
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(6);

      if (response.isEmpty) return [];

      return (response as List)
          .map((product) => Product.fromMap(product))
          .toList();
    } catch (e) {
      print('خطأ في جلب المنتجات المميزة: $e');
      rethrow;
    }
  }
}
