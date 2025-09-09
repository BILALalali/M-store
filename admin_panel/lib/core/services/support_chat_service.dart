import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/support_conversation.dart';
import '../models/support_message.dart';
import 'supabase_service.dart';

class SupportChatService {
  static final SupportChatService _instance = SupportChatService._internal();
  factory SupportChatService() => _instance;
  SupportChatService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  // اختبار صلاحيات المدير
  Future<bool> testAdminPermissions() async {
    try {
      if (!_supabaseService.isReady) {
        print('Supabase غير مهيأ');
        return false;
      }

      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        print('المستخدم غير مسجل الدخول');
        return false;
      }

      print('اختبار صلاحيات المدير للمستخدم: ${currentUser.id}');

      // استخدام service_role client للتحقق من الصلاحيات
      final client = _supabaseService.serviceRoleClient;
      if (client != null) {
        try {
          // التحقق من وجود المدير في جدول admin_users
          final adminCheck = await client
              .from('admin_users')
              .select('*')
              .eq('user_id', currentUser.id)
              .eq('is_active', true)
              .maybeSingle();

          if (adminCheck != null) {
            print('المدير موجود في جدول admin_users: $adminCheck');
            return true;
          } else {
            print('المدير غير موجود في جدول admin_users');

            // محاولة إضافة المدير
            try {
              await client.from('admin_users').insert({
                'user_id': currentUser.id,
                'email': currentUser.email,
                'full_name':
                    currentUser.userMetadata?['full_name'] ?? 'مدير النظام',
                'role': 'super_admin',
                'is_active': true,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
              print('تم إضافة المدير إلى جدول admin_users');
              return true;
            } catch (insertError) {
              print('خطأ في إضافة المدير: $insertError');
              return false;
            }
          }
        } catch (e) {
          print('خطأ في التحقق من الصلاحيات: $e');
          return false;
        }
      } else {
        print('service_role client غير متاح');
        return false;
      }
    } catch (e) {
      print('خطأ في اختبار صلاحيات المدير: $e');
      return false;
    }
  }

  // اختبار الاتصال بقاعدة البيانات
  Future<bool> testDatabaseConnection() async {
    try {
      if (!_supabaseService.isReady) {
        print('Supabase غير مهيأ');
        return false;
      }

      print('اختبار الاتصال بقاعدة البيانات...');

      // اختبار جدول المحادثات
      final conversationsTest = await _supabaseService.client!
          .from('support_conversations')
          .select('count')
          .limit(1);

      print('اختبار جدول المحادثات: $conversationsTest');

      // اختبار جدول الرسائل
      final messagesTest = await _supabaseService.client!
          .from('support_messages')
          .select('count')
          .limit(1);

      print('اختبار جدول الرسائل: $messagesTest');

      // جلب عينة من البيانات
      final sampleConversations = await _supabaseService.client!
          .from('support_conversations')
          .select('*')
          .limit(5);

      print('عينة من المحادثات: $sampleConversations');

      final sampleMessages = await _supabaseService.client!
          .from('support_messages')
          .select('*')
          .limit(5);

      print('عينة من الرسائل: $sampleMessages');

      return true;
    } catch (e) {
      print('خطأ في اختبار الاتصال: $e');
      return false;
    }
  }

  // الحصول على جميع المحادثات
  Future<List<SupportConversation>> getConversations() async {
    try {
      if (!_supabaseService.isReady) {
        print('Supabase غير مهيأ');
        return [];
      }

      print('جلب محادثات فريق الدعم...');

      // محاولة استخدام service_role client للوصول للبيانات
      final client =
          _supabaseService.serviceRoleClient ?? _supabaseService.client!;

      // أولاً، جلب المحادثات بدون العلاقات
      final response = await client
          .from('support_conversations')
          .select('*')
          .order('updated_at', ascending: false);

      print('استجابة قاعدة البيانات: $response');

      final conversations = <SupportConversation>[];

      for (var item in response) {
        print('معالجة محادثة: $item');

        // محاولة جلب معلومات المستخدم من جدول profiles
        String? userEmail;
        String? userName;

        try {
          final profileResponse = await _supabaseService.client!
              .from('profiles')
              .select('email, full_name')
              .eq('id', item['user_id'])
              .maybeSingle();

          if (profileResponse != null) {
            userEmail = profileResponse['email'];
            userName = profileResponse['full_name'];
            print('معلومات المستخدم: $profileResponse');
          }
        } catch (profileError) {
          print('خطأ في جلب معلومات المستخدم: $profileError');
          // محاولة جلب من جدول auth.users
          try {
            final authResponse = await _supabaseService.client!
                .from('auth.users')
                .select('email')
                .eq('id', item['user_id'])
                .maybeSingle();

            if (authResponse != null) {
              userEmail = authResponse['email'];
              print('البريد الإلكتروني من auth.users: $userEmail');
            }
          } catch (authError) {
            print('خطأ في جلب البريد الإلكتروني: $authError');
          }
        }

        // جلب آخر رسالة
        final lastMessage = await _getLastMessage(item['id']);

        // جلب عدد الرسائل غير المقروءة
        final unreadCount = await _getUnreadCount(item['id']);

        conversations.add(
          SupportConversation(
            id: item['id'],
            userId: item['user_id'],
            status: item['status'] ?? 'open',
            isOpen: item['is_open'] ?? true,
            createdAt: DateTime.parse(item['created_at']),
            updatedAt: DateTime.parse(item['updated_at']),
            userEmail: userEmail,
            userName: userName,
            lastMessage: lastMessage?.message,
            lastMessageAt: lastMessage?.createdAt,
            unreadCount: unreadCount,
          ),
        );
      }

      print('تم جلب ${conversations.length} محادثة');
      return conversations;
    } catch (e) {
      print('خطأ في جلب المحادثات: $e');
      // محاولة جلب البيانات بدون علاقات
      try {
        final simpleResponse = await _supabaseService.client!
            .from('support_conversations')
            .select('*')
            .order('updated_at', ascending: false);

        print('استجابة مبسطة: $simpleResponse');

        final conversations = <SupportConversation>[];
        for (var item in simpleResponse) {
          conversations.add(
            SupportConversation(
              id: item['id'],
              userId: item['user_id'],
              status: item['status'] ?? 'open',
              isOpen: item['is_open'] ?? true,
              createdAt: DateTime.parse(item['created_at']),
              updatedAt: DateTime.parse(item['updated_at']),
              userEmail: null,
              userName: 'مستخدم ${item['user_id'].toString().substring(0, 8)}',
              lastMessage: null,
              lastMessageAt: null,
              unreadCount: 0,
            ),
          );
        }

        print('تم جلب ${conversations.length} محادثة (مبسطة)');
        return conversations;
      } catch (simpleError) {
        print('خطأ في الجلب المبسط: $simpleError');
        return [];
      }
    }
  }

  // الحصول على محادثة محددة
  Future<SupportConversation?> getConversation(String conversationId) async {
    try {
      if (!_supabaseService.isReady) {
        return null;
      }

      print('جلب المحادثة: $conversationId');

      final response = await _supabaseService.client!
          .from('support_conversations')
          .select('''
            *,
            profiles!support_conversations_user_id_fkey(
              email,
              full_name
            )
          ''')
          .eq('id', conversationId)
          .single();

      final profile = response['profiles'] as Map<String, dynamic>?;

      // جلب آخر رسالة
      final lastMessage = await _getLastMessage(conversationId);

      // جلب عدد الرسائل غير المقروءة
      final unreadCount = await _getUnreadCount(conversationId);

      return SupportConversation(
        id: response['id'],
        userId: response['user_id'],
        status: response['status'] ?? 'open',
        isOpen: response['is_open'] ?? true,
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        userEmail: profile?['email'],
        userName: profile?['full_name'],
        lastMessage: lastMessage?.message,
        lastMessageAt: lastMessage?.createdAt,
        unreadCount: unreadCount,
      );
    } catch (e) {
      print('خطأ في جلب المحادثة: $e');
      return null;
    }
  }

  // الحصول على رسائل محادثة محددة
  Future<List<SupportMessage>> getMessages(String conversationId) async {
    try {
      if (!_supabaseService.isReady) {
        return [];
      }

      print('جلب رسائل المحادثة: $conversationId');

      // التحقق من أن المستخدم مدير أولاً
      final isAdmin = await _supabaseService.isAdmin();
      print('هل المستخدم مدير؟ $isAdmin');

      // استخدام service_role client للوصول للبيانات
      final client = _supabaseService.serviceRoleClient;
      if (client != null) {
        try {
          print('استخدام service_role client لجلب الرسائل');
          final response = await client
              .from('support_messages')
              .select('*')
              .eq('conversation_id', conversationId)
              .order('created_at', ascending: true)
              .order('id', ascending: true); // ترتيب إضافي حسب ID للاستقرار

          print('استجابة رسائل قاعدة البيانات (service_role): $response');
          print('عدد الرسائل من service_role: ${response.length}');

          // طباعة تفصيلية للرسائل
          for (int i = 0; i < response.length; i++) {
            final msg = response[i];
            print(
              'رسالة $i: "${msg['message']}" - المرسل: ${msg['sender_type']} - الوقت: ${msg['created_at']} - ID: ${msg['id']}',
            );
          }

          return _processMessages(response);
        } catch (serviceError) {
          print('خطأ في service_role client: $serviceError');
          // الانتقال للعميل العادي
        }
      }

      // استخدام العميل العادي كبديل
      print('استخدام العميل العادي لجلب الرسائل');
      final response = await _supabaseService.client!
          .from('support_messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .order('id', ascending: true); // ترتيب إضافي حسب ID للاستقرار

      print('استجابة رسائل قاعدة البيانات (عميل عادي): $response');
      print('عدد الرسائل من العميل العادي: ${response.length}');

      // طباعة تفصيلية للرسائل
      for (int i = 0; i < response.length; i++) {
        final msg = response[i];
        print(
          'رسالة $i: "${msg['message']}" - المرسل: ${msg['sender_type']} - الوقت: ${msg['created_at']} - ID: ${msg['id']}',
        );
      }

      return _processMessages(response);
    } catch (e) {
      print('خطأ في جلب الرسائل: $e');
      return [];
    }
  }

  // معالجة الرسائل
  List<SupportMessage> _processMessages(List<dynamic> response) {
    final messages = <SupportMessage>[];

    for (var item in response) {
      print('معالجة رسالة: $item');

      // محاولة جلب معلومات المرسل
      String? senderName;
      String? senderAvatar;

      try {
        if (item['sender_type'] == 'admin') {
          // جلب معلومات المدير
          senderName = 'فريق الدعم';
          senderAvatar = null;
        } else {
          // جلب معلومات المستخدم
          senderName = 'مستخدم';
          senderAvatar = null;
        }
      } catch (profileError) {
        print('خطأ في جلب معلومات المرسل: $profileError');
        senderName = item['sender_type'] == 'admin' ? 'فريق الدعم' : 'مستخدم';
      }

      final createdAt = DateTime.parse(item['created_at']);
      print('رسالة: ${item['message']} - التاريخ: $createdAt');

      messages.add(
        SupportMessage(
          id: item['id'],
          conversationId: item['conversation_id'],
          senderType: item['sender_type'] ?? 'user',
          senderId: item['sender_id'],
          type: item['type'] ?? 'text',
          message: item['message'] ?? '',
          mediaUrl: item['media_url'],
          createdAt: createdAt,
          senderName: senderName,
          senderAvatar: senderAvatar,
        ),
      );
    }

    // ترتيب الرسائل حسب الوقت (من الأقدم للأحدث)
    messages.sort((a, b) {
      // مقارنة مباشرة للتواريخ (الأقدم أولاً)
      final timeComparison = a.createdAt.compareTo(b.createdAt);
      if (timeComparison != 0) {
        return timeComparison;
      }

      // إذا كانت التواريخ متشابهة، رتب حسب ID (الأقدم أولاً)
      return a.id.compareTo(b.id);
    });

    print('=== معالجة الرسائل في الخدمة ===');
    print('تم معالجة ${messages.length} رسالة مرتبة من الأقدم للأحدث');
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final timeStr =
          '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}:${msg.createdAt.second.toString().padLeft(2, '0')}';
      print(
        '$i. [$timeStr] ${msg.senderType == 'admin' ? '👨‍💼' : '👤'} "${msg.message}"',
      );
    }
    print('================================');

    return messages;
  }

  // إرسال رسالة جديدة
  Future<SupportMessage?> sendMessage({
    required String conversationId,
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

      print('إرسال رسالة جديدة للمحادثة: $conversationId');

      final messageData = {
        'conversation_id': conversationId,
        'sender_type': 'admin',
        'sender_id': currentUser.id,
        'type': type,
        'message': message,
        'media_url': mediaUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client!
          .from('support_messages')
          .insert(messageData)
          .select()
          .single();

      // تحديث وقت آخر تحديث للمحادثة
      await _updateConversationTimestamp(conversationId);

      // جلب معلومات المرسل
      final adminProfile = await _supabaseService.getAdminProfile();

      final supportMessage = SupportMessage(
        id: response['id'],
        conversationId: response['conversation_id'],
        senderType: response['sender_type'],
        senderId: response['sender_id'],
        type: response['type'],
        message: response['message'],
        mediaUrl: response['media_url'],
        createdAt: DateTime.parse(response['created_at']),
        senderName: adminProfile?['full_name'] ?? 'فريق الدعم',
        senderAvatar: adminProfile?['avatar_url'],
      );

      print('تم إرسال الرسالة بنجاح');
      return supportMessage;
    } catch (e) {
      print('خطأ في إرسال الرسالة: $e');
      rethrow;
    }
  }

  // تحديث حالة المحادثة
  Future<bool> updateConversationStatus({
    required String conversationId,
    String? status,
    bool? isOpen,
  }) async {
    try {
      if (!_supabaseService.isReady) {
        throw Exception('Supabase غير مهيأ');
      }

      print('تحديث حالة المحادثة: $conversationId');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status != null) updates['status'] = status;
      if (isOpen != null) updates['is_open'] = isOpen;

      await _supabaseService.client!
          .from('support_conversations')
          .update(updates)
          .eq('id', conversationId);

      print('تم تحديث حالة المحادثة بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تحديث حالة المحادثة: $e');
      return false;
    }
  }

  // تعيين الرسائل كمقروءة
  Future<bool> markMessagesAsRead(String conversationId) async {
    try {
      if (!_supabaseService.isReady) {
        return false;
      }

      print('تعيين الرسائل كمقروءة للمحادثة: $conversationId');

      // في هذا المثال، سنقوم بتحديث آخر وقت قراءة للمحادثة
      // يمكنك إضافة جدول منفصل لتتبع الرسائل المقروءة
      await _supabaseService.client!
          .from('support_conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);

      print('تم تعيين الرسائل كمقروءة');
      return true;
    } catch (e) {
      print('خطأ في تعيين الرسائل كمقروءة: $e');
      return false;
    }
  }

  // الحصول على آخر رسالة في المحادثة
  Future<SupportMessage?> _getLastMessage(String conversationId) async {
    try {
      final response = await _supabaseService.client!
          .from('support_messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return SupportMessage(
        id: response['id'],
        conversationId: response['conversation_id'],
        senderType: response['sender_type'] ?? 'user',
        senderId: response['sender_id'],
        type: response['type'] ?? 'text',
        message: response['message'] ?? '',
        mediaUrl: response['media_url'],
        createdAt: DateTime.parse(response['created_at']),
      );
    } catch (e) {
      print('خطأ في جلب آخر رسالة: $e');
      return null;
    }
  }

  // الحصول على عدد الرسائل غير المقروءة
  Future<int> _getUnreadCount(String conversationId) async {
    try {
      // في هذا المثال، سنقوم بحساب الرسائل من المستخدمين فقط
      // يمكنك تحسين هذا بناءً على متطلباتك
      final response = await _supabaseService.client!
          .from('support_messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('sender_type', 'user')
          .order('created_at', ascending: false);

      // يمكنك إضافة منطق أكثر تعقيداً هنا لتتبع الرسائل المقروءة
      return response.length;
    } catch (e) {
      print('خطأ في حساب الرسائل غير المقروءة: $e');
      return 0;
    }
  }

  // تحديث وقت آخر تحديث للمحادثة
  Future<void> _updateConversationTimestamp(String conversationId) async {
    try {
      await _supabaseService.client!
          .from('support_conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);
    } catch (e) {
      print('خطأ في تحديث وقت المحادثة: $e');
    }
  }

  // الاستماع للتحديثات المباشرة للمحادثات
  RealtimeChannel? _conversationsChannel;
  RealtimeChannel? _messagesChannel;

  // بدء الاستماع للتحديثات المباشرة للمحادثات
  void startListeningToConversations(
    Function(List<SupportConversation>) onUpdate,
  ) {
    try {
      if (!_supabaseService.isReady) return;

      _conversationsChannel = _supabaseService.client!
          .channel('support_conversations_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'support_conversations',
            callback: (payload) async {
              print('تحديث في المحادثات: $payload');
              final conversations = await getConversations();
              onUpdate(conversations);
            },
          )
          .subscribe();

      print('بدأ الاستماع لتحديثات المحادثات');
    } catch (e) {
      print('خطأ في بدء الاستماع للمحادثات: $e');
    }
  }

  // بدء الاستماع للتحديثات المباشرة للرسائل
  void startListeningToMessages(
    String conversationId,
    Function(List<SupportMessage>) onUpdate,
  ) {
    try {
      if (!_supabaseService.isReady) return;

      _messagesChannel = _supabaseService.client!
          .channel('support_messages_changes_$conversationId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'support_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) async {
              print('تحديث في الرسائل: $payload');
              final messages = await getMessages(conversationId);
              onUpdate(messages);
            },
          )
          .subscribe();

      print('بدأ الاستماع لتحديثات الرسائل للمحادثة: $conversationId');
    } catch (e) {
      print('خطأ في بدء الاستماع للرسائل: $e');
    }
  }

  // إيقاف الاستماع للتحديثات
  void stopListening() {
    try {
      _conversationsChannel?.unsubscribe();
      _messagesChannel?.unsubscribe();
      _conversationsChannel = null;
      _messagesChannel = null;
      print('تم إيقاف الاستماع للتحديثات');
    } catch (e) {
      print('خطأ في إيقاف الاستماع: $e');
    }
  }

  // إحصائيات الدردشة
  Future<Map<String, dynamic>> getChatStats() async {
    try {
      if (!_supabaseService.isReady) {
        return _getDefaultChatStats();
      }

      // جلب عدد المحادثات الإجمالي
      final totalConversations = await _supabaseService.client!
          .from('support_conversations')
          .select('id');

      // جلب عدد المحادثات المفتوحة
      final openConversations = await _supabaseService.client!
          .from('support_conversations')
          .select('id')
          .eq('is_open', true);

      // جلب عدد المحادثات المغلقة
      final closedConversations = await _supabaseService.client!
          .from('support_conversations')
          .select('id')
          .eq('is_open', false);

      // جلب عدد الرسائل الإجمالي
      final totalMessages = await _supabaseService.client!
          .from('support_messages')
          .select('id');

      return {
        'total_conversations': totalConversations.length,
        'open_conversations': openConversations.length,
        'closed_conversations': closedConversations.length,
        'total_messages': totalMessages.length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات الدردشة: $e');
      return _getDefaultChatStats();
    }
  }

  Map<String, dynamic> _getDefaultChatStats() {
    return {
      'total_conversations': 0,
      'open_conversations': 0,
      'closed_conversations': 0,
      'total_messages': 0,
    };
  }
}
