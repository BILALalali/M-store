import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = true;

  // بيانات المدير
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  // بيانات إضافية من قاعدة البيانات
  String _joinDate = '';
  String _lastLogin = '';
  String _avatarInitial = 'أ';

  // بيانات الأمان والنشاط
  Map<String, dynamic> _securityInfo = {};
  Map<String, dynamic> _activityStats = {};

  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // تحميل بيانات الملف الشخصي
      final adminProfile = await _supabaseService.getAdminProfile();

      // تحميل بيانات الأمان والنشاط
      final securityInfo = await _supabaseService.getAdminSecurityInfo();
      final activityStats = await _supabaseService.getAdminActivityStats();

      if (adminProfile != null) {
        setState(() {
          _nameController.text = adminProfile['full_name'] ?? '';
          _emailController.text = adminProfile['email'] ?? '';
          _phoneController.text = adminProfile['phone'] ?? '';
          _roleController.text = adminProfile['role'] ?? 'مدير النظام';
          _departmentController.text = 'إدارة عامة';

          // تحديث البيانات الإضافية من قاعدة البيانات
          _joinDate = _formatDate(adminProfile['created_at']);
          _lastLogin = adminProfile['last_login'] != null
              ? _formatDate(adminProfile['last_login'])
              : 'الآن';
          _avatarInitial = _getAvatarInitial(adminProfile['full_name']);

          // تحديث بيانات الأمان والنشاط
          _securityInfo = securityInfo;
          _activityStats = activityStats;

          _isLoading = false;
        });

        print('تم تحميل بيانات الملف الشخصي من قاعدة البيانات: $adminProfile');
        print('بيانات الأمان: $securityInfo');
        print('إحصائيات النشاط: $activityStats');
      } else {
        print('لم يتم العثور على بيانات الملف الشخصي في قاعدة البيانات');
        // استخدام بيانات المستخدم الحالي من Supabase
        final currentUser = _supabaseService.currentUser;
        if (currentUser != null) {
          setState(() {
            _nameController.text =
                currentUser.userMetadata?['full_name'] ??
                currentUser.email?.split('@')[0] ??
                'مستخدم';
            _emailController.text = currentUser.email ?? '';
            _phoneController.text = '';
            _roleController.text = 'مدير النظام';
            _departmentController.text = 'إدارة عامة';

            // استخدام البيانات الافتراضية للأمان والنشاط
            _securityInfo = securityInfo;
            _activityStats = activityStats;

            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('خطأ في تحميل بيانات الملف الشخصي: $e');
      // استخدام بيانات المستخدم الحالي من Supabase في حالة الخطأ
      try {
        final currentUser = _supabaseService.currentUser;
        if (currentUser != null) {
          setState(() {
            _nameController.text =
                currentUser.userMetadata?['full_name'] ??
                currentUser.email?.split('@')[0] ??
                'مستخدم';
            _emailController.text = currentUser.email ?? '';
            _phoneController.text = '';
            _roleController.text = 'مدير النظام';
            _departmentController.text = 'إدارة عامة';

            // استخدام البيانات الافتراضية للأمان والنشاط
            _securityInfo = {
              'last_password_update': 'منذ 30 يوماً',
              'two_factor_enabled': false,
              'active_sessions': 1,
            };
            _activityStats = {
              'updated_products': 0,
              'added_users': 0,
              'processed_orders': 0,
            };

            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (fallbackError) {
        print('خطأ في الحل البديل: $fallbackError');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // دالة لتنسيق التاريخ
  String _formatDate(dynamic date) {
    if (date == null) return 'غير محدد';

    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        return _formatDateToArabic(parsedDate);
      } else if (date is DateTime) {
        return _formatDateToArabic(date);
      }
      return 'غير محدد';
    } catch (e) {
      print('خطأ في تنسيق التاريخ: $e');
      return 'غير محدد';
    }
  }

  // دالة لتنسيق التاريخ باللغة العربية
  String _formatDateToArabic(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'أمس ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      final months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  // دالة للحصول على الحرف الأول من الاسم
  String _getAvatarInitial(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'أ';

    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) return 'أ';

    // البحث عن أول حرف عربي أو إنجليزي
    for (int i = 0; i < trimmedName.length; i++) {
      final char = trimmedName[i];
      if (RegExp(r'[أ-يa-zA-Z]').hasMatch(char)) {
        return char.toUpperCase();
      }
    }

    return 'أ';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      print('حفظ البيانات:');
      print('الاسم: ${_nameController.text}');
      print('الهاتف: ${_phoneController.text}');

      final updatedProfile = await _supabaseService.updateAdminProfile(
        fullName: _nameController.text,
        phone: _phoneController.text,
      );

      if (updatedProfile != null) {
        print('تم تحديث البيانات بنجاح: $updatedProfile');

        // تحديث البيانات مباشرة من الاستجابة
        setState(() {
          _nameController.text =
              updatedProfile['full_name'] ?? _nameController.text;
          _phoneController.text =
              updatedProfile['phone'] ?? _phoneController.text;
          _roleController.text = updatedProfile['role'] ?? _roleController.text;

          // تحديث البيانات الإضافية
          _joinDate = _formatDate(updatedProfile['created_at']);
          _lastLogin = updatedProfile['last_login'] != null
              ? _formatDate(updatedProfile['last_login'])
              : 'الآن';
          _avatarInitial = _getAvatarInitial(updatedProfile['full_name']);

          _isEditing = false;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم حفظ التغييرات بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception('فشل في تحديث البيانات');
      }
    } catch (e) {
      print('خطأ في حفظ التغييرات: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ التغييرات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان الصفحة
            _buildPageHeader(),

            const SizedBox(height: 32),

            // معلومات الملف الشخصي
            _buildProfileInfo(),

            const SizedBox(height: 32),

            // معلومات الحساب
            _buildAccountInfo(),

            const SizedBox(height: 32),

            // إعدادات الأمان
            _buildSecuritySettings(),

            const SizedBox(height: 32),

            // إحصائيات النشاط
            _buildActivityStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Icon(Icons.person, size: 32, color: Colors.blue[600]),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الملف الشخصي',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Text(
                'إدارة معلوماتك الشخصية وإعدادات الحساب',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: ElevatedButton.icon(
            onPressed: _isEditing
                ? _saveProfile
                : () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            label: Text(_isEditing ? 'حفظ التغييرات' : 'تعديل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEditing
                  ? AppColors.success
                  : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'المعلومات الشخصية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // صورة الملف الشخصي
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.secondary,
                  child: Text(
                    _avatarInitial,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // نموذج المعلومات
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildFormField(
                  controller: _nameController,
                  label: 'الاسم الكامل',
                  icon: Icons.person,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 20),
                _buildFormField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email,
                  enabled: _isEditing,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _buildFormField(
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  icon: Icons.phone,
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'معلومات الحساب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildInfoRow('الدور', _roleController.text, Icons.work),
          const SizedBox(height: 16),
          _buildInfoRow('القسم', _departmentController.text, Icons.business),
          const SizedBox(height: 16),
          _buildInfoRow('تاريخ الانضمام', _joinDate, Icons.calendar_today),
          const SizedBox(height: 16),
          _buildInfoRow('آخر تسجيل دخول', _lastLogin, Icons.access_time),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppColors.warning, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إعدادات الأمان',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSecurityOption('تغيير كلمة المرور', '', Icons.lock_outline, () {
            _showChangePasswordDialog();
          }),
          const SizedBox(height: 16),
          _buildSecurityOption(
            'المصادقة الثنائية',
            _securityInfo['two_factor_enabled'] == true ? 'مفعلة' : 'غير مفعلة',
            Icons.verified_user,
            () {
              _showTwoFactorDialog();
            },
          ),
          const SizedBox(height: 16),
          _buildSecurityOption(
            'جلسات تسجيل الدخول',
            '${_securityInfo['active_sessions'] ?? 1} جلسة نشطة',
            Icons.devices,
            () {
              _showSessionsDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.info, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إحصائيات النشاط',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'الطلبات المعالجة',
                  '${_activityStats['processed_orders'] ?? 0}',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatCard(
                  'المستخدمين المضافين',
                  '${_activityStats['added_users'] ?? 0}',
                  Icons.person_add,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatCard(
                  'المنتجات المحدثة',
                  '${_activityStats['updated_products'] ?? 0}',
                  Icons.update,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: enabled ? AppColors.cardBackground : AppColors.secondary,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.text.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // عرض نافذة تغيير كلمة المرور
  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تغيير كلمة المرور'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الحالية',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور الجديدة',
                  border: OutlineInputBorder(),
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
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('كلمة المرور الجديدة غير متطابقة'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                try {
                  await _supabaseService.changePassword(
                    newPasswordController.text,
                  );
                  await _supabaseService.updatePasswordLastUpdate();

                  // إعادة تحميل البيانات
                  await _loadProfileData();

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تغيير كلمة المرور بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في تغيير كلمة المرور: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('تغيير'),
            ),
          ],
        );
      },
    );
  }

  // عرض نافذة المصادقة الثنائية
  void _showTwoFactorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('المصادقة الثنائية'),
          content: Text(
            _securityInfo['two_factor_enabled'] == true
                ? 'المصادقة الثنائية مفعلة حالياً. هل تريد إلغاء تفعيلها؟'
                : 'المصادقة الثنائية غير مفعلة. هل تريد تفعيلها؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('هذه الميزة قيد التطوير'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
              child: Text(
                _securityInfo['two_factor_enabled'] == true
                    ? 'إلغاء التفعيل'
                    : 'تفعيل',
              ),
            ),
          ],
        );
      },
    );
  }

  // عرض نافذة الجلسات
  void _showSessionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('جلسات تسجيل الدخول'),
          content: const Text(
            'جلسة واحدة نشطة حالياً (هذه الجلسة).\n\n'
            'يمكنك تسجيل الخروج من جميع الأجهزة الأخرى من هنا.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('هذه الميزة قيد التطوير'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('تسجيل الخروج من جميع الأجهزة'),
            ),
          ],
        );
      },
    );
  }
}
