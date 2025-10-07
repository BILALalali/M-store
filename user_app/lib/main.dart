import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/other_services_screen.dart';
import 'presentation/screens/delivery_services_screen.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/game_cards_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.init();
    print('تم الاتصال بقاعدة البيانات بنجاح');
  } catch (e) {
    print('فشل في الاتصال بقاعدة البيانات: $e');
    print('سيتم استخدام البيانات المحلية');
  }

  // تهيئة خدمة الإشعارات
  try {
    await NotificationService().initialize();
    print('تم تهيئة خدمة الإشعارات بنجاح');
  } catch (e) {
    print('فشل في تهيئة خدمة الإشعارات: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  
  const MyApp({super.key});

  // Routes configuration
  static final Map<String, WidgetBuilder> _routes = {
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/home': (context) => HomeScreen(),
    '/main': (context) => MainScreen(),
    '/service1': (context) =>
        const OtherServicePlaceholderScreen(title: 'دفع فاتورة'),
    '/service2': (context) =>
        const OtherServicePlaceholderScreen(title: 'تحويل رصيد'),
    '/service3': (context) => const DeliveryServicesScreen(),
    '/game-cards': (context) => const GameCardsScreen(),
    '/chat': (context) => const ChatScreen(),
  };

  // Localization configuration
  static const List<LocalizationsDelegate<dynamic>> _localizationDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> _supportedLocales = [Locale('ar')];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق المستخدم',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: _routes,
      locale: const Locale('ar'),
      supportedLocales: _supportedLocales,
      localizationsDelegates: _localizationDelegates,
    );
  }
}
