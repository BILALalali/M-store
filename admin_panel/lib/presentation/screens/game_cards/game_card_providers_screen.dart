import 'package:flutter/material.dart';
import '../../../core/models/game_card.dart';
import '../../../core/services/game_cards_service.dart';
import '../../../core/theme/app_colors.dart';
import 'add_game_card_provider_screen.dart';
import 'edit_game_card_provider_screen.dart';

class GameCardProvidersScreen extends StatefulWidget {
  const GameCardProvidersScreen({super.key});

  @override
  State<GameCardProvidersScreen> createState() =>
      _GameCardProvidersScreenState();
}

class _GameCardProvidersScreenState extends State<GameCardProvidersScreen> {
  List<GameCardProvider> _providers = [];
  List<GameCardProvider> _filteredProviders = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _showActiveOnly = false;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final providers = await GameCardsService.getAllProviders();
      setState(() {
        _providers = providers;
        _filteredProviders = providers;
        _isLoading = false;
      });

      _filterProviders();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل مقدمي الخدمة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterProviders() {
    setState(() {
      _filteredProviders = _providers.where((provider) {
        // تصفية حسب الحالة النشطة
        if (_showActiveOnly && !provider.isActive) {
          return false;
        }

        // تصفية حسب البحث
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return (provider.name?.toLowerCase().contains(query) ?? false) ||
              (provider.displayNameAr?.toLowerCase().contains(query) ??
                  false) ||
              (provider.displayNameEn?.toLowerCase().contains(query) ?? false);
        }

        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProviders();
  }

  void _onActiveOnlyChanged(bool value) {
    setState(() {
      _showActiveOnly = value;
    });
    _filterProviders();
  }

  Future<void> _deleteProvider(GameCardProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف مقدم الخدمة "${provider.displayNameAr}"؟',
        ),
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
        await GameCardsService.deleteProvider(provider.id!);
        await _loadProviders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف مقدم الخدمة بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف مقدم الخدمة: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleProviderStatus(GameCardProvider provider) async {
    try {
      await GameCardsService.toggleProviderStatus(
        provider.id!,
        !provider.isActive,
      );
      await _loadProviders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.isActive
                  ? 'تم إلغاء تفعيل مقدم الخدمة'
                  : 'تم تفعيل مقدم الخدمة',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تغيير حالة مقدم الخدمة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // بناء صورة مقدم الخدمة أو أيقونة افتراضية
  Widget _buildProviderLogo(GameCardProvider provider) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: provider.isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: provider.logoUrl != null && provider.logoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                provider.logoUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.business,
                    color: provider.isActive
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
                        provider.isActive
                            ? AppColors.primary
                            : AppColors.text.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                },
              ),
            )
          : Icon(
              Icons.business,
              color: provider.isActive
                  ? AppColors.primary
                  : AppColors.text.withValues(alpha: 0.4),
              size: 28,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // أدوات البحث والتصفية
        _buildFilters(),

        // قائمة مقدمي الخدمة
        Expanded(child: _buildProvidersList()),
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
                hintText: 'البحث في مقدمي الخدمة...',
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

          // فلتر مقدمي الخدمة النشطين
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

          // زر إضافة مقدم خدمة جديد
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddGameCardProviderScreen(),
                ),
              );

              if (result == true) {
                await _loadProviders();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة مقدم خدمة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredProviders.isEmpty) {
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
                  ? 'لا توجد مقدمي خدمة تطابق البحث'
                  : 'لا توجد مقدمي خدمة',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.text.withValues(alpha: 0.6),
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'اضغط على زر "إضافة مقدم خدمة" لإضافة مقدم خدمة جديد',
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
      itemCount: _filteredProviders.length,
      itemBuilder: (context, index) {
        final provider = _filteredProviders[index];
        return _buildProviderCard(provider);
      },
    );
  }

  Widget _buildProviderCard(GameCardProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: provider.isActive
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
            // صورة مقدم الخدمة
            _buildProviderLogo(provider),

            const SizedBox(width: 20),

            // معلومات مقدم الخدمة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.displayNameAr ?? 'مقدم خدمة غير محدد',
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
                          color: provider.isActive
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          provider.isActive ? 'نشط' : 'غير نشط',
                          style: TextStyle(
                            fontSize: 12,
                            color: provider.isActive
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    provider.displayNameEn ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'الاسم التقني: ${provider.name ?? 'غير محدد'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // الإجراءات
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر التعديل
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            EditGameCardProviderScreen(provider: provider),
                      ),
                    );

                    if (result == true) {
                      await _loadProviders();
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
                  onPressed: () => _toggleProviderStatus(provider),
                  icon: Icon(
                    provider.isActive ? Icons.visibility_off : Icons.visibility,
                    color: provider.isActive
                        ? AppColors.warning
                        : AppColors.success,
                    size: 20,
                  ),
                  tooltip: provider.isActive ? 'إلغاء التفعيل' : 'تفعيل',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        (provider.isActive
                                ? AppColors.warning
                                : AppColors.success)
                            .withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),

                const SizedBox(width: 8),

                // زر الحذف
                IconButton(
                  onPressed: () => _deleteProvider(provider),
                  icon: Icon(Icons.delete, color: AppColors.error, size: 20),
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
      ),
    );
  }
}
