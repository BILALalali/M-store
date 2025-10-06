import 'package:flutter/material.dart';
import '../../../core/models/advertisement.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
// import '../../../core/utils/util_screen.dart';
import 'add_advertisement_screen.dart';

class AdvertisementsScreen extends StatefulWidget {
  const AdvertisementsScreen({super.key});

  @override
  State<AdvertisementsScreen> createState() => _AdvertisementsScreenState();
}

class _AdvertisementsScreenState extends State<AdvertisementsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Advertisement> _advertisements = [];
  List<Advertisement> _filteredAdvertisements = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'الكل';

  @override
  void initState() {
    super.initState();
    _ensureTableExists();
  }

  // التأكد من وجود الجدول والسياسات
  Future<void> _ensureTableExists() async {
    try {
      await _supabaseService.ensureAdvertisementsTableExists();
      await _loadAdvertisements();
    } catch (e) {
      print('خطأ في التأكد من وجود الجدول: $e');
      // محاولة تحميل الإعلانات حتى لو فشل إنشاء السياسات
      await _loadAdvertisements();
    }
  }

  Future<void> _loadAdvertisements() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final data = await _supabaseService.getAdvertisements();
      final advertisements = data
          .map((map) => Advertisement.fromMap(map))
          .toList();

      setState(() {
        _advertisements = advertisements;
        _filteredAdvertisements = advertisements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الإعلانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterAdvertisements() {
    setState(() {
      _filteredAdvertisements = _advertisements.where((ad) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            ad.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            ad.description.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesStatus =
            _selectedStatus == 'الكل' ||
            (_selectedStatus == 'نشط' && ad.isActive) ||
            (_selectedStatus == 'غير نشط' && !ad.isActive);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _deleteAdvertisement(Advertisement advertisement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الإعلان "${advertisement.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteAdvertisement(advertisement.id);
        await _loadAdvertisements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الإعلان بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف الإعلان: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleAdvertisementStatus(Advertisement advertisement) async {
    try {
      await _supabaseService.toggleAdvertisementStatus(
        advertisement.id,
        !advertisement.isActive,
      );
      await _loadAdvertisements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              advertisement.isActive
                  ? 'تم إلغاء تفعيل الإعلان'
                  : 'تم تفعيل الإعلان',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تغيير حالة الإعلان: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            Expanded(child: _buildAdvertisementsList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddAdvertisementScreen(),
            ),
          );
          if (result == true) {
            _loadAdvertisements();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, size: 32, color: AppColors.primary),
              const SizedBox(width: 16),
              Text(
                'إدارة الإعلانات',
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
            'إدارة الإعلانات والعروض الترويجية',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // حقل البحث
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _filterAdvertisements();
              },
              decoration: InputDecoration(
                hintText: 'البحث في الإعلانات...',
                prefixIcon: const Icon(Icons.search),
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

          // فلتر الحالة
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
                _filterAdvertisements();
              },
              decoration: InputDecoration(
                labelText: 'الحالة',
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
              items: const [
                DropdownMenuItem(value: 'الكل', child: Text('الكل')),
                DropdownMenuItem(value: 'نشط', child: Text('نشط')),
                DropdownMenuItem(value: 'غير نشط', child: Text('غير نشط')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertisementsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredAdvertisements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: AppColors.text.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedStatus != 'الكل'
                  ? 'لا توجد إعلانات تطابق البحث'
                  : 'لا توجد إعلانات',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.text.withValues(alpha: 0.6),
              ),
            ),
            if (_searchQuery.isEmpty && _selectedStatus == 'الكل') ...[
              const SizedBox(height: 8),
              Text(
                'اضغط على زر + لإضافة إعلان جديد',
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
      itemCount: _filteredAdvertisements.length,
      itemBuilder: (context, index) {
        final advertisement = _filteredAdvertisements[index];
        return _buildAdvertisementCard(advertisement);
      },
    );
  }

  Widget _buildAdvertisementCard(Advertisement advertisement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // صورة الإعلان
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              advertisement.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: AppColors.text.withValues(alpha: 0.4),
                  ),
                );
              },
            ),
          ),

          // تفاصيل الإعلان
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        advertisement.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: advertisement.isActive
                            ? Colors.green
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        advertisement.isActive ? 'نشط' : 'غير نشط',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  advertisement.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // معلومات إضافية
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.priority_high,
                      'الأولوية: ${advertisement.priority}',
                      AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.calendar_today,
                      'من: ${_formatDate(advertisement.startDate)}',
                      AppColors.secondary,
                    ),
                    if (advertisement.endDate != null) ...[
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        Icons.event_busy,
                        'إلى: ${_formatDate(advertisement.endDate!)}',
                        Colors.orange,
                      ),
                    ],
                  ],
                ),

                if (advertisement.linkUrl != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.link, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          advertisement.linkUrl!,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // أزرار الإجراءات
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () =>
                          _toggleAdvertisementStatus(advertisement),
                      icon: Icon(
                        advertisement.isActive
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      tooltip: advertisement.isActive
                          ? 'إلغاء التفعيل'
                          : 'تفعيل',
                      color: advertisement.isActive
                          ? Colors.orange
                          : Colors.green,
                    ),
                    IconButton(
                      onPressed: () => _deleteAdvertisement(advertisement),
                      icon: const Icon(Icons.delete),
                      tooltip: 'حذف',
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
