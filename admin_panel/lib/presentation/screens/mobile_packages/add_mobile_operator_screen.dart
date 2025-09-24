import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import '../../../core/models/mobile_package.dart';
import '../../../core/services/mobile_packages_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';

class AddMobileOperatorScreen extends StatefulWidget {
  const AddMobileOperatorScreen({super.key});

  @override
  State<AddMobileOperatorScreen> createState() =>
      _AddMobileOperatorScreenState();
}

class _AddMobileOperatorScreenState extends State<AddMobileOperatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _displayNameArController = TextEditingController();
  final _displayNameEnController = TextEditingController();
  final _logoUrlController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameArController.dispose();
    _displayNameEnController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  // اختيار صورة للمشغل
  Future<void> _pickImage() async {
    try {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();

          reader.onLoadEnd.listen((e) {
            setState(() {
              _selectedImageBytes = reader.result as Uint8List;
              _selectedImageName = file.name;
            });
          });

          reader.readAsArrayBuffer(file);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصورة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // رفع الصورة إلى Supabase Storage
  Future<String?> _uploadImage() async {
    if (_selectedImageBytes == null || _selectedImageName == null) {
      return null;
    }

    try {
      // إنشاء مسار فريد للصورة
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'operator_${timestamp}_$_selectedImageName';

      // رفع الصورة إلى Supabase Storage
      final supabaseService = SupabaseService();
      final client = supabaseService.client;

      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      await client.storage
          .from('operator_logos')
          .uploadBinary(fileName, _selectedImageBytes!);

      // الحصول على رابط الصورة العامة
      final imageUrl = client.storage
          .from('operator_logos')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      throw Exception('فشل في رفع الصورة: $e');
    }
  }

  Future<void> _saveOperator() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? logoUrl;

      // رفع الصورة إذا تم اختيارها
      if (_selectedImageBytes != null) {
        logoUrl = await _uploadImage();
      } else if (_logoUrlController.text.trim().isNotEmpty) {
        // استخدام الرابط المرفق يدوياً
        logoUrl = _logoUrlController.text.trim();
      }

      final operator = MobileOperator(
        name: _nameController.text.trim(),
        displayNameAr: _displayNameArController.text.trim(),
        displayNameEn: _displayNameEnController.text.trim(),
        logoUrl: logoUrl,
        isActive: _isActive,
      );

      await MobilePackagesService.addOperator(operator);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المشغل بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة المشغل: $e'),
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
        title: const Text('إضافة مشغل جديد'),
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

              // اختيار صورة المشغل
              _buildImagePicker(),

              const SizedBox(height: 16),

              // رابط الشعار (بديل)
              TextFormField(
                controller: _logoUrlController,
                decoration: InputDecoration(
                  labelText: 'رابط الشعار (بديل - اختياري)',
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
                      onPressed: _isLoading ? null : _saveOperator,
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
                          : const Text('حفظ المشغل'),
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

  // واجهة اختيار صورة المشغل
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'شعار المشغل',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _selectedImageBytes != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _selectedImageBytes!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImageBytes = null;
                            _selectedImageName = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اضغط لاختيار صورة',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        if (_selectedImageName != null) ...[
          const SizedBox(height: 8),
          Text(
            'الملف المختار: $_selectedImageName',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ],
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
