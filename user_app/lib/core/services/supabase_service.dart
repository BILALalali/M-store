import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static bool _isInitialized = false;
  
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: 'assets/env');
      
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      
      if (url == null || anonKey == null) {
        throw Exception('متغيرات البيئة غير متوفرة');
      }
      
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      
      _isInitialized = true;
      print('تم تهيئة Supabase بنجاح');
    } catch (e) {
      print('فشل في تهيئة Supabase: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  static SupabaseClient? get client {
    if (!_isInitialized) {
      print('تحذير: Supabase لم يتم تهيئته بعد');
      return null;
    }
    return Supabase.instance.client;
  }
  
  static bool get isInitialized => _isInitialized;
}
