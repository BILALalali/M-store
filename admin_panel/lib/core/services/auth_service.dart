import 'package:flutter/material.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  
  // حالة المصادقة
  bool _isAuthenticated = false;
  bool _isAdmin = false;
  bool _isLoading = false;
  Map<String, dynamic>? _adminProfile;
  String? _errorMessage;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get adminProfile => _adminProfile;
  String? get errorMessage => _errorMessage;
  String? get currentUserEmail => _supabaseService.currentUser?.email;

  // تهيئة الخدمة
  Future<void> initialize() async {
    try {
      await _supabaseService.initialize();
      await _checkAuthStatus();
    } catch (e) {
      _setError('خطأ في تهيئة خدمة المصادقة: $e');
    }
  }

  // التحقق من حالة المصادقة
  Future<void> _checkAuthStatus() async {
    try {
      _setLoading(true);
      _clearError();

      final isAuth = _supabaseService.isAuthenticated;
      _isAuthenticated = isAuth;

      if (isAuth) {
        // التحقق من صلاحيات المدير
        final isAdmin = await _supabaseService.isAdmin();
        _isAdmin = isAdmin;

        if (isAdmin) {
          // جلب معلومات المدير
          await _loadAdminProfile();
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('خطأ في التحقق من حالة المصادقة: $e');
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل دخول المشرف
  Future<bool> signInAdmin(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      // تسجيل الدخول
      final response = await _supabaseService.signInWithCredentials(
        email,
        password,
      );

      if (response.user != null) {
        // التحقق من أن المستخدم مدير
        final isAdmin = await _supabaseService.isAdmin();
        
        if (isAdmin) {
          _isAuthenticated = true;
          _isAdmin = true;
          
          // جلب معلومات المدير
          await _loadAdminProfile();
          
          notifyListeners();
          return true;
        } else {
          // تسجيل الخروج إذا لم يكن مدير
          await _supabaseService.signOut();
          _setError('هذا الحساب ليس لديه صلاحيات المدير');
          return false;
        }
      } else {
        _setError('بيانات تسجيل الدخول غير صحيحة');
        return false;
      }
    } catch (e) {
      _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await _supabaseService.signOut();
      
      // إعادة تعيين الحالة
      _isAuthenticated = false;
      _isAdmin = false;
      _adminProfile = null;
      
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تسجيل الخروج: $e');
    } finally {
      _setLoading(false);
    }
  }

  // تحديث معلومات المدير
  Future<bool> updateAdminProfile({String? fullName, String? phone}) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabaseService.updateAdminProfile(
        fullName: fullName,
        phone: phone,
      );

      // إعادة تحميل معلومات المدير
      await _loadAdminProfile();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('خطأ في تحديث الملف الشخصي: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // تغيير كلمة المرور
  Future<bool> changePassword(String newPassword) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabaseService.changePassword(newPassword);
      return true;
    } catch (e) {
      _setError('خطأ في تغيير كلمة المرور: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // جلب معلومات المدير
  Future<void> _loadAdminProfile() async {
    try {
      final profile = await _supabaseService.getAdminProfile();
      if (profile != null) {
        _adminProfile = {
          'email': profile['email'] ?? '',
          'full_name': profile['full_name'] ?? '',
          'phone': profile['phone'] ?? '',
          'role': profile['role'] ?? 'مدير النظام',
          'avatar': profile['avatar'] ?? 'أ',
          'is_active': profile['is_active'] ?? true,
        };
      }
    } catch (e) {
      print('خطأ في جلب معلومات المدير: $e');
    }
  }

  // الحصول على الإحصائيات
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      return await _supabaseService.getDashboardStats();
    } catch (e) {
      _setError('خطأ في جلب الإحصائيات: $e');
      return {
        'orders_count': 0,
        'products_count': 0,
        'users_count': 0,
        'total_revenue': 0.0,
        'pending_orders': 0,
        'completed_orders': 0,
      };
    }
  }

  // الحصول على الطلبات
  Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      return await _supabaseService.getOrders();
    } catch (e) {
      _setError('خطأ في جلب الطلبات: $e');
      return [];
    }
  }

  // الحصول على المنتجات
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      return await _supabaseService.getProducts();
    } catch (e) {
      _setError('خطأ في جلب المنتجات: $e');
      return [];
    }
  }

  // الحصول على المستخدمين
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      return await _supabaseService.getUsers();
    } catch (e) {
      _setError('خطأ في جلب المستخدمين: $e');
      return [];
    }
  }

  // إنشاء حساب مدير جديد (للمطورين فقط)
  Future<bool> createAdminAccount({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabaseService.createAdminAccount(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      return true;
    } catch (e) {
      _setError('خطأ في إنشاء حساب المدير: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // معالجة أخطاء المصادقة
  void _handleAuthError(dynamic error) {
    String errorMessage = 'خطأ في تسجيل الدخول';

    if (error.toString().contains('Invalid login credentials')) {
      errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    } else if (error.toString().contains('Email not confirmed')) {
      errorMessage = 'يرجى تأكيد البريد الإلكتروني أولاً';
    } else if (error.toString().contains('Supabase غير مهيأ')) {
      errorMessage = 'خطأ في الاتصال بالنظام. يرجى المحاولة مرة أخرى';
    } else if (error.toString().contains('هذا الحساب ليس لديه صلاحيات المدير')) {
      errorMessage = 'هذا الحساب ليس لديه صلاحيات المدير';
    } else {
      errorMessage = 'خطأ في تسجيل الدخول: $error';
    }

    _setError(errorMessage);
  }

  // تعيين حالة التحميل
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // تعيين رسالة خطأ
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // مسح رسالة الخطأ
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // إعادة تعيين الحالة
  void reset() {
    _isAuthenticated = false;
    _isAdmin = false;
    _isLoading = false;
    _adminProfile = null;
    _errorMessage = null;
    notifyListeners();
  }
}
