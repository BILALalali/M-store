import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// خدمة الإشعارات المحلية
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('🔔 بدء تهيئة خدمة الإشعارات...');
      
      // إعدادات Android
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // إعدادات iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // إعدادات التهيئة
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // تهيئة الإشعارات
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      print('✅ تم تهيئة الإشعارات الأساسية');

      // إنشاء قناة الإشعارات لـ Android (مهم جداً!)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidPlugin != null) {
          // إنشاء قناة الإشعارات
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            'messages_channel', // يجب أن يطابق channelId في showNewMessageNotification
            'رسائل المحادثات',
            description: 'إشعارات الرسائل الجديدة في المحادثات',
            importance: Importance.max, // أعلى مستوى من الأهمية
            playSound: true,
            enableVibration: true,
            showBadge: true,
            enableLights: true,
            ledColor: Color(0xFF1EC6D9),
          );

          await androidPlugin.createNotificationChannel(channel);

          // إنشاء قناة إشعارات الدعم
          const AndroidNotificationChannel supportChannel =
              AndroidNotificationChannel(
                'support_channel',
                'رسائل فريق الدعم',
                description: 'إشعارات الرسائل الجديدة من فريق الدعم',
                importance: Importance.max,
                playSound: true,
                enableVibration: true,
                showBadge: true,
                enableLights: true,
                ledColor: Color(0xFF1EC6D9),
              );

          await androidPlugin.createNotificationChannel(supportChannel);
          print('✅ تم إنشاء قنوات الإشعارات للأندرويد');

          // طلب الأذونات لـ Android 13+
          final permissionResult = await androidPlugin.requestNotificationsPermission();
          print('🔐 نتيجة طلب الأذونات: $permissionResult');
          
          // التحقق من حالة الأذونات
          final areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
          print('🔔 حالة الإشعارات: $areNotificationsEnabled');
          
          if (areNotificationsEnabled == false) {
            print('⚠️ الإشعارات غير مفعلة! يرجى تفعيلها من إعدادات التطبيق');
          }
        }
      }

      // طلب الأذونات لـ iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        print('✅ تم طلب أذونات iOS');
      }

      _initialized = true;
      print('✅ تم تهيئة خدمة الإشعارات بنجاح');
    } catch (e) {
      print('❌ خطأ في تهيئة خدمة الإشعارات: $e');
      print('تفاصيل الخطأ: ${e.toString()}');
    }
  }

  /// معالج النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    print('تم النقر على الإشعار: ${response.payload}');

    // معالجة النقر على الإشعارات
    if (response.payload != null) {
      if (response.payload == 'support_chat') {
        // الانتقال إلى شاشة الدعم
        _navigateToSupportChat();
      } else {
        // الانتقال إلى محادثة الطلب
        _navigateToOrderChat(response.payload!);
      }
    }
  }

  /// الانتقال إلى شاشة الدعم
  void _navigateToSupportChat() {
    // يمكن إضافة منطق الانتقال هنا
    print('الانتقال إلى شاشة الدعم');
  }

  /// الانتقال إلى محادثة الطلب
  void _navigateToOrderChat(String conversationId) {
    // يمكن إضافة منطق الانتقال هنا
    print('الانتقال إلى محادثة الطلب: $conversationId');
  }

  /// إظهار إشعار رسالة جديدة من الطلبات
  Future<void> showNewMessageNotification({
    required String conversationId,
    required String orderName,
    required String messageText,
    int notificationId = 0,
  }) async {
    print('🔔 محاولة إظهار إشعار طلب: $orderName');
    print('📝 النص: $messageText');
    print('🆔 معرف المحادثة: $conversationId');

    if (!_initialized) {
      print('⚠️ خدمة الإشعارات غير مهيأة');
      return;
    }

    try {
      // إعدادات Android
      final androidDetails = AndroidNotificationDetails(
        'messages_channel', // معرف القناة
        'رسائل المحادثات', // اسم القناة
        channelDescription: 'إشعارات الرسائل الجديدة في المحادثات',
        importance: Importance.max, // أعلى مستوى من الأهمية
        priority: Priority.max, // أعلى مستوى من الأولوية
        showWhen: true,
        enableVibration: true,
        playSound: true,
        enableLights: true, // تفعيل الضوء
        ledColor: const Color(0xFF1EC6D9), // لون الضوء
        ledOnMs: 1000,
        ledOffMs: 500,
        // استخدام الألوان المتوافقة مع الهوية البصرية
        color: const Color(0xFF1EC6D9), // اللون التركواز من الهوية البصرية
        styleInformation: BigTextStyleInformation(
          messageText,
          contentTitle: orderName,
          htmlFormatBigText: true,
        ),
        fullScreenIntent: true, // إظهار كامل الشاشة
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
      );

      // إعدادات iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // إعدادات الإشعار
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // إظهار الإشعار
      await _notifications.show(
        notificationId, // معرف الإشعار (يمكن استخدام hash للـ conversationId)
        orderName,
        messageText,
        notificationDetails,
        payload: conversationId, // بيانات إضافية للاستخدام عند النقر
      );

      print('✅ تم إظهار إشعار رسالة جديدة: $orderName');
      print('📱 معرف الإشعار: $notificationId');
      print('💬 النص: $messageText');
    } catch (e) {
      print('❌ خطأ في إظهار الإشعار: $e');
    }
  }

  /// إظهار إشعار رسالة جديدة من فريق الدعم
  Future<void> showSupportMessageNotification({
    required String messageText,
    int notificationId = 9999, // معرف مختلف لإشعارات الدعم
  }) async {
    print('🔔 محاولة إظهار إشعار دعم');
    print('📝 النص: $messageText');
    print('🆔 معرف الإشعار: $notificationId');

    if (!_initialized) {
      print('⚠️ خدمة الإشعارات غير مهيأة');
      return;
    }

    try {
      // إعدادات Android
      final androidDetails = AndroidNotificationDetails(
        'support_channel', // قناة منفصلة للدعم
        'رسائل فريق الدعم', // اسم القناة
        channelDescription: 'إشعارات الرسائل الجديدة من فريق الدعم',
        importance: Importance.max, // أعلى مستوى من الأهمية
        priority: Priority.max, // أعلى مستوى من الأولوية
        showWhen: true,
        enableVibration: true,
        playSound: true,
        enableLights: true, // تفعيل الضوء
        ledColor: const Color(0xFF1EC6D9), // لون الضوء
        ledOnMs: 1000,
        ledOffMs: 500,
        color: const Color(0xFF1EC6D9), // اللون التركواز من الهوية البصرية
        styleInformation: BigTextStyleInformation(
          messageText,
          contentTitle: 'رسالة جديدة من فريق الدعم',
          htmlFormatBigText: true,
        ),
        fullScreenIntent: true, // إظهار كامل الشاشة
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
      );

      // إعدادات iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // إعدادات الإشعار
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // إظهار الإشعار
      await _notifications.show(
        notificationId,
        'رسالة جديدة من فريق الدعم',
        messageText,
        notificationDetails,
        payload: 'support_chat', // معرف للانتقال إلى شاشة الدعم
      );

      print('✅ تم إظهار إشعار رسالة دعم جديدة');
      print('📱 معرف الإشعار: $notificationId');
      print('💬 النص: $messageText');
    } catch (e) {
      print('❌ خطأ في إظهار إشعار الدعم: $e');
    }
  }

  /// إلغاء جميع الإشعارات
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// إلغاء إشعار محدد
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// فحص حالة أذونات الإشعارات
  Future<bool> areNotificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final result = await androidPlugin.areNotificationsEnabled();
        return result ?? false;
      }
    }
    return true; // افتراضياً مفعلة في iOS
  }

  /// طلب تفعيل الإشعارات من المستخدم
  Future<void> requestNotificationPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }
}
