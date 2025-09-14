import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'support_chat_service.dart';

/// خدمة اختبار نظام الإشعارات
class TestNotificationSystem {
  static final TestNotificationSystem _instance =
      TestNotificationSystem._internal();
  factory TestNotificationSystem() => _instance;
  TestNotificationSystem._internal();

  final NotificationService _notificationService = NotificationService();
  final SupportChatService _chatService = SupportChatService();

  /// اختبار النظام الكامل
  Future<void> testNotificationSystem() async {
    debugPrint('🧪 بدء اختبار نظام الإشعارات...');

    try {
      // 1. اختبار جلب المحادثات
      debugPrint('📱 جلب المحادثات...');
      final conversations = await _chatService.getConversations();
      debugPrint('📊 عدد المحادثات: ${conversations.length}');

      for (final conversation in conversations) {
        debugPrint('📱 محادثة ${conversation.id}:');
        debugPrint(
          '   - المستخدم: ${conversation.userName ?? conversation.userId}',
        );
        debugPrint('   - الرسائل غير المقروءة: ${conversation.unreadCount}');
        debugPrint('   - آخر رسالة: ${conversation.lastMessage ?? "لا توجد"}');
      }

      // 2. اختبار خدمة الإشعارات
      debugPrint('🔔 اختبار خدمة الإشعارات...');
      await _notificationService.refreshNotifications();

      debugPrint(
        '📊 إجمالي الرسائل غير المقروءة: ${_notificationService.totalUnreadMessages}',
      );
      debugPrint(
        '📊 عدد المحادثات غير المقروءة: ${_notificationService.unreadConversations}',
      );
      debugPrint(
        '📊 هل توجد رسائل جديدة: ${_notificationService.hasNewMessages}',
      );

      // 3. اختبار نص الإشعار
      final notificationText = _notificationService.getNotificationText();
      debugPrint('📝 نص الإشعار: "$notificationText"');

      // 4. اختبار نص المحادثات غير المقروءة
      final unreadText = _notificationService.getUnreadConversationsText();
      debugPrint('📝 نص المحادثات غير المقروءة: "$unreadText"');

      debugPrint('✅ تم اختبار نظام الإشعارات بنجاح!');
    } catch (e) {
      debugPrint('❌ خطأ في اختبار نظام الإشعارات: $e');
    }
  }

  /// اختبار تعيين الرسائل كمقروءة
  Future<void> testMarkAsRead(String conversationId) async {
    debugPrint('📖 اختبار تعيين الرسائل كمقروءة للمحادثة: $conversationId');

    try {
      // تعيين الرسائل كمقروءة
      await _notificationService.markConversationAsRead(conversationId);

      // التحقق من النتيجة
      await _notificationService.refreshNotifications();

      debugPrint('📊 بعد التعيين كمقروء:');
      debugPrint(
        '   - إجمالي الرسائل غير المقروءة: ${_notificationService.totalUnreadMessages}',
      );
      debugPrint(
        '   - عدد المحادثات غير المقروءة: ${_notificationService.unreadConversations}',
      );
      debugPrint(
        '   - هل توجد رسائل جديدة: ${_notificationService.hasNewMessages}',
      );

      debugPrint('✅ تم اختبار تعيين الرسائل كمقروءة بنجاح!');
    } catch (e) {
      debugPrint('❌ خطأ في اختبار تعيين الرسائل كمقروءة: $e');
    }
  }

  /// اختبار تعيين جميع الرسائل كمقروءة
  Future<void> testMarkAllAsRead() async {
    debugPrint('📖 اختبار تعيين جميع الرسائل كمقروءة...');

    try {
      await _notificationService.markAllAsRead();

      debugPrint('📊 بعد تعيين جميع الرسائل كمقروءة:');
      debugPrint(
        '   - إجمالي الرسائل غير المقروءة: ${_notificationService.totalUnreadMessages}',
      );
      debugPrint(
        '   - عدد المحادثات غير المقروءة: ${_notificationService.unreadConversations}',
      );
      debugPrint(
        '   - هل توجد رسائل جديدة: ${_notificationService.hasNewMessages}',
      );

      debugPrint('✅ تم اختبار تعيين جميع الرسائل كمقروءة بنجاح!');
    } catch (e) {
      debugPrint('❌ خطأ في اختبار تعيين جميع الرسائل كمقروءة: $e');
    }
  }
}
