import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/services/supabase_service.dart';
import 'presentation/screens/other_services_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق المستخدم',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/main': (context) => MainScreen(),
        '/service1': (context) =>
            const OtherServicePlaceholderScreen(title: 'دفع فاتورة'),
        '/service2': (context) =>
            const OtherServicePlaceholderScreen(title: 'تحويل رصيد'),
        '/service3': (context) =>
            const OtherServicePlaceholderScreen(title: 'شحن رصيد'),
        '/service4': (context) =>
            const OtherServicePlaceholderScreen(title: 'تبرع'),
      },
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
