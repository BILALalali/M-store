import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/supabase_service.dart';
import 'presentation/screens/admin_main_screen.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: "assets/env");

  runApp(const MyAppWithSupabase());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light, // إجبار استخدام النمط النهاري فقط
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // من اليمين لليسار
          child: child!,
        );
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isAdmin = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // انتظار تهيئة Supabase أولاً
      await SupabaseService().initialize();

      final supabaseService = SupabaseService();

      // التحقق من حالة تسجيل الدخول
      final isAuth = supabaseService.isAuthenticated;

      // إذا كان المستخدم مسجل دخول، تحقق من صلاحيات المدير
      bool isAdmin = false;
      if (isAuth) {
        isAdmin = await supabaseService.isAdmin();
      }

      setState(() {
        _isAuthenticated = isAuth;
        _isAdmin = isAdmin;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('خطأ في التحقق من حالة تسجيل الدخول: $e');
      setState(() {
        _isAuthenticated = false;
        _isAdmin = false;
        _isLoading = false;
        _errorMessage = 'خطأ في الاتصال بالنظام: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تهيئة النظام...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'خطأ في الاتصال',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkAuthStatus,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    // التحقق من أن المستخدم مسجل دخول ولديه صلاحيات المدير
    if (_isAuthenticated && _isAdmin) {
      return const AdminMainScreen();
    } else {
      return const LoginScreen();
    }
  }
}

class MyAppWithSupabase extends StatefulWidget {
  const MyAppWithSupabase({super.key});

  @override
  State<MyAppWithSupabase> createState() => _MyAppWithSupabaseState();
}

class _MyAppWithSupabaseState extends State<MyAppWithSupabase> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSupabase();
  }

  Future<void> _initializeSupabase() async {
    try {
      await SupabaseService().initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('خطأ في تهيئة Supabase: $e');
      // حتى لو فشلت التهيئة، نعرض التطبيق
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'جاري تهيئة النظام...',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const MyApp();
  }
}
