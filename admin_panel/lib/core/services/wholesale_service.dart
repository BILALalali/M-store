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

  // Stream controllers للتحديثات في الوقت الفعلي
  final StreamController<List<WholesaleRequest>> _requestsController =
      StreamController<List<WholesaleRequest>>.broadcast();
  final StreamController<List<WholesaleMessage>> _messagesController =
      StreamController<List<WholesaleMessage>>.broadcast();

  // Streams للاستماع للتحديثات
  Stream<List<WholesaleRequest>> get requestsStream =>
      _requestsController.stream;
  Stream<List<WholesaleMessage>> get messagesStream =>
      _messagesController.stream;

  // subscriptions
  RealtimeChannel? _requestsSubscription;
  RealtimeChannel? _messagesSubscription;

  // بدء الاستماع للتحديثات في الوقت الفعلي
  void startRealtimeSubscriptions() {
    if (!_supabaseService.isReady) return;

    final client = _supabaseService.client!;

    // الاستماع لتغييرات في جدول wholesale_requests
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

    print('✅ تم بدء الاستماع للتحديثات في الوقت الفعلي لطلبات الجملة');
  }

  // إيقاف الاستماع
  void stopRealtimeSubscriptions() {
    _requestsSubscription?.unsubscribe();
    _messagesSubscription?.unsubscribe();
    _requestsSubscription = null;
    _messagesSubscription = null;
    print('🛑 تم إيقاف الاستماع للتحديثات في الوقت الفعلي');
  }

  // معالجة التغييرات في طلبات الجملة
  void _handleRequestsChange(PostgresChangePayload payload) async {
    print('📊 معالجة تغيير في طلبات الجملة...');

    try {
      // إعادة جلب البيانات عند أي تغيير
      final updatedRequests = await getWholesaleRequests();
      _requestsController.add(updatedRequests);

      print('✅ تم تحديث قائمة طلبات الجملة: ${updatedRequests.length} طلب');
    } catch (e) {
      print('❌ خطأ في معالجة تغيير طلبات الجملة: $e');
    }
  }

  // إنهاء الموارد
  void dispose() {
    stopRealtimeSubscriptions();
    _requestsController.close();
    _messagesController.close();
  }

  // الحصول على جميع طلبات الجملة
  Future<List<WholesaleRequest>> getWholesaleRequests() async {
    try {
      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return [];
      }

      print('🔄 جلب طلبات الجملة من قاعدة البيانات...');
      final client = _supabaseService.client!;

      // جلب جميع طلبات الجملة الحقيقية
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
        // جلب اسم المستخدم من profiles
        String userName = 'عميل الجملة';
        try {
          final userId = item['user_id'];
          if (userId != null) {
            final profileResponse = await _supabaseService.client!
                .from('profiles')
                .select('name')
                .eq('id', userId)
                .maybeSingle();
            userName =
                profileResponse?['name'] ??
                'عميل ${userId.toString().substring(0, 8)}';
          }
        } catch (e) {
          print('تحذير: لا يمكن جلب اسم المستخدم: $e');
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
            unreadCount: 0,
            hasUnreadMessages: false,
          ),
        );

        print('📋 تم إضافة طلب: $displayProductName (الكمية: $quantity)');
      }

      print('🎉 تم جلب ${requests.length} طلب جملة حقيقي من قاعدة البيانات');

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
      try {
        lastMessage = await _getLastWholesaleMessage(requestId);
        unreadCount = await _getUnreadCount(requestId);
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

      // محاولة جلب رسائل من جدول wholesale_messages أولاً
      print(
        '🔍 البحث عن الرسائل بـ conversation_id = $requestId في wholesale_messages',
      );

      try {
        final response = await _supabaseService.client!
            .from('wholesale_messages')
            .select('*')
            .eq('conversation_id', requestId)
            .order('created_at', ascending: true);

        print('✅ استجابة wholesale_messages: ${response.length} رسالة');

        if (response.isEmpty) {
          print('⚠️ لم يتم العثور على رسائل في wholesale_messages');
          print('🔍 محاولة البحث في جميع الرسائل للتأكد...');

          // محاولة جلب جميع الرسائل للتشخيص
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
        return [];
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

      final messageData = {
        'conversation_id': requestId,
        'sender_type': 'admin',
        'sender_id': currentUser.id,
        'type': type,
        'message': message,
        'media_url': mediaUrl,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      };

      print('📊 بيانات الرسالة: $messageData');

      // محاولة إدراج في جدول wholesale_messages أولاً
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
        rethrow;
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
        return false;
      }

      print('تحديث حالة طلب الجملة $requestId إلى $status');

      await _supabaseService.client!
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

  // تحديث حالة الرسائل كمقروءة عند فتح المحادثة (نسخة من support_messages)
  Future<void> markWholesaleMessagesAsRead(String requestId) async {
    try {
      print('📖 تحديث الرسائل كمقروءة لطلب الجملة: $requestId');

      final client = _supabaseService.client!;

      // تحديث رسائل المستخدمين فقط كمقروءة (نفس منطق support_messages)
      await client
          .from('wholesale_messages')
          .update({'is_read': true})
          .eq('conversation_id', requestId)
          .eq('sender_type', 'user')
          .eq('is_read', false);

      print('✅ تم تحديث الرسائل كمقروءة بنجاح');
    } catch (e) {
      print('خطأ في تحديث حالة الرسائل: $e');
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

  // الحصول على عدد الرسائل غير المقروءة (نسخة من support_messages)
  Future<int> _getUnreadCount(String requestId) async {
    try {
      print('🔍 حساب الرسائل غير المقروءة لطلب الجملة: $requestId');

      final client = _supabaseService.client!;

      // حساب الرسائل غير المقروءة من المستخدمين فقط (نفس منطق support_messages)
      final unreadMessages = await client
          .from('wholesale_messages')
          .select('id, message, created_at')
          .eq('conversation_id', requestId)
          .eq('sender_type', 'user')
          .eq('is_read', false);

      final count = unreadMessages.length;
      print('📊 عدد الرسائل غير المقروءة في طلب الجملة: $count');

      return count;
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
