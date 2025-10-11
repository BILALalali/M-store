import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';
import '../../presentation/screens/order_model.dart';

/// خدمة محادثات طلبات الجملة فقط (معزولة عن باقي أنواع الطلبات)
class OrderChatService {
  static const String _ordersTable = 'wholesale_requests';
  static const String _conversationsTable = 'wholesale_conversations';
  static const String _messagesTable = 'wholesale_messages';
  // جداول الطلبات العادية/التوصيل/الرصيد (موحدة)
  static const String _retailThreadsTable = 'order_threads';
  static const String _retailMessagesTable = 'order_messages';
  static const String _attachmentsBucket = 'wholesale_attachments';

  static SupabaseClient get _client => SupabaseService.client!;

  /// التأكد من وجود حاوية التخزين
  static Future<void> _ensureStorageBucket() async {
    try {
      // محاولة إنشاء الحاوية إذا لم تكن موجودة
      await _client.storage.createBucket(
        _attachmentsBucket,
        const BucketOptions(public: true),
      );
      print('تم إنشاء حاوية التخزين: $_attachmentsBucket');
    } catch (e) {
      // إذا كانت الحاوية موجودة بالفعل، نتجاهل الخطأ
      if (e.toString().contains('already exists') ||
          e.toString().contains('duplicate key') ||
          e.toString().contains('bucket already exists') ||
          e.toString().contains('row-level security policy') ||
          e.toString().contains('403') ||
          e.toString().contains('Unauthorized')) {
        print(
          'الحاوية موجودة بالفعل أو لا توجد صلاحيات لإنشائها: $_attachmentsBucket',
        );
        // لا نعيد رمي الخطأ، نستمر لأن الحاوية قد تكون موجودة بالفعل
      } else {
        print('فشل في إنشاء الحاوية: $e');
        // لا نعيد رمي الخطأ، نستمر لأن الحاوية قد تكون موجودة بالفعل
      }
    }
  }

