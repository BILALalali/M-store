import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support_chat_service.dart';
import 'supabase_service.dart';

class NotificationService extends ChangeNotifier {
  final SupportChatService _chatService = SupportChatService();
  final SupabaseService _supabaseService = SupabaseService();

  int _totalUnreadMessages = 0;
  int _unreadConversations = 0;
  bool _hasNewMessages = false;

  int _supportUnreadMessages = 0;
  int _wholesaleUnreadMessages = 0;
  int _ordersUnreadMessages = 0;

  Timer? _updateTimer;
  RealtimeChannel? _realtimeChannel;

  int get totalUnreadMessages => _totalUnreadMessages;
  int get unreadConversations => _unreadConversations;
  bool get hasNewMessages => _hasNewMessages;

  int get supportUnreadMessages => _supportUnreadMessages;
  int get wholesaleUnreadMessages => _wholesaleUnreadMessages;
  int get ordersUnreadMessages => _ordersUnreadMessages;

  NotificationService() {
    _startPeriodicUpdate();
    _startRealtimeListening();
    Future.delayed(const Duration(milliseconds: 500), () {
      _updateNotifications();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateNotifications();
    });
    _updateNotifications();
  }

  void _startRealtimeListening() {
    try {
      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز للاستماع المباشر');
        return;
      }

      _realtimeChannel = _supabaseService.client!
          .channel('notification_realtime_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'support_messages',
            callback: (payload) async {
              final senderType = payload.newRecord['sender_type'];
              if (senderType == 'user') {
                await _updateNotifications();
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'support_messages',
            callback: (payload) async {
              final oldIsRead = payload.oldRecord['is_read'];
              final newIsRead = payload.newRecord['is_read'];

              if (oldIsRead != newIsRead) {
                await _updateNotifications();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('❌ خطأ في بدء الاستماع المباشر: $e');
    }
  }

  Future<void> _updateNotifications() async {
    try {
      int supportUnread = 0;
      int wholesaleUnread = 0;
      int ordersUnread = 0;
      int totalUnread = 0;
      int unreadConvCount = 0;

      try {
        final supportData = await _calculateSupportUnread();
        supportUnread = supportData['totalUnread']!;
        unreadConvCount += supportData['unreadConversations']!;
      } catch (e) {
        debugPrint('❌ خطأ في حساب رسائل فريق الدعم: $e');
      }

      try {
        final wholesaleData = await _calculateWholesaleUnread();
        wholesaleUnread = wholesaleData['totalUnread']!;
        unreadConvCount += wholesaleData['unreadConversations']!;
      } catch (e) {
        debugPrint('❌ خطأ في حساب رسائل طلبات الجملة: $e');
      }

      try {
        final ordersData = await _calculateOrdersUnread();
        ordersUnread = ordersData['totalUnread']!;
        unreadConvCount += ordersData['unreadConversations']!;
      } catch (e) {
        debugPrint('❌ خطأ في حساب رسائل الطلبات العادية: $e');
      }

      totalUnread = supportUnread + wholesaleUnread + ordersUnread;
      final hasNew = totalUnread > 0;

      if (_totalUnreadMessages != totalUnread ||
          _unreadConversations != unreadConvCount ||
          _hasNewMessages != hasNew ||
          _supportUnreadMessages != supportUnread ||
          _wholesaleUnreadMessages != wholesaleUnread ||
          _ordersUnreadMessages != ordersUnread) {
        _totalUnreadMessages = totalUnread;
        _unreadConversations = unreadConvCount;
        _hasNewMessages = hasNew;

        _supportUnreadMessages = supportUnread;
        _wholesaleUnreadMessages = wholesaleUnread;
        _ordersUnreadMessages = ordersUnread;

        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الإشعارات: $e');
    }
  }

  Future<Map<String, int>> _calculateSupportUnread() async {
    try {
      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز');
        return {'totalUnread': 0, 'unreadConversations': 0};
      }

      final client = _supabaseService.client!;

      final userMessages = await client
          .from('support_messages')
          .select(
            'id, conversation_id, sender_type, is_read, message, created_at',
          )
          .eq('sender_type', 'user')
          .order('created_at', ascending: false);

      int totalUnread = 0;
      final unreadMessages = <Map<String, dynamic>>[];
      final unreadConversationIds = <String>{};

      for (var msg in userMessages) {
        final isRead = msg['is_read'];
        bool isUnread = false;

        if (isRead == null ||
            isRead == false ||
            isRead == 'false' ||
            isRead == 0) {
          isUnread = true;
        }

        if (isUnread) {
          totalUnread++;
          unreadMessages.add(msg);
          unreadConversationIds.add(msg['conversation_id']);
        }
      }

      final uniqueConversations = unreadConversationIds.length;

      return {
        'totalUnread': totalUnread,
        'unreadConversations': uniqueConversations,
      };
    } catch (e) {
      debugPrint('❌ خطأ في حساب رسائل فريق الدعم: $e');
      return {'totalUnread': 0, 'unreadConversations': 0};
    }
  }

  Future<Map<String, int>> _calculateWholesaleUnread() async {
    try {
      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز لحساب رسائل طلبات الجملة');
        return {'totalUnread': 0, 'unreadConversations': 0};
      }

      final client = _supabaseService.client!;
      final userMessages = await client
          .from('wholesale_messages')
          .select(
            'id, conversation_id, sender_type, is_read, message, created_at',
          )
          .eq('sender_type', 'user')
          .order('created_at', ascending: false);

      int totalUnread = 0;
      final unreadConversationIds = <String>{};

      for (var msg in userMessages) {
        final isRead = msg['is_read'];
        bool isUnread = false;

        if (isRead == null ||
            isRead == false ||
            isRead == 'false' ||
            isRead == 0) {
          isUnread = true;
        }

        if (isUnread) {
          totalUnread++;
          unreadConversationIds.add(msg['conversation_id']);
        }
      }

      final uniqueConversations = unreadConversationIds.length;

      return {
        'totalUnread': totalUnread,
        'unreadConversations': uniqueConversations,
      };
    } catch (e) {
      debugPrint('❌ خطأ في حساب رسائل طلبات الجملة: $e');
      return {'totalUnread': 0, 'unreadConversations': 0};
    }
  }

  Future<Map<String, int>> _calculateOrdersUnread() async {
    try {
      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز لحساب رسائل الطلبات العادية');
        return {'totalUnread': 0, 'unreadConversations': 0};
      }

      final client = _supabaseService.client!;
      final userMessages = await client
          .from('order_messages')
          .select(
            'id, conversation_id, sender_type, is_read, message, created_at',
          )
          .eq('sender_type', 'user')
          .order('created_at', ascending: false);

      int totalUnread = 0;
      final unreadOrderIds = <String>{};

      for (var msg in userMessages) {
        final isRead = msg['is_read'];
        bool isUnread = false;

        if (isRead == null ||
            isRead == false ||
            isRead == 'false' ||
            isRead == 0) {
          isUnread = true;
        }

        if (isUnread) {
          totalUnread++;
          unreadOrderIds.add(msg['conversation_id']);
        }
      }

      final uniqueOrders = unreadOrderIds.length;

      return {'totalUnread': totalUnread, 'unreadConversations': uniqueOrders};
    } catch (e) {
      debugPrint('❌ خطأ في حساب رسائل الطلبات العادية: $e');
      return {'totalUnread': 0, 'unreadConversations': 0};
    }
  }

  Future<void> refreshNotifications() async {
    await _updateNotifications();
  }

  Future<void> testUnreadMessages() async {
    try {
      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز');
        return;
      }

      final client = _supabaseService.client!;
      final response = await client
          .from('support_messages')
          .select('id, message, conversation_id, is_read, created_at')
          .eq('sender_type', 'user')
          .or('is_read.is.null,is_read.eq.false')
          .order('created_at', ascending: false);

      debugPrint('عدد الرسائل غير المقروءة: ${response.length}');
    } catch (e) {
      debugPrint('❌ خطأ في اختبار الرسائل غير المقروءة: $e');
    }
  }

  Future<void> testPermissions() async {
    try {
      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز');
        return;
      }

      final client = _supabaseService.client!;
      final currentUser = _supabaseService.currentUser;

      try {
        await client
            .from('admin_users')
            .select('*')
            .eq('user_id', currentUser!.id)
            .single();

        debugPrint('✅ المدير موجود في جدول admin_users');
      } catch (e) {
        debugPrint('❌ خطأ في التحقق من المدير: $e');
      }

      try {
        await client
            .from('support_messages')
            .select('id, message, sender_type')
            .limit(1);
        debugPrint('✅ يمكن القراءة من جدول support_messages');
      } catch (e) {
        debugPrint('❌ خطأ في القراءة من support_messages: $e');
      }

      try {
        await client
            .from('support_messages')
            .update({'is_read': true})
            .eq('id', 'non-existent-id');
        debugPrint('✅ يمكن التحديث في جدول support_messages');
      } catch (e) {
        debugPrint('❌ خطأ في التحديث في support_messages: $e');
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختبار الصلاحيات: $e');
    }
  }

  Future<void> testDatabaseConnection() async {
    try {
      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز');
        return;
      }

      final client = _supabaseService.client!;
      await client.from('support_messages').select('count').limit(1);

      debugPrint('✅ الاتصال بقاعدة البيانات نجح');

      final sampleResponse = await client
          .from('support_messages')
          .select('message, sender_type, is_read')
          .limit(5);

      debugPrint('🔍 عينة من البيانات:');
      for (var msg in sampleResponse) {
        debugPrint(
          '   - "${msg['message']}" - sender: ${msg['sender_type']} - is_read: ${msg['is_read']}',
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في الاتصال بقاعدة البيانات: $e');
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _chatService.markMessagesAsRead(conversationId);
      await _updateNotifications();
    } catch (e) {
      debugPrint('خطأ في تعيين الرسائل كمقروءة: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _chatService.markMessagesAsRead('all');
      await _updateNotifications();
    } catch (e) {
      debugPrint('خطأ في تعيين جميع الرسائل كمقروءة: $e');
    }
  }

  String getNotificationText() {
    if (_totalUnreadMessages == 0) {
      return 'لا توجد رسائل جديدة';
    } else if (_totalUnreadMessages == 1) {
      return 'رسالة واحدة غير مقروءة';
    } else {
      return '$_totalUnreadMessages رسائل غير مقروءة';
    }
  }

  String getUnreadConversationsText() {
    if (_unreadConversations == 0) {
      return 'لا توجد محادثات جديدة';
    } else if (_unreadConversations == 1) {
      return 'محادثة واحدة غير مقروءة';
    } else {
      return '$_unreadConversations محادثات غير مقروءة';
    }
  }
}
