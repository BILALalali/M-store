import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool isEditing = false;
  File? _imageFile;
  String? avatarUrl;
  String? userId;

  // إزالة القيم الافتراضية
  String name = '';
  String email = '';
  String phone = '';
  String governorate = '';
  String address = '';

  final List<String> _syrianGovernorates = [
    'دمشق',
    'ريف دمشق',
    'حلب',
    'حمص',
    'حماة',
    'اللاذقية',
    'طرطوس',
    'إدلب',
    'درعا',
    'السويداء',
    'دير الزور',
    'الحسكة',
    'الرقة',
    'القنيطرة',
  ];

  // Controllers
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  String? selectedGovernorate;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();
    selectedGovernorate = governorate;
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;
    userId = user.id;
    final data = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (data != null) {
      setState(() {
        name = data['name'] ?? '';
        email = user.email ?? '';
        phone = data['phone'] ?? '';
        governorate = data['governorate'] ?? '';
        avatarUrl = data['avatar_url'];
        address = data['address'] ?? '';
        nameController.text = name;
        emailController.text = email;
        phoneController.text = phone;
        addressController.text = address;
        selectedGovernorate = governorate;
      });
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _saveChanges() async {
    if (userId == null) return;
    _showLoadingDialog();
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .update({
            'name': nameController.text,
            'phone': phoneController.text,
            'governorate': selectedGovernorate,
            'address': addressController.text,
          })
          .eq('id', userId);
      print('update response: ' + response.toString());
      await _fetchProfile();
      Navigator.of(context).pop();
      setState(() {
        isEditing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات بنجاح!')));
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
    }
  }

  Future<void> _uploadAndSaveImage(File image) async {
    if (userId == null) return;
    final fileExt = image.path.split('.').last;
    final filePath =
        'avatars/$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    try {
      _showLoadingDialog();
      print('--- رفع الصورة إلى Storage ---');
      final storageResponse = await SupabaseService.client.storage
          .from('avatars')
          .upload(filePath, image as dynamic);
      print('storage upload response: $storageResponse');
      final publicUrl = SupabaseService.client.storage
          .from('avatars')
          .getPublicUrl(filePath);
      print('publicUrl: $publicUrl');
      final updateResponse = await SupabaseService.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);
      print('avatar_url update response: $updateResponse');
      await _fetchProfile();
      Navigator.of(context).pop();
      setState(() {
        avatarUrl = publicUrl;
      });
    } catch (e) {
      Navigator.of(context).pop();
      print('Error uploading image: $e');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
      if (!isEditing) {
        // عند إلغاء التعديل، أعد القيم القديمة
        nameController.text = name;
        emailController.text = email;
        phoneController.text = phone;
        addressController.text = address;
        selectedGovernorate = governorate;
      }
    });
  }

  // منطق اختيار صورة من المعرض
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadAndSaveImage(_imageFile!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8ED6EC),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit),
            tooltip: isEditing ? 'إلغاء' : 'تعديل',
            onPressed: _toggleEdit,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8ED6EC), Color(0xFFF6F3EA)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFF8ED6EC),
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (avatarUrl != null && avatarUrl!.isNotEmpty
                                  ? NetworkImage(avatarUrl!) as ImageProvider
                                  : null),
                        child:
                            _imageFile == null &&
                                (avatarUrl == null || avatarUrl!.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      if (isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF23B3C6),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  isEditing
                      ? TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'الاسم الكامل',
                            prefixIcon: Icon(Icons.person),
                          ),
                        )
                      : ListTile(
                          leading: const Icon(
                            Icons.person,
                            color: Color(0xFF23B3C6),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                  const SizedBox(height: 12),
                  isEditing
                      ? TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email),
                          ),
                        )
                      : ListTile(
                          leading: const Icon(
                            Icons.email,
                            color: Color(0xFF23B3C6),
                          ),
                          title: Text(email),
                        ),
                  const SizedBox(height: 12),
                  isEditing
                      ? TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        )
                      : ListTile(
                          leading: const Icon(
                            Icons.phone,
                            color: Color(0xFF23B3C6),
                          ),
                          title: Text(phone),
                        ),
                  const SizedBox(height: 12),
                  isEditing
                      ? DropdownButtonFormField<String>(
                          value: selectedGovernorate,
                          decoration: const InputDecoration(
                            labelText: 'المحافظة',
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          items: _syrianGovernorates
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedGovernorate = value;
                            });
                          },
                        )
                      : ListTile(
                          leading: const Icon(
                            Icons.location_city,
                            color: Color(0xFF23B3C6),
                          ),
                          title: Text(governorate),
                        ),
                  const SizedBox(height: 12),
                  isEditing
                      ? TextFormField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'العنوان',
                            prefixIcon: Icon(Icons.home),
                          ),
                        )
                      : ListTile(
                          leading: const Icon(
                            Icons.home,
                            color: Color(0xFF23B3C6),
                          ),
                          title: Text(address),
                        ),
                  if (isEditing) ...[
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'حفظ التعديلات',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                  if (!isEditing) ...[
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: تنفيذ منطق تسجيل الخروج (مثلاً حذف التوكن من التخزين المحلي)
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/login', (route) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF23B3C6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'تسجيل خروج',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
