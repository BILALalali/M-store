import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wholesale_request.dart';
import '../models/wholesale_message.dart';
import 'supabase_service.dart';
import 'dart:async';

class WholesaleService {
  static final WholesaleService _instance = WholesaleService._internal();
  factory WholesaleService() => _instance;
  WholesaleService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  final StreamController<List<WholesaleRequest>> _requestsController =
      StreamController<List<WholesaleRequest>>.broadcast();
  final StreamController<List<WholesaleMessage>> _messagesController =
      StreamController<List<WholesaleMessage>>.broadcast();

  Stream<List<WholesaleRequest>> get requestsStream =>
      _requestsController.stream;
  Stream<List<WholesaleMessage>> get messagesStream =>
      _messagesController.stream;

  RealtimeChannel? _requestsSubscription;
  RealtimeChannel? _messagesSubscription;

  void startRealtimeSubscriptions() {
    if (!_supabaseService.isReady) return;

    final client = _supabaseService.client!;

    _requestsSubscription = client
        .channel('wholesale_requests_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wholesale_requests',
          callback: (payload) {
            print('🔄 تغيير في طلبات الجملة: ${payload.eventType}');
            _handleRequestsChange(payload);
          },
        )
        .subscribe();

    _messagesSubscription = client
        .channel('wholesale_messages_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wholesale_messages',
          callback: (payload) {
            print('🔄 تغيير في رسائل الجملة: ${payload.eventType}');
            _handleMessagesChange(payload);
          },
        )
        .subscribe();

    print('✅ تم بدء الاستماع للتحديثات في الوقت الفعلي لطلبات ورسائل الجملة');
  }

  void stopRealtimeSubscriptions() {
    _requestsSubscription?.unsubscribe();
    _messagesSubscription?.unsubscribe();
    _requestsSubscription = null;
    _messagesSubscription = null;
    print('🛑 تم إيقاف الاستماع للتحديثات في الوقت الفعلي');
  }

  void _handleRequestsChange(PostgresChangePayload payload) async {
    print('📊 معالجة تغيير في طلبات الجملة...');

    try {
      final updatedRequests = await getWholesaleRequests();
      _requestsController.add(updatedRequests);

      print('✅ تم تحديث قائمة طلبات الجملة: ${updatedRequests.length} طلب');
    } catch (e) {
      print('❌ خطأ في معالجة تغيير طلبات الجملة: $e');
    }
  }

  void _handleMessagesChange(PostgresChangePayload payload) async {
    print('📊 معالجة تغيير في رسائل الجملة...');

    try {
      final updatedRequests = await getWholesaleRequests();
      _requestsController.add(updatedRequests);
      _messagesController.add([]);

      print(
        '✅ تم تحديث قائمة طلبات الجملة بسبب تغيير الرسائل: ${updatedRequests.length} طلب',
      );
    } catch (e) {
      print('❌ خطأ في معالجة تغيير رسائل الجملة: $e');
    }
  }

  void dispose() {
    stopRealtimeSubscriptions();
    _requestsController.close();
    _messagesController.close();
  }

