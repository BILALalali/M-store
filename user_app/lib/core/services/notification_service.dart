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
      // إعدادات Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

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

      // إنشاء قناة الإشعارات لـ Android (مهم جداً!)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // إنشاء قناة الإشعارات
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            'messages_channel', // يجب أن يطابق channelId في showNewMessageNotification
            'رسائل المحادثات',
            description: 'إشعارات الرسائل الجديدة في المحادثات',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          );
          
          await androidPlugin.createNotificationChannel(channel);
          print('✅ تم إنشاء قناة الإشعارات للأندرويد');
          
          // طلب الأذونات لـ Android 13+
          await androidPlugin.requestNotificationsPermission();
          print('✅ تم طلب أذونات الإشعارات');
        }
      }

      // طلب الأذونات لـ iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
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
    // يمكن إضافة معالجة إضافية هنا للانتقال إلى شاشة المحادثة
  }

  /// إظهار إشعار رسالة جديدة
  Future<void> showNewMessageNotification({
    required String conversationId,
    required String orderName,
    required String messageText,
    int notificationId = 0,
  }) async {
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
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        // استخدام الألوان المتوافقة مع الهوية البصرية
        color: const Color(0xFF1EC6D9), // اللون التركواز من الهوية البصرية
        styleInformation: BigTextStyleInformation(
          messageText,
          contentTitle: orderName,
        ),
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

  /// إلغاء جميع الإشعارات
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// إلغاء إشعار محدد
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}

