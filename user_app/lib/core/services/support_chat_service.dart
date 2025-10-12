import 'dart:io';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'simple_notification_service.dart';

class SupportChatService {
  static const String _conversations = 'support_conversations';
  static const String _messages = 'support_messages';
  static const String _bucket = 'chat_attachments';

  static SupabaseClient get _client => SupabaseService.client!;

  // إنشاء أو جلب محادثة المستخدم الحالية (محادثة واحدة لكل مستخدم)
  static Future<String> getOrCreateConversationForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('المستخدم غير مسجل دخول');
    }

    // حاول جلب محادثة موجودة
    final existing = await _client
        .from(_conversations)
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // أنشئ محادثة جديدة
    final row = await _client
        .from(_conversations)
        .insert({
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  // جلب رسائل محادثة
  static Future<List<dynamic>> fetchMessages(String conversationId) async {
    final rows = await _client
        .from(_messages)
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true); // ترتيب من الأقدم إلى الأحدث
    return rows as List<dynamic>;
  }

  // إرسال رسالة نصية
  static Future<void> sendTextMessage(
    String conversationId,
    String text,
  ) async {
    final user = _client.auth.currentUser;
    await _client.from(_messages).insert({
      'conversation_id': conversationId,
      'sender_type': 'user',
      'sender_id': user?.id,
      'type': 'text',
      'message': text,
      'is_read':
          false, // تحديد الرسالة كغير مقروءة للإنشاء إشعار في لوحة الإدارة
      'created_at': DateTime.now().toIso8601String(),
    });

    // تحديث وقت آخر تحديث للمحادثة
    await _client
        .from(_conversations)
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);
  }

  // إرسال صورة: ترفع إلى التخزين ثم تحفظ الرابط
  static Future<void> sendImageMessage(String conversationId, File file) async {
    final user = _client.auth.currentUser;
    // تأكد من وجود الحاوية
    try {
      await _client.storage.createBucket(
        _bucket,
        const BucketOptions(public: true),
      );
    } catch (_) {}

    final ext = file.path.split('.').last;
    final path =
        '${user?.id}/${DateTime.now().millisecondsSinceEpoch}.${ext.toLowerCase()}';

    await _client.storage.from(_bucket).upload(path, file);
    final url = _client.storage.from(_bucket).getPublicUrl(path);

    await _client.from(_messages).insert({
      'conversation_id': conversationId,
      'sender_type': 'user',
      'sender_id': user?.id,
      'type': 'image',
      'media_url': url,
      'message': 'صورة',
      'is_read':
          false, // تحديد الرسالة كغير مقروءة للإنشاء إشعار في لوحة الإدارة
      'created_at': DateTime.now().toIso8601String(),
    });

    // تحديث وقت آخر تحديث للمحادثة
    await _client
        .from(_conversations)
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);
  }

  // الاشتراك في الرسائل باستخدام stream (أبسط وأكثر توافقاً)
  static Future<StreamSubscription> subscribeToMessages(
    String conversationId,
    void Function(Map<String, dynamic> row) onInsert,
  ) async {
    final seenIds = <String>{};
    try {
      // تهيئة قائمة المعرفات الموجودة لتجنب التكرار عند الاشتراك
      final existing = await fetchMessages(conversationId);
      for (final row in existing) {
        final id = row['id'];
        if (id is String) seenIds.add(id);
      }
    } catch (_) {}

    final sub = _client
        .from(_messages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true) // ترتيب من الأقدم إلى الأحدث
        .listen((rows) {
          for (final row in rows) {
            final id = row['id'];
            if (id is String && !seenIds.contains(id)) {
              seenIds.add(id);
              onInsert(row);
            }
          }
        });

    return sub;
  }

  // حساب عدد الرسائل غير المقروءة من فريق الدعم للمستخدم الحالي
  static Future<int> getUnreadMessagesCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    try {
      // جلب محادثة المستخدم الحالية
      final conversation = await _client
          .from(_conversations)
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (conversation == null) return 0;

      final conversationId = conversation['id'] as String;

      // حساب الرسائل غير المقروءة من فريق الدعم
      final result = await _client
          .from(_messages)
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('sender_type', 'admin')
          .eq('is_read', false);

      return result.length;
    } catch (e) {
      print('خطأ في حساب الرسائل غير المقروءة: $e');
      return 0;
    }
  }

  // تحديث حالة الرسائل كمقروءة عند فتح المحادثة
  static Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await _client
          .from(_messages)
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .eq('sender_type', 'admin')
          .eq('is_read', false);
    } catch (e) {
      print('خطأ في تحديث حالة الرسائل: $e');
    }
  }

  // الاشتراك في تحديثات عدد الرسائل غير المقروءة
  static Future<StreamSubscription> subscribeToUnreadCount(
    void Function(int count) onCountUpdate,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      onCountUpdate(0);
      return StreamController<void>().stream.listen((_) {});
    }

    // جلب العدد الأولي
    final initialCount = await getUnreadMessagesCount();
    onCountUpdate(initialCount);

    // جلب محادثة المستخدم الحالية
    final conversation = await _client
        .from(_conversations)
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (conversation == null) {
      onCountUpdate(0);
      return StreamController<void>().stream.listen((_) {});
    }

    final conversationId = conversation['id'] as String;

    // الاشتراك في تحديثات الرسائل للمحادثة المحددة فقط
    final sub = _client
        .from(_messages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .listen((_) async {
          final count = await getUnreadMessagesCount();
          onCountUpdate(count);
        });

    return sub;
  }

  // خدمة الاستماع لإشعارات الدعم
  static final SimpleNotificationService _notificationService = SimpleNotificationService();
  static StreamSubscription? _supportNotificationSubscription;
  static final Set<String> _notifiedSupportMessageIds = {};

  /// بدء الاستماع لإشعارات الدعم
  static Future<void> startSupportNotificationListener() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // جلب محادثة المستخدم الحالية
      final conversation = await _client
          .from(_conversations)
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (conversation == null) return;

      final conversationId = conversation['id'] as String;

      // إلغاء الاشتراك السابق إذا كان موجوداً
      await _supportNotificationSubscription?.cancel();

      // الاشتراك في الرسائل الجديدة من فريق الدعم
      _supportNotificationSubscription = _client
          .from(_messages)
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .listen((rows) {
            for (final row in rows) {
              final messageId = row['id'] as String?;
              final messageText =
                  row['message'] as String? ?? 'رسالة جديدة من فريق الدعم';
              final senderType = row['sender_type'] as String?;

              // فقط رسائل فريق الدعم
              if (senderType != 'admin') continue;

              // تجنب الإشعارات المكررة
              if (messageId != null &&
                  !_notifiedSupportMessageIds.contains(messageId)) {
                _notifiedSupportMessageIds.add(messageId);

                // تنظيف القائمة إذا أصبحت كبيرة جداً
                if (_notifiedSupportMessageIds.length > 1000) {
                  final toRemove = _notifiedSupportMessageIds
                      .take(500)
                      .toList();
                  _notifiedSupportMessageIds.removeAll(toRemove);
                }

            // إظهار الإشعار
            _notificationService.showSupportMessageNotification(
              messageText: messageText,
              id: messageId.hashCode,
            );

                print('🔔 إشعار رسالة دعم جديدة: $messageText');
              }
            }
          });

      print('✅ بدء الاستماع لإشعارات الدعم');
    } catch (e) {
      print('❌ خطأ في بدء الاستماع لإشعارات الدعم: $e');
    }
  }

  /// إيقاف الاستماع لإشعارات الدعم
  static Future<void> stopSupportNotificationListener() async {
    await _supportNotificationSubscription?.cancel();
    _supportNotificationSubscription = null;
    _notifiedSupportMessageIds.clear();
    print('⏹️ تم إيقاف الاستماع لإشعارات الدعم');
  }
}
