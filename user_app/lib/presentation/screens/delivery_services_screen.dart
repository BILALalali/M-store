import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'orders_screen.dart';
import '../../core/services/order_chat_service.dart';

class DeliveryServicesScreen extends StatefulWidget {
  const DeliveryServicesScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryServicesScreen> createState() => _DeliveryServicesScreenState();
}

class _DeliveryServicesScreenState extends State<DeliveryServicesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cargoTypeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // قائمة أوزان الشحنات
  final List<int> _weightOptions = List.generate(500, (index) => index + 1);
  int? _selectedWeight;

  // متغيرات حالة التحميل
  bool _isLoading = false;
  bool _isUploading = false;

  // ألوان الهوية البصرية
  static const Color primaryColor = Color(0xFF1EC6D9); // فيروزي
  static const Color accentColor = Color(0xFF2E3A59); // أزرق داكن
  static const Color backgroundColor = Color(0xFFF8F9FA); // رمادي فاتح
  static const Color cardColor = Color(0xFFFFFFFF); // أبيض
  static const Color textColor = Color(0xFF2C3E50); // رمادي داكن

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // التحقق من وجود صورة
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار صورة للشحنة'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // بدء التحميل
      setState(() {
        _isLoading = true;
        _isUploading = true;
      });

      try {
        // إنشاء طلب توصيل محفوظ في Supabase ثم إضافته لقائمة المحادثات
        final cargoType = _cargoTypeController.text.trim();
        final location = _locationController.text.trim();
        final desc = _descriptionController.text.trim();
        final weight = _selectedWeight ?? 0;

        final created = await OrderChatService.createDeliveryRequest(
          cargoType: cargoType,
          weightKg: weight,
          location: location,
          description: desc,
          imageFile: _selectedImage!,
        );

        // إضافة الطلب إلى قائمة المحادثات
        OrdersScreen.confirmedOrders.add(created);

        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إرسال طلب التوصيل بنجاح! يمكنك متابعة الطلب من شاشة طلباتي',
            ),
            backgroundColor: primaryColor,
            duration: Duration(seconds: 3),
          ),
        );

        // تفريغ النموذج بعد النجاح
        _formKey.currentState!.reset();
        _cargoTypeController.clear();
        _locationController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedImage = null;
          _selectedWeight = null;
        });
      } catch (e) {
        // عرض رسالة خطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر إرسال الطلب: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      } finally {
        // إنهاء التحميل
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cargoTypeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // زر الرجوع
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'خدمات التوصيل',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // العنوان الرئيسي
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'خدمات التوصيل',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'املأ النموذج أدناه لطلب خدمة التوصيل المطلوبة',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // حقل نوع البضاعة
                _buildTextField(
                  controller: _cargoTypeController,
                  label: 'نوع البضاعة',
                  hint: 'أدخل نوع البضاعة المراد توصيلها',
                  icon: Icons.inventory,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال نوع البضاعة';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // حقل الوزن
                _buildWeightDropdown(),

                const SizedBox(height: 20),

                // حقل المكان
                _buildTextField(
                  controller: _locationController,
                  label: 'مكان الشحنة',
                  hint: 'أدخل عنوان مكان الشحنة',
                  icon: Icons.location_on,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال مكان الشحنة';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // حقل الوصف
                _buildTextField(
                  controller: _descriptionController,
                  label: 'وصف الشحنة',
                  hint: 'أدخل وصفاً مفصلاً للشحنة والتفاصيل المطلوبة',
                  icon: Icons.description,
                  maxLines: 4,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال وصف الشحنة';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // حقل رفع الصورة
                _buildImagePicker(),

                const SizedBox(height: 32),

                // مؤشر التحميل
                if (_isUploading) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'جاري رفع الصورة وحفظ البيانات...',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // زر الإرسال
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'جاري الإرسال...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'إرسال طلب التوصيل',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // معلومات إضافية
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'سيتم التواصل معك خلال 24 ساعة لتأكيد طلب التوصيل وتحديد السعر',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(color: textColor, fontFamily: 'Cairo'),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          labelStyle: const TextStyle(color: primaryColor, fontFamily: 'Cairo'),
          hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Cairo'),
        ),
        enabled: enabled,
      ),
    );
  }

  Widget _buildWeightDropdown() {
    return AbsorbPointer(
      absorbing: _isLoading,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonFormField<int>(
          value: _selectedWeight,
          decoration: InputDecoration(
            labelText: 'وزن الشحنة',
            hintText: 'اختر وزن الشحنة',
            prefixIcon: Icon(Icons.scale, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            labelStyle: const TextStyle(
              color: primaryColor,
              fontFamily: 'Cairo',
            ),
            hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Cairo'),
          ),
          items: _weightOptions.map((int weight) {
            return DropdownMenuItem<int>(
              value: weight,
              child: Text(
                '$weight كغ',
                style: const TextStyle(color: textColor, fontFamily: 'Cairo'),
              ),
            );
          }).toList(),
          onChanged: (int? newValue) {
            setState(() {
              _selectedWeight = newValue;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'يرجى اختيار وزن الشحنة';
            }
            return null;
          },
          dropdownColor: cardColor,
          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
          style: const TextStyle(color: textColor, fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.image, color: primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'صورة الشحنة *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          if (_selectedImage != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
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
              ),
            ),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(
                  _selectedImage == null ? 'اختر صورة' : 'تغيير الصورة',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
