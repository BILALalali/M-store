import 'package:flutter/material.dart';
import '../../../core/models/mobile_package.dart';
import '../../../core/services/mobile_packages_service.dart';
import '../../../core/theme/app_colors.dart';

class EditMobilePackageScreen extends StatefulWidget {
  final MobilePackage package;
  final List<MobileOperator> operators;

  const EditMobilePackageScreen({
    super.key,
    required this.package,
    required this.operators,
  });

  @override
  State<EditMobilePackageScreen> createState() =>
      _EditMobilePackageScreenState();
}

class _EditMobilePackageScreenState extends State<EditMobilePackageScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _packageNameController;
  late TextEditingController _packageValueController;
  late TextEditingController _packagePriceController;
  late TextEditingController _descriptionArController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _sortOrderController;

  MobileOperator? _selectedOperator;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _findSelectedOperator();

    // إضافة listener لحقل قيمة الباقة لملء الوصف تلقائياً
    _packageValueController.addListener(_updateDescriptionFromValue);
  }

  void _initializeControllers() {
    _packageNameController = TextEditingController(
      text: widget.package.packageName,
    );
    _packageValueController = TextEditingController(
      text: widget.package.packageValue.toString(),
    );
    _packagePriceController = TextEditingController(
      text: widget.package.packagePrice.toString(),
    );
    _descriptionArController = TextEditingController(
      text: widget.package.descriptionAr ?? '',
    );
    _descriptionEnController = TextEditingController(
      text: widget.package.descriptionEn ?? '',
    );
    _sortOrderController = TextEditingController(
      text: widget.package.sortOrder.toString(),
    );
    _isActive = widget.package.isActive;
  }

  void _findSelectedOperator() {
    _selectedOperator = widget.operators.firstWhere(
      (op) => op.id == widget.package.operatorId,
      orElse: () => widget.operators.first,
    );
  }

  // تحديث الوصف تلقائياً بناءً على قيمة الباقة
  void _updateDescriptionFromValue() {
    final value = _packageValueController.text.trim();
    if (value.isNotEmpty) {
      // تحديث الوصف بالعربية تلقائياً
      _descriptionArController.text = 'قيمة الباقة: $value';

      // تحديث الوصف بالإنجليزية تلقائياً
      _descriptionEnController.text = 'Package Value: $value';

      // تحديث اسم الباقة تلقائياً
      _updatePackageName();
    } else {
      // إذا كان الحقل فارغ، امسح الوصف
      _descriptionArController.clear();
      _descriptionEnController.clear();
      _packageNameController.clear();
    }
  }

  // تحديث اسم الباقة تلقائياً بناءً على المشغل والقيمة
  void _updatePackageName() {
    final value = _packageValueController.text.trim();
    if (value.isNotEmpty && _selectedOperator != null) {
      _packageNameController.text =
          '${_selectedOperator!.displayNameAr} $value';
    }
  }

  // تحديث اسم الباقة عند تغيير المشغل
  void _onOperatorChanged(MobileOperator? operator) {
    setState(() {
      _selectedOperator = operator;
    });
    _updatePackageName();
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _packageValueController.dispose();
    _packagePriceController.dispose();
    _descriptionArController.dispose();
    _descriptionEnController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _updatePackage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedOperator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المشغل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedPackage = widget.package.copyWith(
        operatorId: _selectedOperator!.id!,
        packageName: _packageNameController.text.trim(),
        packageValue: double.parse(_packageValueController.text),
        packagePrice: double.parse(_packagePriceController.text),
        descriptionAr: _descriptionArController.text.trim().isEmpty
            ? null
            : _descriptionArController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim().isEmpty
            ? null
            : _descriptionEnController.text.trim(),
        isActive: _isActive,
        sortOrder: int.tryParse(_sortOrderController.text) ?? 0,
      );

      await MobilePackagesService.updatePackage(updatedPackage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الباقة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الباقة: $e'),
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
        title: const Text('تعديل الباقة'),
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
              // معلومات الباقة الأساسية
              _buildSectionHeader('معلومات الباقة الأساسية'),
              const SizedBox(height: 16),

              // حقل اسم الباقة مخفي (يتم ملؤه تلقائياً)
              Visibility(
                visible: false,
                child: TextFormField(
                  controller: _packageNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اسم الباقة مطلوب';
                    }
                    return null;
                  },
                ),
              ),

              // المشغل
              DropdownButtonFormField<MobileOperator>(
                value: _selectedOperator,
                onChanged: _onOperatorChanged,
                decoration: InputDecoration(
                  labelText: 'المشغل *',
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
                items: widget.operators.map((operator) {
                  return DropdownMenuItem<MobileOperator>(
                    value: operator,
                    child: Text(operator.displayNameAr),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'يرجى اختيار المشغل';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // قيمة الباقة والسعر
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _packageValueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'قيمة الباقة (ل.س) *',
                        hintText: '50',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'قيمة الباقة مطلوبة';
                        }
                        if (double.tryParse(value) == null) {
                          return 'يرجى إدخال رقم صحيح';
                        }
                        if (double.parse(value) <= 0) {
                          return 'قيمة الباقة يجب أن تكون أكبر من صفر';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _packagePriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'سعر الباقة (ل.س) *',
                        hintText: '52.50',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'سعر الباقة مطلوب';
                        }
                        if (double.tryParse(value) == null) {
                          return 'يرجى إدخال رقم صحيح';
                        }
                        if (double.parse(value) <= 0) {
                          return 'سعر الباقة يجب أن يكون أكبر من صفر';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ترتيب العرض
              TextFormField(
                controller: _sortOrderController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ترتيب العرض',
                  hintText: '0',
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
                    if (int.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // الوصف
              _buildSectionHeader('الوصف'),
              const SizedBox(height: 16),

              // الوصف بالعربية
              TextFormField(
                controller: _descriptionArController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'الوصف بالعربية',
                  hintText: 'قيمة الباقة: 50 ليرة سورية',
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

              // الوصف بالإنجليزية
              TextFormField(
                controller: _descriptionEnController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'الوصف بالإنجليزية',
                  hintText: 'Package Value: 50 Syrian Lira',
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

              const SizedBox(height: 24),

              // الإعدادات
              _buildSectionHeader('الإعدادات'),
              const SizedBox(height: 16),

              // حالة الباقة
              SwitchListTile(
                title: const Text('الباقة نشطة'),
                subtitle: const Text('الباقة ستظهر للمستخدمين'),
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
                      onPressed: _isLoading ? null : _updatePackage,
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
                          : const Text('تحديث الباقة'),
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
