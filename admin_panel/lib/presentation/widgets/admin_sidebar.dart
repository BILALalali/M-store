import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onProfileTap,
    this.onSettingsTap,
    this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.sidebar,
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Navigation Items
          Expanded(child: _buildNavigationList()),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCollapsed = constraints.maxWidth < 200;

        return Container(
          height: 80,
          padding: EdgeInsets.all(isCollapsed ? 8 : 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            border: Border(bottom: BorderSide(color: AppColors.accent)),
          ),
          child: isCollapsed
              ? Center(
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 24,
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'لوحة الإدارة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildNavigationList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // لوحة الإدارة
        _buildSectionHeader('لوحة الإدارة'),
        _buildNavItem(
          icon: Icons.dashboard,
          title: 'الرئيسية',
          subtitle: 'لوحة التحكم الرئيسية',
          index: 0,
        ),
        
        const SizedBox(height: 16),
        
        // إدارة المنتجات
        _buildSectionHeader('إدارة المنتجات'),
        _buildNavItem(
          icon: Icons.inventory,
          title: 'المنتجات',
          subtitle: 'إدارة وإضافة المنتجات',
          index: 1,
        ),
        _buildNavItem(
          icon: Icons.campaign,
          title: 'الإعلانات',
          subtitle: 'إدارة الإعلانات والعروض',
          index: 2,
        ),
        _buildNavItem(
          icon: Icons.person,
          title: 'الملف الشخصي',
          subtitle: 'إدارة الملف الشخصي',
          index: 3,
        ),
        
        const SizedBox(height: 16),
        
        // الإعدادات
        _buildSectionHeader('الإعدادات'),
        _buildNavItem(
          icon: Icons.settings,
          title: 'الإعدادات',
          subtitle: 'إعدادات النظام والحساب',
          index: 4,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCollapsed = constraints.maxWidth < 200;

        return Container(
          padding: EdgeInsets.all(isCollapsed ? 8 : 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.accent)),
          ),
          child: isCollapsed
              ? Column(
                  children: [
                    // معلومات المدير - نسخة مصغرة
                    CircleAvatar(
                      backgroundColor: AppColors.secondary,
                      radius: 16,
                      child: Text(
                        'أ',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // أزرار الإعدادات وتسجيل الخروج
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: AppColors.text,
                            size: 16,
                          ),
                          onPressed: onSettingsTap,
                          tooltip: 'الإعدادات',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.logout,
                            color: AppColors.error,
                            size: 16,
                          ),
                          onPressed: onLogoutTap,
                          tooltip: 'تسجيل الخروج',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  children: [
                    // معلومات المدير
                    InkWell(
                      onTap: onProfileTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.secondary,
                              radius: 20,
                              child: Text(
                                'أ',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مدير النظام',
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'admin@mstore.com',
                                    style: TextStyle(
                                      color: AppColors.text.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // أزرار الإعدادات وتسجيل الخروج
                    Row(
                      children: [
                        Expanded(
                          child: IconButton(
                            icon: Icon(
                              Icons.settings,
                              color: AppColors.text,
                              size: 20,
                            ),
                            onPressed: onSettingsTap,
                            tooltip: 'الإعدادات',
                          ),
                        ),
                        Expanded(
                          child: IconButton(
                            icon: Icon(
                              Icons.logout,
                              color: AppColors.error,
                              size: 20,
                            ),
                            onPressed: onLogoutTap,
                            tooltip: 'تسجيل الخروج',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.text.withValues(alpha: 0.8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : AppColors.text),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.text,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.8)
                : AppColors.text.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
        onTap: () => onItemSelected(index),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
