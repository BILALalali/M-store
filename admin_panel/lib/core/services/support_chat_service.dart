import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/support_conversation.dart';
import '../models/support_message.dart';
import 'supabase_service.dart';
import 'dart:async';

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

      // استخدام العميل العادي للتحقق من الصلاحيات
      final client = _supabaseService.client!;
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

      print('🚀 ===== بدء جلب محادثات فريق الدعم =====');

      // استخدام العميل العادي للوصول للبيانات (أكثر استقراراً)
      final client = _supabaseService.client!;

      // جلب جميع المحادثات
      final response = await client
          .from('support_conversations')
          .select('*')
          .order('updated_at', ascending: false);

      print('استجابة قاعدة البيانات: $response');

      final conversations = <SupportConversation>[];

      for (var item in response) {
        print(
          '🚀 ===== معالجة محادثة: ID=${item['id']}, user_id=${item['user_id']} =====',
        );

        String? userName;
        String? userEmail;
        // ===== بداية جلب معلومات المستخدم =====
        try {
          // استخدام الاستعلام المباشر لجدول profiles
          final profileResponse = await _supabaseService.client!
              .from('profiles')
              .select('name')
              .eq('id', item['user_id'])
              .maybeSingle();

          if (profileResponse != null && profileResponse['name'] != null) {
            userName = profileResponse['name'];
            print('✅ تم جلب اسم المستخدم: $userName');
          } else {
            // إنشاء اسم مؤقت أكثر وضوحاً
            final userId = item['user_id'].toString();
            userName = 'مستخدم ${userId.substring(0, 8)}';
            print('❌ لم يتم العثور على الاسم، استخدام المعرف: $userName');
          }
        } catch (profileError) {
          print('❌ خطأ في جلب الاسم: $profileError');
          final userId = item['user_id'].toString();
          userName = 'مستخدم ${userId.substring(0, 8)}';
        }
        // ===== نهاية جلب معلومات المستخدم =====

        // جلب آخر رسالة
        final lastMessage = await _getLastMessage(item['id']);

        // جلب عدد الرسائل غير المقروءة
        final unreadCount = await _getUnreadCount(item['id']);
        print('📊 المحادثة ${item['id']}: unreadCount = $unreadCount');

        final hasUnreadMessages = unreadCount > 0;
        print(
          '🚀 المحادثة ${item['id']}: unreadCount=$unreadCount, hasUnreadMessages=$hasUnreadMessages',
        );

        conversations.add(
          SupportConversation(
            id: item['id'],
            userId: item['user_id'],
            createdAt: DateTime.parse(item['created_at']),
            updatedAt: DateTime.parse(item['updated_at']),
            userEmail: userEmail,
            userName: userName,
            lastMessage: lastMessage?.message,
            lastMessageAt: lastMessage?.createdAt,
            unreadCount: unreadCount,
            hasUnreadMessages: hasUnreadMessages, // تحديد وجود رسائل غير مقروءة
          ),
        );

        print('🚀 ===== انتهاء معالجة المحادثة: ${item['id']} =====');
      }

      print(
        '🚀 ===== انتهاء جلب محادثات فريق الدعم: ${conversations.length} محادثة =====',
      );
      return conversations;
    } catch (e) {
      print('خطأ في جلب المحادثات: $e');
      // محاولة جلب البيانات بدون علاقات
      try {
        final simpleResponse = await _supabaseService.client!
            .from('support_conversations')
            .select('*')
            .order('updated_at', ascending: false);

        final conversations = <SupportConversation>[];
        for (var item in simpleResponse) {
          // جلب اسم المستخدم من جدول profiles حتى في الحالة المبسطة
          String? userName;
          try {
            // استخدام الاستعلام المباشر لجدول profiles
            final profileResponse = await _supabaseService.client!
                .from('profiles')
                .select('name')
                .eq('id', item['user_id'])
                .maybeSingle();

            if (profileResponse != null && profileResponse['name'] != null) {
              userName = profileResponse['name'];
              print('✅ [مبسط] تم جلب اسم المستخدم: $userName');
            } else {
              final userId = item['user_id'].toString();
              userName = 'مستخدم ${userId.substring(0, 8)}';
              print(
                '❌ [مبسط] لم يتم العثور على الاسم، استخدام المعرف: $userName',
              );
            }
          } catch (profileError) {
            print('❌ [مبسط] خطأ في جلب الاسم: $profileError');
            final userId = item['user_id'].toString();
            userName = 'مستخدم ${userId.substring(0, 8)}';
          }

          // حتى في الحالة المبسطة، نحتاج لحساب الرسائل غير المقروءة
          final unreadCount = await _getUnreadCount(item['id']);

          conversations.add(
            SupportConversation(
              id: item['id'],
              userId: item['user_id'],
              createdAt: DateTime.parse(item['created_at']),
              updatedAt: DateTime.parse(item['updated_at']),
              userEmail: null,
              userName: userName,
              lastMessage: null,
              lastMessageAt: null,
              unreadCount: unreadCount,
              hasUnreadMessages:
                  unreadCount >
                  0, // حساب الرسائل غير المقروءة حتى في الحالة المبسطة
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
              name
            )
          ''')
          .eq('id', conversationId)
          .single();

      final profile = response['profiles'] as Map<String, dynamic>?;

      // جلب آخر رسالة
      final lastMessage = await _getLastMessage(conversationId);

      // جلب عدد الرسائل غير المقروءة
      final unreadCount = await _getUnreadCount(conversationId);
      final userId = response['user_id'];
      String? userName;
      try {
        // استخدام الاستعلام المباشر لجدول profiles
        final profileResponse = await _supabaseService.client!
            .from('profiles')
            .select('name')
            .eq('id', userId)
            .maybeSingle();
        if (profileResponse != null && profileResponse['name'] != null) {
          userName = profileResponse['name'];
          print('✅ تم جلب اسم المستخدم للمحادثة: $userName');
        }
      } catch (e) {
        print('❌ خطأ في جلب اسم المستخدم: $e');
      }

      return SupportConversation(
        id: response['id'],
        userId: userId,
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        userEmail: null,
        userName: userName ?? profile?['name'],
        lastMessage: lastMessage?.message,
        lastMessageAt: lastMessage?.createdAt,
        unreadCount: unreadCount,
        hasUnreadMessages: unreadCount > 0, // تحديد وجود رسائل غير مقروءة
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

      // استخدام العميل العادي للوصول للبيانات
      final client = _supabaseService.client!;
      print('استخدام العميل العادي لجلب الرسائل');
      final response = await client
          .from('support_messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .order('id', ascending: true); // ترتيب إضافي حسب ID للاستقرار

      print('استجابة رسائل قاعدة البيانات: $response');
      print('عدد الرسائل: ${response.length}');

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
      // تجاهل الرسائل النظامية (إذا وجدت)
      if (item['message'] == 'read_marker') {
        print('🚫 تجاهل رسالة نظامية: ${item['id']}');
        continue;
      }

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
          isRead: item['is_read'] ?? false,
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
        'is_read': false, // جميع الرسائل غير مقروءة افتراضياً
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
        isRead: response['is_read'] ?? false,
      );

      print('تم إرسال الرسالة بنجاح');
      return supportMessage;
    } catch (e) {
      print('خطأ في إرسال الرسالة: $e');
      rethrow;
    }
  }

  // تحديث حالة المحادثة

  // تعيين رسائل المدير كمقروءة (للمستخدم - يقرأ رسائل المدير)
  Future<bool> markAdminMessagesAsRead(String conversationId) async {
    try {
      if (!_supabaseService.isReady) {
        return false;
      }

      print('📖 تعيين رسائل المدير كمقروءة للمحادثة: $conversationId');

      // تحديث رسائل المدير فقط (المستخدم يقرأ رسائل المدير)
      await _supabaseService.client!
          .from('support_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .eq('sender_type', 'admin')
          .eq('is_read', false);

      print('✅ تم تعيين رسائل المدير كمقروءة للمحادثة: $conversationId');
      return true;
    } catch (e) {
      print('❌ خطأ في تعيين رسائل المدير كمقروءة: $e');
      return false;
    }
  }

  // الحصول على آخر رسالة في المحادثة
  Future<SupportMessage?> _getLastMessage(String conversationId) async {
    try {
      // جلب آخر رسالة
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
        isRead: response['is_read'] ?? false,
      );
    } catch (e) {
      print('خطأ في جلب آخر رسالة: $e');
      return null;
    }
  }

  // حساب إجمالي الرسائل غير المقروءة من جميع المستخدمين
  Future<int> getTotalUnreadMessagesCount() async {
    try {
      print('🔍 حساب إجمالي الرسائل غير المقروءة من جميع المستخدمين');

      final client = _supabaseService.client!;

      // جلب جميع الرسائل غير المقروءة من المستخدمين
      final result = await client
          .from('support_messages')
          .select('id, message, created_at')
          .eq('sender_type', 'user')
          .eq('is_read', false);

      final count = result.length;
      print('📊 إجمالي الرسائل غير المقروءة: $count');

      // طباعة تفاصيل الرسائل غير المقروءة للتأكد
      for (final msg in result) {
        print(
          '📨 رسالة غير مقروءة: "${msg['message']}" - ${msg['created_at']}',
        );
      }

      return count;
    } catch (e) {
      print('خطأ في حساب إجمالي الرسائل غير المقروءة: $e');
      return 0;
    }
  }

  // حساب عدد المحادثات التي تحتوي على رسائل غير مقروءة
  Future<int> getUnreadConversationsCount() async {
    try {
      print('🔍 حساب عدد المحادثات غير المقروءة');

      final client = _supabaseService.client!;

      // جلب جميع المحادثات المفتوحة
      final conversations = await client
          .from('support_conversations')
          .select('id');

      int unreadConversations = 0;

      // فحص كل محادثة لوجود رسائل غير مقروءة
      for (final conv in conversations) {
        final unreadCount = await _getUnreadCount(conv['id']);
        if (unreadCount > 0) {
          unreadConversations++;
        }
      }

      print('📊 عدد المحادثات غير المقروءة: $unreadConversations');
      return unreadConversations;
    } catch (e) {
      print('خطأ في حساب المحادثات غير المقروءة: $e');
      return 0;
    }
  }

  // الاشتراك في تحديثات الرسائل غير المقروءة
  Future<StreamSubscription> subscribeToUnreadCount(
    void Function(int totalUnread, int unreadConversations) onCountUpdate,
  ) async {
    print('🚀 بدء الاشتراك في تحديثات الرسائل غير المقروءة');

    // جلب العدد الأولي
    final totalUnread = await getTotalUnreadMessagesCount();
    final unreadConversations = await getUnreadConversationsCount();
    print(
      '📊 العدد الأولي - الرسائل: $totalUnread، المحادثات: $unreadConversations',
    );
    onCountUpdate(totalUnread, unreadConversations);

    // بدء التحديث الدوري كل 2 ثانية للتأكد من دقة البيانات
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      print('⏰ تحديث دوري للرسائل غير المقروءة');
      final totalUnread = await getTotalUnreadMessagesCount();
      final unreadConversations = await getUnreadConversationsCount();
      onCountUpdate(totalUnread, unreadConversations);
    });

    // الاشتراك في تحديثات الرسائل من المستخدمين
    final sub = _supabaseService.client!
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .listen((data) async {
          print('📨 تحديث في الرسائل: ${data.length} رسالة');

          // فحص إذا كانت هناك رسائل جديدة من المستخدمين
          bool hasNewUserMessages = false;
          for (final message in data) {
            if (message['sender_type'] == 'user' &&
                message['is_read'] == false) {
              hasNewUserMessages = true;
              print('📨 رسالة جديدة من مستخدم: ${message['message']}');
              break;
            }
          }

          if (hasNewUserMessages) {
            print('🔄 تحديث فوري بسبب رسالة جديدة');
            final totalUnread = await getTotalUnreadMessagesCount();
            final unreadConversations = await getUnreadConversationsCount();
            onCountUpdate(totalUnread, unreadConversations);
          }
        });

    return sub;
  }

  // إعادة تحميل البيانات يدوياً
  Future<void> refreshUnreadCount(
    void Function(int totalUnread, int unreadConversations) onCountUpdate,
  ) async {
    print('🔄 إعادة تحميل البيانات يدوياً');
    final totalUnread = await getTotalUnreadMessagesCount();
    final unreadConversations = await getUnreadConversationsCount();
    onCountUpdate(totalUnread, unreadConversations);
  }

  // الحصول على المحادثات غير المقروءة
  Future<List<SupportConversation>> getUnreadConversations() async {
    try {
      print('🔍 جلب المحادثات غير المقروءة');

      final client = _supabaseService.client!;

      print('🔍 العميل المستخدم: عادي');

      // جلب جميع المحادثات
      print('🔍 جلب جميع المحادثات من قاعدة البيانات...');
      final conversations = await client
          .from('support_conversations')
          .select('''
            id,
            user_id,
            user_name,
            user_email,
            created_at,
            updated_at
          ''')
          .order('updated_at', ascending: false);

      print('📊 تم جلب ${conversations.length} محادثة من قاعدة البيانات');

      List<SupportConversation> unreadConversations = [];

      // فحص كل محادثة لوجود رسائل غير مقروءة
      print(
        '🔍 فحص ${conversations.length} محادثة للبحث عن الرسائل غير المقروءة...',
      );
      for (final conv in conversations) {
        final unreadCount = await _getUnreadCount(conv['id']);

        if (unreadCount > 0) {
          // جلب آخر رسالة
          final lastMessage = await _getLastMessage(conv['id']);

          unreadConversations.add(
            SupportConversation(
              id: conv['id'],
              userId: conv['user_id'],
              userName: conv['user_name'],
              userEmail: conv['user_email'],
              createdAt: DateTime.parse(conv['created_at']),
              updatedAt: DateTime.parse(conv['updated_at']),
              lastMessage: lastMessage?.message,
              unreadCount: unreadCount,
              hasUnreadMessages: true,
            ),
          );
        }
      }

      print('📊 عدد المحادثات غير المقروءة: ${unreadConversations.length}');

      return unreadConversations;
    } catch (e) {
      print('خطأ في جلب المحادثات غير المقروءة: $e');
      return [];
    }
  }

  // تحديث حالة الرسائل كمقروءة عند فتح المحادثة
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      print('📖 تحديث الرسائل كمقروءة للمحادثة: $conversationId');

      final client = _supabaseService.client!;

      await client
          .from('support_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .eq('sender_type', 'user')
          .eq('is_read', false);

      print('✅ تم تحديث الرسائل كمقروءة بنجاح');
    } catch (e) {
      print('خطأ في تحديث حالة الرسائل: $e');
    }
  }

  // الحصول على عدد الرسائل غير المقروءة
  Future<int> _getUnreadCount(String conversationId) async {
    try {
      print(
        '🔍 ===== بدء حساب الرسائل غير المقروءة للمحادثة: $conversationId =====',
      );

      // استخدام العميل العادي للوصول للبيانات
      final client = _supabaseService.client!;

      print('🔍 العميل المستخدم: عادي');

      // استخدام الاستعلام المباشر مباشرة (أكثر موثوقية)
      print('🔍 استخدام الاستعلام المباشر لحساب الرسائل غير المقروءة...');

      // جلب جميع الرسائل في المحادثة أولاً للتحقق
      print('🔍 جلب جميع الرسائل للمحادثة: $conversationId');
      final allMessages = await client
          .from('support_messages')
          .select('id, sender_type, is_read, message, created_at')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false);

      print('🔍 جميع الرسائل في المحادثة: ${allMessages.length}');
      print(
        '🔍 تفاصيل الاستعلام: SELECT id, sender_type, is_read, message, created_at FROM support_messages WHERE conversation_id = $conversationId',
      );

      // طباعة تفاصيل جميع الرسائل للتشخيص
      for (var msg in allMessages) {
        print(
          '🔍 رسالة: ID=${msg['id']}, sender_type=${msg['sender_type']}, is_read=${msg['is_read']}, message="${msg['message']}"',
        );
      }

      // حساب الرسائل غير المقروءة يدوياً من جميع الرسائل
      int unreadCount = 0;
      final unreadMessages = <Map<String, dynamic>>[];

      print('🔍 بدء حساب الرسائل غير المقروءة يدوياً (فقط من المستخدمين)...');
      for (var msg in allMessages) {
        final isRead = msg['is_read'];
        final senderType = msg['sender_type'];
        bool isUnread = false;

        print(
          '🔍 فحص رسالة: ID=${msg['id']}, sender_type=$senderType, is_read=$isRead (نوع: ${isRead.runtimeType})',
        );

        // التحقق من أن الرسالة من مستخدم وليس من مدير
        if (senderType != 'user') {
          print('🔍 الرسالة من المدير - لا تحتسب كغير مقروءة');
          continue;
        }

        // التحقق من القيم المختلفة لـ is_read
        if (isRead == null) {
          print('🔍 الرسالة غير مقروءة (is_read = null)');
          isUnread = true;
        } else if (isRead == false) {
          print('🔍 الرسالة غير مقروءة (is_read = false)');
          isUnread = true;
        } else if (isRead == 'false') {
          print('🔍 الرسالة غير مقروءة (is_read = "false")');
          isUnread = true;
        } else if (isRead == 0) {
          print('🔍 الرسالة غير مقروءة (is_read = 0)');
          isUnread = true;
        } else {
          print('🔍 الرسالة مقروءة (is_read = $isRead)');
        }

        if (isUnread) {
          unreadCount++;
          unreadMessages.add(msg);
          print(
            '🔍 تم إضافة رسالة غير مقروءة من مستخدم. العدد الحالي: $unreadCount',
          );
        }
      }

      print('📊 تم حساب ${unreadMessages.length} رسالة غير مقروءة يدوياً');

      // طباعة تفاصيل الرسائل غير المقروءة للتشخيص
      for (var msg in unreadMessages) {
        print(
          '📊 رسالة غير مقروءة: ID=${msg['id']}, sender_type=${msg['sender_type']}, is_read=${msg['is_read']}, message="${msg['message']}"',
        );
      }

      print('📊 عدد الرسائل غير المقروءة في المحادثة: $unreadCount');
      print(
        '🔍 ===== انتهاء حساب الرسائل غير المقروءة للمحادثة: $conversationId =====',
      );

      return unreadCount;
    } catch (e) {
      print('❌ خطأ في حساب الرسائل غير المقروءة: $e');
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
              print('🔄 تحديث قائمة المحادثات بسبب تغيير في جدول المحادثات...');
              final conversations = await getConversations();
              print('🔄 تم جلب ${conversations.length} محادثة بعد التحديث');
              onUpdate(conversations);
            },
          )
          .subscribe();

      // إضافة استماع لتحديثات الرسائل أيضاً
      _supabaseService.client!
          .channel('support_messages_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'support_messages',
            callback: (payload) async {
              print('رسالة جديدة في جدول support_messages: $payload');
              print('🔄 تحديث قائمة المحادثات بسبب رسالة جديدة...');
              // تحديث قائمة المحادثات عند إضافة رسالة جديدة
              final conversations = await getConversations();
              print(
                '🔄 تم جلب ${conversations.length} محادثة بعد الرسالة الجديدة',
              );
              onUpdate(conversations);
            },
          )
          .subscribe();

      print('بدأ الاستماع لتحديثات المحادثات والرسائل');
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
      final allConversations = await _supabaseService.client!
          .from('support_conversations')
          .select('id');

      // جلب عدد الرسائل الإجمالي
      final totalMessages = await _supabaseService.client!
          .from('support_messages')
          .select('id');

      return {
        'total_conversations': totalConversations.length,
        'open_conversations': allConversations.length,
        'closed_conversations': 0, // لا يوجد حالياً تمييز بين المفتوحة والمغلقة
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

  // اختبار خاص للرسائل غير المقروءة
  Future<void> testUnreadMessages() async {
    try {
      print('🧪 اختبار الرسائل غير المقروءة...');

      final client = _supabaseService.client!;

      // جلب جميع الرسائل غير المقروءة مباشرة
      final unreadMessages = await client
          .from('support_messages')
          .select('id, conversation_id, sender_type, is_read, message')
          .eq('sender_type', 'user')
          .eq('is_read', false);

      print('📊 عدد الرسائل غير المقروءة مباشرة: ${unreadMessages.length}');

      // جلب المحادثات التي تحتوي على رسائل غير مقروءة
      if (unreadMessages.isNotEmpty) {
        final conversationIds = unreadMessages
            .map((m) => m['conversation_id'])
            .toSet()
            .toList();
        final conversationsWithUnread = await client
            .from('support_conversations')
            .select('id, user_name')
            .inFilter('id', conversationIds);

        print(
          '📊 عدد المحادثات التي تحتوي على رسائل غير مقروءة: ${conversationsWithUnread.length}',
        );
      }
    } catch (e) {
      print('❌ خطأ في اختبار الرسائل غير المقروءة: $e');
    }
  }
}
