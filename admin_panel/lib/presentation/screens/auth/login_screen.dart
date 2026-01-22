import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // استخدام خدمة المصادقة
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // شعار التطبيق
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'لوحة الإدارة',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'تسجيل الدخول للوصول للوحة الإدارة',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // عرض رسالة الخطأ إذا وجدت
                  if (_authService.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        _authService.errorMessage!,
                        style: TextStyle(color: AppColors.error, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // حقل البريد الإلكتروني
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_authService.isLoading,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      hintText: 'أدخل بريدك الإلكتروني',
                      prefixIcon: Icon(Icons.email, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال البريد الإلكتروني';
                      }
                      if (!value.contains('@')) {
                        return 'يرجى إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // حقل كلمة المرور
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_authService.isLoading,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      hintText: 'أدخل كلمة المرور',
                      prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.text.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال كلمة المرور';
                      }
                      if (value.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // زر تسجيل الدخول
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _authService.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _authService.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // رابط نسيت كلمة المرور
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _authService.isLoading
                            ? null
                            : () {
                                _showResetPasswordDialog();
                              },
                        child: Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(color: AppColors.primary, fontSize: 14),
                        ),
                      ),
                      Text(
                        ' | ',
                        style: TextStyle(color: AppColors.text.withValues(alpha: 0.3)),
                      ),
                      TextButton(
                        onPressed: _authService.isLoading
                            ? null
                            : () {
                                _showDirectPasswordResetDialog();
                              },
                        child: Text(
                          'تغيير مباشر (للمطورين)',
                          style: TextStyle(color: AppColors.warning, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text;

      print('بدء عملية تسجيل الدخول...');

      // استخدام خدمة المصادقة المحسنة
      final success = await _authService.signInAdmin(email, password);

      if (success && mounted) {
        print('تم تسجيل الدخول بنجاح، الانتقال للوحة الإدارة...');

        // الانتقال للوحة الإدارة - سيتم التوجيه تلقائياً من AuthWrapper
        // Navigator.of(context).pushReplacementNamed('/admin');
      } else {
        print('فشل في تسجيل الدخول');
        // رسالة الخطأ ستظهر تلقائياً من AuthService
      }
    } catch (e) {
      print('خطأ في تسجيل الدخول: $e');
      // رسالة الخطأ ستظهر تلقائياً من AuthService
    }
  }

  // عرض نافذة إعادة تعيين كلمة المرور
  void _showResetPasswordDialog() {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إعادة تعيين كلمة المرور'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'أدخل بريدك الإلكتروني وسنرسل لك رابط لإعادة تعيين كلمة المرور',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_authService.isLoading,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  hintText: 'أدخل بريدك الإلكتروني',
                  prefixIcon: Icon(Icons.email, color: AppColors.primary),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _authService.isLoading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: _authService.isLoading
                  ? null
                  : () async {
                      if (emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يرجى إدخال البريد الإلكتروني'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      final email = emailController.text.trim();
                      final success = await _authService.resetPassword(email);

                      if (mounted) {
                        Navigator.of(context).pop();

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم إرسال رابط إعادة تعيين كلمة المرور إلى $email',
                              ),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _authService.errorMessage ??
                                    'فشل في إرسال رابط إعادة تعيين كلمة المرور',
                              ),
                              backgroundColor: AppColors.error,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _authService.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('إرسال'),
            ),
          ],
        );
      },
    );
  }

  // عرض نافذة تغيير كلمة المرور مباشرة (للمطورين)
  void _showDirectPasswordResetDialog() {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تغيير كلمة المرور مباشرة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '⚠️ هذه الوظيفة للمطورين فقط وتحتاج service_role key',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_authService.isLoading,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'أدخل بريدك الإلكتروني',
                    prefixIcon: Icon(Icons.email, color: AppColors.primary),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  enabled: !_authService.isLoading,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    hintText: 'أدخل كلمة المرور الجديدة',
                    prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  enabled: !_authService.isLoading,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    hintText: 'أعد إدخال كلمة المرور',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _authService.isLoading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: _authService.isLoading
                  ? null
                  : () async {
                      if (emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يرجى إدخال البريد الإلكتروني'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if (passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يرجى إدخال كلمة المرور الجديدة'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if (passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if (passwordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('كلمة المرور غير متطابقة'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      final email = emailController.text.trim();
                      final newPassword = passwordController.text;
                      final success = await _authService.resetPasswordDirectly(
                        email,
                        newPassword,
                      );

                      if (mounted) {
                        Navigator.of(context).pop();

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم تغيير كلمة المرور بنجاح لـ $email',
                              ),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _authService.errorMessage ??
                                    'فشل في تغيير كلمة المرور',
                              ),
                              backgroundColor: AppColors.error,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: _authService.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('تغيير'),
            ),
          ],
        );
      },
    );
  }
}
