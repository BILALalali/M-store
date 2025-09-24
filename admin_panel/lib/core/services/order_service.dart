import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_thread.dart';
import '../models/order_message.dart';
import 'supabase_service.dart';
import 'dart:async';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  // Stream controllers للتحديثات في الوقت الفعلي
  final StreamController<List<OrderThread>> _ordersController =
      StreamController<List<OrderThread>>.broadcast();
  final StreamController<List<OrderMessage>> _messagesController =
      StreamController<List<OrderMessage>>.broadcast();

  // Streams للاستماع للتحديثات
  Stream<List<OrderThread>> get ordersStream => _ordersController.stream;
  Stream<List<OrderMessage>> get messagesStream => _messagesController.stream;

  // subscriptions
  RealtimeChannel? _ordersSubscription;
  RealtimeChannel? _messagesSubscription;

  // بدء الاستماع للتحديثات في الوقت الفعلي
  void startRealtimeSubscriptions() {
    if (!_supabaseService.isReady) return;

    final client = _supabaseService.client!;

    // الاستماع لتغييرات في جدول order_threads
    _ordersSubscription = client
        .channel('order_threads_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'order_threads',
          callback: (payload) {
            print('🔄 تغيير في الطلبات: ${payload.eventType}');
            _handleOrdersChange(payload);
          },
        )
        .subscribe();

    print('✅ تم بدء الاستماع للتحديثات في الوقت الفعلي للطلبات');
  }

  // إيقاف الاستماع
  void stopRealtimeSubscriptions() {
    _ordersSubscription?.unsubscribe();
    _messagesSubscription?.unsubscribe();
    _ordersSubscription = null;
    _messagesSubscription = null;
    print('🛑 تم إيقاف الاستماع للتحديثات في الوقت الفعلي للطلبات');
  }

  // معالجة التغييرات في الطلبات
  void _handleOrdersChange(PostgresChangePayload payload) async {
    print('📊 معالجة تغيير في الطلبات...');

    try {
      // إعادة جلب البيانات عند أي تغيير
      final updatedOrders = await getOrders();
      _ordersController.add(updatedOrders);

      print('✅ تم تحديث قائمة الطلبات: ${updatedOrders.length} طلب');
    } catch (e) {
      print('❌ خطأ في معالجة تغيير الطلبات: $e');
    }
  }

  // إنهاء الموارد
  void dispose() {
    stopRealtimeSubscriptions();
    _ordersController.close();
    _messagesController.close();
  }

  // اختبار الاتصال بقاعدة البيانات
  Future<bool> testDatabaseConnection() async {
    try {
      if (!_supabaseService.isReady) {
        print('Supabase غير مهيأ');
        return false;
      }

      print('اختبار الاتصال بجدول الطلبات...');

      // اختبار جدول الطلبات
      final ordersTest = await _supabaseService.client!
          .from('order_threads')
          .select('count')
          .limit(1);

      print('اختبار جدول الطلبات: $ordersTest');

      // جلب عينة من الطلبات
      final sampleOrders = await _supabaseService.client!
          .from('order_threads')
          .select('*')
          .limit(5);

      print('عينة من الطلبات: $sampleOrders');

      return true;
    } catch (e) {
      print('خطأ في اختبار الاتصال بجدول الطلبات: $e');
      return false;
    }
  }

  // الحصول على جميع الطلبات
  Future<List<OrderThread>> getOrders() async {
    try {
      if (!_supabaseService.isReady) {
        print('Supabase غير مهيأ');
        return [];
      }

      print('🚀 ===== بدء جلب الطلبات =====');

      final client = _supabaseService.client!;

      // جلب جميع الطلبات
      print('🔍 إرسال استعلام إلى جدول order_threads...');
      final response = await client
          .from('order_threads')
          .select('*')
          .order('updated_at', ascending: false);

      print('✅ استجابة قاعدة البيانات: ${response.length} طلب');
      print('📋 البيانات المستلمة: $response');

      final orders = <OrderThread>[];

      for (var item in response) {
        print(
          '🚀 ===== معالجة طلب: ID=${item['id']}, user_id=${item['user_id']} =====',
        );

        String? userName;
        String? userEmail;

        // جلب معلومات المستخدم
        try {
          final userId = item['user_id'];
          if (userId != null) {
            final profileResponse = await _supabaseService.client!
                .from('profiles')
                .select('name')
                .eq('id', userId)
                .maybeSingle();

            if (profileResponse != null && profileResponse['name'] != null) {
              userName = profileResponse['name'];
              print('✅ تم جلب اسم المستخدم: $userName');
            } else {
              userName = 'مستخدم ${userId.toString().substring(0, 8)}';
              print('❌ لم يتم العثور على الاسم، استخدام المعرف: $userName');
            }
          } else {
            userName = 'مستخدم غير محدد';
            print('❌ معرف المستخدم مفقود');
          }
        } catch (profileError) {
          print('❌ خطأ في جلب الاسم: $profileError');
          final userId = item['user_id']?.toString() ?? 'unknown';
          userName =
              'مستخدم ${userId.length > 8 ? userId.substring(0, 8) : userId}';
        }

        // جلب آخر رسالة (إذا كان هناك نظام رسائل للطلبات)
        OrderMessage? lastMessage;
        int unreadCount = 0;
        try {
          lastMessage = await _getLastOrderMessage(item['id']);
          unreadCount = await _getUnreadOrderMessagesCount(item['id']);
        } catch (e) {
          print(
            'تحذير: لا يمكن جلب رسائل الطلب (قد لا يكون النظام مُعَد بعد): $e',
          );
        }

        print('📊 الطلب ${item['id']}: unreadCount = $unreadCount');

        final hasUnreadMessages = unreadCount > 0;

        // معالجة البيانات الفارغة أو المفقودة
        final String title = item['title']?.toString().trim() ?? '';
        final String productNames =
            item['product_names']?.toString().trim() ?? '';
        final String summary = item['summary']?.toString().trim() ?? '';

        // إذا كان العنوان فارغ، استخدم اسم المنتجات أو معرف مختصر
        final String displayTitle = title.isNotEmpty
            ? title
            : productNames.isNotEmpty
            ? productNames
            : 'طلب ${item['id'].toString().substring(0, 8)}';

        // معالجة حقول التاريخ بشكل آمن
        DateTime createdAt = DateTime.now();
        DateTime updatedAt = DateTime.now();

        try {
          createdAt = DateTime.parse(item['created_at']);
        } catch (e) {
          print('❌ خطأ في تحليل created_at: $e');
        }

        try {
          updatedAt = DateTime.parse(item['updated_at']);
        } catch (e) {
          print('❌ خطأ في تحليل updated_at: $e');
        }

        orders.add(
          OrderThread(
            id: item['id']?.toString() ?? 'unknown',
            userId: item['user_id']?.toString() ?? 'unknown',
            title: displayTitle,
            productNames: productNames.isNotEmpty ? productNames : null,
            summary: summary.isNotEmpty ? summary : null,
            orderType: item['order_type']?.toString() ?? 'retail',
            status: item['status']?.toString() ?? 'pending',
            imageUrl: item['image_url']?.toString(),
            createdAt: createdAt,
            updatedAt: updatedAt,
            userName: userName,
            userEmail: userEmail,
            lastMessage: lastMessage?.message,
            lastMessageAt: lastMessage?.createdAt,
            unreadCount: unreadCount,
            hasUnreadMessages: hasUnreadMessages,
          ),
        );

        print('✅ تم إضافة الطلب: $displayTitle');

        print('🚀 ===== انتهاء معالجة الطلب: ${item['id']} =====');
      }

      print('🚀 ===== انتهاء جلب الطلبات: ${orders.length} طلب =====');

      // إرسال البيانات للـ stream
      _ordersController.add(orders);

      return orders;
    } catch (e) {
      print('❌ خطأ في جلب الطلبات: $e');
      print('❌ تفاصيل الخطأ: ${e.toString()}');

      // محاولة إضافية للحصول على معلومات أكثر عن الخطأ
      if (e.toString().contains('permission') || e.toString().contains('RLS')) {
        print('❌ قد تكون هناك مشكلة في تصاريح قاعدة البيانات (RLS Policies)');
      }

      return [];
    }
  }

  // الحصول على طلب محدد
  Future<OrderThread?> getOrder(String orderId) async {
    try {
      if (!_supabaseService.isReady) {
        return null;
      }

      print('جلب الطلب: $orderId');

      final response = await _supabaseService.client!
          .from('order_threads')
          .select('*')
          .eq('id', orderId)
          .single();

      final userId = response['user_id'];
      String? userName;

      try {
        final profileResponse = await _supabaseService.client!
            .from('profiles')
            .select('name')
            .eq('id', userId)
            .maybeSingle();
        if (profileResponse != null && profileResponse['name'] != null) {
          userName = profileResponse['name'];
        }
      } catch (e) {
        print('❌ خطأ في جلب اسم المستخدم: $e');
      }

      // جلب آخر رسالة وعدد الرسائل غير المقروءة
      OrderMessage? lastMessage;
      int unreadCount = 0;
      try {
        lastMessage = await _getLastOrderMessage(orderId);
        unreadCount = await _getUnreadOrderMessagesCount(orderId);
      } catch (e) {
        print('تحذير: لا يمكن جلب رسائل الطلب: $e');
      }

      return OrderThread(
        id: response['id'],
        userId: userId,
        title: response['title'] ?? '',
        productNames: response['product_names'],
        summary: response['summary'],
        orderType: response['order_type'] ?? 'retail',
        status: response['status'] ?? 'pending',
        imageUrl: response['image_url'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        userName: userName,
        lastMessage: lastMessage?.message,
        lastMessageAt: lastMessage?.createdAt,
        unreadCount: unreadCount,
        hasUnreadMessages: unreadCount > 0,
      );
    } catch (e) {
      print('خطأ في جلب الطلب: $e');
      return null;
    }
  }

  // الحصول على رسائل طلب محدد
  Future<List<OrderMessage>> getOrderMessages(String orderId) async {
    try {
      if (!_supabaseService.isReady) {
        return [];
      }

      print('جلب رسائل الطلب: $orderId');

      // محاولة جلب رسائل من جدول order_messages أولاً
      try {
        final response = await _supabaseService.client!
            .from('order_messages')
            .select('*')
            .eq('order_thread_id', orderId)
            .order('created_at', ascending: true);

        print('تم جلب ${response.length} رسالة من جدول order_messages');
        return _processOrderMessages(response);
      } catch (e) {
        print(
          'جدول order_messages غير موجود، محاولة استخدام support_messages: $e',
        );

        // إذا لم يكن جدول order_messages موجوداً، استخدم support_messages مع ربط مختلف
        try {
          final response = await _supabaseService.client!
              .from('support_messages')
              .select('*')
              .eq('conversation_id', orderId)
              .order('created_at', ascending: true);

          print('تم جلب ${response.length} رسالة من جدول support_messages');
          return _processSupportMessagesAsOrderMessages(response, orderId);
        } catch (supportError) {
          print('خطأ في جلب الرسائل من support_messages: $supportError');
          return [];
        }
      }
    } catch (e) {
      print('خطأ في جلب رسائل الطلب: $e');
      return [];
    }
  }

  // إرسال رسالة للطلب
  Future<OrderMessage?> sendOrderMessage({
    required String orderId,
    required String message,
    String? mediaUrl,
    String type = 'text',
  }) async {
    try {
      if (!_supabaseService.isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      print('إرسال رسالة جديدة للطلب: $orderId');

      final messageData = {
        'order_thread_id': orderId,
        'sender_type': 'admin',
        'sender_id': currentUser.id,
        'type': type,
        'message': message,
        'media_url': mediaUrl,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      };

      // محاولة إدراج في جدول order_messages أولاً
      try {
        final response = await _supabaseService.client!
            .from('order_messages')
            .insert(messageData)
            .select()
            .single();

        await _updateOrderTimestamp(orderId);
        return OrderMessage.fromJson(response);
      } catch (e) {
        print('جدول order_messages غير موجود، استخدام support_messages: $e');

        // إذا لم يكن جدول order_messages موجوداً، استخدم support_messages
        final supportMessageData = {
          'conversation_id': orderId,
          'sender_type': 'admin',
          'sender_id': currentUser.id,
          'type': type,
          'message': message,
          'media_url': mediaUrl,
          'created_at': DateTime.now().toIso8601String(),
          'is_read': false,
        };

        final response = await _supabaseService.client!
            .from('support_messages')
            .insert(supportMessageData)
            .select()
            .single();

        await _updateOrderTimestamp(orderId);

        // تحويل من support_message إلى order_message
        return OrderMessage(
          id: response['id'],
          orderThreadId: orderId,
          senderType: response['sender_type'],
          senderId: response['sender_id'],
          type: response['type'],
          message: response['message'],
          mediaUrl: response['media_url'],
          createdAt: DateTime.parse(response['created_at']),
          isRead: response['is_read'] ?? false,
          senderName: 'فريق الدعم',
        );
      }
    } catch (e) {
      print('خطأ في إرسال رسالة الطلب: $e');
      rethrow;
    }
  }

  // تحديث حالة الطلب
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      if (!_supabaseService.isReady) {
        return false;
      }

      print('تحديث حالة الطلب $orderId إلى $status');

      await _supabaseService.client!
          .from('order_threads')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      print('✅ تم تحديث حالة الطلب بنجاح');
      return true;
    } catch (e) {
      print('❌ خطأ في تحديث حالة الطلب: $e');
      return false;
    }
  }

  // تعيين رسائل الطلب كمقروءة
  Future<void> markOrderMessagesAsRead(String orderId) async {
    try {
      print('📖 تحديث رسائل الطلب كمقروءة: $orderId');

      final client = _supabaseService.client!;

      // محاولة تحديث في جدول order_messages أولاً
      try {
        await client
            .from('order_messages')
            .update({'is_read': true})
            .eq('order_thread_id', orderId)
            .eq('sender_type', 'user')
            .eq('is_read', false);
      } catch (e) {
        // إذا لم يكن الجدول موجوداً، استخدم support_messages
        await client
            .from('support_messages')
            .update({'is_read': true})
            .eq('conversation_id', orderId)
            .eq('sender_type', 'user')
            .eq('is_read', false);
      }

      print('✅ تم تحديث رسائل الطلب كمقروءة بنجاح');
    } catch (e) {
      print('خطأ في تحديث حالة رسائل الطلب: $e');
    }
  }

  // إحصائيات الطلبات
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      if (!_supabaseService.isReady) {
        return _getDefaultOrderStats();
      }

      final client = _supabaseService.client!;

      // إجمالي الطلبات
      final totalOrders = await client.from('order_threads').select('id');

      // الطلبات المعلقة
      final pendingOrders = await client
          .from('order_threads')
          .select('id')
          .eq('status', 'pending');

      // الطلبات المكتملة
      final completedOrders = await client
          .from('order_threads')
          .select('id')
          .eq('status', 'completed');

      // الطلبات قيد المعالجة
      final processingOrders = await client
          .from('order_threads')
          .select('id')
          .eq('status', 'processing');

      return {
        'total_orders': totalOrders.length,
        'pending_orders': pendingOrders.length,
        'completed_orders': completedOrders.length,
        'processing_orders': processingOrders.length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات الطلبات: $e');
      return _getDefaultOrderStats();
    }
  }

  // دوال مساعدة خاصة

  // الحصول على آخر رسالة في الطلب
  Future<OrderMessage?> _getLastOrderMessage(String orderId) async {
    try {
      // محاولة جلب من order_messages أولاً
      try {
        final response = await _supabaseService.client!
            .from('order_messages')
            .select('*')
            .eq('order_thread_id', orderId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          return OrderMessage.fromJson(response);
        }
      } catch (e) {
        // جلب من support_messages
        final response = await _supabaseService.client!
            .from('support_messages')
            .select('*')
            .eq('conversation_id', orderId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          return OrderMessage(
            id: response['id'],
            orderThreadId: orderId,
            senderType: response['sender_type'] ?? 'user',
            senderId: response['sender_id'],
            type: response['type'] ?? 'text',
            message: response['message'] ?? '',
            mediaUrl: response['media_url'],
            createdAt: DateTime.parse(response['created_at']),
            isRead: response['is_read'] ?? false,
          );
        }
      }

      return null;
    } catch (e) {
      print('خطأ في جلب آخر رسالة للطلب: $e');
      return null;
    }
  }

  // حساب عدد الرسائل غير المقروءة للطلب
  Future<int> _getUnreadOrderMessagesCount(String orderId) async {
    try {
      // محاولة العد من order_messages أولاً
      try {
        final response = await _supabaseService.client!
            .from('order_messages')
            .select('id')
            .eq('order_thread_id', orderId)
            .eq('sender_type', 'user')
            .eq('is_read', false);

        return response.length;
      } catch (e) {
        // العد من support_messages
        final response = await _supabaseService.client!
            .from('support_messages')
            .select('id')
            .eq('conversation_id', orderId)
            .eq('sender_type', 'user')
            .eq('is_read', false);

        return response.length;
      }
    } catch (e) {
      print('خطأ في حساب الرسائل غير المقروءة للطلب: $e');
      return 0;
    }
  }

  // تحديث وقت آخر تحديث للطلب
  Future<void> _updateOrderTimestamp(String orderId) async {
    try {
      await _supabaseService.client!
          .from('order_threads')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);
    } catch (e) {
      print('خطأ في تحديث وقت الطلب: $e');
    }
  }

  // معالجة رسائل order_messages
  List<OrderMessage> _processOrderMessages(List<dynamic> response) {
    final messages = <OrderMessage>[];

    for (var item in response) {
      try {
        messages.add(OrderMessage.fromJson(item));
      } catch (e) {
        print('خطأ في معالجة رسالة الطلب: $e');
      }
    }

    return messages;
  }

  // معالجة رسائل support_messages كرسائل طلبات
  List<OrderMessage> _processSupportMessagesAsOrderMessages(
    List<dynamic> response,
    String orderId,
  ) {
    final messages = <OrderMessage>[];

    for (var item in response) {
      try {
        messages.add(
          OrderMessage(
            id: item['id'],
            orderThreadId: orderId,
            senderType: item['sender_type'] ?? 'user',
            senderId: item['sender_id'],
            type: item['type'] ?? 'text',
            message: item['message'] ?? '',
            mediaUrl: item['media_url'],
            createdAt: DateTime.parse(item['created_at']),
            isRead: item['is_read'] ?? false,
            senderName: item['sender_type'] == 'admin'
                ? 'فريق الدعم'
                : 'المستخدم',
          ),
        );
      } catch (e) {
        print('خطأ في معالجة رسالة الدعم كرسالة طلب: $e');
      }
    }

    return messages;
  }

  Map<String, dynamic> _getDefaultOrderStats() {
    return {
      'total_orders': 0,
      'pending_orders': 0,
      'completed_orders': 0,
      'processing_orders': 0,
    };
  }

  // الاستماع للتحديثات المباشرة للطلبات
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _orderMessagesChannel;

  // بدء الاستماع للتحديثات المباشرة للطلبات
  void startListeningToOrders(Function(List<OrderThread>) onUpdate) {
    try {
      if (!_supabaseService.isReady) return;

      _ordersChannel = _supabaseService.client!
          .channel('order_threads_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'order_threads',
            callback: (payload) async {
              print('تحديث في الطلبات: $payload');
              final orders = await getOrders();
              onUpdate(orders);
            },
          )
          .subscribe();

      print('بدأ الاستماع لتحديثات الطلبات');
    } catch (e) {
      print('خطأ في بدء الاستماع للطلبات: $e');
    }
  }

  // بدء الاستماع للتحديثات المباشرة لرسائل الطلب
  void startListeningToOrderMessages(
    String orderId,
    Function(List<OrderMessage>) onUpdate,
  ) {
    try {
      if (!_supabaseService.isReady) return;

      // الاستماع لرسائل order_messages
      _orderMessagesChannel = _supabaseService.client!
          .channel('order_messages_changes_$orderId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'order_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'order_thread_id',
              value: orderId,
            ),
            callback: (payload) async {
              print('تحديث في رسائل الطلب: $payload');
              final messages = await getOrderMessages(orderId);
              onUpdate(messages);
            },
          )
          .subscribe();

      // إضافة استماع لـ support_messages أيضاً كبديل
      _supabaseService.client!
          .channel('support_messages_for_order_$orderId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'support_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: orderId,
            ),
            callback: (payload) async {
              print('تحديث في رسائل الدعم للطلب: $payload');
              final messages = await getOrderMessages(orderId);
              onUpdate(messages);
            },
          )
          .subscribe();

      print('بدأ الاستماع لتحديثات رسائل الطلب: $orderId');
    } catch (e) {
      print('خطأ في بدء الاستماع لرسائل الطلب: $e');
    }
  }

  // إيقاف الاستماع للتحديثات
  void stopListening() {
    try {
      _ordersChannel?.unsubscribe();
      _orderMessagesChannel?.unsubscribe();
      _ordersChannel = null;
      _orderMessagesChannel = null;
      print('تم إيقاف الاستماع لتحديثات الطلبات');
    } catch (e) {
      print('خطأ في إيقاف الاستماع: $e');
    }
  }
}
