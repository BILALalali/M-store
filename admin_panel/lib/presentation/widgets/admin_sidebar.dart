import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AdminSidebar extends StatefulWidget {
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
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  // حالة الأقسام القابلة للطي
  bool _isGeneralExpanded = true;
  bool _isManagementExpanded = true;
  bool _isChatsExpanded = false;

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
        // قسم عام
        _buildCollapsibleSection(
          title: 'عام',
          isExpanded: _isGeneralExpanded,
          onToggle: () =>
              setState(() => _isGeneralExpanded = !_isGeneralExpanded),
          children: [
            _buildNavItem(
              icon: Icons.dashboard,
              title: 'الرئيسية',
              subtitle: 'لوحة التحكم الرئيسية',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.person,
              title: 'الملف الشخصي',
              subtitle: 'إدارة الملف الشخصي',
              index: 5,
            ),
            _buildNavItem(
              icon: Icons.settings,
              title: 'الإعدادات',
              subtitle: 'إعدادات النظام والحساب',
              index: 6,
            ),
          ],
        ),

        const SizedBox(height: 8),

        // قسم إدارة
        _buildCollapsibleSection(
          title: 'إدارة',
          isExpanded: _isManagementExpanded,
          onToggle: () =>
              setState(() => _isManagementExpanded = !_isManagementExpanded),
          children: [
            _buildNavItem(
              icon: Icons.inventory,
              title: 'المنتجات',
              subtitle: 'إدارة وإضافة المنتجات',
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.phone_android,
              title: 'بطاقات الجوال',
              subtitle: 'إدارة باقات ومشغلي الجوال',
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.games,
              title: 'بطاقات الألعاب',
              subtitle: 'إدارة بطاقات ومقدمي خدمة الألعاب',
              index: 3,
            ),
            _buildNavItem(
              icon: Icons.campaign,
              title: 'الإعلانات',
              subtitle: 'إدارة الإعلانات والعروض',
              index: 4,
            ),
          ],
        ),

        const SizedBox(height: 8),

        // قسم الدردشات
        _buildCollapsibleSection(
          title: 'الدردشات',
          isExpanded: _isChatsExpanded,
          onToggle: () => setState(() => _isChatsExpanded = !_isChatsExpanded),
          children: [
            _buildNavItem(
              icon: Icons.support_agent,
              title: 'فريق الدعم',
              subtitle: 'إدارة دردشات الدعم',
              index: 7,
            ),
          ],
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
                          onPressed: widget.onSettingsTap,
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
                          onPressed: widget.onLogoutTap,
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
                      onTap: widget.onProfileTap,
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
                            onPressed: widget.onSettingsTap,
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
                            onPressed: widget.onLogoutTap,
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

  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // رأس القسم القابل للطي
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // محتوى القسم
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isExpanded ? null : 0,
            child: isExpanded
                ? Column(children: children)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
  }) {
    final isSelected = widget.selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : AppColors.text,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.text,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.8)
                : AppColors.text.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
        onTap: () => widget.onItemSelected(index),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        dense: true,
      ),
    );
  }
}
