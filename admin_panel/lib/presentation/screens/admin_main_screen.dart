import 'package:flutter/material.dart';
import '../widgets/admin_sidebar.dart';
import '../../core/theme/app_colors.dart';
import 'profile/profile_screen.dart';
import 'settings/settings_screen.dart';
import 'auth/login_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  // قائمة الشاشات - سنبدأ بشاشة واحدة فقط
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProfileScreen(), // شاشة الملف الشخصي
    const SettingsScreen(), // شاشة الإعدادات
  ];

  // عناوين الشاشات
  final List<String> _screenTitles = [
    'لوحة الإدارة',
    'الملف الشخصي',
    'الإعدادات',
  ];

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: AppColors.error, size: 24),
              const SizedBox(width: 8),
              const Text('تسجيل الخروج'),
            ],
          ),
          content: const Text('هل أنت متأكد من أنك تريد تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: TextStyle(color: AppColors.text.withValues(alpha: 0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // انتقل لشاشة تسجيل الدخول
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // القائمة الجانبية
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 80 : 280,
            child: AdminSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              onProfileTap: () {
                setState(() {
                  _selectedIndex = 1; // الانتقال لصفحة الملف الشخصي
                });
              },
              onSettingsTap: () {
                setState(() {
                  _selectedIndex = 2; // الانتقال لصفحة الإعدادات
                });
              },
              onLogoutTap: _handleLogout,
            ),
          ),

          // المحتوى الرئيسي
          Expanded(
            child: Column(
              children: [
                // شريط العنوان
                _buildTopBar(),

                // المحتوى
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.secondary)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر إخفاء/إظهار القائمة الجانبية
          IconButton(
            icon: Icon(
              _isSidebarCollapsed ? Icons.menu_open : Icons.menu,
              color: AppColors.text,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),

          const SizedBox(width: 20),

          // عنوان الشاشة الحالية
          Expanded(
            child: Text(
              _screenTitles[_selectedIndex],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const Spacer(),

          // الإشعارات
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.text,
                    size: 24,
                  ),
                  onPressed: () {
                    // TODO: عرض الإشعارات
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// شاشة لوحة الإدارة البسيطة
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'لوحة الإدارة',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'مرحباً بك في لوحة إدارة النظام',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
