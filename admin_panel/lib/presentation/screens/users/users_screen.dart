import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/users_service.dart';
import '../../../core/utils/util_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UsersService _usersService = UsersService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _usersService.getUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب المستخدمين: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          final name = user['name']?.toString().toLowerCase() ?? '';
          final phone = user['phone']?.toString().toLowerCase() ?? '';
          final governorate = user['governorate']?.toString().toLowerCase() ?? '';
          final address = user['address']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          
          return name.contains(searchLower) ||
                 phone.contains(searchLower) ||
                 governorate.contains(searchLower) ||
                 address.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _resetUserPassword(Map<String, dynamic> user) async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('تغيير كلمة المرور'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'المستخدم: ${user['name'] ?? 'غير محدد'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
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

              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('تغيير'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // عرض مؤشر التحميل
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('جاري تغيير كلمة المرور...'),
              ],
            ),
          ),
        );

        // تغيير كلمة المرور
        await _usersService.resetUserPassword(
          user['id'],
          passwordController.text,
        );

        // إغلاق مؤشر التحميل
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تغيير كلمة مرور المستخدم "${user['name'] ?? 'غير محدد'}" بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        // إغلاق مؤشر التحميل
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تغيير كلمة المرور: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        passwordController.dispose();
        confirmPasswordController.dispose();
      }
    } else {
      passwordController.dispose();
      confirmPasswordController.dispose();
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المستخدم "${user['name'] ?? 'غير محدد'}"؟\n\nهذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // عرض مؤشر التحميل
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('جاري حذف المستخدم...'),
              ],
            ),
          ),
        );

        // محاولة الحذف باستخدام service_role أولاً
        bool deleted = false;
        try {
          await _usersService.deleteUserWithServiceRole(user['id']);
          deleted = true;
        } catch (e) {
          print('فشل الحذف باستخدام service_role: $e');
          // محاولة الحذف العادي
          await _usersService.deleteUser(user['id']);
          deleted = true;
        }

        // إغلاق مؤشر التحميل
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (deleted) {
          // إزالة المستخدم من القائمة
          setState(() {
            _users.removeWhere((u) => u['id'] == user['id']);
            _filteredUsers.removeWhere((u) => u['id'] == user['id']);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم حذف المستخدم "${user['name'] ?? 'غير محدد'}" بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } catch (e) {
        // إغلاق مؤشر التحميل
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف المستخدم: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenType = UtilScreen.getScreenType(context);
          final padding = UtilScreen.getPadding(context, PaddingType.medium);
          final spacing = UtilScreen.getSpacing(context);
          
          return SingleChildScrollView(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - padding.vertical,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رأس الصفحة
                  _buildHeader(context, screenType),

                  SizedBox(height: spacing * 2),

                  // شريط البحث
                  _buildSearchBar(context, screenType),

                  SizedBox(height: spacing * 1.5),

                  // إحصائيات سريعة
                  _buildStatsCards(context, screenType),

                  SizedBox(height: spacing * 1.5),

                  // قائمة المستخدمين
                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(spacing * 2),
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  else if (_filteredUsers.isEmpty)
                    _buildEmptyState(context, screenType)
                  else
                    _buildUsersList(context, screenType, constraints),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ScreenType screenType) {
    final titleSize = UtilScreen.getFontSize(context, FontSizeType.title);
    final subtitleSize = UtilScreen.getFontSize(context, FontSizeType.subtitle);
    final iconSize = UtilScreen.isMobile(context) ? 24.0 : 32.0;

    return Row(
      children: [
        Icon(Icons.people, size: iconSize, color: AppColors.primary),
        SizedBox(width: UtilScreen.getSpacing(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة المستخدمين',
                style: TextStyle(
                  fontSize: titleSize + 8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'إدارة المستخدمين المسجلين في النظام',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        // زر التحديث
        IconButton(
          onPressed: _loadUsers,
          icon: Icon(Icons.refresh, color: AppColors.primary),
          tooltip: 'تحديث',
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, ScreenType screenType) {
    final padding = UtilScreen.getPadding(context, PaddingType.small);
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterUsers,
        decoration: InputDecoration(
          hintText: 'البحث في المستخدمين...',
          hintStyle: TextStyle(color: AppColors.text.withValues(alpha: 0.5)),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterUsers('');
                  },
                  icon: Icon(Icons.clear, color: AppColors.text.withValues(alpha: 0.5)),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, ScreenType screenType) {
    final spacing = UtilScreen.getSpacing(context);
    
    if (UtilScreen.isMobile(context)) {
      return Column(
        children: [
          _buildStatCard(
            context,
            'إجمالي المستخدمين',
            '${_users.length}',
            Icons.people,
            AppColors.primary,
          ),
          SizedBox(height: spacing),
          _buildStatCard(
            context,
            'المستخدمين المفلترين',
            '${_filteredUsers.length}',
            Icons.filter_list,
            AppColors.info,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'إجمالي المستخدمين',
            '${_users.length}',
            Icons.people,
            AppColors.primary,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildStatCard(
            context,
            'المستخدمين المفلترين',
            '${_filteredUsers.length}',
            Icons.filter_list,
            AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final padding = UtilScreen.getPadding(context, PaddingType.card);
    final bodySize = UtilScreen.getFontSize(context, FontSizeType.body);
    final titleSize = UtilScreen.getFontSize(context, FontSizeType.title);
    final iconSize = UtilScreen.isMobile(context) ? 20.0 : 24.0;
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: iconSize),
          SizedBox(width: UtilScreen.getSpacing(context)),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: titleSize + 4,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: bodySize,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ScreenType screenType) {
    final padding = UtilScreen.getPadding(context, PaddingType.large);
    final titleSize = UtilScreen.getFontSize(context, FontSizeType.title);
    final bodySize = UtilScreen.getFontSize(context, FontSizeType.body);
    final iconSize = UtilScreen.isMobile(context) ? 48.0 : 64.0;
    
    return Container(
      padding: padding,
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: iconSize,
            color: AppColors.text.withValues(alpha: 0.3),
          ),
          SizedBox(height: UtilScreen.getSpacing(context) * 2),
          Text(
            _searchQuery.isEmpty ? 'لا يوجد مستخدمين' : 'لا توجد نتائج للبحث',
            style: TextStyle(
              fontSize: titleSize,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: UtilScreen.getSpacing(context)),
          Text(
            _searchQuery.isEmpty 
                ? 'لم يتم تسجيل أي مستخدمين بعد'
                : 'جرب البحث بكلمات مختلفة',
            style: TextStyle(
              fontSize: bodySize,
              color: AppColors.text.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(BuildContext context, ScreenType screenType, BoxConstraints constraints) {
    final isMobile = UtilScreen.isMobile(context);
    final isTablet = screenType == ScreenType.tablet;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // رأس الجدول
          Container(
            padding: UtilScreen.getPadding(context, PaddingType.small),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: isMobile
                ? _buildMobileHeader(context)
                : _buildDesktopHeader(context, isTablet),
          ),
          // قائمة المستخدمين
          ..._filteredUsers.map((user) => _buildUserRow(context, user, isMobile, isTablet)),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildHeaderText(context, 'الاسم'),
        ),
        Expanded(
          child: _buildHeaderText(context, 'الإجراءات'),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(BuildContext context, bool isTablet) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildHeaderText(context, 'الاسم')),
        if (!isTablet) Expanded(flex: 2, child: _buildHeaderText(context, 'رقم الهاتف')),
        Expanded(flex: isTablet ? 3 : 2, child: _buildHeaderText(context, 'المحافظة')),
        if (!isTablet) Expanded(flex: 2, child: _buildHeaderText(context, 'العنوان')),
        Expanded(flex: 1, child: _buildHeaderText(context, 'تاريخ التسجيل')),
        Expanded(flex: 1, child: _buildHeaderText(context, 'الإجراءات')),
      ],
    );
  }

  Widget _buildHeaderText(BuildContext context, String text) {
    final fontSize = UtilScreen.getFontSize(context, FontSizeType.body);
    
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        fontSize: fontSize,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildUserRow(
    BuildContext context,
    Map<String, dynamic> user,
    bool isMobile,
    bool isTablet,
  ) {
    final createdAt = user['created_at'] != null
        ? DateTime.parse(user['created_at'])
        : null;
    
    final formattedDate = createdAt != null
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
        : 'غير محدد';

    final padding = UtilScreen.getPadding(context, PaddingType.small);
    final bodySize = UtilScreen.getFontSize(context, FontSizeType.body);
    final captionSize = UtilScreen.getFontSize(context, FontSizeType.caption);
    final iconSize = UtilScreen.isMobile(context) ? 18.0 : 20.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: isMobile
          ? _buildMobileUserRow(context, user, formattedDate, iconSize, bodySize)
          : _buildDesktopUserRow(context, user, formattedDate, isTablet, iconSize, bodySize, captionSize),
    );
  }

  Widget _buildMobileUserRow(
    BuildContext context,
    Map<String, dynamic> user,
    String formattedDate,
    double iconSize,
    double fontSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name']?.toString() ?? 'غير محدد',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                      fontSize: fontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user['phone'] != null) ...[
                    SizedBox(height: 4),
                    Text(
                      user['phone']?.toString() ?? '',
                      style: TextStyle(
                        color: AppColors.text.withValues(alpha: 0.7),
                        fontSize: fontSize - 2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _resetUserPassword(user),
                  icon: Icon(
                    Icons.lock_reset,
                    color: AppColors.warning,
                    size: iconSize,
                  ),
                  tooltip: 'تغيير كلمة المرور',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteUser(user),
                  icon: Icon(
                    Icons.delete,
                    color: AppColors.error,
                    size: iconSize,
                  ),
                  tooltip: 'حذف المستخدم',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (user['governorate'] != null || user['address'] != null) ...[
          SizedBox(height: 8),
          Text(
            '${user['governorate'] ?? ''}${user['address'] != null ? ' - ${user['address']}' : ''}',
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.6),
              fontSize: fontSize - 2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        SizedBox(height: 4),
        Text(
          formattedDate,
          style: TextStyle(
            color: AppColors.text.withValues(alpha: 0.5),
            fontSize: fontSize - 2,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopUserRow(
    BuildContext context,
    Map<String, dynamic> user,
    String formattedDate,
    bool isTablet,
    double iconSize,
    double bodySize,
    double captionSize,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            user['name']?.toString() ?? 'غير محدد',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w500,
              fontSize: bodySize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isTablet)
          Expanded(
            flex: 2,
            child: Text(
              user['phone']?.toString() ?? 'غير محدد',
              style: TextStyle(
                color: AppColors.text,
                fontSize: bodySize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Expanded(
          flex: isTablet ? 3 : 2,
          child: Text(
            user['governorate']?.toString() ?? 'غير محدد',
            style: TextStyle(
              color: AppColors.text,
              fontSize: bodySize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isTablet)
          Expanded(
            flex: 2,
            child: Text(
              user['address']?.toString() ?? 'غير محدد',
              style: TextStyle(
                color: AppColors.text,
                fontSize: bodySize,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Expanded(
          flex: 1,
          child: Text(
            formattedDate,
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.7),
              fontSize: captionSize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _resetUserPassword(user),
                icon: Icon(
                  Icons.lock_reset,
                  color: AppColors.warning,
                  size: iconSize,
                ),
                tooltip: 'تغيير كلمة المرور',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                onPressed: () => _deleteUser(user),
                icon: Icon(
                  Icons.delete,
                  color: AppColors.error,
                  size: iconSize,
                ),
                tooltip: 'حذف المستخدم',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
