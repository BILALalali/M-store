import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/services/supabase_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Constants
  static const Color _primaryColor = Color(0xFF8ED6EC);
  static const Color _secondaryColor = Color(0xFF23B3C6);
  static const Color _backgroundColor = Color(0xFFF6F3EA);

  // State variables
  bool isEditing = false;
  File? _imageFile;
  String? avatarUrl;
  String? userId;

  // User data
  String name = '';
  String email = '';
  String phone = '';
  String governorate = '';
  String address = '';

  // Controllers
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  String? selectedGovernorate;

  // Syrian governorates list
  static const List<String> _syrianGovernorates = [
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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchProfile();
  }

  void _initializeControllers() {
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();
    selectedGovernorate = governorate;
  }

  Future<void> _fetchProfile() async {
    // التحقق من أن Supabase متوفر
    if (SupabaseService.client == null) {
      print('Supabase غير متوفر');
      return;
    }
    
    final user = SupabaseService.client!.auth.currentUser;
    if (user == null) return;

    userId = user.id;
    final data = await SupabaseService.client!
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

        // Update controllers
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
      // التحقق من أن Supabase متوفر
      if (SupabaseService.client == null) {
        throw Exception('Supabase غير متوفر');
      }
      
      await SupabaseService.client!
          .from('profiles')
          .update({
            'name': nameController.text,
            'phone': phoneController.text,
            'governorate': selectedGovernorate,
            'address': addressController.text,
          })
          .eq('id', userId!);

      await _fetchProfile();
      Navigator.of(context).pop();
      setState(() {
        isEditing = false;
      });

      _showSuccessMessage('تم حفظ التعديلات بنجاح!');
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorMessage('حدث خطأ أثناء الحفظ: $e');
    }
  }

  Future<void> _uploadAndSaveImage(File image) async {
    if (userId == null) return;

    final fileExt = image.path.split('.').last;
    final filePath =
        'avatars/$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      _showLoadingDialog();

      // التحقق من أن Supabase متوفر
      if (SupabaseService.client == null) {
        throw Exception('Supabase غير متوفر');
      }

      // Upload to storage
      await SupabaseService.client!.storage
          .from('avatars')
          .upload(filePath, image as dynamic);

      // Get public URL
      final publicUrl = SupabaseService.client!.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Update profile
      await SupabaseService.client!
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId!);

      await _fetchProfile();
      Navigator.of(context).pop();
      setState(() {
        avatarUrl = publicUrl;
      });
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorMessage('خطأ في رفع الصورة: $e');
    }
  }

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
      if (!isEditing) {
        // Reset to original values when canceling edit
        nameController.text = name;
        emailController.text = email;
        phoneController.text = phone;
        addressController.text = address;
        selectedGovernorate = governorate;
      }
    });
  }

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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout() async {
    try {
      // تسجيل الخروج من Supabase أولاً
      if (SupabaseService.client != null) {
        await SupabaseService.client!.auth.signOut();
        print('تم تسجيل الخروج من Supabase بنجاح');
      }
      
      // الانتقال لشاشة تسجيل الدخول
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      print('خطأ في تسجيل الخروج: $e');
      // حتى لو حدث خطأ، انتقل لشاشة تسجيل الدخول
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryColor,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(isEditing ? Icons.close : Icons.edit),
          tooltip: isEditing ? 'إلغاء' : 'تعديل',
          onPressed: _toggleEdit,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_primaryColor, _backgroundColor],
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
                _buildAvatarSection(),
                const SizedBox(height: 18),
                _buildProfileFields(),
                const SizedBox(height: 28),
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: _primaryColor,
          backgroundImage: _getAvatarImage(),
          child: _getAvatarChild(),
        ),
        if (isEditing) _buildCameraButton(),
      ],
    );
  }

  ImageProvider? _getAvatarImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return NetworkImage(avatarUrl!);
    }
    return null;
  }

  Widget? _getAvatarChild() {
    if (_imageFile == null && (avatarUrl == null || avatarUrl!.isEmpty)) {
      return const Icon(Icons.person, size: 48, color: Colors.white);
    }
    return null;
  }

  Widget _buildCameraButton() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: InkWell(
        onTap: _pickImage,
        child: Container(
          decoration: BoxDecoration(
            color: _secondaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          padding: const EdgeInsets.all(6),
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildProfileFields() {
    return Column(
      children: [
        _buildField(
          icon: Icons.person,
          label: 'الاسم الكامل',
          controller: nameController,
          value: name,
        ),
        const SizedBox(height: 12),
        _buildField(
          icon: Icons.email,
          label: 'البريد الإلكتروني',
          controller: emailController,
          value: email,
        ),
        const SizedBox(height: 12),
        _buildField(
          icon: Icons.phone,
          label: 'رقم الهاتف',
          controller: phoneController,
          value: phone,
        ),
        const SizedBox(height: 12),
        _buildGovernorateField(),
        const SizedBox(height: 12),
        _buildField(
          icon: Icons.home,
          label: 'العنوان',
          controller: addressController,
          value: address,
        ),
      ],
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String value,
  }) {
    if (isEditing) {
      return TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      );
    } else {
      return ListTile(
        leading: Icon(icon, color: _secondaryColor),
        title: Text(
          value,
          style: label == 'الاسم الكامل'
              ? const TextStyle(fontWeight: FontWeight.bold)
              : null,
        ),
      );
    }
  }

  Widget _buildGovernorateField() {
    if (isEditing) {
      return DropdownButtonFormField<String>(
        value: selectedGovernorate,
        decoration: const InputDecoration(
          labelText: 'المحافظة',
          prefixIcon: Icon(Icons.location_city),
        ),
        items: _syrianGovernorates
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedGovernorate = value;
          });
        },
      );
    } else {
      return ListTile(
        leading: const Icon(Icons.location_city, color: Color(0xFF23B3C6)),
        title: Text(governorate),
      );
    }
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEditing ? _saveChanges : _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEditing ? null : _secondaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isEditing ? 'حفظ التعديلات' : 'تسجيل خروج',
          style: TextStyle(
            fontSize: 16,
            color: isEditing ? null : Colors.white,
          ),
        ),
      ),
    );
  }
}
