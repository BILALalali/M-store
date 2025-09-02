import 'package:flutter/material.dart';
import '../../../core/models/mobile_package.dart';
import '../../../core/services/mobile_packages_service.dart';
import '../../../core/theme/app_colors.dart';
import 'add_mobile_operator_screen.dart';
import 'edit_mobile_operator_screen.dart';

class MobileOperatorsScreen extends StatefulWidget {
  const MobileOperatorsScreen({super.key});

  @override
  State<MobileOperatorsScreen> createState() => _MobileOperatorsScreenState();
}

class _MobileOperatorsScreenState extends State<MobileOperatorsScreen> {
  List<MobileOperator> _operators = [];
  List<MobileOperator> _filteredOperators = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _showActiveOnly = false;

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  Future<void> _loadOperators() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final operators = await MobilePackagesService.getAllOperators();

      setState(() {
        _operators = operators;
        _filteredOperators = operators;
        _isLoading = false;
      });

      _filterOperators();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المشغلين: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterOperators() {
    setState(() {
      _filteredOperators = _operators.where((operator) {
        // تصفية حسب الحالة النشطة
        if (_showActiveOnly && !operator.isActive) {
          return false;
        }

        // تصفية حسب البحث
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return operator.name.toLowerCase().contains(query) ||
              operator.displayNameAr.toLowerCase().contains(query) ||
              operator.displayNameEn.toLowerCase().contains(query);
        }

        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterOperators();
  }

  void _onActiveOnlyChanged(bool value) {
    setState(() {
      _showActiveOnly = value;
    });
    _filterOperators();
  }

  Future<void> _deleteOperator(MobileOperator operator) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المشغل "${operator.displayNameAr}"؟'),
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
        await MobilePackagesService.deleteOperator(operator.id!);
        await _loadOperators();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المشغل بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف المشغل: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleOperatorStatus(MobileOperator operator) async {
    try {
      await MobilePackagesService.toggleOperatorStatus(
        operator.id!,
        !operator.isActive,
      );
      await _loadOperators();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              operator.isActive
                  ? 'تم إلغاء تفعيل المشغل'
                  : 'تم تفعيل المشغل',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تغيير حالة المشغل: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // أدوات البحث والتصفية
        _buildFilters(),

        // قائمة المشغلين
        Expanded(child: _buildOperatorsList()),
      ],
    );
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
      child: Row(
        children: [
          // حقل البحث
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'البحث في المشغلين...',
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
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
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

          // فلتر المشغلين النشطين
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _showActiveOnly,
                onChanged: (value) => _onActiveOnlyChanged(value ?? false),
                activeColor: AppColors.primary,
              ),
              const Text('النشطين فقط'),
            ],
          ),

          const SizedBox(width: 16),

          // زر إضافة مشغل جديد
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddMobileOperatorScreen(),
                ),
              );

              if (result == true) {
                await _loadOperators();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة مشغل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredOperators.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: AppColors.text.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'لا توجد مشغلين تطابق البحث'
                  : 'لا توجد مشغلين',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.text.withValues(alpha: 0.6),
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'اضغط على زر "إضافة مشغل" لإضافة مشغل جديد',
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
      itemCount: _filteredOperators.length,
      itemBuilder: (context, index) {
        final operator = _filteredOperators[index];
        return _buildOperatorCard(operator);
      },
    );
  }

  Widget _buildOperatorCard(MobileOperator operator) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: operator.isActive
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
            // أيقونة المشغل
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: operator.isActive
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: operator.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        operator.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.business,
                            color: operator.isActive
                                ? AppColors.primary
                                : AppColors.text.withValues(alpha: 0.4),
                            size: 28,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.business,
                      color: operator.isActive
                          ? AppColors.primary
                          : AppColors.text.withValues(alpha: 0.4),
                      size: 28,
                    ),
            ),

            const SizedBox(width: 20),

            // معلومات المشغل
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          operator.displayNameAr,
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
                          color: operator.isActive
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          operator.isActive ? 'نشط' : 'غير نشط',
                          style: TextStyle(
                            fontSize: 12,
                            color: operator.isActive ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    operator.displayNameEn,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    'الاسم التقني: ${operator.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // الإجراءات
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // زر التعديل
                    IconButton(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditMobileOperatorScreen(
                              operator: operator,
                            ),
                          ),
                        );

                        if (result == true) {
                          await _loadOperators();
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
                      onPressed: () => _toggleOperatorStatus(operator),
                      icon: Icon(
                        operator.isActive ? Icons.visibility_off : Icons.visibility,
                        color: operator.isActive ? AppColors.warning : AppColors.success,
                        size: 20,
                      ),
                      tooltip: operator.isActive ? 'إلغاء التفعيل' : 'تفعيل',
                      style: IconButton.styleFrom(
                        backgroundColor: (operator.isActive ? AppColors.warning : AppColors.success)
                            .withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // زر الحذف
                    IconButton(
                      onPressed: () => _deleteOperator(operator),
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
