import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support_chat_service.dart';
import 'supabase_service.dart';

class NotificationService extends ChangeNotifier {
  final SupportChatService _chatService = SupportChatService();
  final SupabaseService _supabaseService = SupabaseService();

  // إحصائيات الإشعارات
  int _totalUnreadMessages = 0;
  int _unreadConversations = 0;
  bool _hasNewMessages = false;

  // إحصائيات منفصلة لكل قسم
  int _supportUnreadMessages = 0;
  int _wholesaleUnreadMessages = 0;
  int _ordersUnreadMessages = 0;

  // Timer للتحديث الدوري
  Timer? _updateTimer;

  // Realtime channel للاستماع المباشر
  RealtimeChannel? _realtimeChannel;

  // Getters
  int get totalUnreadMessages => _totalUnreadMessages;
  int get unreadConversations => _unreadConversations;
  bool get hasNewMessages => _hasNewMessages;

  // Getters للعدادات المنفصلة
  int get supportUnreadMessages => _supportUnreadMessages;
  int get wholesaleUnreadMessages => _wholesaleUnreadMessages;
  int get ordersUnreadMessages => _ordersUnreadMessages;

  NotificationService() {
    _startPeriodicUpdate();
    _startRealtimeListening();
    // تحديث فوري عند إنشاء الخدمة
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

  // بدء التحديث الدوري كل 10 ثوانٍ (أسرع للاستجابة)
  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateNotifications();
    });

    // تحديث فوري عند بدء الخدمة
    _updateNotifications();
  }

  // بدء الاستماع المباشر لتحديثات قاعدة البيانات
  void _startRealtimeListening() {
    try {
      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز للاستماع المباشر');
        return;
      }

      debugPrint('🔊 بدء الاستماع المباشر لتحديثات الرسائل...');

      _realtimeChannel = _supabaseService.client!
          .channel('notification_realtime_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'support_messages',
            callback: (payload) async {
              debugPrint(
                '🔔 رسالة جديدة في قاعدة البيانات: ${payload.newRecord}',
              );

              // التحقق من أن الرسالة من مستخدم (وليس من مدير)
              final senderType = payload.newRecord['sender_type'];
              if (senderType == 'user') {
                debugPrint('🔔 رسالة جديدة من مستخدم - تحديث الإشعارات فوراً');
                // تحديث فوري للإشعارات
                await _updateNotifications();
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'support_messages',
            callback: (payload) async {
              debugPrint(
                '📝 تحديث رسالة في قاعدة البيانات: ${payload.newRecord}',
              );

              // إذا تم تحديث حالة is_read
              final oldIsRead = payload.oldRecord['is_read'];
              final newIsRead = payload.newRecord['is_read'];

              if (oldIsRead != newIsRead) {
                debugPrint('📝 تغيير في حالة قراءة الرسالة - تحديث الإشعارات');
                await _updateNotifications();
              }
            },
          )
          .subscribe();

      debugPrint('✅ تم بدء الاستماع المباشر للإشعارات');
    } catch (e) {
      debugPrint('❌ خطأ في بدء الاستماع المباشر: $e');
    }
  }

  // تحديث الإشعارات
  Future<void> _updateNotifications() async {
    try {
      debugPrint('🔄 تحديث الإشعارات...');

      // حساب الرسائل غير المقروءة من جميع المصادر
      int supportUnread = 0;
      int wholesaleUnread = 0;
      int ordersUnread = 0;
      int totalUnread = 0;
      int unreadConvCount = 0;

      // 1. رسائل فريق الدعم
      try {
        final supportData = await _calculateSupportUnread();
        supportUnread = supportData['totalUnread']!;
        unreadConvCount += supportData['unreadConversations']!;
        debugPrint('📞 رسائل فريق الدعم غير المقروءة: $supportUnread');
      } catch (e) {
        debugPrint('❌ خطأ في حساب رسائل فريق الدعم: $e');
      }

      // 2. رسائل طلبات الجملة
      try {
        final wholesaleData = await _calculateWholesaleUnread();
        wholesaleUnread = wholesaleData['totalUnread']!;
        unreadConvCount += wholesaleData['unreadConversations']!;
        debugPrint('🏢 رسائل طلبات الجملة غير المقروءة: $wholesaleUnread');
      } catch (e) {
        debugPrint('❌ خطأ في حساب رسائل طلبات الجملة: $e');
      }

      // 3. رسائل الطلبات العادية
      try {
        final ordersData = await _calculateOrdersUnread();
        ordersUnread = ordersData['totalUnread']!;
        unreadConvCount += ordersData['unreadConversations']!;
        debugPrint('📦 رسائل الطلبات العادية غير المقروءة: $ordersUnread');
        debugPrint(
          '📦 محادثات الطلبات العادية غير المقروءة: ${ordersData['unreadConversations']}',
        );
      } catch (e) {
        debugPrint('❌ خطأ في حساب رسائل الطلبات العادية: $e');
      }

      // حساب الإجمالي
      totalUnread = supportUnread + wholesaleUnread + ordersUnread;
      final hasNew = totalUnread > 0;

      debugPrint('📊 إجمالي الرسائل غير المقروءة: $totalUnread');
      debugPrint(
        '📊 تفصيل: دعم=$supportUnread, جملة=$wholesaleUnread, طلبات=$ordersUnread',
      );
      debugPrint('📊 عدد المحادثات غير المقروءة: $unreadConvCount');
      debugPrint('📊 هل توجد رسائل جديدة: $hasNew');

      // تحديث القيم فقط إذا تغيرت
      if (_totalUnreadMessages != totalUnread ||
          _unreadConversations != unreadConvCount ||
          _hasNewMessages != hasNew ||
          _supportUnreadMessages != supportUnread ||
          _wholesaleUnreadMessages != wholesaleUnread ||
          _ordersUnreadMessages != ordersUnread) {
        debugPrint('🔄 تحديث قيم الإشعارات...');

        // إذا كان هناك رسائل جديدة (زيادة في العدد)
        final isNewMessage = totalUnread > _totalUnreadMessages;

        _totalUnreadMessages = totalUnread;
        _unreadConversations = unreadConvCount;
        _hasNewMessages = hasNew;

        // تحديث العدادات المنفصلة
        _supportUnreadMessages = supportUnread;
        _wholesaleUnreadMessages = wholesaleUnread;
        _ordersUnreadMessages = ordersUnread;

        debugPrint('🔢 القيم النهائية المحفوظة:');
        debugPrint('   - supportUnreadMessages: $_supportUnreadMessages');
        debugPrint('   - wholesaleUnreadMessages: $_wholesaleUnreadMessages');
        debugPrint('   - ordersUnreadMessages: $_ordersUnreadMessages');
        debugPrint('   - totalUnreadMessages: $_totalUnreadMessages');

        notifyListeners();
        debugPrint('✅ تم تحديث الإشعارات وإشعار المستمعين');

        // إشعار بصري إضافي للرسائل الجديدة
        if (isNewMessage && totalUnread > 0) {
          debugPrint(
            '🔔🔔🔔 رسالة جديدة! إجمالي الرسائل غير المقروءة: $totalUnread',
          );
        }
      } else {
        debugPrint('ℹ️ لا توجد تغييرات في الإشعارات');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الإشعارات: $e');
    }
  }

  // حساب رسائل فريق الدعم غير المقروءة
  Future<Map<String, int>> _calculateSupportUnread() async {
    try {
      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز');
        return {'totalUnread': 0, 'unreadConversations': 0};
      }

      final client = _supabaseService.client!;

      debugPrint('🔍 حساب الرسائل غير المقروءة مباشرة من قاعدة البيانات...');
      debugPrint('🔍 العميل المستخدم: عادي');

      // جلب جميع الرسائل أولاً للتحقق
      final allMessages = await client
          .from('support_messages')
          .select('id, conversation_id, sender_type, is_read, message')
          .order('created_at', ascending: false);

      debugPrint('🔍 إجمالي الرسائل في قاعدة البيانات: ${allMessages.length}');

      // طباعة تفاصيل جميع الرسائل
      for (var msg in allMessages.take(10)) {
        debugPrint(
          '🔍 رسالة: "${msg['message']}" - sender: ${msg['sender_type']} - is_read: ${msg['is_read']} (نوع: ${msg['is_read'].runtimeType})',
        );
      }

      // جلب جميع رسائل المستخدمين أولاً
      final userMessages = await client
          .from('support_messages')
          .select(
            'id, conversation_id, sender_type, is_read, message, created_at',
          )
          .eq('sender_type', 'user') // فقط رسائل المستخدمين
          .order('created_at', ascending: false);

      debugPrint('🔍 جميع رسائل المستخدمين: ${userMessages.length}');

      // طباعة تفاصيل جميع رسائل المستخدمين
      for (var msg in userMessages.take(10)) {
        debugPrint(
          '🔍 رسالة مستخدم: "${msg['message']}" - is_read: ${msg['is_read']} (نوع: ${msg['is_read'].runtimeType})',
        );
      }

      // حساب الرسائل غير المقروءة يدوياً (is_read = false أو is_read = null)
      int totalUnread = 0;
      final unreadMessages = <Map<String, dynamic>>[];
      final unreadConversationIds = <String>{};

      for (var msg in userMessages) {
        final isRead = msg['is_read'];
        bool isUnread = false;

        // التحقق من القيم المختلفة لـ is_read
        if (isRead == null) {
          isUnread = true;
          debugPrint('🔍 رسالة مع is_read = null: "${msg['message']}"');
        } else if (isRead == false) {
          isUnread = true;
          debugPrint('🔍 رسالة مع is_read = false: "${msg['message']}"');
        } else if (isRead == 'false') {
          isUnread = true;
          debugPrint('🔍 رسالة مع is_read = "false": "${msg['message']}"');
        } else if (isRead == 0) {
          isUnread = true;
          debugPrint('🔍 رسالة مع is_read = 0: "${msg['message']}"');
        }

        if (isUnread) {
          totalUnread++;
          unreadMessages.add(msg);
          unreadConversationIds.add(msg['conversation_id']);
        }
      }

      final uniqueConversations = unreadConversationIds.length;

      debugPrint(
        '🔍 إجمالي الرسائل غير المقروءة (محسوبة يدوياً): $totalUnread',
      );

      debugPrint(
        '🔍 عدد المحادثات المختلفة غير المقروءة: $uniqueConversations',
      );

      // عرض تفاصيل الرسائل غير المقروءة
      for (var msg in unreadMessages.take(5)) {
        debugPrint(
          '🔍 رسالة غير مقروءة: ID=${msg['id']}, المحادثة=${msg['conversation_id']}, المرسل=${msg['sender_type']}, is_read=${msg['is_read']}, الرسالة="${msg['message']}"',
        );
      }

      return {
        'totalUnread': totalUnread,
        'unreadConversations': uniqueConversations,
      };
    } catch (e) {
      debugPrint('❌ خطأ في حساب رسائل فريق الدعم: $e');
      return {'totalUnread': 0, 'unreadConversations': 0};
    }
  }

  // حساب رسائل طلبات الجملة غير المقروءة
  Future<Map<String, int>> _calculateWholesaleUnread() async {
    try {
      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز لحساب رسائل طلبات الجملة');
        return {'totalUnread': 0, 'unreadConversations': 0};
      }

      final client = _supabaseService.client!;
      debugPrint('🔍 حساب رسائل طلبات الجملة غير المقروءة...');

      // جلب جميع رسائل المستخدمين من جدول wholesale_messages
      final userMessages = await client
          .from('wholesale_messages')
          .select(
            'id, conversation_id, sender_type, is_read, message, created_at',
          )
          .eq('sender_type', 'user') // فقط رسائل المستخدمين
          .order('created_at', ascending: false);

      debugPrint(
        '🔍 جميع رسائل طلبات الجملة من المستخدمين: ${userMessages.length}',
      );

      // حساب الرسائل غير المقروءة
      int totalUnread = 0;
      final unreadConversationIds = <String>{};

      for (var msg in userMessages) {
        final isRead = msg['is_read'];
        bool isUnread = false;

        // التحقق من القيم المختلفة لـ is_read
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

      debugPrint('🔍 رسائل طلبات الجملة غير المقروءة: $totalUnread');
      debugPrint(
        '🔍 عدد محادثات طلبات الجملة غير المقروءة: $uniqueConversations',
      );

      return {
        'totalUnread': totalUnread,
        'unreadConversations': uniqueConversations,
      };
    } catch (e) {
      debugPrint('❌ خطأ في حساب رسائل طلبات الجملة: $e');
      return {'totalUnread': 0, 'unreadConversations': 0};
    }
  }

  // حساب رسائل الطلبات العادية غير المقروءة
  Future<Map<String, int>> _calculateOrdersUnread() async {
    try {
      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز لحساب رسائل الطلبات العادية');
        return {'totalUnread': 0, 'unreadConversations': 0};
      }

      final client = _supabaseService.client!;
      debugPrint('🔍 حساب رسائل الطلبات العادية غير المقروءة...');

      // جلب جميع رسائل المستخدمين من جدول order_messages
      final userMessages = await client
          .from('order_messages')
          .select(
            'id, conversation_id, sender_type, is_read, message, created_at',
          )
          .eq('sender_type', 'user') // فقط رسائل المستخدمين
          .order('created_at', ascending: false);

      debugPrint(
        '🔍 جميع رسائل الطلبات العادية من المستخدمين: ${userMessages.length}',
      );

      // طباعة تفاصيل الرسائل للتشخيص
      for (var msg in userMessages.take(5)) {
        debugPrint(
          '🔍 رسالة طلب: ID=${msg['id']}, conversation_id=${msg['conversation_id']}, sender=${msg['sender_type']}, is_read=${msg['is_read']} (نوع: ${msg['is_read'].runtimeType}), message="${msg['message']}"',
        );
      }

      // حساب الرسائل غير المقروءة
      int totalUnread = 0;
      final unreadOrderIds = <String>{};

      for (var msg in userMessages) {
        final isRead = msg['is_read'];
        bool isUnread = false;

        // التحقق من القيم المختلفة لـ is_read
        if (isRead == null ||
            isRead == false ||
            isRead == 'false' ||
            isRead == 0) {
          isUnread = true;
          debugPrint(
            '🔍 رسالة طلب غير مقروءة: ID=${msg['id']}, is_read=$isRead',
          );
        }

        if (isUnread) {
          totalUnread++;
          unreadOrderIds.add(msg['conversation_id']);
        }
      }

      final uniqueOrders = unreadOrderIds.length;

      debugPrint('🔍 رسائل الطلبات العادية غير المقروءة: $totalUnread');
      debugPrint('🔍 عدد طلبات عادية غير مقروءة: $uniqueOrders');

      return {'totalUnread': totalUnread, 'unreadConversations': uniqueOrders};
    } catch (e) {
      debugPrint('❌ خطأ في حساب رسائل الطلبات العادية: $e');
      debugPrint('❌ تفاصيل الخطأ: ${e.toString()}');
      return {'totalUnread': 0, 'unreadConversations': 0};
    }
  }

  // تحديث فوري للإشعارات
  Future<void> refreshNotifications() async {
    await _updateNotifications();
  }

  // اختبار النظام - جلب عدد الرسائل غير المقروءة مباشرة من قاعدة البيانات
  Future<void> testUnreadMessages() async {
    try {
      debugPrint('🧪 اختبار نظام الرسائل غير المقروءة...');

      // اختبار الاتصال أولاً
      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز');
        return;
      }

      final client = _supabaseService.client!;

      debugPrint('🔍 العميل المستخدم: عادي');

      // اختبار 1: جلب جميع الرسائل
      debugPrint('🧪 اختبار 1: جلب جميع الرسائل...');
      final allMessages = await client
          .from('support_messages')
          .select(
            'id, conversation_id, sender_type, is_read, message, created_at',
          )
          .order('created_at', ascending: false);

      debugPrint('🧪 إجمالي الرسائل في قاعدة البيانات: ${allMessages.length}');

      // اختبار 2: جلب رسائل المستخدمين فقط
      debugPrint('🧪 اختبار 2: جلب رسائل المستخدمين...');
      final userMessages = await client
          .from('support_messages')
          .select(
            'id, conversation_id, sender_type, is_read, message, created_at',
          )
          .eq('sender_type', 'user')
          .order('created_at', ascending: false);

      debugPrint('🧪 عدد رسائل المستخدمين: ${userMessages.length}');

      // اختبار 3: جلب الرسائل غير المقروءة من المستخدمين فقط
      debugPrint('🧪 اختبار 3: جلب الرسائل غير المقروءة من المستخدمين...');
      final response = await client
          .from('support_messages')
          .select(
            'id, conversation_id, sender_type, is_read, message, created_at',
          )
          .eq('sender_type', 'user') // فقط رسائل المستخدمين
          .eq('is_read', false)
          .order('created_at', ascending: false);

      debugPrint(
        '🧪 عدد الرسائل غير المقروءة من المستخدمين: ${response.length}',
      );

      // اختبار إضافي: جلب الرسائل غير المقروءة باستخدام دالة قاعدة البيانات
      try {
        final functionResult = await client.rpc('get_unread_messages_count');
        debugPrint(
          '🧪 عدد الرسائل غير المقروءة (دالة قاعدة البيانات): $functionResult',
        );
      } catch (e) {
        debugPrint('🧪 خطأ في استدعاء دالة قاعدة البيانات: $e');
      }

      // اختبار إضافي: جلب الرسائل غير المقروءة مباشرة من قاعدة البيانات
      try {
        final directUnread = await client
            .from('support_messages')
            .select('id')
            .eq('is_read', false);
        debugPrint(
          '🧪 عدد الرسائل غير المقروءة (استعلام مباشر): ${directUnread.length}',
        );
      } catch (e) {
        debugPrint('🧪 خطأ في الاستعلام المباشر: $e');
      }

      // عرض تفاصيل الرسائل غير المقروءة
      for (var msg in response) {
        debugPrint(
          '🧪 رسالة غير مقروءة: "${msg['message']}" - المحادثة: ${msg['conversation_id']} - الوقت: ${msg['created_at']} - is_read: ${msg['is_read']}',
        );
      }

      // اختبار 4: جلب الرسائل المقروءة للمقارنة
      debugPrint('🧪 اختبار 4: جلب الرسائل المقروءة...');
      final readMessages = await client
          .from('support_messages')
          .select(
            'id, conversation_id, sender_type, is_read, message, created_at',
          )
          .eq('is_read', true)
          .order('created_at', ascending: false);

      debugPrint(
        '🧪 عدد الرسائل المقروءة (جميع الرسائل): ${readMessages.length}',
      );

      // اختبار 5: جلب الرسائل مع is_read = null
      debugPrint('🧪 اختبار 5: جلب الرسائل مع is_read = null...');
      final nullReadMessages = await client
          .from('support_messages')
          .select(
            'id, conversation_id, sender_type, is_read, message, created_at',
          )
          .eq('sender_type', 'user')
          .isFilter('is_read', null)
          .order('created_at', ascending: false);

      debugPrint(
        '🧪 عدد الرسائل مع is_read = null: ${nullReadMessages.length}',
      );

      // اختبار 6: فحص نوع البيانات في is_read
      debugPrint('🧪 اختبار 6: فحص نوع البيانات في is_read...');
      if (userMessages.isNotEmpty) {
        for (var msg in userMessages.take(3)) {
          final isReadValue = msg['is_read'];
          debugPrint(
            '🧪 رسالة "${msg['message']}" - is_read: $isReadValue (نوع: ${isReadValue.runtimeType})',
          );
        }
      }

      // اختبار 7: جلب الرسائل مع is_read = 'false' (كـ string)
      debugPrint('🧪 اختبار 7: جلب الرسائل مع is_read = "false"...');
      try {
        final stringFalseMessages = await client
            .from('support_messages')
            .select(
              'id, conversation_id, sender_type, is_read, message, created_at',
            )
            .eq('sender_type', 'user')
            .eq('is_read', 'false')
            .order('created_at', ascending: false);

        debugPrint(
          '🧪 عدد الرسائل مع is_read = "false": ${stringFalseMessages.length}',
        );
      } catch (e) {
        debugPrint('🧪 خطأ في اختبار is_read = "false": $e');
      }

      // تحديث الإشعارات بعد الاختبار
      await _updateNotifications();
    } catch (e) {
      debugPrint('❌ خطأ في اختبار الرسائل غير المقروءة: $e');
      debugPrint('❌ تفاصيل الخطأ: ${e.toString()}');
    }
  }

  // اختبار الصلاحيات
  Future<void> testPermissions() async {
    try {
      debugPrint('🔐 اختبار الصلاحيات...');

      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز');
        return;
      }

      final client = _supabaseService.client!;

      // اختبار 1: التحقق من وجود المستخدم الحالي
      final currentUser = _supabaseService.currentUser;
      debugPrint('🔐 المستخدم الحالي: ${currentUser?.id}');
      debugPrint('🔐 البريد الإلكتروني: ${currentUser?.email}');

      // اختبار 2: التحقق من وجود المدير في جدول admin_users
      try {
        final adminCheck = await client
            .from('admin_users')
            .select('*')
            .eq('user_id', currentUser?.id ?? '')
            .eq('is_active', true)
            .maybeSingle();

        if (adminCheck != null) {
          debugPrint('✅ المدير موجود في جدول admin_users');
          debugPrint('🔐 تفاصيل المدير: $adminCheck');
        } else {
          debugPrint('❌ المدير غير موجود في جدول admin_users');

          // محاولة إضافة المدير
          try {
            await client.from('admin_users').insert({
              'user_id': currentUser?.id,
              'email': currentUser?.email,
              'full_name': 'مدير النظام',
              'role': 'super_admin',
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
            debugPrint('✅ تم إضافة المدير إلى جدول admin_users');
          } catch (insertError) {
            debugPrint('❌ خطأ في إضافة المدير: $insertError');
          }
        }
      } catch (e) {
        debugPrint('❌ خطأ في التحقق من المدير: $e');
      }

      // اختبار 3: اختبار القراءة من جدول support_messages
      try {
        final testRead = await client
            .from('support_messages')
            .select('id, sender_type, is_read, message')
            .limit(1);
        debugPrint('✅ يمكن القراءة من جدول support_messages');
        debugPrint('🔐 عدد النتائج: ${testRead.length}');
      } catch (e) {
        debugPrint('❌ خطأ في القراءة من support_messages: $e');
      }

      // اختبار 4: اختبار التحديث في جدول support_messages
      try {
        await client
            .from('support_messages')
            .update({'is_read': false})
            .eq('id', 'non-existent-id');
        debugPrint('✅ يمكن التحديث في جدول support_messages');
      } catch (e) {
        debugPrint('❌ خطأ في التحديث في support_messages: $e');
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختبار الصلاحيات: $e');
    }
  }

  // اختبار الاتصال بقاعدة البيانات
  Future<void> testDatabaseConnection() async {
    try {
      debugPrint('🔌 اختبار الاتصال بقاعدة البيانات...');

      if (!_supabaseService.isReady) {
        debugPrint('❌ Supabase غير جاهز');
        return;
      }

      final client = _supabaseService.client!;

      // اختبار الاتصال البسيط
      final testResponse = await client
          .from('support_messages')
          .select('count')
          .limit(1);

      debugPrint('✅ الاتصال بقاعدة البيانات نجح');
      debugPrint('🔍 عدد الرسائل في الجدول: ${testResponse.length}');

      // اختبار جلب عينة من البيانات
      final sampleResponse = await client
          .from('support_messages')
          .select('id, sender_type, is_read, message')
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

  // تعيين الرسائل كمقروءة (للمحادثة المحددة)
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      debugPrint('📖 تعيين الرسائل كمقروءة للمحادثة: $conversationId');
      await _chatService.markMessagesAsRead(conversationId);
      // تحديث الإشعارات بعد تعيين الرسائل كمقروءة
      await _updateNotifications();
    } catch (e) {
      debugPrint('خطأ في تعيين الرسائل كمقروءة: $e');
    }
  }

  // تعيين جميع الرسائل كمقروءة
  Future<void> markAllAsRead() async {
    try {
      final conversations = await _chatService.getConversations();

      for (final conversation in conversations) {
        if (conversation.unreadCount > 0) {
          await _chatService.markMessagesAsRead(conversation.id);
        }
      }

      // تحديث الإشعارات
      await _updateNotifications();
    } catch (e) {
      debugPrint('خطأ في تعيين جميع الرسائل كمقروءة: $e');
    }
  }

  // الحصول على نص الإشعار
  String getNotificationText() {
    if (_totalUnreadMessages == 0) {
      return '';
    } else if (_totalUnreadMessages == 1) {
      return 'رسالة جديدة';
    } else if (_totalUnreadMessages <= 10) {
      return '$_totalUnreadMessages رسائل جديدة';
    } else {
      return '$_totalUnreadMessages+ رسالة جديدة';
    }
  }

  // الحصول على نص المحادثات غير المقروءة
  String getUnreadConversationsText() {
    if (_unreadConversations == 0) {
      return '';
    } else if (_unreadConversations == 1) {
      return 'محادثة واحدة غير مقروءة';
    } else {
      return '$_unreadConversations محادثات غير مقروءة';
    }
  }
}
