import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_thread.dart';
import '../models/order_message.dart';
import 'supabase_service.dart';
import 'dart:async';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  final StreamController<List<OrderThread>> _ordersController =
      StreamController<List<OrderThread>>.broadcast();
  final StreamController<List<OrderMessage>> _messagesController =
      StreamController<List<OrderMessage>>.broadcast();

  Stream<List<OrderThread>> get ordersStream => _ordersController.stream;
  Stream<List<OrderMessage>> get messagesStream => _messagesController.stream;

  RealtimeChannel? _ordersSubscription;
  RealtimeChannel? _messagesSubscription;

  void startRealtimeSubscriptions() {
    if (!_supabaseService.isReady) return;

    final client = _supabaseService.client!;

    _ordersSubscription = client
        .channel('order_threads_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'order_threads',
          callback: (payload) {
            print('🔄 تغيير في الطلبات: ${payload.eventType}');
            _handleOrdersChange(payload);
          },
        )
        .subscribe();

    print('✅ تم بدء الاستماع للتحديثات في الوقت الفعلي للطلبات');
  }

  void stopRealtimeSubscriptions() {
    _ordersSubscription?.unsubscribe();
    _messagesSubscription?.unsubscribe();
    _ordersSubscription = null;
    _messagesSubscription = null;
    print('🛑 تم إيقاف الاستماع للتحديثات في الوقت الفعلي للطلبات');
  }

  void _handleOrdersChange(PostgresChangePayload payload) async {
    print('📊 معالجة تغيير في الطلبات...');

    try {
      final updatedOrders = await getOrders();
      _ordersController.add(updatedOrders);

      print('✅ تم تحديث قائمة الطلبات: ${updatedOrders.length} طلب');
    } catch (e) {
      print('❌ خطأ في معالجة تغيير الطلبات: $e');
    }
  }

  void dispose() {
    stopRealtimeSubscriptions();
    _ordersController.close();
    _messagesController.close();
  }

  Future<bool> testDatabaseConnection() async {
    try {
      if (!_supabaseService.isReady) {
        print('Supabase غير مهيأ');
        return false;
      }

      print('اختبار الاتصال بجدول الطلبات...');

      final ordersTest = await _supabaseService.client!
          .from('order_threads')
          .select('count')
          .limit(1);

      print('اختبار جدول الطلبات: $ordersTest');

      final sampleOrders = await _supabaseService.client!
          .from('order_threads')
          .select('*')
          .limit(5);

      print('عينة من الطلبات: $sampleOrders');

      return true;
    } catch (e) {
      print('خطأ في اختبار الاتصال بجدول الطلبات: $e');
      return false;
    }
  }

  Future<List<OrderThread>> getOrders() async {
    try {
      if (!_supabaseService.isReady) {
        print('Supabase غير مهيأ');
        return [];
      }

      print('🚀 ===== بدء جلب الطلبات =====');

      final client = _supabaseService.client!;

      // جلب جميع الطلبات
      print('🔍 إرسال استعلام إلى جدول order_threads...');
      final response = await client
          .from('order_threads')
          .select('*')
          .order('updated_at', ascending: false);

      print('✅ استجابة قاعدة البيانات: ${response.length} طلب');
      print('📋 البيانات المستلمة: $response');

      final orders = <OrderThread>[];

      for (var item in response) {
        print(
          '🚀 ===== معالجة طلب: ID=${item['id']}, user_id=${item['user_id']} =====',
        );

        String? userName;
        String? userEmail;

        // جلب معلومات المستخدم
        try {
          final userId = item['user_id'];
          if (userId != null) {
            final profileResponse = await _supabaseService.client!
                .from('profiles')
                .select('name')
                .eq('id', userId)
                .maybeSingle();

            if (profileResponse != null && profileResponse['name'] != null) {
              userName = profileResponse['name'];
              print('✅ تم جلب اسم المستخدم: $userName');
            } else {
              userName = 'مستخدم ${userId.toString().substring(0, 8)}';
              print('❌ لم يتم العثور على الاسم، استخدام المعرف: $userName');
            }
          } else {
            userName = 'مستخدم غير محدد';
            print('❌ معرف المستخدم مفقود');
          }
        } catch (profileError) {
          print('❌ خطأ في جلب الاسم: $profileError');
          final userId = item['user_id']?.toString() ?? 'unknown';
          userName =
              'مستخدم ${userId.length > 8 ? userId.substring(0, 8) : userId}';
        }

        // جلب آخر رسالة (إذا كان هناك نظام رسائل للطلبات)
        OrderMessage? lastMessage;
        int unreadCount = 0;
        bool hasAdminMessage = false;
        DateTime? firstAdminMessageAt;
        try {
          lastMessage = await _getLastOrderMessage(item['id']);
          unreadCount = await _getUnreadCount(item['id']);

          // فحص ما إذا كان المشرف قد أرسل أي رسالة
          final adminMessages = await _getAdminMessages(item['id']);
          hasAdminMessage = adminMessages.isNotEmpty;
          if (hasAdminMessage) {
            firstAdminMessageAt = adminMessages.first.createdAt;
          }
        } catch (e) {
          print(
            'تحذير: لا يمكن جلب رسائل الطلب (قد لا يكون النظام مُعَد بعد): $e',
          );
        }

        print(
          '📊 الطلب ${item['id']}: unreadCount = $unreadCount, hasAdminMessage = $hasAdminMessage',
        );

        final hasUnreadMessages = unreadCount > 0;

        // معالجة البيانات الفارغة أو المفقودة
        final String title = item['title']?.toString().trim() ?? '';
        final String productNames =
            item['product_names']?.toString().trim() ?? '';
        final String summary = item['summary']?.toString().trim() ?? '';

        // إذا كان العنوان فارغ، استخدم اسم المنتجات أو معرف مختصر
        final String displayTitle = title.isNotEmpty
            ? title
            : productNames.isNotEmpty
            ? productNames
            : 'طلب ${item['id'].toString().substring(0, 8)}';

        // معالجة حقول التاريخ بشكل آمن
        DateTime createdAt = DateTime.now();
        DateTime updatedAt = DateTime.now();

        try {
          createdAt = DateTime.parse(item['created_at']);
        } catch (e) {
          print('❌ خطأ في تحليل created_at: $e');
        }

        try {
          updatedAt = DateTime.parse(item['updated_at']);
        } catch (e) {
          print('❌ خطأ في تحليل updated_at: $e');
        }

        orders.add(
          OrderThread(
            id: item['id']?.toString() ?? 'unknown',
            userId: item['user_id']?.toString() ?? 'unknown',
            title: displayTitle,
            productNames: productNames.isNotEmpty ? productNames : null,
            summary: summary.isNotEmpty ? summary : null,
            orderType: item['order_type']?.toString() ?? 'retail',
            status: item['status']?.toString() ?? 'pending',
            imageUrl: item['image_url']?.toString(),
            createdAt: createdAt,
            updatedAt: updatedAt,
            userName: userName,
            userEmail: userEmail,
            lastMessage: lastMessage?.message,
            lastMessageAt: lastMessage?.createdAt,
            unreadCount: unreadCount,
            hasUnreadMessages: hasUnreadMessages,
            hasAdminMessage: hasAdminMessage,
            firstAdminMessageAt: firstAdminMessageAt,
          ),
        );

        print('✅ تم إضافة الطلب: $displayTitle');

        print('🚀 ===== انتهاء معالجة الطلب: ${item['id']} =====');
      }

      print('🚀 ===== انتهاء جلب الطلبات: ${orders.length} طلب =====');

      // إرسال البيانات للـ stream
      _ordersController.add(orders);

      return orders;
    } catch (e) {
      print('❌ خطأ في جلب الطلبات: $e');
      print('❌ تفاصيل الخطأ: ${e.toString()}');

      // محاولة إضافية للحصول على معلومات أكثر عن الخطأ
      if (e.toString().contains('permission') || e.toString().contains('RLS')) {
        print('❌ قد تكون هناك مشكلة في تصاريح قاعدة البيانات (RLS Policies)');
      }

      return [];
    }
  }

  // الحصول على طلب محدد
  Future<OrderThread?> getOrder(String orderId) async {
    try {
      if (!_supabaseService.isReady) {
        return null;
      }

      print('جلب الطلب: $orderId');

      final response = await _supabaseService.client!
          .from('order_threads')
          .select('*')
          .eq('id', orderId)
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
      OrderMessage? lastMessage;
      int unreadCount = 0;
      bool hasAdminMessage = false;
      DateTime? firstAdminMessageAt;
      try {
        lastMessage = await _getLastOrderMessage(orderId);
        unreadCount = await _getUnreadCount(orderId);

        // فحص ما إذا كان المشرف قد أرسل أي رسالة
        final adminMessages = await _getAdminMessages(orderId);
        hasAdminMessage = adminMessages.isNotEmpty;
        if (hasAdminMessage) {
          firstAdminMessageAt = adminMessages.first.createdAt;
        }
      } catch (e) {
        print('تحذير: لا يمكن جلب رسائل الطلب: $e');
      }

      return OrderThread(
        id: response['id'],
        userId: userId,
        title: response['title'] ?? '',
        productNames: response['product_names'],
        summary: response['summary'],
        orderType: response['order_type'] ?? 'retail',
        status: response['status'] ?? 'pending',
        imageUrl: response['image_url'],
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
      print('خطأ في جلب الطلب: $e');
      return null;
    }
  }

  // الحصول على رسائل طلب محدد
  Future<List<OrderMessage>> getOrderMessages(String orderId) async {
    try {
      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return [];
      }

      print('🔍 ==== بدء جلب رسائل الطلب ====');
      print('📋 معرف الطلب: $orderId');
      print(
        '👤 المستخدم الحالي: ${_supabaseService.currentUser?.id ?? 'غير مسجل'}',
      );

      // جلب رسائل من جدول order_messages باستخدام conversation_id
      print('🔍 البحث عن الرسائل بـ conversation_id = $orderId');

      final response = await _supabaseService.client!
          .from('order_messages')
          .select('*')
          .eq('conversation_id', orderId)
          .order('created_at', ascending: true);

      print('✅ استجابة قاعدة البيانات: ${response.length} رسالة');

      if (response.isEmpty) {
        print('⚠️ لم يتم العثور على رسائل');
        print('🔍 محاولة البحث في جميع الرسائل للتأكد...');

        // محاولة جلب جميع الرسائل للتشخيص
        final allMessages = await _supabaseService.client!
            .from('order_messages')
            .select('conversation_id, sender_type, message, created_at')
            .limit(10);

        print('📊 عينة من الرسائل الموجودة:');
        for (var msg in allMessages) {
          print(
            '   - conversation_id: ${msg['conversation_id']}, sender: ${msg['sender_type']}, message: ${msg['message']}',
          );
        }
      } else {
        print('📋 تفاصيل الرسائل المستلمة:');
        for (var msg in response) {
          print(
            '   - ID: ${msg['id']}, sender: ${msg['sender_type']}, message: ${msg['message']}',
          );
        }
      }

      final processedMessages = _processOrderMessages(response);
      print('✅ تم معالجة ${processedMessages.length} رسالة بنجاح');
      print('🔍 ==== انتهاء جلب رسائل الطلب ====');

      return processedMessages;
    } catch (e) {
      print('❌ خطأ في جلب رسائل الطلب: $e');
      print('❌ نوع الخطأ: ${e.runtimeType}');
      print('❌ تفاصيل الخطأ: ${e.toString()}');
      return [];
    }
  }

  // إرسال رسالة للطلب
  Future<OrderMessage?> sendOrderMessage({
    required String orderId,
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

      print('📤 ==== بدء إرسال رسالة جديدة ====');
      print('📋 معرف الطلب: $orderId');
      print('👤 المرسل: ${currentUser.id} (admin)');
      print('💬 الرسالة: $message');

      final messageData = {
        'conversation_id': orderId,
        'sender_type': 'admin',
        'sender_id': currentUser.id,
        'type': type,
        'message': message,
        'media_url': mediaUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      print('📊 بيانات الرسالة: $messageData');

      final response = await _supabaseService.client!
          .from('order_messages')
          .insert(messageData)
          .select()
          .single();

      print('✅ تم إدراج الرسالة في قاعدة البيانات: ${response['id']}');

      await _updateOrderTimestamp(orderId);

      // إضافة اسم المرسل
      final processedResponse = Map<String, dynamic>.from(response);
      processedResponse['sender_name'] = 'فريق الدعم';

      final orderMessage = OrderMessage.fromJson(processedResponse);
      print('✅ تم إنشاء كائن OrderMessage بنجاح');
      print('📤 ==== انتهاء إرسال الرسالة ====');

      return orderMessage;
    } catch (e) {
      print('❌ خطأ في إرسال رسالة الطلب: $e');
      print('❌ نوع الخطأ: ${e.runtimeType}');
      print('❌ تفاصيل الخطأ: ${e.toString()}');
      rethrow;
    }
  }

  // تحديث حالة الطلب
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      if (!_supabaseService.isReady) {
        return false;
      }

      print('تحديث حالة الطلب $orderId إلى $status');

      await _supabaseService.client!
          .from('order_threads')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      print('✅ تم تحديث حالة الطلب بنجاح');
      return true;
    } catch (e) {
      print('❌ خطأ في تحديث حالة الطلب: $e');
      return false;
    }
  }

  // حل نهائي باستخدام RPC function المحسنة
  Future<int> _forceUpdateMessagesAsRead(String orderId) async {
    try {
      print('🔧 استخدام RPC function المحسنة...');

      final client = _supabaseService.client!;

      // استخدام الدالة الجديدة المحسنة
      final result = await client.rpc(
        'mark_order_messages_as_read',
        params: {'conversation_id_param': orderId},
      );

      print('✅ نتيجة RPC المحسنة: $result');

      // التحقق من النتيجة
      final verificationResult = await client.rpc(
        'get_unread_count_for_conversation',
        params: {'conversation_id_param': orderId},
      );

      print('🔍 عدد الرسائل غير المقروءة بعد التحديث: $verificationResult');

      return result as int? ?? 0;
    } catch (e) {
      print('❌ فشل في RPC function: $e');

      // محاولة بديلة: تحديث مباشر مع تجاهل RLS
      try {
        print('🔧 محاولة تحديث مباشر مع تجاهل RLS...');
        final client = _supabaseService.client!;

        // جلب الرسائل غير المقروءة
        final unreadMessages = await client
            .from('order_messages')
            .select('id, message')
            .eq('conversation_id', orderId)
            .eq('sender_type', 'user')
            .eq('is_read', false);

        print('📊 عدد الرسائل غير المقروءة للتحديث: ${unreadMessages.length}');

        if (unreadMessages.isEmpty) {
          print('ℹ️ لا توجد رسائل غير مقروءة');
          return 0;
        }

        // طباعة تفاصيل الرسائل
        for (var msg in unreadMessages) {
          print('📄 رسالة غير مقروءة: ${msg['id']} - "${msg['message']}"');
        }

        int successCount = 0;

        // تحديث كل رسالة بشكل منفصل
        for (var message in unreadMessages) {
          try {
            print('🔄 محاولة تحديث رسالة: ${message['id']}');

            final updateResult = await client
                .from('order_messages')
                .update({
                  'is_read': true,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', message['id'])
                .select();

            if (updateResult.isNotEmpty) {
              print('✅ نجح تحديث رسالة: ${message['id']}');
              successCount++;
            } else {
              print('❌ فشل تحديث رسالة: ${message['id']} - لم يتم إرجاع نتيجة');
            }
          } catch (singleError) {
            print('❌ خطأ في تحديث رسالة ${message['id']}: $singleError');
          }

          // انتظار قصير بين المحاولات
          await Future.delayed(const Duration(milliseconds: 200));
        }

        print(
          '📊 النتيجة النهائية: تم تحديث $successCount من أصل ${unreadMessages.length} رسالة',
        );
        return successCount;
      } catch (finalError) {
        print('❌ فشل في المحاولة البديلة: $finalError');
        return 0;
      }
    }
  }

  // تحديث حالة الرسائل كمقروءة عند فتح المحادثة من تطبيق المشرف
  Future<int> markOrderMessagesAsRead(String orderId) async {
    try {
      print('📖 ==== بدء تحديث الرسائل كمقروءة ====');
      print('🔍 معرف الطلب: $orderId');

      if (!_supabaseService.isReady) {
        print('❌ Supabase غير مهيأ');
        return 0;
      }

      final client = _supabaseService.client!;

      // أولاً: محاولة استخدام RPC function إذا كانت موجودة
      try {
        print('🚀 محاولة استخدام RPC function...');

        final rpcResult = await client.rpc(
          'mark_order_messages_as_read',
          params: {'conversation_id_param': orderId},
        );

        final updatedCount = rpcResult as int? ?? 0;
        print('✅ نجح RPC function! تم تحديث $updatedCount رسالة');

        if (updatedCount > 0) {
          // التحقق من النتيجة
          final verifyCount = await client.rpc(
            'get_unread_count_for_conversation',
            params: {'conversation_id_param': orderId},
          );

          print('🔍 عدد الرسائل غير المقروءة المتبقية: $verifyCount');
          print('🎉 تم حل المشكلة باستخدام RPC function!');
          return updatedCount;
        }
      } catch (rpcError) {
        print('❌ RPC function غير متوفرة أو فشلت: $rpcError');
        print('🔄 التحول إلى الطريقة التقليدية...');
      }

      // فحص المستخدم الحالي
      final currentUser = _supabaseService.currentUser;
      print('👤 المستخدم الحالي: ${currentUser?.id ?? 'غير مسجل'}');
      print(
        '🔑 دور المستخدم: ${currentUser?.userMetadata?['role'] ?? 'غير محدد'}',
      );

      // أولاً: عرض جميع الرسائل في المحادثة للتشخيص
      print('🔍 جلب جميع الرسائل في المحادثة...');
      final allMessages = await client
          .from('order_messages')
          .select(
            'id, message, sender_type, is_read, created_at, conversation_id',
          )
          .eq('conversation_id', orderId)
          .order('created_at', ascending: true);

      print('📊 إجمالي الرسائل في المحادثة: ${allMessages.length}');

      if (allMessages.isNotEmpty) {
        print('📋 تفاصيل جميع الرسائل:');
        for (var msg in allMessages) {
          print(
            '   - ID: ${msg['id']}, Type: ${msg['sender_type']}, Read: ${msg['is_read']}, Text: "${msg['message']}"',
          );
        }
      } else {
        print('⚠️ لم يتم العثور على أي رسائل في المحادثة!');
        return 0;
      }

      // فلترة الرسائل غير المقروءة من المستخدمين
      final unreadUserMessages = allMessages
          .where(
            (msg) => msg['sender_type'] == 'user' && msg['is_read'] == false,
          )
          .toList();

      print('🆕 عدد رسائل المستخدم غير المقروءة: ${unreadUserMessages.length}');

      if (unreadUserMessages.isEmpty) {
        print('ℹ️ لا توجد رسائل غير مقروءة من المستخدم لتحديثها');
        return 0;
      }

      print('📋 رسائل المستخدم غير المقروءة:');
      for (var msg in unreadUserMessages) {
        print(
          '   - ID: ${msg['id']}, Message: "${msg['message']}", Created: ${msg['created_at']}',
        );
      }

      // ثانياً: محاولة تحديث كل رسالة بشكل منفصل للتشخيص الأفضل
      print('🔄 بدء تحديث الرسائل واحدة تلو الأخرى...');
      int successCount = 0;
      List<String> failedIds = [];

      for (var msg in unreadUserMessages) {
        try {
          print('   🔄 تحديث الرسالة: ${msg['id']}');

          final singleUpdateResult = await client
              .from('order_messages')
              .update({'is_read': true})
              .eq('id', msg['id'])
              .select();

          if (singleUpdateResult.isNotEmpty) {
            print('   ✅ تم تحديث الرسالة: ${msg['id']} بنجاح');
            successCount++;
          } else {
            print('   ❌ فشل تحديث الرسالة: ${msg['id']} - لم يتم إرجاع نتيجة');
            failedIds.add(msg['id']);
          }
        } catch (singleError) {
          print('   ❌ خطأ في تحديث الرسالة: ${msg['id']} - $singleError');
          failedIds.add(msg['id']);
        }

        // انتظار قصير بين التحديثات
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print('📊 نتائج التحديث الفردي:');
      print('   - نجح: $successCount رسالة');
      print('   - فشل: ${failedIds.length} رسالة');
      if (failedIds.isNotEmpty) {
        print('   - الرسائل الفاشلة: $failedIds');
      }

      // ثالثاً: التحقق النهائي من النتيجة
      print('🔍 التحقق النهائي من حالة الرسائل...');
      final finalCheck = await client
          .from('order_messages')
          .select('id, is_read')
          .eq('conversation_id', orderId)
          .eq('sender_type', 'user');

      final stillUnread = finalCheck
          .where((msg) => msg['is_read'] == false)
          .length;

      print('📊 النتائج النهائية:');
      print('   - رسائل تم تحديثها بنجاح: $successCount');
      print('   - رسائل لا تزال غير مقروءة: $stillUnread');

      if (stillUnread == 0 && successCount > 0) {
        print('🎉 تم تحديث جميع رسائل المستخدم كمقروءة بنجاح!');
      } else if (stillUnread > 0) {
        print('⚠️ لا تزال هناك رسائل غير مقروءة - محاولة الحل المؤقت...');

        // محاولة الحل المؤقت
        final forceResult = await _forceUpdateMessagesAsRead(orderId);
        if (forceResult > 0) {
          print('✅ نجح الحل المؤقت في تحديث $forceResult رسالة');
          return forceResult;
        } else {
          print('❌ فشل الحل المؤقت أيضاً - المشكلة في صلاحيات Supabase');
        }
      }

      print('📖 ==== انتهاء تحديث الرسائل كمقروءة ====');
      return successCount;
    } catch (e) {
      print('❌ خطأ عام في تحديث حالة الرسائل: $e');
      print('❌ نوع الخطأ: ${e.runtimeType}');
      print('❌ تفاصيل الخطأ: ${e.toString()}');

      // طباعة stack trace للمساعدة في التشخيص
      if (e is Exception) {
        print('❌ Stack trace: ${StackTrace.current}');
      }

      return 0;
    }
  }

  // إحصائيات الطلبات
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      if (!_supabaseService.isReady) {
        return _getDefaultOrderStats();
      }

      final client = _supabaseService.client!;

      // إجمالي الطلبات
      final totalOrders = await client.from('order_threads').select('id');

      // الطلبات المعلقة
      final pendingOrders = await client
          .from('order_threads')
          .select('id')
          .eq('status', 'pending');

      // الطلبات المكتملة
      final completedOrders = await client
          .from('order_threads')
          .select('id')
          .eq('status', 'completed');

      // الطلبات قيد المعالجة
      final processingOrders = await client
          .from('order_threads')
          .select('id')
          .eq('status', 'processing');

      return {
        'total_orders': totalOrders.length,
        'pending_orders': pendingOrders.length,
        'completed_orders': completedOrders.length,
        'processing_orders': processingOrders.length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات الطلبات: $e');
      return _getDefaultOrderStats();
    }
  }

  // دوال مساعدة خاصة

  // الحصول على آخر رسالة في الطلب
  Future<OrderMessage?> _getLastOrderMessage(String orderId) async {
    try {
      final response = await _supabaseService.client!
          .from('order_messages')
          .select('*')
          .eq('conversation_id', orderId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        // إضافة اسم المرسل وقيمة افتراضية لـ is_read
        final processedResponse = Map<String, dynamic>.from(response);
        processedResponse['sender_name'] = response['sender_type'] == 'admin'
            ? 'فريق الدعم'
            : 'المستخدم';
        // تم استلام حقل is_read من قاعدة البيانات

        return OrderMessage.fromJson(processedResponse);
      }

      return null;
    } catch (e) {
      print('خطأ في جلب آخر رسالة للطلب: $e');
      return null;
    }
  }

  // الحصول على رسائل المشرف في الطلب
  Future<List<OrderMessage>> _getAdminMessages(String orderId) async {
    try {
      final response = await _supabaseService.client!
          .from('order_messages')
          .select('*')
          .eq('conversation_id', orderId)
          .eq('sender_type', 'admin')
          .order('created_at', ascending: true);

      final processedMessages = _processOrderMessages(response);
      return processedMessages;
    } catch (e) {
      print('خطأ في جلب رسائل المشرف للطلب: $e');
      return [];
    }
  }

  // الحصول على عدد الرسائل غير المقروءة (نسخة من support_messages)
  Future<int> _getUnreadCount(String orderId) async {
    try {
      print('🔍 حساب الرسائل غير المقروءة للطلب: $orderId');

      final client = _supabaseService.client!;

      // حساب الرسائل غير المقروءة من المستخدمين فقط (نفس منطق support_messages)
      final unreadMessages = await client
          .from('order_messages')
          .select('id, message, created_at')
          .eq('conversation_id', orderId)
          .eq('sender_type', 'user')
          .eq('is_read', false);

      final count = unreadMessages.length;
      print('📊 عدد الرسائل غير المقروءة في الطلب: $count');

      return count;
    } catch (e) {
      print('❌ خطأ في حساب الرسائل غير المقروءة: $e');
      return 0;
    }
  }

  // حساب إجمالي الرسائل غير المقروءة من جميع الطلبات (نسخة من support_messages)
  Future<int> getTotalUnreadOrderMessagesCount() async {
    try {
      print('🔍 حساب إجمالي الرسائل غير المقروءة من جميع الطلبات');

      final client = _supabaseService.client!;

      // جلب جميع الرسائل غير المقروءة من المستخدمين (نفس منطق support_messages)
      final result = await client
          .from('order_messages')
          .select('id, message, created_at')
          .eq('sender_type', 'user')
          .eq('is_read', false);

      final count = result.length;
      print('📊 إجمالي الرسائل غير المقروءة في الطلبات: $count');

      // طباعة تفاصيل الرسائل غير المقروءة للتأكد
      for (final msg in result) {
        print(
          '📨 رسالة غير مقروءة: "${msg['message']}" - ${msg['created_at']}',
        );
      }

      return count;
    } catch (e) {
      print('خطأ في حساب إجمالي الرسائل غير المقروءة في الطلبات: $e');
      return 0;
    }
  }

  // حساب عدد الطلبات التي تحتوي على رسائل غير مقروءة (نسخة من support_messages)
  Future<int> getUnreadOrderThreadsCount() async {
    try {
      print('🔍 حساب عدد الطلبات غير المقروءة');

      final client = _supabaseService.client!;

      // جلب جميع الطلبات المفتوحة
      final orderThreads = await client.from('order_threads').select('id');

      int unreadThreads = 0;

      // فحص كل طلب لوجود رسائل غير مقروءة
      for (final thread in orderThreads) {
        final unreadCount = await _getUnreadCount(thread['id']);
        if (unreadCount > 0) {
          unreadThreads++;
        }
      }

      print('📊 عدد الطلبات غير المقروءة: $unreadThreads');
      return unreadThreads;
    } catch (e) {
      print('خطأ في حساب الطلبات غير المقروءة: $e');
      return 0;
    }
  }

  // تحديث وقت آخر تحديث للطلب
  Future<void> _updateOrderTimestamp(String orderId) async {
    try {
      await _supabaseService.client!
          .from('order_threads')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);
    } catch (e) {
      print('خطأ في تحديث وقت الطلب: $e');
    }
  }

  // معالجة رسائل order_messages
  List<OrderMessage> _processOrderMessages(List<dynamic> response) {
    final messages = <OrderMessage>[];

    for (var item in response) {
      try {
        // إضافة اسم المرسل وقيمة افتراضية لـ is_read
        final processedItem = Map<String, dynamic>.from(item);
        processedItem['sender_name'] = item['sender_type'] == 'admin'
            ? 'فريق الدعم'
            : 'المستخدم';
        // تم استلام حقل is_read من قاعدة البيانات
        messages.add(OrderMessage.fromJson(processedItem));
      } catch (e) {
        print('خطأ في معالجة رسالة الطلب: $e');
      }
    }

    return messages;
  }

  Map<String, dynamic> _getDefaultOrderStats() {
    return {
      'total_orders': 0,
      'pending_orders': 0,
      'completed_orders': 0,
      'processing_orders': 0,
    };
  }

  // الاستماع للتحديثات المباشرة للطلبات
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _orderMessagesChannel;

  // بدء الاستماع للتحديثات المباشرة للطلبات
  void startListeningToOrders(Function(List<OrderThread>) onUpdate) {
    try {
      if (!_supabaseService.isReady) return;

      _ordersChannel = _supabaseService.client!
          .channel('order_threads_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'order_threads',
            callback: (payload) async {
              print('تحديث في الطلبات: $payload');
              final orders = await getOrders();
              onUpdate(orders);
            },
          )
          .subscribe();

      print('بدأ الاستماع لتحديثات الطلبات');
    } catch (e) {
      print('خطأ في بدء الاستماع للطلبات: $e');
    }
  }

  // بدء الاستماع للتحديثات المباشرة لرسائل الطلب
  void startListeningToOrderMessages(
    String orderId,
    Function(List<OrderMessage>) onUpdate,
  ) {
    try {
      if (!_supabaseService.isReady) return;

      // إيقاف أي استماع سابق
      stopListeningToOrderMessages();

      print('🔥 بدء الاستماع لرسائل الطلب: $orderId');

      // الاستماع لرسائل order_messages
      _orderMessagesChannel = _supabaseService.client!
          .channel('order_messages_changes_$orderId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'order_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: orderId,
            ),
            callback: (payload) async {
              print('🔔 تحديث في رسائل الطلب: ${payload.eventType}');
              print('📋 تفاصيل التحديث: ${payload.newRecord}');
              try {
                final messages = await getOrderMessages(orderId);
                onUpdate(messages);
                print('✅ تم تحديث الرسائل: ${messages.length} رسالة');
              } catch (e) {
                print('❌ خطأ في تحديث الرسائل: $e');
              }
            },
          )
          .subscribe((status, [error]) {
            print('📡 حالة الاشتراك: $status');
            if (error != null) {
              print('❌ خطأ في الاشتراك: $error');
            }
          });

      print('✅ تم بدء الاستماع لتحديثات رسائل الطلب: $orderId');
    } catch (e) {
      print('❌ خطأ في بدء الاستماع لرسائل الطلب: $e');
    }
  }

  // إيقاف الاستماع لرسائل طلب محدد
  void stopListeningToOrderMessages() {
    try {
      if (_orderMessagesChannel != null) {
        _orderMessagesChannel!.unsubscribe();
        _orderMessagesChannel = null;
        print('🛑 تم إيقاف الاستماع لرسائل الطلب');
      }
    } catch (e) {
      print('❌ خطأ في إيقاف الاستماع لرسائل الطلب: $e');
    }
  }

  // إيقاف الاستماع للتحديثات
  void stopListening() {
    try {
      _ordersChannel?.unsubscribe();
      _ordersChannel = null;
      stopListeningToOrderMessages();
      print('تم إيقاف الاستماع لتحديثات الطلبات');
    } catch (e) {
      print('خطأ في إيقاف الاستماع: $e');
    }
  }
}
