import 'package:flutter/material.dart';
import '../../../core/models/mobile_package.dart';
import '../../../core/services/mobile_packages_service.dart';
import '../../../core/theme/app_colors.dart';
import 'add_mobile_package_screen.dart';
import 'edit_mobile_package_screen.dart';
import 'mobile_operators_screen.dart';

class MobilePackagesScreen extends StatefulWidget {
  const MobilePackagesScreen({super.key});

  @override
  State<MobilePackagesScreen> createState() => _MobilePackagesScreenState();
}

class _MobilePackagesScreenState extends State<MobilePackagesScreen>
    with TickerProviderStateMixin {
  List<MobilePackage> _packages = [];
  List<MobilePackage> _filteredPackages = [];
  List<MobileOperator> _operators = [];
  MobileOperator? _selectedOperator;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _showActiveOnly = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // جلب الباقات والمشغلين بشكل متوازي
      final results = await Future.wait([
        MobilePackagesService.getAllPackages(),
        MobilePackagesService.getAllOperators(),
      ]);

      setState(() {
        _packages = results[0] as List<MobilePackage>;
        _operators = results[1] as List<MobileOperator>;
        _filteredPackages = _packages;
        _isLoading = false;
      });

      _filterPackages();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterPackages() {
    setState(() {
      _filteredPackages = _packages.where((package) {
        // تصفية حسب المشغل
        if (_selectedOperator != null &&
            package.operatorId != _selectedOperator!.id) {
          return false;
        }

        // تصفية حسب الحالة النشطة
        if (_showActiveOnly && !package.isActive) {
          return false;
        }

        // تصفية حسب البحث
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return package.packageName.toLowerCase().contains(query) ||
              (package.descriptionAr?.toLowerCase().contains(query) ?? false) ||
              (package.descriptionEn?.toLowerCase().contains(query) ?? false);
        }

        return true;
      }).toList();
    });
  }

  void _onOperatorChanged(MobileOperator? operator) {
    setState(() {
      _selectedOperator = operator;
    });
    _filterPackages();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterPackages();
  }

  void _onActiveOnlyChanged(bool value) {
    setState(() {
      _showActiveOnly = value;
    });
    _filterPackages();
  }

  Future<void> _deletePackage(MobilePackage package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الباقة "${package.packageName}"؟'),
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
        await MobilePackagesService.deletePackage(package.id!);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الباقة بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف الباقة: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _togglePackageStatus(MobilePackage package) async {
    try {
      await MobilePackagesService.togglePackageStatus(
        package.id!,
        !package.isActive,
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              package.isActive ? 'تم إلغاء تفعيل الباقة' : 'تم تفعيل الباقة',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تغيير حالة الباقة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getOperatorName(int operatorId) {
    final operator = _operators.firstWhere(
      (op) => op.id == operatorId,
      orElse: () => MobileOperator(
        name: 'غير محدد',
        displayNameAr: 'غير محدد',
        displayNameEn: 'Unknown',
      ),
    );
    return operator.displayNameAr;
  }

  // الحصول على بيانات المشغل
  MobileOperator? _getOperator(int operatorId) {
    try {
      return _operators.firstWhere((op) => op.id == operatorId);
    } catch (e) {
      return null;
    }
  }

  // بناء صورة المشغل أو أيقونة افتراضية
  Widget _buildOperatorLogo(MobilePackage package) {
    final operator = _getOperator(package.operatorId);
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: package.isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: operator?.logoUrl != null && operator!.logoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                operator.logoUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.phone_android,
                    color: package.isActive
                        ? AppColors.primary
                        : AppColors.text.withValues(alpha: 0.4),
                    size: 28,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        package.isActive ? AppColors.primary : AppColors.text.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                },
              ),
            )
          : Icon(
              Icons.phone_android,
              color: package.isActive
                  ? AppColors.primary
                  : AppColors.text.withValues(alpha: 0.4),
              size: 28,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // رأس الصفحة
          _buildHeader(),

          // تبويبات
          _buildTabs(),

          // المحتوى
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPackagesTab(), _buildOperatorsTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddMobilePackageScreen(),
                  ),
                );

                if (result == true) {
                  await _loadData();
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(Icons.phone_android, size: 32, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة بطاقات الجوال',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'إدارة وإضافة وتعديل باقات ومشغلي الجوال',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_filteredPackages.length} باقة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.secondary.withValues(alpha: 0.2)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.text.withValues(alpha: 0.6),
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(icon: Icon(Icons.phone_android), text: 'الباقات'),
          Tab(icon: Icon(Icons.business), text: 'المشغلين'),
        ],
      ),
    );
  }

  Widget _buildPackagesTab() {
    return Column(
      children: [
        // أدوات البحث والتصفية
        _buildFilters(),

        // قائمة الباقات
        Expanded(child: _buildPackagesList()),
      ],
    );
  }

  Widget _buildOperatorsTab() {
    return const MobileOperatorsScreen();
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.secondary.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // حقل البحث
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'البحث في الباقات...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.secondary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // قائمة المشغلين
              Flexible(
                child: DropdownButtonFormField<MobileOperator>(
                  value: _selectedOperator,
                  onChanged: _onOperatorChanged,
                  decoration: InputDecoration(
                    labelText: 'المشغل',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.secondary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<MobileOperator>(
                      value: null,
                      child: Text('جميع المشغلين'),
                    ),
                    ..._operators.map((operator) {
                      return DropdownMenuItem<MobileOperator>(
                        value: operator,
                        child: Text(operator.displayNameAr),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // فلتر الباقات النشطة
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _showActiveOnly,
                    onChanged: (value) => _onActiveOnlyChanged(value ?? false),
                    activeColor: AppColors.primary,
                  ),
                  const Text('النشطة فقط'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredPackages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_android_outlined,
              size: 64,
              color: AppColors.text.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedOperator != null
                  ? 'لا توجد باقات تطابق البحث'
                  : 'لا توجد باقات',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.text.withValues(alpha: 0.6),
              ),
            ),
            if (_searchQuery.isEmpty && _selectedOperator == null) ...[
              const SizedBox(height: 8),
              Text(
                'اضغط على زر + لإضافة باقة جديدة',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredPackages.length,
      itemBuilder: (context, index) {
        final package = _filteredPackages[index];
        return _buildPackageCard(package);
      },
    );
  }

  Widget _buildPackageCard(MobilePackage package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: package.isActive
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.secondary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // صورة المشغل أو أيقونة الباقة
            _buildOperatorLogo(package),

            const SizedBox(width: 20),

            // معلومات الباقة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          package.packageName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: package.isActive
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          package.isActive ? 'نشط' : 'غير نشط',
                          style: TextStyle(
                            fontSize: 12,
                            color: package.isActive
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getOperatorName(package.operatorId),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ترتيب: ${package.sortOrder}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.text.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (package.descriptionAr != null &&
                      package.descriptionAr!.isNotEmpty)
                    Text(
                      package.descriptionAr!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // السعر والإجراءات
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${package.packageValue.toStringAsFixed(0)} ل.س',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'السعر: ${package.packagePrice.toStringAsFixed(2)} ل.س',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // زر التعديل
                    IconButton(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditMobilePackageScreen(
                              package: package,
                              operators: _operators,
                            ),
                          ),
                        );

                        if (result == true) {
                          await _loadData();
                        }
                      },
                      icon: Icon(Icons.edit, color: AppColors.info, size: 20),
                      tooltip: 'تعديل',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.info.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // زر تغيير الحالة
                    IconButton(
                      onPressed: () => _togglePackageStatus(package),
                      icon: Icon(
                        package.isActive
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: package.isActive
                            ? AppColors.warning
                            : AppColors.success,
                        size: 20,
                      ),
                      tooltip: package.isActive ? 'إلغاء التفعيل' : 'تفعيل',
                      style: IconButton.styleFrom(
                        backgroundColor:
                            (package.isActive
                                    ? AppColors.warning
                                    : AppColors.success)
                                .withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // زر الحذف
                    IconButton(
                      onPressed: () => _deletePackage(package),
                      icon: Icon(
                        Icons.delete,
                        color: AppColors.error,
                        size: 20,
                      ),
                      tooltip: 'حذف',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
