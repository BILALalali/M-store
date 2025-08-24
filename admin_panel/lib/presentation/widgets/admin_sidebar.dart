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
      color: Colors.grey[900],
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
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        border: Border(bottom: BorderSide(color: AppColors.accent)),
      ),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          const Text(
            'لوحة الإدارة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // سنضيف العناصر تدريجياً
        _buildSectionHeader('لوحة الإدارة'),
        _buildNavItem(
          icon: Icons.dashboard,
          title: 'الرئيسية',
          subtitle: 'لوحة التحكم الرئيسية',
          index: 0,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.accent)),
      ),
      child: Column(
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
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'admin@mstore.com',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 11,
                          ),
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
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  onPressed: onSettingsTap,
                  tooltip: 'الإعدادات',
                ),
              ),
              Expanded(
                child: IconButton(
                  icon: Icon(Icons.logout, color: AppColors.error, size: 20),
                  onPressed: onLogoutTap,
                  tooltip: 'تسجيل الخروج',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.secondary,
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
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : AppColors.secondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected
                ? AppColors.secondary
                : AppColors.secondary.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        onTap: () => onItemSelected(index),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
