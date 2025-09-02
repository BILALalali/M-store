import 'package:flutter/material.dart';
import '../widgets/admin_sidebar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';
import 'profile/profile_screen.dart';
import 'settings/settings_screen.dart';
import 'products/index.dart';
import 'advertisements/index.dart';
import '../../core/services/auth_service.dart'; // Added import for AuthService

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  // قائمة الشاشات
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductsScreen(), // شاشة إدارة المنتجات
    const AdvertisementsScreen(), // شاشة إدارة الإعلانات
    const ProfileScreen(), // شاشة الملف الشخصي
    const SettingsScreen(), // شاشة الإعدادات
  ];

  // عناوين الشاشات
  final List<String> _screenTitles = [
    'لوحة الإدارة',
    'إدارة المنتجات',
    'إدارة الإعلانات',
    'الملف الشخصي',
    'الإعدادات',
  ];

  void _handleLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد تسجيل الخروج'),
          content: const Text('هل أنت متأكد من أنك تريد تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إلغاء'),
            ),
            StatefulBuilder(
              builder: (context, setDialogState) {
                return ElevatedButton(
                  onPressed: () async {
                    // تعطيل الزر لمنع الضغط المتكرر
                    setDialogState(() {});

                    try {
                      // إغلاق الـ dialog أولاً
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }

                      print('بدء عملية تسجيل الخروج...');

                      // عرض شاشة الانتظار
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) {
                          return const AlertDialog(
                            content: Row(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 20),
                                Text('جاري تسجيل الخروج...'),
                              ],
                            ),
                          );
                        },
                      );

                      // تسجيل الخروج من AuthService
                      final authService = AuthService();

                      // إغلاق شاشة الانتظار قبل تسجيل الخروج
                      try {
                        Navigator.of(context, rootNavigator: true).pop();
                      } catch (e) {
                        print('خطأ في إغلاق شاشة الانتظار: $e');
                      }

                      await authService.signOut();

                      print('تم اكتمال عملية تسجيل الخروج من AuthService');

                      // لا حاجة للتنقل - AuthWrapper سيتولى الأمر تلقائياً
                      print(
                        'تم تسجيل الخروج بنجاح - AuthWrapper سيعرض شاشة تسجيل الدخول تلقائياً',
                      );
                    } catch (e) {
                      print('خطأ في تسجيل الخروج: $e');

                      // إغلاق شاشة الانتظار في حالة الخطأ
                      if (mounted) {
                        try {
                          Navigator.of(context, rootNavigator: true).pop();
                        } catch (closeError) {
                          print('خطأ في إغلاق شاشة الانتظار: $closeError');
                        }

                        // عرض رسالة خطأ
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('خطأ في تسجيل الخروج: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    } finally {
                      // تم إكمال العملية
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('تسجيل الخروج'),
                );
              },
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
                  _selectedIndex = 3; // الانتقال لصفحة الملف الشخصي
                });
              },
              onSettingsTap: () {
                setState(() {
                  _selectedIndex = 4; // الانتقال لصفحة الإعدادات
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
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _supabaseService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              Expanded(
                child: Text(
                  'لوحة الإدارة',
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
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;

                // تحديد عدد الأعمدة بناءً على العرض المتاح
                int crossAxisCount;
                double childAspectRatio;
                double spacing;

                if (availableWidth < 600) {
                  // شاشات صغيرة جداً
                  crossAxisCount = 1;
                  childAspectRatio = 2.2;
                  spacing = 12;
                } else if (availableWidth < 900) {
                  // شاشات صغيرة (موبايل)
                  crossAxisCount = 1;
                  childAspectRatio = 2.0;
                  spacing = 16;
                } else if (availableWidth < 1200) {
                  // شاشات متوسطة (تابلت)
                  crossAxisCount = 2;
                  childAspectRatio = 1.8;
                  spacing = 20;
                } else if (availableWidth < 1600) {
                  // شاشات كبيرة (ديسكتوب)
                  crossAxisCount = 3;
                  childAspectRatio = 1.6;
                  spacing = 24;
                } else {
                  // شاشات كبيرة جداً
                  crossAxisCount = 4;
                  childAspectRatio = 1.4;
                  spacing = 28;
                }

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
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
                );
              },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // استخدام constraints.maxWidth بدلاً من MediaQuery
        final availableWidth = constraints.maxWidth;

        // حساب الأحجام الديناميكية بناءً على العرض المتاح
        final isSmallScreen = availableWidth < 600;
        final isMediumScreen = availableWidth >= 600 && availableWidth < 900;

        // تعديل الأحجام بناءً على العرض المتاح
        final iconSize = isSmallScreen ? 28.0 : (isMediumScreen ? 32.0 : 40.0);
        final valueFontSize = isSmallScreen
            ? 20.0
            : (isMediumScreen ? 24.0 : 28.0);
        final titleFontSize = isSmallScreen
            ? 10.0
            : (isMediumScreen ? 12.0 : 14.0);
        final padding = isSmallScreen ? 12.0 : (isMediumScreen ? 16.0 : 24.0);
        final spacing = isSmallScreen ? 8.0 : (isMediumScreen ? 12.0 : 16.0);

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
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // مهم: منع التمدد الزائد
              children: [
                Icon(icon, size: iconSize, color: color),
                SizedBox(height: spacing),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis, // منع تجاوز النص
                    maxLines: 2, // السماح بسطرين كحد أقصى
                  ),
                ),
                SizedBox(height: spacing * 0.5),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis, // منع تجاوز النص
                    maxLines: 3, // السماح بثلاثة أسطر كحد أقصى
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
