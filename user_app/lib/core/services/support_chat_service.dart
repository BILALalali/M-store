import 'dart:io';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

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
        .eq('is_open', true)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // أنشئ محادثة جديدة
    final row = await _client
        .from(_conversations)
        .insert({'user_id': user.id, 'status': 'open', 'is_open': true})
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
        .order('created_at');
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
    });
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
    });
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
        .order('created_at')
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
}
