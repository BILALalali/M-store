import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/users_service.dart';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس الصفحة
            Row(
              children: [
                Icon(Icons.people, size: 32, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة المستخدمين',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'إدارة المستخدمين المسجلين في النظام',
                        style: TextStyle(
                          fontSize: 16,
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
            ),

            const SizedBox(height: 32),

            // شريط البحث
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ),

            const SizedBox(height: 24),

            // إحصائيات سريعة
            _buildStatsCards(),

            const SizedBox(height: 24),

            // قائمة المستخدمين
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredUsers.isEmpty)
              _buildEmptyState()
            else
              _buildUsersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'إجمالي المستخدمين',
            '${_users.length}',
            Icons.people,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'المستخدمين المفلترين',
            '${_filteredUsers.length}',
            Icons.filter_list,
            AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.text.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'لا يوجد مستخدمين' : 'لا توجد نتائج للبحث',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'لم يتم تسجيل أي مستخدمين بعد'
                : 'جرب البحث بكلمات مختلفة',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildHeaderText('الاسم')),
                Expanded(flex: 2, child: _buildHeaderText('رقم الهاتف')),
                Expanded(flex: 2, child: _buildHeaderText('المحافظة')),
                Expanded(flex: 2, child: _buildHeaderText('العنوان')),
                Expanded(flex: 1, child: _buildHeaderText('تاريخ التسجيل')),
                Expanded(flex: 1, child: _buildHeaderText('الإجراءات')),
              ],
            ),
          ),
          // قائمة المستخدمين
          ..._filteredUsers.map((user) => _buildUserRow(user)),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        fontSize: 14,
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    final createdAt = user['created_at'] != null
        ? DateTime.parse(user['created_at'])
        : null;
    
    final formattedDate = createdAt != null
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
        : 'غير محدد';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              user['name']?.toString() ?? 'غير محدد',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user['phone']?.toString() ?? 'غير محدد',
              style: TextStyle(color: AppColors.text),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user['governorate']?.toString() ?? 'غير محدد',
              style: TextStyle(color: AppColors.text),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user['address']?.toString() ?? 'غير محدد',
              style: TextStyle(color: AppColors.text),
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
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                // زر الحذف
                IconButton(
                  onPressed: () => _deleteUser(user),
                  icon: Icon(
                    Icons.delete,
                    color: AppColors.error,
                    size: 20,
                  ),
                  tooltip: 'حذف المستخدم',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
