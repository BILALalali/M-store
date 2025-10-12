import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'simple_notification_service.dart';
import '../../presentation/screens/order_model.dart';

/// خدمة الاستماع للرسائل الجديدة في جميع المحادثات
class MessageListenerService {
  static final MessageListenerService _instance =
      MessageListenerService._internal();
  factory MessageListenerService() => _instance;
  MessageListenerService._internal();

  final Map<String, RealtimeChannel> _channels = {};
  final SimpleNotificationService _notificationService = SimpleNotificationService();
  Timer? _pollingTimer;
  final Set<String> _notifiedMessageIds =
      {}; // لتتبع الرسائل التي تم الإشعار عنها

  // Callbacks لتحديث الواجهة
  VoidCallback? onNewMessagesReceived;

  /// بدء الاستماع لجميع المحادثات
  Future<void> startListening(List<Order> orders) async {
    print('🔔 بدء الاستماع لـ ${orders.length} محادثة');

    // إلغاء أي اشتراكات سابقة
    await stopListening();

    // الاستماع لكل محادثة
    for (final order in orders) {
      if (order.conversationId != null) {
        await _listenToConversation(order);
      }
    }

    // بدء التحديث الدوري كـ backup للـ realtime
    _startPolling();
  }

  /// الاستماع لمحادثة واحدة
  Future<void> _listenToConversation(Order order) async {
    final conversationId = order.conversationId;
    if (conversationId == null) return;

    // تجنب الاشتراك المكرر
    if (_channels.containsKey(conversationId)) return;

    try {
      final client = SupabaseService.client!;

      // تحديد جدول الرسائل - محاولة تحديد من نوع الطلب
      String table;
      if (order.orderType == OrderType.wholesale) {
        table = 'wholesale_messages';
      } else {
        table = 'order_messages';
      }

      print('🔍 بدء الاستماع للمحادثة: ${order.productName} (جدول: $table)');

      // إنشاء قناة Realtime للاستماع للرسائل من الإدارة فقط
      final channel = client.channel('notifications_$conversationId');

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
              print('📨 تم استقبال تغيير في الجدول: $table');
              final newRecord = payload.newRecord;
              print('📨 بيانات الرسالة: $newRecord');

              // فقط رسائل الإدارة
              if (newRecord['sender_type'] == 'admin') {
                print('🔔 رسالة جديدة من الإدارة في الخلفية!');
                _handleNewMessage(newRecord, order);
              } else {
                print('⚠️ رسالة من المستخدم، لن يتم إشعار');
              }
            },
          )
          .subscribe();

