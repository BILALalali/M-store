import 'package:flutter/material.dart';
import '../widgets/admin_sidebar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
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
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  // استخدام خدمة المصادقة لتسجيل الخروج
                  final authService = AuthService();
                  await authService.signOut();

                  if (mounted) {
                    // انتقل لشاشة تسجيل الدخول
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                } catch (e) {
                  // تجاهل الأخطاء عند تسجيل الخروج
                  print('خطأ في تسجيل الخروج: $e');

                  // حتى لو حدث خطأ، انتقل لشاشة تسجيل الدخول
                  if (mounted) {
                    try {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    } catch (navError) {
                      print('خطأ في التنقل: $navError');
                      // إعادة تشغيل التطبيق كحل أخير
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                }
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

// شاشة لوحة الإدارة مع الإحصائيات
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _authService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
              Icon(Icons.dashboard, size: 32, color: AppColors.primary),
              const SizedBox(width: 16),
              Text(
                'لوحة الإدارة',
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
            'نظرة عامة على النظام والإحصائيات',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 32),

          // بطاقات الإحصائيات
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'إجمالي الطلبات',
                  '${_stats['orders_count'] ?? 0}',
                  Icons.shopping_cart,
                  AppColors.primary,
                ),
                _buildStatCard(
                  'إجمالي المنتجات',
                  '${_stats['products_count'] ?? 0}',
                  Icons.inventory,
                  AppColors.success,
                ),
                _buildStatCard(
                  'إجمالي المستخدمين',
                  '${_stats['users_count'] ?? 0}',
                  Icons.people,
                  AppColors.info,
                ),
                _buildStatCard(
                  'إجمالي الإيرادات',
                  '${_stats['total_revenue']?.toStringAsFixed(2) ?? '0.00'} ريال',
                  Icons.attach_money,
                  AppColors.warning,
                ),
                _buildStatCard(
                  'الطلبات المعلقة',
                  '${_stats['pending_orders'] ?? 0}',
                  Icons.pending,
                  AppColors.error,
                ),
                _buildStatCard(
                  'الطلبات المكتملة',
                  '${_stats['completed_orders'] ?? 0}',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
