import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// خدمة الإشعارات المبسطة والمضمونة
class SimpleNotificationService {
  static final SimpleNotificationService _instance = SimpleNotificationService._internal();
  factory SimpleNotificationService() => _instance;
  SimpleNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// تهيئة بسيطة ومضمونة
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('🔔 بدء تهيئة الإشعارات المبسطة...');

      // إعدادات Android بسيطة
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // إعدادات iOS محسنة
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
        requestProvisionalPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      // إعدادات التهيئة
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // تهيئة الإشعارات
      await _notifications.initialize(initSettings);
      print('✅ تم تهيئة الإشعارات المبسطة');

      // إنشاء قناة بسيطة للأندرويد
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // قناة محسنة للخلفية
          const channel = AndroidNotificationChannel(
            'simple_channel',
            'إشعارات التطبيق',
            description: 'إشعارات بسيطة من التطبيق',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
            enableLights: true,
            ledColor: Color(0xFF1EC6D9),
          );
          
          await androidPlugin.createNotificationChannel(channel);
          print('✅ تم إنشاء قناة الإشعارات البسيطة');
          
          // طلب الأذونات
          await androidPlugin.requestNotificationsPermission();
          print('✅ تم طلب أذونات الإشعارات');
        }
      }

      // طلب الأذونات لـ iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        
        if (iosPlugin != null) {
          final result = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
            provisional: true,
          );
          print('🔐 نتيجة طلب أذونات iOS: $result');
          
          // التحقق من حالة الأذونات
          final areEnabled = await iosPlugin.checkPermissions();
          print('🔔 حالة أذونات iOS: $areEnabled');
        }
        print('✅ تم طلب أذونات iOS');
      }

      _initialized = true;
      print('✅ تم تهيئة الإشعارات المبسطة بنجاح');
    } catch (e) {
      print('❌ خطأ في تهيئة الإشعارات المبسطة: $e');
    }
  }

  /// إظهار إشعار بسيط ومضمون
  Future<void> showSimpleNotification({
    required String title,
    required String body,
    int id = 1,
  }) async {
    if (!_initialized) {
      print('⚠️ الإشعارات غير مهيأة');
      return;
    }

    try {
      print('🔔 محاولة إظهار إشعار بسيط: $title');
      
      // إعدادات Android محسنة للخلفية
      const androidDetails = AndroidNotificationDetails(
        'simple_channel',
        'إشعارات التطبيق',
        channelDescription: 'إشعارات بسيطة من التطبيق',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        color: Color(0xFF1EC6D9),
        fullScreenIntent: true, // إشعار كامل الشاشة
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        ongoing: false, // لا تبقى ثابتة
        autoCancel: true, // تختفي عند النقر
        silent: false, // مع صوت
        enableLights: true, // تفعيل الضوء
        ledColor: Color(0xFF1EC6D9),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      // إعدادات iOS محسنة
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        sound: 'default',
        badgeNumber: 1,
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: 'message_category',
        threadIdentifier: 'message_thread',
      );

      // إعدادات الإشعار
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // إظهار الإشعار
      await _notifications.show(id, title, body, notificationDetails);
      
      print('✅ تم إظهار الإشعار البسيط بنجاح');
      print('📱 العنوان: $title');
      print('📝 النص: $body');
    } catch (e) {
      print('❌ خطأ في إظهار الإشعار البسيط: $e');
    }
  }

  /// اختبار الإشعارات
  Future<void> testNotifications() async {
    print('🧪 بدء اختبار الإشعارات البسيطة...');
    
    // اختبار إشعار الدعم
    await showSimpleNotification(
      title: 'رسالة من فريق الدعم',
      body: 'مرحباً! هذه رسالة تجريبية من فريق الدعم',
      id: 1001,
    );
    
    // انتظار ثانيتين
    await Future.delayed(const Duration(seconds: 2));
    
    // اختبار إشعار الطلب
    await showSimpleNotification(
      title: 'رسالة من الإدارة',
      body: 'تم تحديث حالة طلبك. يرجى المراجعة',
      id: 1002,
    );
    
    print('✅ انتهى اختبار الإشعارات البسيطة');
  }

  /// إظهار إشعار رسالة دعم جديدة
  Future<void> showSupportMessageNotification({
    required String messageText,
    int id = 1001,
  }) async {
    await showSimpleNotification(
      title: 'رسالة من فريق الدعم',
      body: messageText,
      id: id,
    );
  }

  /// إظهار إشعار رسالة طلب جديدة
  Future<void> showOrderMessageNotification({
    required String orderName,
    required String messageText,
    int id = 2001,
  }) async {
    await showSimpleNotification(
      title: 'رسالة من الإدارة - $orderName',
      body: messageText,
      id: id,
    );
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
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      if (iosPlugin != null) {
        final permissions = await iosPlugin.checkPermissions();
        return permissions?.isEnabled ?? false;
      }
    }
    return true; // افتراضياً مفعلة
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
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
          provisional: true,
        );
      }
    }
  }

  /// إلغاء جميع الإشعارات
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('🗑️ تم إلغاء جميع الإشعارات');
  }
}
