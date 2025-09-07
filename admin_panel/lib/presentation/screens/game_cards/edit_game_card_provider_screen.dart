import 'package:flutter/material.dart';
import '../../../core/models/game_card.dart';
import '../../../core/services/game_cards_service.dart';
import '../../../core/theme/app_colors.dart';

class EditGameCardProviderScreen extends StatefulWidget {
  final GameCardProvider provider;

  const EditGameCardProviderScreen({super.key, required this.provider});

  @override
  State<EditGameCardProviderScreen> createState() =>
      _EditGameCardProviderScreenState();
}

class _EditGameCardProviderScreenState
    extends State<EditGameCardProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _displayNameArController = TextEditingController();
  final _displayNameEnController = TextEditingController();
  final _logoUrlController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameArController.dispose();
    _displayNameEnController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    _nameController.text = widget.provider.name ?? '';
    _displayNameArController.text = widget.provider.displayNameAr ?? '';
    _displayNameEnController.text = widget.provider.displayNameEn ?? '';
    _logoUrlController.text = widget.provider.logoUrl ?? '';
  }

  Future<void> _saveProvider() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProvider = widget.provider.copyWith(
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        displayNameAr: _displayNameArController.text.trim().isEmpty
            ? null
            : _displayNameArController.text.trim(),
        displayNameEn: _displayNameEnController.text.trim().isEmpty
            ? null
            : _displayNameEnController.text.trim(),
        logoUrl: _logoUrlController.text.trim().isEmpty
            ? null
            : _logoUrlController.text.trim(),
      );

      await GameCardsService.updateProvider(updatedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث مقدم الخدمة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث مقدم الخدمة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل مقدم خدمة'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات أساسية
              _buildSectionHeader('المعلومات الأساسية'),
              const SizedBox(height: 16),

              // الاسم التقني
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم التقني *',
                  hintText: 'مثال: steam, xbox, nintendo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الاسم التقني مطلوب';
                  }
                  if (!RegExp(r'^[a-z_]+$').hasMatch(value.trim())) {
                    return 'الاسم التقني يجب أن يحتوي على أحرف صغيرة وشرطات سفلية فقط';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // الاسم المعروض بالعربية
              TextFormField(
                controller: _displayNameArController,
                decoration: InputDecoration(
                  labelText: 'الاسم المعروض بالعربية *',
                  hintText: 'مثال: Steam',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الاسم المعروض بالعربية مطلوب';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // الاسم المعروض بالإنجليزية
              TextFormField(
                controller: _displayNameEnController,
                decoration: InputDecoration(
                  labelText: 'الاسم المعروض بالإنجليزية *',
                  hintText: 'Example: Steam',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الاسم المعروض بالإنجليزية مطلوب';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // رابط الشعار
              _buildSectionHeader('الشعار'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _logoUrlController,
                onChanged: (value) {
                  setState(() {}); // إعادة بناء الواجهة لمعاينة الشعار
                },
                decoration: InputDecoration(
                  labelText: 'رابط الشعار',
                  hintText: 'مثال: assets/steam_icon.png',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // معاينة الشعار
              if (_logoUrlController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معاينة الشعار:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _logoUrlController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.business,
                                  color: AppColors.primary,
                                  size: 40,
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // أزرار الحفظ والإلغاء
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProvider,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'حفظ التغييرات',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text,
                        side: BorderSide(color: AppColors.secondary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      ),
    );
  }
}