  /// رفع صورة إلى التخزين مع معالجة الأخطاء
  static Future<String> _uploadImageToStorage(
    File imageFile,
    String userId,
  ) async {
    try {
      // محاولة رفع الصورة إلى الحاوية الموجودة
      final ext = imageFile.path.split('.').last.toLowerCase();
      final storagePath =
          'orders/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      print('محاولة رفع الصورة إلى: $storagePath');

      // التحقق من وجود الحاوية أولاً
      try {
        await _client.storage.from(_attachmentsBucket).list(path: 'orders');
        print('الحاوية متاحة للاستخدام');
      } catch (e) {
        print('الحاوية غير متاحة، محاولة إنشاؤها: $e');
        await _ensureStorageBucket();
      }

      // رفع الصورة
      await _client.storage
          .from(_attachmentsBucket)
          .upload(storagePath, imageFile);

      // الحصول على الرابط العام
      final imageUrl = _client.storage
          .from(_attachmentsBucket)
          .getPublicUrl(storagePath);

      print('تم رفع الصورة بنجاح: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('فشل في رفع الصورة: $e');
      // إرجاع سلسلة فارغة في حالة الفشل
      return '';
    }
  }

  // تحديد جدول الرسائل حسب مصدر المحادثة (جملة أم عادي)
  static Future<String> _resolveMessagesTable(String conversationId) async {
    try {
      final existsWholesale = await _client
          .from(_conversationsTable)
          .select('id')
          .eq('id', conversationId)
          .maybeSingle();
      if (existsWholesale != null) return _messagesTable;
    } catch (_) {}
    return _retailMessagesTable;
  }

  /// إنشاء طلب توصيل (Delivery) كمحادثة من نوع الطلبات العادية
  /// يستخدم جدول `order_threads` ويُخزن الصورة في نفس الحاوية
  static Future<Order> createDeliveryRequest({
    required String cargoType,
    required int weightKg,
    required String location,
    required String description,
    required File imageFile,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل دخول');

    // رفع الصورة إلى التخزين إن أمكن
    String imageUrl = '';
    try {
      // التأكد من وجود حاوية التخزين
      await _ensureStorageBucket();

      // رفع الصورة باستخدام الطريقة المساعدة
      imageUrl = await _uploadImageToStorage(imageFile, user.id);
    } catch (e) {
      print('فشل في رفع الصورة: $e');
      // لا نفشل إذا فشل رفع الصورة، نستمر بدون صورة
      imageUrl = '';
    }

    final summary = StringBuffer()
      ..writeln(description)
      ..writeln('الوزن: $weightKg كغ')
      ..write('الموقع: $location');

    final threadRow = await _client
        .from(_retailThreadsTable)
        .insert({
          'user_id': user.id,
          'title': cargoType,
          'product_names': [cargoType],
          'summary': summary.toString(),
          'order_type': OrderType.delivery.name,
          'status': 'pending',
          'image_url': imageUrl,
        })
        .select('id, created_at, title, image_url, summary')
        .single();

    final String threadId = threadRow['id'] as String;

    return Order(
      orderId: threadId,
      conversationId: threadId,
      productName: cargoType,
      productImage: (threadRow['image_url'] ?? '') as String,
      productId: threadId,
      productUrl: '',
      date: DateTime.parse(threadRow['created_at'] as String),
      status: OrderStatus.pending,
      userName: user.email ?? user.id,
      orderType: OrderType.delivery,
      description: threadRow['summary'] as String?,
      quantity: null,
    );
  }

  /// إنشاء طلب جملة مع محادثة مرتبطة وإرجاع نموذج `Order`
  static Future<Order> createWholesaleOrder({
    required String productName,
    required int quantity,
    required String description,
    File? imageFile,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('المستخدم غير مسجل دخول');
    }

    // ارفع الصورة إن وُجدت
    String imageUrl = '';
    if (imageFile != null) {
      try {
        // التأكد من وجود حاوية التخزين
        await _ensureStorageBucket();

        final ext = imageFile.path.split('.').last;
        final storagePath =
            'orders/${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

        print('محاولة رفع صورة الجملة إلى: $storagePath');

        await _client.storage
            .from(_attachmentsBucket)
            .upload(storagePath, imageFile);
        imageUrl = _client.storage
            .from(_attachmentsBucket)
            .getPublicUrl(storagePath);

        print('تم رفع صورة الجملة بنجاح: $imageUrl');
      } catch (e) {
        // لا نفشل إذا فشل رفع الصورة
        print('فشل في رفع صورة الجملة: $e');
        imageUrl = '';
      }
    }

    // أنشئ سجل الطلب
    final orderRow = await _client
        .from(_ordersTable)
        .insert({
          'user_id': user.id,
          'product_name': productName,
          'description': description,
          'quantity': quantity,
          'image_url': imageUrl,
          'status': 'pending',
        })
        .select('id, created_at, product_name, image_url')
        .single();

    final String orderId = orderRow['id'] as String;

    // أنشئ محادثة مرتبطة بالطلب
    final convRow = await _client
        .from(_conversationsTable)
        .insert({
          'request_id': orderId,
          'user_id': user.id,
          'is_open': true,
          'status': 'open',
        })
        .select('id')
        .single();

    final String conversationId = convRow['id'] as String;

    // أعد نموذج Order للتطبيق
    return Order(
      orderId: orderId,
      conversationId: conversationId,
      productName: productName,
      productImage: imageUrl,
      productId: orderId,
      productUrl: '',
      date: DateTime.parse(orderRow['created_at'] as String),
      status: OrderStatus.pending,
      userName: user.email ?? user.id,
      orderType: OrderType.wholesale,
      description: description,
      quantity: quantity,
    );
  }

  /// جلب كل طلبات الجملة للمستخدم الحالي مع المحادثة المرتبطة
  static Future<List<Order>> fetchWholesaleOrdersForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final requestRows = await _client
        .from(_ordersTable)
        .select(
          'id, product_name, image_url, description, quantity, status, created_at',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final requestIds = requestRows.map((r) => r['id'] as String).toList();
    Map<String, String> requestIdToConversationId = {};
    Map<String, bool> conversationIdToHasUnread = {};
    Map<String, int> conversationIdToUnreadCount = {};

    if (requestIds.isNotEmpty) {
      final convRows = await _client
          .from(_conversationsTable)
          .select('id, request_id')
          .inFilter('request_id', requestIds);
      for (final row in convRows) {
        final rid = row['request_id'] as String?;
        final cid = row['id'] as String?;
        if (rid != null && cid != null) {
          requestIdToConversationId[rid] = cid;
        }
      }

      // جلب معلومات الرسائل غير المقروءة من الإدارة
      final conversationIds = requestIdToConversationId.values.toList();
      if (conversationIds.isNotEmpty) {
        final unreadRows = await _client
            .from(_messagesTable)
            .select('conversation_id')
            .inFilter('conversation_id', conversationIds)
            .eq('sender_type', 'admin')
            .eq('is_read', false);

        // حساب عدد الرسائل غير المقروءة لكل محادثة
        for (final row in unreadRows) {
          final convId = row['conversation_id'] as String?;
          if (convId != null) {
            conversationIdToHasUnread[convId] = true;
            conversationIdToUnreadCount[convId] =
                (conversationIdToUnreadCount[convId] ?? 0) + 1;
          }
        }
      }
    }

    OrderStatus _mapStatus(String? s) {
      switch ((s ?? 'pending').toLowerCase()) {
        case 'confirmed':
          return OrderStatus.confirmed;
        case 'cancelled':
          return OrderStatus.cancelled;
        default:
          return OrderStatus.pending;
      }
    }

    final List<Order> orders = [];
    for (final r in requestRows) {
      final id = r['id'] as String;
      final conversationId = requestIdToConversationId[id];
      final hasUnreadMessages =
          conversationId != null &&
          conversationIdToHasUnread[conversationId] == true;
      final unreadCount = conversationId != null
          ? (conversationIdToUnreadCount[conversationId] ?? 0)
          : 0;

      orders.add(
        Order(
          orderId: id,
          conversationId: conversationId,
          productName: (r['product_name'] ?? '') as String,
          productImage: (r['image_url'] ?? '') as String,
          productId: id,
          productUrl: '',
          date: DateTime.parse((r['created_at'] as String)),
          status: _mapStatus(r['status'] as String?),
          userName: user.email ?? user.id,
          hasUnreadMessages: hasUnreadMessages,
          unreadCount: unreadCount,
          orderType: OrderType.wholesale,
          description: r['description'] as String?,
          quantity: (r['quantity'] as int?) ?? 0,
        ),
      );
    }

    return orders;
  }

  /// جلب رسائل محادثة
  static Future<List<Map<String, dynamic>>> fetchMessages(
    String conversationId,
  ) async {
    final table = await _resolveMessagesTable(conversationId);
    final rows = await _client
        .from(table)
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// الاشتراك في الرسائل بصيغة Realtime
  static Future<RealtimeChannel> subscribeToMessages(
    String conversationId,
    void Function(Map<String, dynamic> row) onInsert,
  ) async {
    // تحديد جدول الرسائل أولاً
    final table = await _resolveMessagesTable(conversationId);

    // إنشاء قناة Realtime للاستماع للإدراجات الجديدة فقط
    final channel = _client.channel('messages_$conversationId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload, [ref]) {
            print('🔔 رسالة جديدة مستلمة في المحادثة $conversationId');
            // استدعاء callback مع الرسالة الجديدة
            final newRecord = payload.newRecord;
            onInsert(newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// إرسال رسالة نصية
  static Future<void> sendText(String conversationId, String text) async {
    final user = _client.auth.currentUser;
    final table = await _resolveMessagesTable(conversationId);
    await _client.from(table).insert({
      'conversation_id': conversationId,
      'sender_type': 'user',
      'sender_id': user?.id,
      'type': 'text',
      'message': text,
    });
  }

  /// إرسال صورة: ترفع لستوريج ثم يحفظ الرابط
  static Future<void> sendImage(String conversationId, File file) async {
    final user = _client.auth.currentUser;
    try {
      // التأكد من وجود حاوية التخزين
      await _ensureStorageBucket();

      // رفع الصورة باستخدام الطريقة المساعدة
      final url = await _uploadImageToStorage(file, user?.id ?? '');

      if (url.isNotEmpty) {
        final table = await _resolveMessagesTable(conversationId);
        await _client.from(table).insert({
          'conversation_id': conversationId,
          'sender_type': 'user',
          'sender_id': user?.id,
          'type': 'image',
          'media_url': url,
          'message': 'صورة',
        });
      } else {
        throw Exception('فشل في رفع الصورة');
      }
    } catch (e) {
      print('فشل في إرسال الصورة: $e');
      rethrow;
    }
  }

  // ===== الطلبات العادية: إنشاء محادثة عند تأكيد الطلب من الشاشة الرئيسية =====
  static Future<Order> createRetailOrderThread({
    required List<String> productNames,
    required String productImage,
    required OrderType orderType,
    String? description,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل دخول');

    final title = productNames.join(', ');

    final threadRow = await _client
        .from(_retailThreadsTable)
        .insert({
          'user_id': user.id,
          'title': title,
          'product_names': productNames,
          'summary': description ?? '',
          'order_type': orderType.name,
          'status': 'pending',
          'image_url': productImage,
        })
        .select('id, created_at, title, image_url')
        .single();

    final threadId = threadRow['id'] as String;

    return Order(
      orderId: threadId,
      conversationId: threadId, // معرف المحادثة = معرف الخيط
      productName: title,
      productImage: (threadRow['image_url'] ?? '') as String,
      productId: threadId,
      productUrl: '',
      date: DateTime.parse(threadRow['created_at'] as String),
      status: OrderStatus.pending,
      userName: user.email ?? user.id,
      orderType: orderType,
      description: description,
      quantity: null,
    );
  }

  static Future<List<Order>> fetchRetailOrdersForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from(_retailThreadsTable)
        .select('id, title, image_url, status, created_at, order_type, summary')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    // جلب معلومات الرسائل غير المقروءة من الإدارة
    final threadIds = rows.map((r) => r['id'] as String).toList();
    Map<String, bool> threadIdToHasUnread = {};
    Map<String, int> threadIdToUnreadCount = {};

    if (threadIds.isNotEmpty) {
      final unreadRows = await _client
          .from(_retailMessagesTable)
          .select('conversation_id')
          .inFilter('conversation_id', threadIds)
          .eq('sender_type', 'admin')
          .eq('is_read', false);

      // حساب عدد الرسائل غير المقروءة لكل محادثة
      for (final row in unreadRows) {
        final convId = row['conversation_id'] as String?;
        if (convId != null) {
          threadIdToHasUnread[convId] = true;
          threadIdToUnreadCount[convId] =
              (threadIdToUnreadCount[convId] ?? 0) + 1;
        }
      }
    }

    OrderStatus _mapStatus(String? s) {
      switch ((s ?? 'pending').toLowerCase()) {
        case 'confirmed':
          return OrderStatus.confirmed;
        case 'cancelled':
          return OrderStatus.cancelled;
        default:
          return OrderStatus.pending;
      }
    }

    OrderType _mapType(String? s) {
      switch ((s ?? 'retail').toLowerCase()) {
        case 'delivery':
          return OrderType.delivery;
        case 'mobile_credit':
          return OrderType.mobileCredit;
        case 'wholesale':
          return OrderType.wholesale;
        default:
          return OrderType.retail;
      }
    }

    return rows.map((r) {
      final threadId = r['id'] as String;
      final hasUnreadMessages = threadIdToHasUnread[threadId] == true;
      final unreadCount = threadIdToUnreadCount[threadId] ?? 0;

      return Order(
        orderId: threadId,
        conversationId: threadId,
        productName: (r['title'] ?? '') as String,
        productImage: (r['image_url'] ?? '') as String,
        productId: threadId,
        productUrl: '',
        date: DateTime.parse(r['created_at'] as String),
        status: _mapStatus(r['status'] as String?),
        userName: user.email ?? user.id,
        hasUnreadMessages: hasUnreadMessages,
        unreadCount: unreadCount,
        orderType: _mapType(r['order_type'] as String?),
        description: r['summary'] as String?,
        quantity: null,
      );
    }).toList();
  }

  /// تحديث حالة القراءة للرسائل من الإدارة في محادثة معينة
  static Future<void> markAdminMessagesAsRead(String conversationId) async {
    try {
      // تحديد جدول الرسائل أولاً
      final table = await _resolveMessagesTable(conversationId);

      // تحديث جميع الرسائل من الإدارة غير المقروءة
      await _client
          .from(table)
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .eq('sender_type', 'admin')
          .eq('is_read', false);

      print('تم تحديث حالة القراءة للمحادثة: $conversationId');
    } catch (e) {
      print('خطأ في تحديث حالة القراءة: $e');
      // لا نعيد رمي الخطأ، نستمر في العمل
    }
  }
}
