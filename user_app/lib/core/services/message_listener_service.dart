import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_chat_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';
import '../../presentation/screens/order_model.dart';

/// خدمة الاستماع للرسائل الجديدة في جميع المحادثات
class MessageListenerService {
  static final MessageListenerService _instance =
      MessageListenerService._internal();
  factory MessageListenerService() => _instance;
  MessageListenerService._internal();

  final Map<String, RealtimeChannel> _channels = {};
  final NotificationService _notificationService = NotificationService();
  Timer? _pollingTimer;
  final Set<String> _notifiedMessageIds = {}; // لتتبع الرسائل التي تم الإشعار عنها
  
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

      // إنشاء قناة Realtime للاستماع للرسائل من الإدارة فقط
      final channel = client.channel('notifications_$conversationId');
      
      channel
          .on(
            RealtimeListenTypes.postgresChanges,
            ChannelFilter(
              event: 'INSERT',
              schema: 'public',
              table: table,
              filter: 'conversation_id=eq.$conversationId',
            ),
            (payload, [ref]) {
              final newRecord = payload['new'] as Map<String, dynamic>?;
              if (newRecord != null) {
                // فقط رسائل الإدارة
                if (newRecord['sender_type'] == 'admin') {
                  print('🔔 رسالة جديدة من الإدارة في الخلفية!');
                  _handleNewMessage(newRecord, order);
                }
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
      _notificationService.showNewMessageNotification(
        conversationId: convId,
        orderName: order.orderType == OrderType.wholesale
            ? 'طلب جملة - ${order.productName}'
            : order.orderType == OrderType.mobileCredit
            ? 'طلب رصيد - ${order.productName}'
            : order.orderType == OrderType.delivery
            ? 'طلب شحن - ${order.productName}'
            : 'طلب ${order.productName}',
        messageText: notificationText,
        notificationId: convId.hashCode,
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
    
    // التحديث كل 30 ثانية
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      print('🔄 تحديث دوري للمحادثات...');
      onNewMessagesReceived?.call();
    });
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