  Future<List<WholesaleRequest>> getWholesaleRequests() async {
    try {
      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return [];
      }

      print('🔄 جلب طلبات الجملة من قاعدة البيانات...');
      final client = _supabaseService.client!;

      // جلب جميع طلبات الجملة
      final response = await client
          .from('wholesale_requests')
          .select('*')
          .order('created_at', ascending: false);

      print('✅ تم جلب ${response.length} طلب جملة من قاعدة البيانات');

      if (response.isEmpty) {
        print('⚠️ لا توجد طلبات جملة في قاعدة البيانات');
        return [];
      }

      final requests = <WholesaleRequest>[];

      for (var item in response) {
        // جلب اسم المستخدم
        String userName = 'عميل الجملة';
        try {
          final userId = item['user_id'];
          if (userId != null) {
            final profileResponse = await _supabaseService.client!
                .from('profiles')
                .select('name')
                .eq('id', userId)
                .maybeSingle();
            userName = profileResponse?['name'] ?? 'عميل الجملة';
          }
        } catch (e) {
          print('⚠️ خطأ في جلب اسم المستخدم: $e');
          userName = 'عميل الجملة';
        }

        // معالجة البيانات الحقيقية
        final String productName = (item['product_name'] ?? '')
            .toString()
            .trim();
        final String description = (item['description'] ?? '')
            .toString()
            .trim();
        final int quantity = (item['quantity'] is int)
            ? item['quantity']
            : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
        final String status = (item['status'] ?? 'pending').toString();

        // تحديد اسم المنتج للعرض
        final String displayProductName = productName.isNotEmpty
            ? productName
            : description.isNotEmpty
            ? (description.length > 50
                  ? '${description.substring(0, 50)}...'
                  : description)
            : 'طلب جملة ${item['id'].toString().substring(0, 8)}';

        // معالجة التواريخ
        DateTime createdAt = DateTime.now();
        DateTime updatedAt = DateTime.now();

        try {
          if (item['created_at'] != null) {
            createdAt = DateTime.parse(item['created_at'].toString());
          }
          if (item['updated_at'] != null) {
            updatedAt = DateTime.parse(item['updated_at'].toString());
          }
        } catch (e) {
          print('تحذير: خطأ في تحليل التاريخ: $e');
        }

        // حساب الرسائل غير المقروءة لهذا الطلب
        int unreadCount = 0;
        bool hasAdminMessage = false;
        DateTime? firstAdminMessageAt;
        try {
          unreadCount = await _getUnreadCount(item['id']?.toString() ?? '');

          // فحص ما إذا كان المشرف قد أرسل أي رسالة
          final adminMessages = await _getAdminWholesaleMessages(
            item['id']?.toString() ?? '',
          );
          hasAdminMessage = adminMessages.isNotEmpty;
          if (hasAdminMessage) {
            firstAdminMessageAt = adminMessages.first.createdAt;
          }
        } catch (e) {
          print(
            'تحذير: لا يمكن حساب الرسائل غير المقروءة لطلب ${item['id']}: $e',
          );
        }

        // إضافة الطلب للقائمة
        requests.add(
          WholesaleRequest(
            id: item['id']?.toString() ?? 'unknown',
            userId: item['user_id']?.toString() ?? 'unknown',
            productName: displayProductName,
            description: description.isNotEmpty ? description : 'لا يوجد وصف',
            quantity: quantity,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            userName: userName,
            userEmail: null,
            lastMessage: null,
            lastMessageAt: null,
            unreadCount: unreadCount,
            hasUnreadMessages: unreadCount > 0,
            hasAdminMessage: hasAdminMessage,
            firstAdminMessageAt: firstAdminMessageAt,
          ),
        );
      }

      print('🎉 تم جلب ${requests.length} طلب جملة من قاعدة البيانات');

      // إرسال البيانات للـ stream
      _requestsController.add(requests);

      return requests;
    } catch (e) {
      print('❌ خطأ في جلب طلبات الجملة: $e');
      return [];
    }
  }

  // الحصول على طلب جملة محدد
  Future<WholesaleRequest?> getWholesaleRequest(String requestId) async {
    try {
      if (!_supabaseService.isReady) {
        return null;
      }

      print('جلب طلب الجملة: $requestId');

      final response = await _supabaseService.client!
          .from('wholesale_requests')
          .select('*')
          .eq('id', requestId)
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
      WholesaleMessage? lastMessage;
      int unreadCount = 0;
      bool hasAdminMessage = false;
      DateTime? firstAdminMessageAt;
      try {
        lastMessage = await _getLastWholesaleMessage(requestId);
        unreadCount = await _getUnreadCount(requestId);

        // فحص ما إذا كان المشرف قد أرسل أي رسالة
        final adminMessages = await _getAdminWholesaleMessages(requestId);
        hasAdminMessage = adminMessages.isNotEmpty;
        if (hasAdminMessage) {
          firstAdminMessageAt = adminMessages.first.createdAt;
        }

        print(
          '📊 طلب الجملة $requestId: $unreadCount رسالة غير مقروءة, hasAdminMessage: $hasAdminMessage',
        );
      } catch (e) {
        print('تحذير: لا يمكن جلب رسائل طلب الجملة: $e');
      }

      return WholesaleRequest(
        id: response['id'],
        userId: userId,
        productName: response['product_name'] ?? 'منتج غير محدد',
        description: response['description'] ?? 'لا يوجد وصف',
        quantity: response['quantity'] ?? 1,
        status: response['status'] ?? 'pending',
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        userName: userName,
        lastMessage: lastMessage?.message,
        lastMessageAt: lastMessage?.createdAt,
        unreadCount: unreadCount,
        hasUnreadMessages: unreadCount > 0,
        hasAdminMessage: hasAdminMessage,
        firstAdminMessageAt: firstAdminMessageAt,
      );
    } catch (e) {
      print('خطأ في جلب طلب الجملة: $e');
      return null;
    }
  }

  // الحصول على رسائل طلب جملة محدد
  Future<List<WholesaleMessage>> getWholesaleMessages(String requestId) async {
    try {
      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return [];
      }

      print('🔍 ==== بدء جلب رسائل طلب الجملة ====');
      print('📋 معرف طلب الجملة: $requestId');
      print(
        '👤 المستخدم الحالي: ${_supabaseService.currentUser?.id ?? 'غير مسجل'}',
      );

      // التحقق من دور المستخدم الحالي
      await _checkAdminRole();

      // التأكد من وجود محادثة أولاً
      await ensureWholesaleConversationExists(requestId);

      // محاولة جلب رسائل من جدول wholesale_messages
      print(
        '🔍 البحث عن الرسائل بـ conversation_id = $requestId في wholesale_messages',
      );

      try {
        // جلب الرسائل مع معلومات إضافية
        final response = await _supabaseService.client!
            .from('wholesale_messages')
            .select('''
              id,
              conversation_id,
              sender_type,
              sender_id,
              type,
              message,
              media_url,
              is_read,
              created_at
            ''')
            .eq('conversation_id', requestId)
            .order('created_at', ascending: true);

        print('✅ استجابة wholesale_messages: ${response.length} رسالة');

        if (response.isEmpty) {
          print('⚠️ لم يتم العثور على رسائل في wholesale_messages');
          print('🔍 محاولة البحث في جميع الرسائل للتأكد...');

          // محاولة جلب جميع الرسائل للتشخيص
          try {
            final allMessages = await _supabaseService.client!
                .from('wholesale_messages')
                .select('conversation_id, sender_type, message, created_at')
                .limit(10);

            print('📊 عينة من رسائل wholesale_messages الموجودة:');
            for (var msg in allMessages) {
              print(
                '   - conversation_id: ${msg['conversation_id']}, sender: ${msg['sender_type']}, message: ${msg['message']}',
              );
            }
          } catch (diagnosticError) {
            print('❌ خطأ في التشخيص: $diagnosticError');
            print('💡 قد تكون المشكلة في صلاحيات RLS');
          }
        } else {
          print('📋 تفاصيل الرسائل المستلمة من wholesale_messages:');
          for (var msg in response) {
            print(
              '   - ID: ${msg['id']}, sender: ${msg['sender_type']}, message: ${msg['message']}',
            );
          }
        }

        final processedMessages = _processWholesaleMessages(response);
        print(
          '✅ تم معالجة ${processedMessages.length} رسالة بنجاح من wholesale_messages',
        );
        print('🔍 ==== انتهاء جلب رسائل طلب الجملة ====');

        return processedMessages;
      } catch (e) {
        print('❌ خطأ في الوصول لجدول wholesale_messages: $e');
        print('💡 المحاولة بحل بديل...');

        // محاولة حل بديل - جلب الرسائل بدون تصفية
        try {
          print('🔄 محاولة جلب جميع الرسائل...');
          final allMessages = await _supabaseService.client!
              .from('wholesale_messages')
              .select('*')
              .order('created_at', ascending: true);

          // تصفية الرسائل يدوياً
          final filteredMessages = allMessages
              .where((msg) => msg['conversation_id'] == requestId)
              .toList();

          print('✅ تم جلب ${filteredMessages.length} رسالة بالطريقة البديلة');
          return _processWholesaleMessages(filteredMessages);
        } catch (alternativeError) {
          print('❌ فشل الحل البديل أيضاً: $alternativeError');

          // محاولة أخيرة - استخدام service_role client
          try {
            print('🔄 محاولة استخدام service_role client...');
            final serviceClient = _supabaseService.serviceRoleClient;
            if (serviceClient != null) {
              final serviceResponse = await serviceClient
                  .from('wholesale_messages')
                  .select('*')
                  .eq('conversation_id', requestId)
                  .order('created_at', ascending: true);

              print(
                '✅ تم جلب ${serviceResponse.length} رسالة باستخدام service_role',
              );
              return _processWholesaleMessages(serviceResponse);
            }
          } catch (serviceError) {
            print('❌ فشل استخدام service_role أيضاً: $serviceError');
          }

          return [];
        }
      }
    } catch (e) {
      print('❌ خطأ عام في جلب رسائل طلب الجملة: $e');
      print('❌ نوع الخطأ: ${e.runtimeType}');
      print('❌ تفاصيل الخطأ: ${e.toString()}');
      return [];
    }
  }

  // إرسال رسالة لطلب الجملة
  Future<WholesaleMessage?> sendWholesaleMessage({
    required String requestId,
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

      print('📤 ==== بدء إرسال رسالة طلب جملة جديدة ====');
      print('📋 معرف طلب الجملة: $requestId');
      print('👤 المرسل: ${currentUser.id} (admin)');
      print('💬 الرسالة: $message');

      // التأكد من وجود محادثة لطلب الجملة
      await ensureWholesaleConversationExists(requestId);

      final messageData = {
        'conversation_id': requestId,
        'sender_type': 'admin',
        'sender_id': currentUser.id,
        'type': type,
        'message': message,
        'media_url': mediaUrl,
        'is_read': false,
      };

      print('📊 بيانات الرسالة: $messageData');

      // محاولة إدراج في جدول wholesale_messages
      try {
        final response = await _supabaseService.client!
            .from('wholesale_messages')
            .insert(messageData)
            .select()
            .single();

        print(
          '✅ تم إدراج الرسالة في جدول wholesale_messages: ${response['id']}',
        );

        await _updateWholesaleRequestTimestamp(requestId);

        final wholesaleMessage = WholesaleMessage.fromJson(response);
        print('✅ تم إنشاء كائن WholesaleMessage بنجاح');
        print('📤 ==== انتهاء إرسال رسالة طلب الجملة ====');

        return wholesaleMessage;
      } catch (e) {
        print('❌ خطأ في إدراج رسالة في wholesale_messages: $e');
        print('💡 المحاولة باستخدام service_role client...');

        // محاولة استخدام service_role client
        try {
          final serviceClient = _supabaseService.serviceRoleClient;
          if (serviceClient != null) {
            final serviceResponse = await serviceClient
                .from('wholesale_messages')
                .insert(messageData)
                .select()
                .single();

            print(
              '✅ تم إدراج الرسالة باستخدام service_role: ${serviceResponse['id']}',
            );

            await _updateWholesaleRequestTimestamp(requestId);

            final wholesaleMessage = WholesaleMessage.fromJson(serviceResponse);
            print('✅ تم إنشاء كائن WholesaleMessage باستخدام service_role');
            print('📤 ==== انتهاء إرسال رسالة طلب الجملة ====');

            return wholesaleMessage;
          } else {
            throw Exception('service_role client غير متاح');
          }
        } catch (serviceError) {
          print('❌ فشل استخدام service_role أيضاً: $serviceError');
          rethrow;
        }
      }
    } catch (e) {
      print('❌ خطأ في إرسال رسالة طلب الجملة: $e');
      print('❌ نوع الخطأ: ${e.runtimeType}');
      print('❌ تفاصيل الخطأ: ${e.toString()}');
      rethrow;
    }
  }

  // تحديث حالة طلب الجملة
  Future<bool> updateWholesaleRequestStatus(
    String requestId,
    String status,
  ) async {
    try {
      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return false;
      }

      print('🔄 تحديث حالة طلب الجملة $requestId إلى $status');

      final client = _supabaseService.client!;

      // تحديث حالة الطلب
      await client
          .from('wholesale_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      print('✅ تم تحديث حالة طلب الجملة بنجاح');

      return true;
    } catch (e) {
      print('❌ خطأ في تحديث حالة طلب الجملة: $e');
      return false;
    }
  }

  // تحديث حالة الرسائل كمقروءة عند فتح المحادثة
  Future<void> markWholesaleMessagesAsRead(String requestId) async {
    try {
      print('📖 ==== تحديث الرسائل كمقروءة ====');
      print('📋 معرف المحادثة: $requestId');

      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return;
      }

      final client = _supabaseService.client!;

      // 1. جلب الرسائل غير المقروءة من المستخدمين
      final unreadMessages = await client
          .from('wholesale_messages')
          .select('id, sender_type, message, is_read, created_at')
          .eq('conversation_id', requestId)
          .eq('sender_type', 'user')
          .eq('is_read', false);

      print('📊 عدد الرسائل غير المقروءة: ${unreadMessages.length}');

      if (unreadMessages.isEmpty) {
        print('ℹ️ لا توجد رسائل غير مقروءة من المستخدمين');
        return;
      }

      // 2. طباعة تفاصيل الرسائل
      print('📋 الرسائل غير المقروءة:');
      for (var msg in unreadMessages) {
        print('   - ID: ${msg['id']}');
        print('   - الرسالة: ${msg['message']}');
        print('   - مقروءة: ${msg['is_read']}');
        print('   ---');
      }

      // 3. تحديث الرسائل كمقروءة
      print('🔄 تحديث الرسائل في قاعدة البيانات...');

      final updateResult = await client
          .from('wholesale_messages')
          .update({'is_read': true})
          .eq('conversation_id', requestId)
          .eq('sender_type', 'user')
          .eq('is_read', false)
          .select('id, is_read, created_at');

      print('✅ تم تحديث ${updateResult.length} رسالة كمقروءة');

      // 4. التحقق من التحديث
      final verifyResult = await client
          .from('wholesale_messages')
          .select('id, is_read')
          .eq('conversation_id', requestId)
          .eq('sender_type', 'user')
          .eq('is_read', false);

      print('📊 عدد الرسائل غير المقروءة بعد التحديث: ${verifyResult.length}');

      print('📖 ==== انتهاء التحديث ====');
    } catch (e) {
      print('❌ خطأ في تحديث الرسائل: $e');
    }
  }

  // تحديث محسن للرسائل كمقروءة مع معالجة أفضل للأخطاء
  Future<bool> markWholesaleMessagesAsReadImproved(String requestId) async {
    try {
      print('📖 ==== بدء التحديث المحسن للرسائل كمقروءة ====');
      print('📋 معرف طلب الجملة: $requestId');

      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return false;
      }

      final client = _supabaseService.client!;

      // 1. التحقق من وجود حقل is_read
      try {
        await client.from('wholesale_messages').select('is_read').limit(1);
        print('✅ حقل is_read موجود في الجدول');
      } catch (e) {
        print('❌ حقل is_read غير موجود: $e');
        print(
          '💡 يجب تشغيل ملف SQL: admin_panel/sql/add_is_read_to_wholesale_messages.sql',
        );
        return false;
      }

      // 2. جلب جميع الرسائل من المستخدمين في هذه المحادثة
      final allUserMessages = await client
          .from('wholesale_messages')
          .select('id, sender_type, message, is_read, created_at')
          .eq('conversation_id', requestId)
          .eq('sender_type', 'user')
          .order('created_at', ascending: false);

      print(
        '📊 إجمالي رسائل المستخدمين في المحادثة: ${allUserMessages.length}',
      );

      if (allUserMessages.isEmpty) {
        print('ℹ️ لا توجد رسائل من المستخدمين في هذه المحادثة');
        return true;
      }

      // 3. تصفية الرسائل غير المقروءة
      final unreadMessages = allUserMessages
          .where((msg) => msg['is_read'] == false)
          .toList();
      print('📊 عدد الرسائل غير المقروءة: ${unreadMessages.length}');

      if (unreadMessages.isEmpty) {
        print('ℹ️ جميع رسائل المستخدمين مقروءة بالفعل');
        return true;
      }

      // 4. طباعة تفاصيل الرسائل غير المقروءة
      print('📋 تفاصيل الرسائل غير المقروءة:');
      for (var msg in unreadMessages) {
        print('   - ID: ${msg['id']}');
        print('   - الرسالة: ${msg['message']}');
        print('   - مقروءة: ${msg['is_read']}');
        print('   - التاريخ: ${msg['created_at']}');
        print('   ---');
      }

      // 5. تحديث الرسائل واحدة تلو الأخرى لضمان النجاح
      int successCount = 0;
      int failCount = 0;

      for (var msg in unreadMessages) {
        try {
          print('🔄 تحديث الرسالة: ${msg['id']}');

          final updateResult = await client
              .from('wholesale_messages')
              .update({'is_read': true})
              .eq('id', msg['id'])
              .select('id, is_read, created_at');

          if (updateResult.isNotEmpty) {
            final updatedMsg = updateResult.first;
            if (updatedMsg['is_read'] == true) {
              successCount++;
              print('✅ تم تحديث الرسالة بنجاح: ${msg['id']}');
              print('   - مقروءة: ${updatedMsg['is_read']}');
              print('   - وقت الإنشاء: ${updatedMsg['created_at']}');
            } else {
              failCount++;
              print(
                '❌ فشل في تحديث الرسالة: ${msg['id']} - is_read لا يزال false',
              );
            }
          } else {
            failCount++;
            print('❌ لم يتم تحديث أي سجل للرسالة: ${msg['id']}');
          }
        } catch (e) {
          failCount++;
          print('❌ خطأ في تحديث الرسالة ${msg['id']}: $e');
        }

        // تأخير قصير بين التحديثات
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print('📊 نتائج التحديث:');
      print('   - نجح: $successCount رسالة');
      print('   - فشل: $failCount رسالة');

      // 6. التحقق من التحديث
      if (successCount > 0) {
        print('🔍 التحقق من التحديث...');
        final verifyResult = await client
            .from('wholesale_messages')
            .select('id, is_read')
            .eq('conversation_id', requestId)
            .eq('sender_type', 'user')
            .eq('is_read', false);

        print(
          '📊 عدد الرسائل غير المقروءة بعد التحديث: ${verifyResult.length}',
        );
      }

      // 7. تحديث وقت آخر قراءة للمحادثة
      try {
        await _updateConversationLastReadTime(requestId);
      } catch (e) {
        print('⚠️ تحذير: فشل في تحديث وقت آخر قراءة: $e');
      }

      print('📖 ==== انتهاء التحديث المحسن ====');
      return successCount > 0;
    } catch (e) {
      print('❌ خطأ في التحديث المحسن: $e');
      print('❌ تفاصيل الخطأ: ${e.toString()}');
      return false;
    }
  }

  // إحصائيات طلبات الجملة
  Future<Map<String, dynamic>> getWholesaleStats() async {
    try {
      if (!_supabaseService.isReady) {
        return _getDefaultWholesaleStats();
      }

      final client = _supabaseService.client!;

      // إجمالي طلبات الجملة
      final totalRequests = await client
          .from('wholesale_requests')
          .select('id');

      // الطلبات المعلقة
      final pendingRequests = await client
          .from('wholesale_requests')
          .select('id')
          .eq('status', 'pending');

      // الطلبات قيد الدراسة
      final underReviewRequests = await client
          .from('wholesale_requests')
          .select('id')
          .eq('status', 'under_review');

      // الطلبات الموافق عليها
      final approvedRequests = await client
          .from('wholesale_requests')
          .select('id')
          .eq('status', 'approved');

      // الطلبات المكتملة
      final completedRequests = await client
          .from('wholesale_requests')
          .select('id')
          .eq('status', 'completed');

      return {
        'total_requests': totalRequests.length,
        'pending_requests': pendingRequests.length,
        'under_review_requests': underReviewRequests.length,
        'approved_requests': approvedRequests.length,
        'completed_requests': completedRequests.length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات طلبات الجملة: $e');
      return _getDefaultWholesaleStats();
    }
  }

  // دوال مساعدة خاصة

  // الحصول على آخر رسالة في طلب الجملة
  Future<WholesaleMessage?> _getLastWholesaleMessage(String requestId) async {
    try {
      // محاولة جلب من wholesale_messages أولاً
      try {
        final response = await _supabaseService.client!
            .from('wholesale_messages')
            .select('*')
            .eq('conversation_id', requestId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          return WholesaleMessage.fromJson(response);
        }
      } catch (e) {
        // جلب من support_messages
        final response = await _supabaseService.client!
            .from('support_messages')
            .select('*')
            .eq('conversation_id', requestId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          return WholesaleMessage(
            id: response['id'],
            conversationId: requestId,
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
      print('خطأ في جلب آخر رسالة لطلب الجملة: $e');
      return null;
    }
  }

  // الحصول على رسائل المشرف في طلب الجملة
  Future<List<WholesaleMessage>> _getAdminWholesaleMessages(
    String requestId,
  ) async {
    try {
      final response = await _supabaseService.client!
          .from('wholesale_messages')
          .select('*')
          .eq('conversation_id', requestId)
          .eq('sender_type', 'admin')
          .order('created_at', ascending: true);

      final processedMessages = _processWholesaleMessages(response);
      return processedMessages;
    } catch (e) {
      print('خطأ في جلب رسائل المشرف لطلب الجملة: $e');
      return [];
    }
  }

  // الحصول على عدد الرسائل غير المقروءة (دالة عامة)
  Future<int> getUnreadCount(String requestId) async {
    return await _getUnreadCount(requestId);
  }

  // الحصول على عدد الرسائل غير المقروءة
  Future<int> _getUnreadCount(String requestId) async {
    try {
      if (!_supabaseService.isReady) {
        return 0;
      }

      final client = _supabaseService.client!;

      // حساب الرسائل غير المقروءة من المستخدمين فقط
      final unreadMessages = await client
          .from('wholesale_messages')
          .select('id')
          .eq('conversation_id', requestId)
          .eq('sender_type', 'user')
          .eq('is_read', false);

      return unreadMessages.length;
    } catch (e) {
      print('❌ خطأ في حساب الرسائل غير المقروءة: $e');
      return 0;
    }
  }

  // حساب إجمالي الرسائل غير المقروءة من جميع طلبات الجملة (نسخة من support_messages)
  Future<int> getTotalUnreadWholesaleMessagesCount() async {
    try {
      print('🔍 حساب إجمالي الرسائل غير المقروءة من جميع طلبات الجملة');

      final client = _supabaseService.client!;

      // جلب جميع الرسائل غير المقروءة من المستخدمين (نفس منطق support_messages)
      final result = await client
          .from('wholesale_messages')
          .select('id, message, created_at')
          .eq('sender_type', 'user')
          .eq('is_read', false);

      final count = result.length;
      print('📊 إجمالي الرسائل غير المقروءة في طلبات الجملة: $count');

      // طباعة تفاصيل الرسائل غير المقروءة للتأكد
      for (final msg in result) {
        print(
          '📨 رسالة غير مقروءة: "${msg['message']}" - ${msg['created_at']}',
        );
      }

      return count;
    } catch (e) {
      print('خطأ في حساب إجمالي الرسائل غير المقروءة في طلبات الجملة: $e');
      return 0;
    }
  }

  // حساب عدد طلبات الجملة التي تحتوي على رسائل غير مقروءة (نسخة من support_messages)
  Future<int> getUnreadWholesaleRequestsCount() async {
    try {
      print('🔍 حساب عدد طلبات الجملة غير المقروءة');

      final client = _supabaseService.client!;

      // جلب جميع طلبات الجملة المفتوحة
      final wholesaleRequests = await client
          .from('wholesale_requests')
          .select('id');

      int unreadRequests = 0;

      // فحص كل طلب لوجود رسائل غير مقروءة
      for (final request in wholesaleRequests) {
        final unreadCount = await _getUnreadCount(request['id']);
        if (unreadCount > 0) {
          unreadRequests++;
        }
      }

      print('📊 عدد طلبات الجملة غير المقروءة: $unreadRequests');
      return unreadRequests;
    } catch (e) {
      print('خطأ في حساب طلبات الجملة غير المقروءة: $e');
      return 0;
    }
  }

  // تحديث وقت آخر تحديث لطلب الجملة
  Future<void> _updateWholesaleRequestTimestamp(String requestId) async {
    try {
      await _supabaseService.client!
          .from('wholesale_requests')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', requestId);
    } catch (e) {
      print('خطأ في تحديث وقت طلب الجملة: $e');
    }
  }

  // تحديث وقت آخر قراءة للمحادثة
  Future<void> _updateConversationLastReadTime(String requestId) async {
    try {
      await _supabaseService.client!
          .from('wholesale_conversations')
          .update({
            'last_read_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      print('✅ تم تحديث وقت آخر قراءة للمحادثة');
    } catch (e) {
      print('❌ خطأ في تحديث وقت آخر قراءة: $e');
    }
  }

  // معالجة رسائل wholesale_messages
  List<WholesaleMessage> _processWholesaleMessages(List<dynamic> response) {
    final messages = <WholesaleMessage>[];

    for (var item in response) {
      try {
        messages.add(WholesaleMessage.fromJson(item));
      } catch (e) {
        print('خطأ في معالجة رسالة طلب الجملة: $e');
      }
    }

    return messages;
  }

  Map<String, dynamic> _getDefaultWholesaleStats() {
    return {
      'total_requests': 0,
      'pending_requests': 0,
      'under_review_requests': 0,
      'approved_requests': 0,
      'completed_requests': 0,
    };
  }

  // التحقق من دور المشرف
  Future<void> _checkAdminRole() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        print('❌ المستخدم غير مسجل دخول');
        return;
      }

      // محاولة جلب الملف الشخصي مع التحقق من وجود عمود role
      try {
        final profile = await _supabaseService.client!
            .from('profiles')
            .select('role, name')
            .eq('id', currentUser.id)
            .maybeSingle();

        if (profile != null) {
          print('👤 دور المستخدم الحالي: ${profile['role'] ?? 'غير محدد'}');
          print('👤 اسم المستخدم: ${profile['name'] ?? 'غير محدد'}');

          if (profile['role'] != 'admin') {
            print('⚠️ المستخدم ليس مشرفاً - قد تكون هناك مشاكل في الصلاحيات');
            print('💡 قم بتحديث دور المستخدم إلى admin في جدول profiles');
          }
        } else {
          print('⚠️ لم يتم العثور على ملف المستخدم');
        }
      } catch (roleError) {
        print('⚠️ خطأ في جلب دور المستخدم: $roleError');
        print(
          '💡 قد يكون عمود role غير موجود - سيتم المتابعة بدون التحقق من الدور',
        );

        // محاولة جلب الملف بدون عمود role
        try {
          final basicProfile = await _supabaseService.client!
              .from('profiles')
              .select('name, email')
              .eq('id', currentUser.id)
              .maybeSingle();

          if (basicProfile != null) {
            print('👤 اسم المستخدم: ${basicProfile['name'] ?? 'غير محدد'}');
            print(
              '👤 البريد الإلكتروني: ${basicProfile['email'] ?? 'غير محدد'}',
            );
          }
        } catch (basicError) {
          print('❌ خطأ في جلب الملف الشخصي: $basicError');
        }
      }
    } catch (e) {
      print('❌ خطأ في التحقق من دور المستخدم: $e');
    }
  }

  // التأكد من وجود محادثة لطلب الجملة
  Future<void> ensureWholesaleConversationExists(String requestId) async {
    try {
      print('🔍 التحقق من وجود محادثة لطلب الجملة: $requestId');

      // التحقق من وجود المحادثة
      final existingConversation = await _supabaseService.client!
          .from('wholesale_conversations')
          .select('id')
          .eq('id', requestId)
          .maybeSingle();

      if (existingConversation == null) {
        print('⚠️ المحادثة غير موجودة، سيتم إنشاؤها...');

        // جلب معلومات طلب الجملة
        final requestInfo = await _supabaseService.client!
            .from('wholesale_requests')
            .select('user_id, product_name, status')
            .eq('id', requestId)
            .single();

        // إنشاء محادثة جديدة
        final conversationData = {
          'id': requestId,
          'request_id': requestId,
          'user_id': requestInfo['user_id'],
          'status': 'active',
        };

        try {
          await _supabaseService.client!
              .from('wholesale_conversations')
              .insert(conversationData);

          print('✅ تم إنشاء محادثة جديدة لطلب الجملة: $requestId');
        } catch (insertError) {
          print('❌ خطأ في إنشاء المحادثة: $insertError');
          print('💡 المحاولة باستخدام service_role client...');

          // محاولة استخدام service_role client
          try {
            final serviceClient = _supabaseService.serviceRoleClient;
            if (serviceClient != null) {
              await serviceClient
                  .from('wholesale_conversations')
                  .insert(conversationData);

              print('✅ تم إنشاء محادثة باستخدام service_role: $requestId');
            } else {
              print('❌ service_role client غير متاح');
            }
          } catch (serviceError) {
            print('❌ فشل استخدام service_role أيضاً: $serviceError');
          }
        }
      } else {
        print('✅ المحادثة موجودة بالفعل: $requestId');
      }
    } catch (e) {
      print('❌ خطأ في التأكد من وجود المحادثة: $e');
      // لا نعيد الخطأ هنا، بل نحاول المتابعة
    }
  }

  // الاستماع للتحديثات المباشرة
  RealtimeChannel? _wholesaleRequestsChannel;
  RealtimeChannel? _wholesaleMessagesChannel;

  // بدء الاستماع للتحديثات المباشرة لطلبات الجملة
  void startListeningToWholesaleRequests(
    Function(List<WholesaleRequest>) onUpdate,
  ) {
    try {
      if (!_supabaseService.isReady) return;

      _wholesaleRequestsChannel = _supabaseService.client!
          .channel('wholesale_requests_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'wholesale_requests',
            callback: (payload) async {
              print('تحديث في طلبات الجملة: $payload');
              final requests = await getWholesaleRequests();
              onUpdate(requests);
            },
          )
          .subscribe();

      print('بدأ الاستماع لتحديثات طلبات الجملة');
    } catch (e) {
      print('خطأ في بدء الاستماع لطلبات الجملة: $e');
    }
  }

  // بدء الاستماع للتحديثات المباشرة لرسائل طلب الجملة
  void startListeningToWholesaleMessages(
    String requestId,
    Function(List<WholesaleMessage>) onUpdate,
  ) {
    try {
      if (!_supabaseService.isReady) return;

      // إيقاف أي استماع سابق
      stopListeningToWholesaleMessages();

      print('🔥 بدء الاستماع لرسائل طلب الجملة: $requestId');

      // الاستماع لرسائل wholesale_messages
      _wholesaleMessagesChannel = _supabaseService.client!
          .channel('wholesale_messages_changes_$requestId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'wholesale_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: requestId,
            ),
            callback: (payload) async {
              print('🔔 تحديث في رسائل طلب الجملة: ${payload.eventType}');
              print('📋 تفاصيل التحديث: ${payload.newRecord}');
              try {
                final messages = await getWholesaleMessages(requestId);
                onUpdate(messages);
                print('✅ تم تحديث رسائل طلب الجملة: ${messages.length} رسالة');
              } catch (e) {
                print('❌ خطأ في تحديث رسائل طلب الجملة: $e');
              }
            },
          )
          .subscribe((status, [error]) {
            print('📡 حالة الاشتراك wholesale_messages: $status');
            if (error != null) {
              print('❌ خطأ في الاشتراك wholesale_messages: $error');
            }
          });

      // إضافة استماع لـ support_messages أيضاً كبديل
      _supabaseService.client!
          .channel('support_messages_for_wholesale_$requestId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'support_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: requestId,
            ),
            callback: (payload) async {
              print(
                '🔔 تحديث في رسائل الدعم لطلب الجملة: ${payload.eventType}',
              );
              try {
                final messages = await getWholesaleMessages(requestId);
                onUpdate(messages);
                print(
                  '✅ تم تحديث رسائل الدعم للجملة: ${messages.length} رسالة',
                );
              } catch (e) {
                print('❌ خطأ في تحديث رسائل الدعم للجملة: $e');
              }
            },
          )
          .subscribe((status, [error]) {
            print('📡 حالة الاشتراك support_messages: $status');
            if (error != null) {
              print('❌ خطأ في الاشتراك support_messages: $error');
            }
          });

      print('✅ تم بدء الاستماع لتحديثات رسائل طلب الجملة: $requestId');
    } catch (e) {
      print('❌ خطأ في بدء الاستماع لرسائل طلب الجملة: $e');
    }
  }

  // إيقاف الاستماع لرسائل طلب جملة محدد
  void stopListeningToWholesaleMessages() {
    try {
      if (_wholesaleMessagesChannel != null) {
        _wholesaleMessagesChannel!.unsubscribe();
        _wholesaleMessagesChannel = null;
        print('🛑 تم إيقاف الاستماع لرسائل طلب الجملة');
      }
    } catch (e) {
      print('❌ خطأ في إيقاف الاستماع لرسائل طلب الجملة: $e');
    }
  }

  // إيقاف الاستماع للتحديثات
  void stopListening() {
    try {
      _wholesaleRequestsChannel?.unsubscribe();
      _wholesaleRequestsChannel = null;
      stopListeningToWholesaleMessages();
      print('تم إيقاف الاستماع لتحديثات طلبات الجملة');
    } catch (e) {
      print('خطأ في إيقاف الاستماع: $e');
    }
  }

  // إنشاء محادثات مفقودة لجميع طلبات الجملة
  Future<void> createMissingConversations() async {
    try {
      print('🔧 ==== بدء إنشاء المحادثات المفقودة ====');

      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return;
      }

      // جلب جميع طلبات الجملة
      final requests = await _supabaseService.client!
          .from('wholesale_requests')
          .select('id, user_id, product_name, status, created_at');

      print('📋 تم جلب ${requests.length} طلب جملة');

      int createdCount = 0;
      int existingCount = 0;

      for (var request in requests) {
        final requestId = request['id'];

        // التحقق من وجود المحادثة
        final existingConversation = await _supabaseService.client!
            .from('wholesale_conversations')
            .select('id')
            .eq('id', requestId)
            .maybeSingle();

        if (existingConversation == null) {
          // إنشاء محادثة جديدة
          final conversationData = {
            'id': requestId,
            'request_id': requestId,
            'user_id': request['user_id'],
            'status': 'active',
            'created_at': request['created_at'],
            'updated_at': DateTime.now().toIso8601String(),
            'last_message_at': request['created_at'],
          };

          try {
            await _supabaseService.client!
                .from('wholesale_conversations')
                .insert(conversationData);

            createdCount++;
            print('✅ تم إنشاء محادثة لطلب: $requestId');
          } catch (e) {
            print('❌ خطأ في إنشاء محادثة لطلب $requestId: $e');
          }
        } else {
          existingCount++;
          print('✅ المحادثة موجودة بالفعل لطلب: $requestId');
        }
      }

      print('🎉 ==== انتهاء إنشاء المحادثات المفقودة ====');
      print('📊 تم إنشاء $createdCount محادثة جديدة');
      print('📊 $existingCount محادثة كانت موجودة بالفعل');
      print('📊 إجمالي الطلبات: ${requests.length}');
    } catch (e) {
      print('❌ خطأ في إنشاء المحادثات المفقودة: $e');
    }
  }

  // اختبار تحديث رسائل محادثة محددة
  Future<void> testUpdateSpecificConversation(String conversationId) async {
    try {
      print('🔄 ==== اختبار تحديث محادثة محددة ====');
      print('📋 معرف المحادثة: $conversationId');

      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return;
      }

      // جلب الرسائل غير المقروءة من المستخدمين لهذه المحادثة
      final unreadMessages = await _supabaseService.client!
          .from('wholesale_messages')
          .select('id, sender_type, message, is_read, created_at')
          .eq('conversation_id', conversationId)
          .eq('sender_type', 'user')
          .eq('is_read', false)
          .order('created_at', ascending: false);

      print(
        '📊 عدد الرسائل غير المقروءة في المحادثة: ${unreadMessages.length}',
      );

      if (unreadMessages.isNotEmpty) {
        print('📋 تفاصيل الرسائل غير المقروءة:');
        for (var msg in unreadMessages) {
          print('   - ID: ${msg['id']}');
          print('   - المرسل: ${msg['sender_type']}');
          print('   - الرسالة: ${msg['message']}');
          print('   - مقروءة: ${msg['is_read']}');
          print('   - التاريخ: ${msg['created_at']}');
          print('   ---');
        }

        // تحديث الرسائل كمقروءة
        print('🔄 جاري تحديث الرسائل...');
        await markWholesaleMessagesAsRead(conversationId);

        // التحقق من التحديث
        final updatedMessages = await _supabaseService.client!
            .from('wholesale_messages')
            .select('id, sender_type, message, is_read')
            .eq('conversation_id', conversationId)
            .eq('sender_type', 'user')
            .eq('is_read', false);

        print(
          '✅ عدد الرسائل غير المقروءة بعد التحديث: ${updatedMessages.length}',
        );

        if (updatedMessages.isEmpty) {
          print('🎉 تم تحديث جميع الرسائل بنجاح!');
        } else {
          print('⚠️ لا تزال هناك رسائل غير مقروءة');
        }
      } else {
        print('ℹ️ لا توجد رسائل غير مقروءة في هذه المحادثة');
      }

      print('🔄 ==== انتهاء اختبار تحديث المحادثة ====');
    } catch (e) {
      print('❌ خطأ في اختبار تحديث المحادثة: $e');
    }
  }

  // اختبار التحديث التلقائي للرسائل
  Future<void> testAutoUpdateMessages() async {
    try {
      print('🔄 ==== اختبار التحديث التلقائي للرسائل ====');

      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return;
      }

      // جلب جميع الرسائل غير المقروءة من المستخدمين
      final unreadMessages = await _supabaseService.client!
          .from('wholesale_messages')
          .select(
            'id, conversation_id, sender_type, message, is_read, created_at',
          )
          .eq('sender_type', 'user')
          .eq('is_read', false)
          .order('created_at', ascending: false);

      print('📊 إجمالي الرسائل غير المقروءة: ${unreadMessages.length}');

      if (unreadMessages.isNotEmpty) {
        // تجميع الرسائل حسب المحادثة
        Map<String, List<Map<String, dynamic>>> conversationMessages = {};
        for (var msg in unreadMessages) {
          final conversationId = msg['conversation_id'] as String;
          if (!conversationMessages.containsKey(conversationId)) {
            conversationMessages[conversationId] = [];
          }
          conversationMessages[conversationId]!.add(msg);
        }

        print(
          '📊 عدد المحادثات التي تحتوي على رسائل غير مقروءة: ${conversationMessages.length}',
        );

        // اختبار تحديث كل محادثة
        for (var conversationId in conversationMessages.keys) {
          final messages = conversationMessages[conversationId]!;
          print(
            '🔄 اختبار تحديث المحادثة: $conversationId (${messages.length} رسالة)',
          );

          // تحديث الرسائل كمقروءة
          await markWholesaleMessagesAsRead(conversationId);

          // التحقق من التحديث
          final updatedMessages = await _supabaseService.client!
              .from('wholesale_messages')
              .select('id, sender_type, message, is_read')
              .eq('conversation_id', conversationId)
              .eq('sender_type', 'user')
              .eq('is_read', false);

          print(
            '✅ عدد الرسائل غير المقروءة بعد التحديث: ${updatedMessages.length}',
          );
        }
      } else {
        print('ℹ️ لا توجد رسائل غير مقروءة للاختبار');
      }

      print('🔄 ==== انتهاء اختبار التحديث التلقائي ====');
    } catch (e) {
      print('❌ خطأ في اختبار التحديث التلقائي: $e');
    }
  }

  // اختبار الرسائل غير المقروءة
  Future<void> testUnreadMessages() async {
    try {
      print('🔍 ==== اختبار الرسائل غير المقروءة ====');

      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return;
      }

      // جلب جميع الرسائل غير المقروءة من المستخدمين
      final unreadMessages = await _supabaseService.client!
          .from('wholesale_messages')
          .select(
            'id, conversation_id, sender_type, message, is_read, created_at',
          )
          .eq('sender_type', 'user')
          .eq('is_read', false)
          .order('created_at', ascending: false);

      print('📊 إجمالي الرسائل غير المقروءة: ${unreadMessages.length}');

      if (unreadMessages.isNotEmpty) {
        print('📋 تفاصيل الرسائل غير المقروءة:');
        for (var msg in unreadMessages) {
          print('   - المحادثة: ${msg['conversation_id']}');
          print('   - المرسل: ${msg['sender_type']}');
          print('   - الرسالة: ${msg['message']}');
          print('   - مقروءة: ${msg['is_read']}');
          print('   - التاريخ: ${msg['created_at']}');
          print('   ---');
        }

        // تجميع الرسائل حسب المحادثة
        Map<String, int> conversationCounts = {};
        for (var msg in unreadMessages) {
          final conversationId = msg['conversation_id'] as String;
          conversationCounts[conversationId] =
              (conversationCounts[conversationId] ?? 0) + 1;
        }

        print('📊 عدد الرسائل غير المقروءة لكل محادثة:');
        conversationCounts.forEach((conversationId, count) {
          print('   - $conversationId: $count رسالة');
        });
      } else {
        print('ℹ️ لا توجد رسائل غير مقروءة');
      }

      print('🔍 ==== انتهاء اختبار الرسائل غير المقروءة ====');
    } catch (e) {
      print('❌ خطأ في اختبار الرسائل غير المقروءة: $e');
    }
  }

  // تشخيص مشكلة تحديث is_read
  Future<void> diagnoseIsReadUpdate(String requestId) async {
    try {
      print('🔧 ==== تشخيص مشكلة تحديث is_read ====');
      print('📋 معرف طلب الجملة: $requestId');

      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return;
      }

      final client = _supabaseService.client!;

      // 1. فحص بنية الجدول
      print('🔍 1. فحص بنية جدول wholesale_messages...');
      try {
        await client.from('wholesale_messages').select('*').limit(1);
        print('✅ الجدول موجود ويمكن الوصول إليه');
      } catch (e) {
        print('❌ خطأ في الوصول للجدول: $e');
        return;
      }

      // 2. فحص وجود حقل is_read
      print('🔍 2. فحص وجود حقل is_read...');
      try {
        final sampleData = await client
            .from('wholesale_messages')
            .select('id, is_read')
            .limit(1);

        if (sampleData.isNotEmpty) {
          print('✅ حقل is_read موجود');
          print(
            '   - نوع البيانات: ${sampleData.first['is_read'].runtimeType}',
          );
        } else {
          print('⚠️ لا توجد بيانات في الجدول');
        }
      } catch (e) {
        print('❌ حقل is_read غير موجود أو غير صحيح: $e');
        print(
          '💡 يجب تشغيل ملف SQL: admin_panel/sql/add_is_read_to_wholesale_messages.sql',
        );
        return;
      }

      // 3. فحص الرسائل في المحادثة المحددة
      print('🔍 3. فحص الرسائل في المحادثة $requestId...');
      final messages = await client
          .from('wholesale_messages')
          .select('id, sender_type, message, is_read, created_at')
          .eq('conversation_id', requestId)
          .order('created_at', ascending: false);

      print('📊 إجمالي الرسائل في المحادثة: ${messages.length}');

      if (messages.isNotEmpty) {
        print('📋 تفاصيل الرسائل:');
        for (var msg in messages) {
          print('   - ID: ${msg['id']}');
          print('   - المرسل: ${msg['sender_type']}');
          print('   - الرسالة: ${msg['message']}');
          print(
            '   - مقروءة: ${msg['is_read']} (نوع: ${msg['is_read'].runtimeType})',
          );
          print('   - التاريخ: ${msg['created_at']}');
          print('   ---');
        }

        // 4. فحص الرسائل غير المقروءة من المستخدمين
        final unreadUserMessages = messages
            .where(
              (msg) => msg['sender_type'] == 'user' && msg['is_read'] == false,
            )
            .toList();

        print(
          '📊 الرسائل غير المقروءة من المستخدمين: ${unreadUserMessages.length}',
        );

        if (unreadUserMessages.isNotEmpty) {
          print('🔍 4. اختبار تحديث الرسائل...');

          // محاولة تحديث رسالة واحدة أولاً
          final firstMessage = unreadUserMessages.first;
          print('🔄 تحديث الرسالة الأولى: ${firstMessage['id']}');

          try {
            final updateResult = await client
                .from('wholesale_messages')
                .update({'is_read': true})
                .eq('id', firstMessage['id'])
                .select('id, is_read');

            if (updateResult.isNotEmpty) {
              print('✅ تم تحديث الرسالة بنجاح:');
              print('   - ID: ${updateResult.first['id']}');
              print('   - مقروءة: ${updateResult.first['is_read']}');

              // إعادة تعيين الرسالة لاختبار آخر
              await client
                  .from('wholesale_messages')
                  .update({'is_read': false})
                  .eq('id', firstMessage['id']);
              print('🔄 تم إعادة تعيين الرسالة للاختبار');
            } else {
              print('❌ فشل في تحديث الرسالة');
            }
          } catch (updateError) {
            print('❌ خطأ في تحديث الرسالة: $updateError');
          }
        }
      }

      // 5. فحص الصلاحيات
      print('🔍 5. فحص صلاحيات المستخدم...');
      try {
        final user = await client.auth.getUser();
        print('👤 المستخدم الحالي: ${user.user?.email}');
        print('🔑 معرف المستخدم: ${user.user?.id}');
      } catch (e) {
        print('❌ خطأ في فحص المستخدم: $e');
      }

      print('🔧 ==== انتهاء التشخيص ====');
    } catch (e) {
      print('❌ خطأ في التشخيص: $e');
    }
  }

  // اختبار سريع لنظام محادثة طلبات الجملة
  Future<void> quickTestWholesaleSystem() async {
    try {
      print('🔧 ==== اختبار سريع لنظام محادثة طلبات الجملة ====');

      // 1. فحص حالة Supabase
      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return;
      }
      print('✅ Supabase جاهز');

      // 2. فحص المستخدم الحالي
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        print('❌ لا يوجد مستخدم مسجل دخول');
        return;
      }
      print('✅ المستخدم: ${currentUser.id}');

      // 3. اختبار الوصول لجدول wholesale_messages
      try {
        await _supabaseService.client!
            .from('wholesale_messages')
            .select('id')
            .limit(1);
        print('✅ يمكن الوصول لجدول wholesale_messages');
      } catch (e) {
        print('❌ لا يمكن الوصول لجدول wholesale_messages: $e');

        // محاولة استخدام service_role
        try {
          final serviceClient = _supabaseService.serviceRoleClient;
          if (serviceClient != null) {
            await serviceClient
                .from('wholesale_messages')
                .select('id')
                .limit(1);
            print('✅ يمكن الوصول باستخدام service_role');
          }
        } catch (serviceError) {
          print('❌ فشل service_role أيضاً: $serviceError');
        }
      }

      // 4. اختبار إدراج رسالة تجريبية
      try {
        final testMessage = {
          'conversation_id': 'test-wholesale-conversation-id',
          'sender_type': 'admin',
          'sender_id': currentUser.id,
          'type': 'text',
          'message': 'رسالة تجريبية من مشرف طلبات الجملة',
        };

        final insertResult = await _supabaseService.client!
            .from('wholesale_messages')
            .insert(testMessage)
            .select();

        print('✅ تم إدراج رسالة تجريبية: ${insertResult.first['id']}');

        // حذف الرسالة التجريبية
        await _supabaseService.client!
            .from('wholesale_messages')
            .delete()
            .eq('id', insertResult.first['id']);
        print('✅ تم حذف الرسالة التجريبية');
      } catch (e) {
        print('❌ خطأ في إدراج رسالة تجريبية: $e');

        // محاولة استخدام service_role
        try {
          final serviceClient = _supabaseService.serviceRoleClient;
          if (serviceClient != null) {
            final testMessage = {
              'conversation_id': 'test-wholesale-conversation-id',
              'sender_type': 'admin',
              'sender_id': currentUser.id,
              'type': 'text',
              'message': 'رسالة تجريبية باستخدام service_role',
            };

            final insertResult = await serviceClient
                .from('wholesale_messages')
                .insert(testMessage)
                .select();

            print(
              '✅ تم إدراج رسالة تجريبية باستخدام service_role: ${insertResult.first['id']}',
            );

            // حذف الرسالة التجريبية
            await serviceClient
                .from('wholesale_messages')
                .delete()
                .eq('id', insertResult.first['id']);
            print('✅ تم حذف الرسالة التجريبية باستخدام service_role');
          }
        } catch (serviceError) {
          print('❌ فشل service_role أيضاً: $serviceError');
        }
      }

      print('🔧 ==== انتهاء الاختبار السريع ====');
    } catch (e) {
      print('❌ خطأ في الاختبار السريع: $e');
    }
  }

  // اختبار شامل لنظام محادثة طلبات الجملة
  Future<void> diagnoseWholesaleChatSystem() async {
    try {
      print('🔧 ==== بدء تشخيص نظام محادثة طلبات الجملة ====');

      // 1. فحص حالة Supabase
      print('1️⃣ فحص حالة Supabase...');
      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return;
      }
      print('✅ Supabase جاهز');

      // 2. فحص المستخدم الحالي
      print('2️⃣ فحص المستخدم الحالي...');
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        print('❌ لا يوجد مستخدم مسجل دخول');
        return;
      }
      print(
        '✅ المستخدم: ${currentUser.id} (${currentUser.email ?? 'بدون بريد'})',
      );

      // 3. اختبار الوصول لجدول wholesale_messages
      print('3️⃣ اختبار الوصول لجدول wholesale_messages...');
      try {
        final testQuery = await _supabaseService.client!
            .from('wholesale_messages')
            .select('id')
            .limit(1);
        print('✅ يمكن الوصول لجدول wholesale_messages');
        print('📊 نتيجة الاستعلام التجريبي: ${testQuery.length} صف');
      } catch (e) {
        print('❌ لا يمكن الوصول لجدول wholesale_messages: $e');
        print('❌ نوع الخطأ: ${e.runtimeType}');

        // محاولة معرفة المزيد عن الخطأ
        if (e.toString().contains('RLS')) {
          print(
            '💡 المشكلة: Row Level Security (RLS) - المشرف لا يملك صلاحيات',
          );
        } else if (e.toString().contains('permission')) {
          print('💡 المشكلة: صلاحيات - تحقق من permissions');
        } else if (e.toString().contains('relation') ||
            e.toString().contains('does not exist')) {
          print('💡 المشكلة: الجدول غير موجود');
        }
      }

      // 4. جلب عينة من رسائل طلبات الجملة
      print('4️⃣ جلب عينة من رسائل طلبات الجملة...');
      try {
        final sampleMessages = await _supabaseService.client!
            .from('wholesale_messages')
            .select('id, conversation_id, sender_type, message, created_at')
            .limit(5)
            .order('created_at', ascending: false);

        print('✅ تم جلب ${sampleMessages.length} رسالة من wholesale_messages');
        for (var msg in sampleMessages) {
          print(
            '   📨 ${msg['conversation_id']}: ${msg['sender_type']} - ${msg['message']}',
          );
        }
      } catch (e) {
        print('❌ خطأ في جلب الرسائل من wholesale_messages: $e');
        print('❌ تفاصيل الخطأ: ${e.toString()}');

        // تحليل نوع الخطأ
        if (e.toString().contains('42501') ||
            e.toString().contains('insufficient_privilege')) {
          print(
            '💡 السبب: المشرف لا يملك صلاحية SELECT على جدول wholesale_messages',
          );
          print('🔧 الحل المطلوب: إضافة RLS Policy للمشرفين');
        } else if (e.toString().contains('42P01') ||
            e.toString().contains('relation') ||
            e.toString().contains('does not exist')) {
          print('💡 السبب: جدول wholesale_messages غير موجود');
          print('🔧 الحل المطلوب: إنشاء الجدول أو التحقق من اسم الجدول');
        }

        // محاولة support_messages كبديل
        print('🔄 محاولة البحث في support_messages...');
        try {
          final supportMessages = await _supabaseService.client!
              .from('support_messages')
              .select('id, conversation_id, sender_type, message, created_at')
              .limit(5)
              .order('created_at', ascending: false);

          print('✅ تم جلب ${supportMessages.length} رسالة من support_messages');
          for (var msg in supportMessages) {
            print(
              '   📨 ${msg['conversation_id']}: ${msg['sender_type']} - ${msg['message']}',
            );
          }
        } catch (supportError) {
          print('❌ خطأ في جلب الرسائل من support_messages: $supportError');
        }
      }

      // 5. اختبار إدراج رسالة تجريبية في wholesale_messages
      print('5️⃣ اختبار إدراج رسالة تجريبية في wholesale_messages...');
      try {
        final testMessage = {
          'conversation_id': 'test-wholesale-conversation-id',
          'sender_type': 'admin',
          'sender_id': currentUser.id,
          'type': 'text',
          'message': 'رسالة تجريبية من مشرف طلبات الجملة',
          'created_at': DateTime.now().toIso8601String(),
        };

        final insertResult = await _supabaseService.client!
            .from('wholesale_messages')
            .insert(testMessage)
            .select();

        print(
          '✅ تم إدراج رسالة تجريبية في wholesale_messages: ${insertResult.first['id']}',
        );

        // حذف الرسالة التجريبية
        await _supabaseService.client!
            .from('wholesale_messages')
            .delete()
            .eq('id', insertResult.first['id']);
        print('✅ تم حذف الرسالة التجريبية من wholesale_messages');
      } catch (e) {
        print('❌ خطأ في إدراج رسالة تجريبية في wholesale_messages: $e');
        print('❌ تفاصيل خطأ الإدراج: ${e.toString()}');

        // تحليل نوع الخطأ في الإدراج
        if (e.toString().contains('42501') ||
            e.toString().contains('insufficient_privilege')) {
          print(
            '💡 السبب: المشرف لا يملك صلاحية INSERT على جدول wholesale_messages',
          );
          print('🔧 الحل المطلوب: إضافة RLS Policy للكتابة');
        } else if (e.toString().contains('23503') ||
            e.toString().contains('foreign key')) {
          print('💡 السبب: قيود Foreign Key');
          print('🔧 الحل المطلوب: التحقق من قيود الجدول');
        }

        // محاولة support_messages كبديل
        print('🔄 محاولة إدراج رسالة تجريبية في support_messages...');
        try {
          final testMessage = {
            'conversation_id': 'test-wholesale-conversation-id',
            'sender_type': 'admin',
            'sender_id': currentUser.id,
            'type': 'text',
            'message': 'رسالة تجريبية من مشرف طلبات الجملة (support_messages)',
            'created_at': DateTime.now().toIso8601String(),
          };

          final insertResult = await _supabaseService.client!
              .from('support_messages')
              .insert(testMessage)
              .select();

          print(
            '✅ تم إدراج رسالة تجريبية في support_messages: ${insertResult.first['id']}',
          );

          // حذف الرسالة التجريبية
          await _supabaseService.client!
              .from('support_messages')
              .delete()
              .eq('id', insertResult.first['id']);
          print('✅ تم حذف الرسالة التجريبية من support_messages');
        } catch (supportError) {
          print(
            '❌ خطأ في إدراج رسالة تجريبية في support_messages: $supportError',
          );
        }
      }

      print('🔧 ==== انتهاء تشخيص نظام محادثة طلبات الجملة ====');

      // إضافة دليل إصلاح المشاكل
      print('');
      print('📋 ==== دليل إصلاح المشاكل الشائعة ====');
      print('');
      print('❌ إذا ظهر خطأ "insufficient_privilege" أو "42501":');
      print('   🔧 الحل: إضافة RLS Policy في Supabase:');
      print('   💻 SQL Command:');
      print(
        '   CREATE POLICY "Admins can read wholesale messages" ON wholesale_messages',
      );
      print('   FOR SELECT USING (true);');
      print('   ');
      print(
        '   CREATE POLICY "Admins can insert wholesale messages" ON wholesale_messages',
      );
      print('   FOR INSERT WITH CHECK (sender_type = \'admin\');');
      print('');
      print('❌ إذا ظهر خطأ "relation does not exist":');
      print('   🔧 الحل: إنشاء جدول wholesale_messages:');
      print('   💻 SQL Command:');
      print('   CREATE TABLE wholesale_messages (');
      print('     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,');
      print('     conversation_id UUID NOT NULL,');
      print('     sender_type TEXT NOT NULL,');
      print('     sender_id UUID NOT NULL,');
      print('     type TEXT DEFAULT \'text\',');
      print('     message TEXT NOT NULL,');
      print('     media_url TEXT,');
      print('     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()');
      print('   );');
      print('');
      print('❌ إذا كانت الرسائل لا تظهر في الوقت الفعلي:');
      print('   🔧 الحل: التأكد من Real-time subscriptions في Supabase');
      print('   💻 Settings → API → Real-time → Enable for wholesale_messages');
      print('');
      print('📋 ==== انتهاء دليل الإصلاح ====');
    } catch (e) {
      print('❌ خطأ عام في تشخيص طلبات الجملة: $e');
    }
  }
}
