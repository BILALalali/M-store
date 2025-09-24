import 'package:flutter/material.dart';
import '../../../core/models/game_card.dart';
import '../../../core/services/game_cards_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:html' as html;

class AddGameCardProviderScreen extends StatefulWidget {
  const AddGameCardProviderScreen({super.key});

  @override
  State<AddGameCardProviderScreen> createState() =>
      _AddGameCardProviderScreenState();
}

class _AddGameCardProviderScreenState extends State<AddGameCardProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _displayNameArController = TextEditingController();
  final _displayNameEnController = TextEditingController();

  bool _isSaving = false;
  bool _isUploadingImage = false;
  String? _selectedImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameArController.dispose();
    _displayNameEnController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false;

    input.click();

    input.onChange.listen((e) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        if (file.type.startsWith('image/')) {
          setState(() {
            _isUploadingImage = true;
          });
          _uploadImage(file);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يرجى اختيار ملف صورة صالح'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<void> _uploadImage(html.File file) async {
    try {
      final supabaseService = SupabaseService();
      final imageUrl = await supabaseService.uploadImage(file);

      if (imageUrl != null) {
        setState(() {
          _selectedImageUrl = imageUrl;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الصورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('فشل في رفع الصورة');
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProvider() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = GameCardProvider(
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        displayNameAr: _displayNameArController.text.trim().isEmpty
            ? null
            : _displayNameArController.text.trim(),
        displayNameEn: _displayNameEnController.text.trim().isEmpty
            ? null
            : _displayNameEnController.text.trim(),
        logoUrl: _selectedImageUrl,
        isActive: true,
      );

      await GameCardsService.addProvider(provider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة مقدم الخدمة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة مقدم الخدمة: $e'),
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
        title: const Text('إضافة مقدم خدمة'),
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

              // رفع الشعار
              _buildSectionHeader('الشعار'),
              const SizedBox(height: 16),

              // زر اختيار الصورة
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.cardBackground,
                ),
                child: InkWell(
                  onTap: _isUploadingImage ? null : _selectImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isUploadingImage)
                        Column(
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'جاري رفع الصورة...',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.text.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        )
                      else if (_selectedImageUrl != null)
                        Column(
                          children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _selectedImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.secondary.withValues(
                                        alpha: 0.1,
                                      ),
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: AppColors.secondary.withValues(
                                          alpha: 0.5,
                                        ),
                                        size: 30,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
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
                            const SizedBox(height: 8),
                            Text(
                              'تم اختيار الصورة',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'اضغط لتغيير الصورة',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.text.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'اختر صورة الشعار',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PNG, JPG, GIF (حد أقصى 5MB)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.text.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
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
                              'حفظ مقدم الخدمة',
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
