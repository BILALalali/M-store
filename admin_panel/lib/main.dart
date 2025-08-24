import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/supabase_service.dart';
import 'presentation/screens/admin_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: "assets/.env");

  runApp(const MyAppWithSupabase());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // من اليمين لليسار
          child: child!,
        );
      },
      home: const AdminMainScreen(),
    );
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
