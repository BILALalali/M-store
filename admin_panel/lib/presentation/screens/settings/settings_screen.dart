import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> _changePassword() async {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تغيير كلمة المرور'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
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
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _supabaseService.changePassword(
                    newPasswordController.text,
                  );

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تغيير كلمة المرور بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ في تغيير كلمة المرور: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('تغيير'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس الصفحة
          Row(
            children: [
              Icon(Icons.settings, size: 32, color: AppColors.primary),
              const SizedBox(width: 16),
              Text(
                'الإعدادات',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'تخصيص إعدادات النظام والحساب',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 32),

          // إعدادات الإشعارات
          _buildSettingsSection(
            title: 'إعدادات الإشعارات',
            icon: Icons.notifications,
            children: [
              _buildSwitchTile(
                icon: Icons.notifications,
                title: 'الإشعارات العامة',
                subtitle: 'تفعيل أو إلغاء الإشعارات',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              _buildSwitchTile(
                icon: Icons.email,
                title: 'إشعارات البريد الإلكتروني',
                subtitle: 'استلام إشعارات عبر البريد الإلكتروني',
                value: true,
                onChanged: (value) {
                  // TODO: تفعيل/إلغاء إشعارات البريد الإلكتروني
                },
              ),
              _buildSwitchTile(
                icon: Icons.phone,
                title: 'إشعارات الهاتف',
                subtitle: 'استلام إشعارات عبر الهاتف',
                value: false,
                onChanged: (value) {
                  // TODO: تفعيل/إلغاء إشعارات الهاتف
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // إعدادات متقدمة
          _buildSettingsSection(
            title: 'إعدادات متقدمة',
            icon: Icons.settings_applications,
            children: [
              _buildSwitchTile(
                icon: Icons.analytics,
                title: 'تقارير مفصلة',
                subtitle: 'عرض تقارير مفصلة للنظام',
                value: true,
                onChanged: (value) {
                  // TODO: تفعيل/إلغاء التقارير المفصلة
                },
              ),
              _buildSwitchTile(
                icon: Icons.backup,
                title: 'النسخ الاحتياطي التلقائي',
                subtitle: 'إنشاء نسخ احتياطية تلقائية',
                value: false,
                onChanged: (value) {
                  // TODO: تفعيل/إلغاء النسخ الاحتياطي التلقائي
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // إعدادات الأمان
          _buildSettingsSection(
            title: 'إعدادات الأمان',
            icon: Icons.security,
            children: [
              _buildSwitchTile(
                icon: Icons.security,
                title: 'المصادقة الثنائية',
                subtitle: 'تفعيل المصادقة الثنائية للحساب',
                value: false,
                onChanged: (value) {
                  // TODO: تفعيل/إلغاء المصادقة الثنائية
                },
              ),
              _buildSwitchTile(
                icon: Icons.login,
                title: 'تسجيل الدخول المتعدد',
                subtitle: 'السماح بتسجيل دخول من أجهزة متعددة',
                value: true,
                onChanged: (value) {
                  // TODO: تفعيل/إلغاء تسجيل الدخول المتعدد
                },
              ),
              _buildSettingsTile(
                icon: Icons.lock,
                title: 'تغيير كلمة المرور',
                subtitle: 'تغيير كلمة مرور الحساب',
                onTap: _changePassword,
              ),
              _buildSettingsTile(
                icon: Icons.history,
                title: 'سجل النشاط',
                subtitle: 'عرض سجل تسجيل الدخول والأنشطة',
                onTap: () {
                  // TODO: فتح نافذة سجل النشاط
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.2),
              ),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.text),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.text.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.text.withValues(alpha: 0.5),
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.text),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.text.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}
