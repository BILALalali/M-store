import 'package:flutter/material.dart';
import '../../../core/models/mobile_package.dart';
import '../../../core/services/mobile_packages_service.dart';
import '../../../core/theme/app_colors.dart';

class EditMobileOperatorScreen extends StatefulWidget {
  final MobileOperator operator;

  const EditMobileOperatorScreen({super.key, required this.operator});

  @override
  State<EditMobileOperatorScreen> createState() =>
      _EditMobileOperatorScreenState();
}

class _EditMobileOperatorScreenState extends State<EditMobileOperatorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _displayNameArController;
  late TextEditingController _displayNameEnController;
  late TextEditingController _logoUrlController;

  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.operator.name);
    _displayNameArController = TextEditingController(
      text: widget.operator.displayNameAr,
    );
    _displayNameEnController = TextEditingController(
      text: widget.operator.displayNameEn,
    );
    _logoUrlController = TextEditingController(
      text: widget.operator.logoUrl ?? '',
    );
    _isActive = widget.operator.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameArController.dispose();
    _displayNameEnController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateOperator() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedOperator = widget.operator.copyWith(
        name: _nameController.text.trim(),
        displayNameAr: _displayNameArController.text.trim(),
        displayNameEn: _displayNameEnController.text.trim(),
        logoUrl: _logoUrlController.text.trim().isEmpty
            ? null
            : _logoUrlController.text.trim(),
        isActive: _isActive,
      );

      await MobilePackagesService.updateOperator(updatedOperator);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث المشغل بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث المشغل: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المشغل'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات المشغل الأساسية
              _buildSectionHeader('معلومات المشغل الأساسية'),
              const SizedBox(height: 16),

              // الاسم التقني
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم التقني *',
                  hintText: 'مثال: syriatel, mtn, wafa',
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
                  hintText: 'مثال: سيرياتيل',
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
                  hintText: 'مثال: SyriaTel',
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

              const SizedBox(height: 16),

              // رابط الشعار
              TextFormField(
                controller: _logoUrlController,
                decoration: InputDecoration(
                  labelText: 'رابط الشعار (اختياري)',
                  hintText: 'https://example.com/logo.png',
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
                  if (value != null && value.trim().isNotEmpty) {
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null || !uri.hasAbsolutePath) {
                      return 'يرجى إدخال رابط صحيح';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // الإعدادات
              _buildSectionHeader('الإعدادات'),
              const SizedBox(height: 16),

              // حالة المشغل
              SwitchListTile(
                title: const Text('المشغل نشط'),
                subtitle: const Text('المشغل سيظهر في قائمة المشغلين'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: AppColors.primary,
              ),

              const SizedBox(height: 32),

              // أزرار الحفظ والإلغاء
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateOperator,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('تحديث المشغل'),
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
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      ),
    );
  }
}
