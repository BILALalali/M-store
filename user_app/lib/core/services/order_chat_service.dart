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
  static const String _attachmentsBucket = 'wholesale_attachments';

  static SupabaseClient get _client => SupabaseService.client!;

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
        try {
          await _client.storage.createBucket(
            _attachmentsBucket,
            const BucketOptions(public: true),
          );
        } catch (_) {}

        final ext = imageFile.path.split('.').last;
        final storagePath =
            'orders/${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _client.storage
            .from(_attachmentsBucket)
            .upload(storagePath, imageFile);
        imageUrl = _client.storage
            .from(_attachmentsBucket)
            .getPublicUrl(storagePath);
      } catch (e) {
        // لا نفشل إذا فشل رفع الصورة
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

    if (requestRows is! List) return [];

    final requestIds = requestRows.map((r) => r['id'] as String).toList();
    Map<String, String> requestIdToConversationId = {};
    if (requestIds.isNotEmpty) {
      final convRows = await _client
          .from(_conversationsTable)
          .select('id, request_id')
          .in_('request_id', requestIds);
      if (convRows is List) {
        for (final row in convRows) {
          final rid = row['request_id'] as String?;
          final cid = row['id'] as String?;
          if (rid != null && cid != null) {
            requestIdToConversationId[rid] = cid;
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
      orders.add(
        Order(
          orderId: id,
          conversationId: requestIdToConversationId[id],
          productName: (r['product_name'] ?? '') as String,
          productImage: (r['image_url'] ?? '') as String,
          productId: id,
          productUrl: '',
          date: DateTime.parse((r['created_at'] as String)),
          status: _mapStatus(r['status'] as String?),
          userName: user.email ?? user.id,
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
    final rows = await _client
        .from(_messagesTable)
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// الاشتراك في الرسائل بصيغة stream
  static StreamSubscription<List<Map<String, dynamic>>> subscribeToMessages(
    String conversationId,
    void Function(Map<String, dynamic> row) onInsert,
  ) {
    return _client
        .from(_messagesTable)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .listen((rows) {
          for (final row in rows) {
            onInsert(row);
          }
        });
  }

  /// إرسال رسالة نصية
  static Future<void> sendText(String conversationId, String text) async {
    final user = _client.auth.currentUser;
    await _client.from(_messagesTable).insert({
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
      try {
        await _client.storage.createBucket(
          _attachmentsBucket,
          const BucketOptions(public: true),
        );
      } catch (_) {}
      final ext = file.path.split('.').last.toLowerCase();
      final storagePath =
          'messages/${user?.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage.from(_attachmentsBucket).upload(storagePath, file);
      final url = _client.storage
          .from(_attachmentsBucket)
          .getPublicUrl(storagePath);

      await _client.from(_messagesTable).insert({
        'conversation_id': conversationId,
        'sender_type': 'user',
        'sender_id': user?.id,
        'type': 'image',
        'media_url': url,
        'message': 'صورة',
      });
    } catch (e) {
      rethrow;
    }
  }
}
