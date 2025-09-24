import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';

class AddAdvertisementScreen extends StatefulWidget {
  const AddAdvertisementScreen({super.key});

  @override
  State<AddAdvertisementScreen> createState() => _AddAdvertisementScreenState();
}

class _AddAdvertisementScreenState extends State<AddAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _priorityController = TextEditingController();

  // State variables
  html.File? _selectedImage;
  bool _isLoading = false;
  bool _isActive = true;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _ensureTableExists();
  }

  // التأكد من وجود الجدول والسياسات
  Future<void> _ensureTableExists() async {
    try {
      await _supabaseService.ensureAdvertisementsTableExists();
    } catch (e) {
      print('خطأ في التأكد من وجود الجدول: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkUrlController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  // اختيار صورة من الجهاز
  void _pickImage() {
    try {
      final input = html.FileUploadInputElement()
        ..accept = 'image/*'
        ..multiple = false;

      input.onChange.listen((event) {
        if (input.files != null && input.files!.isNotEmpty) {
          setState(() {
            _selectedImage = input.files!.first;
          });
        }
      });

      input.click();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // حذف الصورة المختارة
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // حفظ الإعلان
  Future<void> _saveAdvertisement() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار صورة للإعلان'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // رفع الصورة إلى Supabase Storage
      final imageUrl = await _supabaseService.uploadImage(_selectedImage!);
      if (imageUrl == null) {
        throw Exception('فشل في رفع الصورة');
      }

      // إنشاء بيانات الإعلان
      final advertisementData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'link_url': _linkUrlController.text.trim().isEmpty
            ? null
            : _linkUrlController.text.trim(),
        'is_active': _isActive,
        'priority': int.parse(_priorityController.text),
        'start_date': _startDate.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'admin_id': _supabaseService.currentUserId, // إضافة معرف المدير الحالي
      };

      // حفظ الإعلان في قاعدة البيانات
      final result = await _supabaseService.addAdvertisement(advertisementData);

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ الإعلان بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('فشل في حفظ الإعلان');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الإعلان: $e'),
            backgroundColor: Colors.red,
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

  // اختيار تاريخ البداية
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  // اختيار تاريخ الانتهاء
  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة إعلان جديد'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildBasicInfoSection(),
                    const SizedBox(height: 32),
                    _buildImageSection(),
                    const SizedBox(height: 32),
                    _buildSettingsSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'إضافة إعلان جديد',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل تفاصيل الإعلان الجديد',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('المعلومات الأساسية', Icons.info),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _titleController,
          label: 'عنوان الإعلان',
          hint: 'أدخل عنوان الإعلان',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال عنوان الإعلان';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'وصف الإعلان',
          hint: 'أدخل وصف الإعلان',
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال وصف الإعلان';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _linkUrlController,
          label: 'رابط الإعلان (اختياري)',
          hint: 'https://example.com',
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final uri = Uri.tryParse(value);
              if (uri == null || !uri.hasAbsolutePath) {
                return 'يرجى إدخال رابط صحيح';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('صورة الإعلان', Icons.image),
        const SizedBox(height: 16),

        if (_selectedImage != null) ...[
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 48, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  _selectedImage!.name,
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete),
                  label: const Text('إزالة الصورة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 48,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 8),
                Text(
                  'لم يتم اختيار صورة',
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('اختيار صورة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('إعدادات الإعلان', Icons.settings),
        const SizedBox(height: 16),

        // الأولوية
        _buildTextField(
          controller: _priorityController,
          label: 'الأولوية',
          hint: '1',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال الأولوية';
            }
            final priority = int.tryParse(value);
            if (priority == null || priority < 1 || priority > 10) {
              return 'الأولوية يجب أن تكون بين 1 و 10';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // التواريخ
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'تاريخ البداية',
                value: _startDate,
                onTap: _selectStartDate,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'تاريخ الانتهاء (اختياري)',
                value: _endDate,
                onTap: _selectEndDate,
                isOptional: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // حالة التفعيل
        SwitchListTile(
          title: const Text('تفعيل الإعلان'),
          subtitle: Text(
            _isActive
                ? 'الإعلان نشط وسيتم عرضه'
                : 'الإعلان غير نشط ولن يتم عرضه',
          ),
          value: _isActive,
          onChanged: (value) {
            setState(() {
              _isActive = value;
            });
          },
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _saveAdvertisement,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'حفظ الإعلان',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إلغاء', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool isOptional = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? '${value.day}/${value.month}/${value.year}'
                      : isOptional
                      ? 'اختياري'
                      : 'اختر التاريخ',
                  style: TextStyle(
                    color: value != null
                        ? AppColors.text
                        : AppColors.text.withValues(alpha: 0.5),
                    fontSize: 16,
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