      _channels[conversationId] = channel;
      print('✅ بدأ الاستماع للمحادثة: ${order.productName}');
    } catch (e) {
      print('❌ خطأ في الاستماع للمحادثة $conversationId: $e');
    }
  }

  /// معالجة رسالة جديدة
  void _handleNewMessage(Map<String, dynamic> row, Order order) {
    try {
      final messageId = row['id'] as String?;
      final messageText = row['message'] as String? ?? 'رسالة جديدة';
      final messageType = row['type'] as String? ?? 'text';

      // تجنب الإشعارات المكررة
      if (messageId != null && _notifiedMessageIds.contains(messageId)) {
        return;
      }

      // إضافة إلى قائمة الرسائل المعلن عنها
      if (messageId != null) {
        _notifiedMessageIds.add(messageId);

        // تنظيف القائمة إذا أصبحت كبيرة جداً
        if (_notifiedMessageIds.length > 1000) {
          final toRemove = _notifiedMessageIds.take(500).toList();
          _notifiedMessageIds.removeAll(toRemove);
        }
      }

      // تحضير نص الرسالة للإشعار
      String notificationText = messageText;
      if (messageType == 'image') {
        notificationText = '📷 تم إرسال صورة';
      }

      // إظهار الإشعار
      final convId = order.conversationId ?? '';
      final orderName = order.orderType == OrderType.wholesale
          ? 'طلب جملة - ${order.productName}'
          : order.orderType == OrderType.mobileCredit
          ? 'طلب رصيد - ${order.productName}'
          : order.orderType == OrderType.delivery
          ? 'طلب شحن - ${order.productName}'
          : 'طلب ${order.productName}';
      
      _notificationService.showOrderMessageNotification(
        orderName: orderName,
        messageText: notificationText,
        id: convId.hashCode,
      );

      print('🔔 إشعار رسالة جديدة: ${order.productName}');

      // إشعار الواجهة بوجود رسائل جديدة
      onNewMessagesReceived?.call();
    } catch (e) {
      print('❌ خطأ في معالجة الرسالة الجديدة: $e');
    }
  }

  /// بدء التحديث الدوري (كـ backup للـ realtime)
  void _startPolling() {
    _pollingTimer?.cancel();

    // التحديث كل 10 ثواني للتحقق من الرسائل الجديدة
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      print('🔄 تحديث دوري للمحادثات...');
      _checkForNewMessages();
    });
  }

  /// فحص الرسائل الجديدة دورياً
  Future<void> _checkForNewMessages() async {
    try {
      final client = SupabaseService.client;
      if (client == null) return;

      // فحص رسائل الدعم
      await _checkSupportMessages(client);

      // فحص رسائل الطلبات
      await _checkOrderMessages(client);
    } catch (e) {
      print('❌ خطأ في الفحص الدوري: $e');
    }
  }

  /// فحص رسائل الدعم الجديدة
  Future<void> _checkSupportMessages(SupabaseClient client) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return;

      // جلب محادثة الدعم
      final conversation = await client
          .from('support_conversations')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (conversation == null) return;

      final conversationId = conversation['id'] as String;

      // جلب الرسائل الجديدة من فريق الدعم
      final messages = await client
          .from('support_messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .eq('sender_type', 'admin')
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(5);

      for (final message in messages) {
        final messageId = message['id'] as String;
        if (!_notifiedMessageIds.contains(messageId)) {
          _notifiedMessageIds.add(messageId);

          // إظهار إشعار الدعم
          _notificationService.showSupportMessageNotification(
            messageText: message['message'] ?? 'رسالة جديدة من فريق الدعم',
            id: messageId.hashCode,
          );

          print('🔔 إشعار دعم جديد: ${message['message']}');
        }
      }
    } catch (e) {
      print('❌ خطأ في فحص رسائل الدعم: $e');
    }
  }

  /// فحص رسائل الطلبات الجديدة
  Future<void> _checkOrderMessages(SupabaseClient client) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return;

      // فحص رسائل الجملة
      await _checkWholesaleMessages(client, user.id);

      // فحص رسائل الطلبات العادية
      await _checkRetailMessages(client, user.id);
    } catch (e) {
      print('❌ خطأ في فحص رسائل الطلبات: $e');
    }
  }

  /// فحص رسائل الجملة
  Future<void> _checkWholesaleMessages(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      // جلب محادثات الجملة للمستخدم
      final conversations = await client
          .from('wholesale_conversations')
          .select('id, request_id')
          .eq('user_id', userId);

      for (final conv in conversations) {
        final conversationId = conv['id'] as String;

        // جلب الرسائل الجديدة من الإدارة
        final messages = await client
            .from('wholesale_messages')
            .select('*')
            .eq('conversation_id', conversationId)
            .eq('sender_type', 'admin')
            .eq('is_read', false)
            .order('created_at', ascending: false)
            .limit(3);

        for (final message in messages) {
          final messageId = message['id'] as String;
          if (!_notifiedMessageIds.contains(messageId)) {
            _notifiedMessageIds.add(messageId);

            // جلب تفاصيل الطلب
            final request = await client
                .from('wholesale_requests')
                .select('product_name')
                .eq('id', conv['request_id'])
                .maybeSingle();

            final productName = request?['product_name'] ?? 'طلب جملة';

            // إظهار إشعار الطلب
            _notificationService.showOrderMessageNotification(
              orderName: 'طلب جملة - $productName',
              messageText: message['message'] ?? 'رسالة جديدة من الإدارة',
              id: messageId.hashCode,
            );

            print('🔔 إشعار جملة جديد: $productName');
          }
        }
      }
    } catch (e) {
      print('❌ خطأ في فحص رسائل الجملة: $e');
    }
  }

  /// فحص رسائل الطلبات العادية
  Future<void> _checkRetailMessages(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      // جلب محادثات الطلبات العادية للمستخدم
      final conversations = await client
          .from('order_threads')
          .select('id, title, order_type')
          .eq('user_id', userId);

      for (final conv in conversations) {
        final conversationId = conv['id'] as String;

        // جلب الرسائل الجديدة من الإدارة
        final messages = await client
            .from('order_messages')
            .select('*')
            .eq('conversation_id', conversationId)
            .eq('sender_type', 'admin')
            .eq('is_read', false)
            .order('created_at', ascending: false)
            .limit(3);

        for (final message in messages) {
          final messageId = message['id'] as String;
          if (!_notifiedMessageIds.contains(messageId)) {
            _notifiedMessageIds.add(messageId);

            final orderType = conv['order_type'] as String?;
            final title = conv['title'] as String? ?? 'طلب';

            String orderName;
            switch (orderType) {
              case 'mobile_credit':
                orderName = 'طلب رصيد - $title';
                break;
              case 'delivery':
                orderName = 'طلب شحن - $title';
                break;
              default:
                orderName = 'طلب - $title';
            }

            // إظهار إشعار الطلب
            _notificationService.showOrderMessageNotification(
              orderName: orderName,
              messageText: message['message'] ?? 'رسالة جديدة من الإدارة',
              id: messageId.hashCode,
            );

            print('🔔 إشعار طلب جديد: $orderName');
          }
        }
      }
    } catch (e) {
      print('❌ خطأ في فحص رسائل الطلبات العادية: $e');
    }
  }

  /// إيقاف الاستماع لجميع المحادثات
  Future<void> stopListening() async {
    print('⏹️ إيقاف الاستماع لجميع المحادثات');

    // إلغاء جميع القنوات
    for (final channel in _channels.values) {
      await channel.unsubscribe();
    }
    _channels.clear();

    // إيقاف التحديث الدوري
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// إيقاف الاستماع لمحادثة واحدة
  Future<void> stopListeningToConversation(String conversationId) async {
    final channel = _channels.remove(conversationId);
    if (channel != null) {
      await channel.unsubscribe();
      print('⏹️ تم إيقاف الاستماع للمحادثة: $conversationId');
    }
  }

  /// تنظيف الموارد
  Future<void> dispose() async {
    await stopListening();
    _notifiedMessageIds.clear();
    onNewMessagesReceived = null;
  }
}
