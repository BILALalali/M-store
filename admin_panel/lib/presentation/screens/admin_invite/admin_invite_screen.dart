import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class AdminInviteScreen extends StatefulWidget {
  const AdminInviteScreen({super.key});

  @override
  State<AdminInviteScreen> createState() => _AdminInviteScreenState();
}

class _AdminInviteScreenState extends State<AdminInviteScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _inviteAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // التحقق من أن كلمة المرور وتأكيدها متطابقان
      if (_passwordController.text != _confirmPasswordController.text) {
        throw Exception('كلمة المرور وتأكيدها غير متطابقتين');
      }

      // التحقق من وجود المدير مسبقاً
      final adminExists = await _supabaseService.checkAdminExists(
        _emailController.text.trim(),
      );

      if (adminExists) {
        // إذا كان المدير موجود، اعرض خيار تأكيد البريد الإلكتروني
        _showConfirmEmailDialog();
        return;
      }

      // إنشاء حساب المدير الجديد
      await _supabaseService.createAdminAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      // عرض رسالة نجاح
      if (mounted) {
        _showSuccessMessage();
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showConfirmEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المدير موجود بالفعل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هذا البريد الإلكتروني مسجل كمدير بالفعل.'),
            const SizedBox(height: 16),
            const Text('هل تريد تأكيد البريد الإلكتروني للمدير؟'),
            const SizedBox(height: 8),
            Text(
              'ملاحظة: هذا قد يحل مشكلة عدم قدرة المدير على تسجيل الدخول.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _confirmExistingAdminEmail();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد البريد الإلكتروني'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExistingAdminEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseService.confirmAdminEmail(_emailController.text.trim());

      if (mounted) {
        _showInfoMessage(
          'تم تأكيد البريد الإلكتروني بنجاح! يمكن للمدير الآن تسجيل الدخول.',
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('خطأ في تأكيد البريد الإلكتروني: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم إنشاء حساب المدير بنجاح! سيحتاج المدير لتأكيد البريد الإلكتروني قبل تسجيل الدخول.',
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _clearForm() {
    _emailController.clear();
    _fullNameController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  void _generateStrongPassword() {
    // توليد كلمة مرور قوية
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    String password = '';

    for (int i = 0; i < 12; i++) {
      password += chars[(random + i) % chars.length];
    }

    _passwordController.text = password;
    _confirmPasswordController.text = password;

    // نسخ كلمة المرور للحافظة
    Clipboard.setData(ClipboardData(text: password));

    _showInfoMessage('تم توليد كلمة مرور قوية ونسخها للحافظة');
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.info),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس الصفحة
          Row(
            children: [
              Icon(Icons.person_add, size: 32, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'دعوة مشرف جديد',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'إضافة مدير جديد للوصول إلى لوحة الإدارة',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 32),

          // نموذج إضافة المدير
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // البريد الإلكتروني
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني *',
                        hintText: 'admin@example.com',
                        prefixIcon: Icon(Icons.email, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'البريد الإلكتروني مطلوب';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value.trim())) {
                          return 'البريد الإلكتروني غير صحيح';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // الاسم الكامل
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل *',
                        hintText: 'أدخل الاسم الكامل للمدير',
                        prefixIcon: Icon(
                          Icons.person,
                          color: AppColors.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الاسم الكامل مطلوب';
                        }
                        if (value.trim().length < 2) {
                          return 'الاسم يجب أن يكون حرفين على الأقل';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // رقم الهاتف (اختياري)
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف (اختياري)',
                        hintText: '+90 555 123 4567',
                        prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (value.trim().length < 10) {
                            return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // كلمة المرور
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور *',
                              hintText: 'أدخل كلمة مرور قوية',
                              prefixIcon: Icon(
                                Icons.lock,
                                color: AppColors.primary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'كلمة المرور مطلوبة';
                              }
                              if (value.length < 6) {
                                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _generateStrongPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.text,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                          ),
                          child: const Text('توليد'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // تأكيد كلمة المرور
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور *',
                        hintText: 'أعد إدخال كلمة المرور',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'تأكيد كلمة المرور مطلوب';
                        }
                        if (value != _passwordController.text) {
                          return 'كلمة المرور وتأكيدها غير متطابقتين';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // أزرار العمل
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _inviteAdmin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'إنشاء حساب المدير',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: _isLoading ? null : _clearForm,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'مسح النموذج',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ملاحظة
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'سيتم إنشاء حساب جديد للمدير. سيحتاج المدير لتأكيد البريد الإلكتروني من رسالة ستصله، أو يمكن استخدام خيار "تأكيد البريد الإلكتروني" بإدخال بريده مرة أخرى.',
                              style: TextStyle(
                                color: AppColors.info,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
