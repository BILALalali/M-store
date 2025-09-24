import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/game_card.dart';
import '../../../core/services/game_cards_service.dart';
import '../../../core/theme/app_colors.dart';

class AddGameCardScreen extends StatefulWidget {
  const AddGameCardScreen({super.key});

  @override
  State<AddGameCardScreen> createState() => _AddGameCardScreenState();
}

class _AddGameCardScreenState extends State<AddGameCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _cardValueController = TextEditingController();
  final _cardPriceController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');

  List<GameCardProvider> _providers = [];
  GameCardProvider? _selectedProvider;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardValueController.dispose();
    _cardPriceController.dispose();
    _descriptionArController.dispose();
    _descriptionEnController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    try {
      final providers = await GameCardsService.getAllProviders();
      setState(() {
        _providers = providers;
        _isLoading = false;
      });
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

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار مقدم الخدمة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final card = GameCard(
        providerId: _selectedProvider!.id,
        cardName: _cardNameController.text.trim().isEmpty
            ? null
            : _cardNameController.text.trim(),
        cardValue: _cardValueController.text.trim().isEmpty
            ? null
            : double.parse(_cardValueController.text),
        cardPrice: _cardPriceController.text.trim().isEmpty
            ? null
            : double.parse(_cardPriceController.text),
        descriptionAr: _descriptionArController.text.trim().isEmpty
            ? null
            : _descriptionArController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim().isEmpty
            ? null
            : _descriptionEnController.text.trim(),
        sortOrder: _sortOrderController.text.trim().isEmpty
            ? null
            : int.parse(_sortOrderController.text),
        isActive: true,
      );

      await GameCardsService.addCard(card);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة البطاقة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة البطاقة: $e'),
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
        title: const Text('إضافة بطاقة لعبة'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات أساسية
                    _buildSectionHeader('المعلومات الأساسية'),
                    const SizedBox(height: 16),

                    // اسم البطاقة
                    TextFormField(
                      controller: _cardNameController,
                      decoration: InputDecoration(
                        labelText: 'اسم البطاقة *',
                        hintText: 'مثال: Steam Gift Card',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اسم البطاقة مطلوب';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // مقدم الخدمة
                    DropdownButtonFormField<GameCardProvider>(
                      value: _selectedProvider,
                      onChanged: (value) {
                        setState(() {
                          _selectedProvider = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'مقدم الخدمة *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _providers.map((provider) {
                        return DropdownMenuItem<GameCardProvider>(
                          value: provider,
                          child: Text(
                            provider.displayNameAr ?? 'غير محدد',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'مقدم الخدمة مطلوب';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // قيمة البطاقة والسعر
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cardValueController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'قيمة البطاقة (\$) *',
                              hintText: '50',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'قيمة البطاقة مطلوبة';
                              }
                              final val = double.tryParse(value);
                              if (val == null || val <= 0) {
                                return 'قيمة البطاقة يجب أن تكون رقم أكبر من 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cardPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'السعر (ل.س) *',
                              hintText: '52.50',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'السعر مطلوب';
                              }
                              final val = double.tryParse(value);
                              if (val == null || val <= 0) {
                                return 'السعر يجب أن يكون رقم أكبر من 0';
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'ترتيب العرض',
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'ترتيب العرض مطلوب';
                        }
                        final val = int.tryParse(value);
                        if (val == null || val < 0) {
                          return 'ترتيب العرض يجب أن يكون رقم أكبر من أو يساوي 0';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // الوصف
                    _buildSectionHeader('الوصف'),
                    const SizedBox(height: 16),

                    // الوصف بالعربية
                    TextFormField(
                      controller: _descriptionArController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'الوصف بالعربية',
                        hintText: 'مثال: بطاقة هدايا Steam - 50\$',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
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
                        hintText: 'Example: Steam Gift Card - 50\$',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // أزرار الحفظ والإلغاء
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveCard,
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
                                    'حفظ البطاقة',
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
