import '../services/order_service.dart';
import '../services/supabase_service.dart';

class OrderDebug {
  static Future<void> testOrderConnection() async {
    print('🔧 ===== بدء اختبار اتصال الطلبات =====');

    final orderService = OrderService();
    final supabaseService = SupabaseService();

    try {
      // 1. التحقق من حالة Supabase
      print('🔍 1. فحص حالة Supabase...');
      print('  - هل Supabase جاهز؟ ${supabaseService.isReady}');
      print('  - المستخدم الحالي: ${supabaseService.currentUser?.id}');

      // 2. اختبار الاتصال بقاعدة البيانات
      print('🔍 2. اختبار الاتصال بقاعدة البيانات...');
      final connectionTest = await orderService.testDatabaseConnection();
      print('  - نتيجة اختبار الاتصال: $connectionTest');

      // 3. محاولة جلب الطلبات
      print('🔍 3. محاولة جلب الطلبات...');
      final orders = await orderService.getOrders();
      print('  - عدد الطلبات المجلوبة: ${orders.length}');

      if (orders.isNotEmpty) {
        print('✅ تم جلب الطلبات بنجاح!');
        for (int i = 0; i < orders.length; i++) {
          final order = orders[i];
          print(
            '  ${i + 1}. ${order.title} - ${order.status} - ${order.orderType}',
          );
        }
      } else {
        print('❌ لم يتم جلب أي طلبات');

        // 4. محاولة استعلام مباشر لفهم المشكلة
        print('🔍 4. محاولة استعلام مباشر...');
        try {
          final directResponse = await supabaseService.client!
              .from('order_threads')
              .select('count')
              .single();
          print('  - عدد السجلات في order_threads: $directResponse');
        } catch (directError) {
          print('  - خطأ في الاستعلام المباشر: $directError');
        }

        // 5. فحص تصاريح قاعدة البيانات
        print('🔍 5. فحص الجداول المتاحة...');
        try {
          final tablesTest = await supabaseService.client!
              .from('information_schema.tables')
              .select('table_name')
              .eq('table_schema', 'public')
              .limit(10);
          print(
            '  - الجداول المتاحة: ${tablesTest.map((t) => t['table_name']).join(', ')}',
          );
        } catch (tablesError) {
          print('  - خطأ في فحص الجداول: $tablesError');
        }
      }
    } catch (e) {
      print('❌ خطأ عام في اختبار الطلبات: $e');
      print('❌ تفاصيل: ${e.toString()}');
    }

    print('🔧 ===== انتهاء اختبار اتصال الطلبات =====');
  }

  static Future<void> debugSingleOrder(String orderId) async {
    print('🔧 ===== اختبار طلب محدد: $orderId =====');

    final orderService = OrderService();

    try {
      final order = await orderService.getOrder(orderId);
      if (order != null) {
        print('✅ تم جلب الطلب:');
        print('  - ID: ${order.id}');
        print('  - العنوان: ${order.title}');
        print('  - المستخدم: ${order.userName}');
        print('  - النوع: ${order.orderType}');
        print('  - الحالة: ${order.status}');
        print('  - المنتجات: ${order.productNames}');
        print('  - الملخص: ${order.summary}');
      } else {
        print('❌ لم يتم العثور على الطلب');
      }
    } catch (e) {
      print('❌ خطأ في جلب الطلب: $e');
    }

    print('🔧 ===== انتهاء اختبار الطلب المحدد =====');
  }
}
