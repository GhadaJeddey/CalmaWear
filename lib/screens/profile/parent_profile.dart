// screens/profile/parent_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_service.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({Key? key}) : super(key: key);

  @override
  _ParentProfileScreenState createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  List<TextEditingController> _teacherPhoneControllers = [];
  DateTime? _selectedDate;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes; // For web compatibility
  String? _uploadedImageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers first
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _dobController = TextEditingController();
    // Then load user data
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Refresh user data from Firestore
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUser();

    final user = authProvider.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber ?? '';
      _emailController.text = user.email;

      // Load existing date of birth
      if (user.dateOfBirth != null) {
        _selectedDate = user.dateOfBirth;
        _dobController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      }

      // Load existing profile image URL
      _uploadedImageUrl = user.profileImageUrl;

      // Load existing teacher phone numbers
      _teacherPhoneControllers.clear();
      if (user.teacherPhoneNumbers.isNotEmpty) {
        for (var phone in user.teacherPhoneNumbers) {
          _teacherPhoneControllers.add(TextEditingController(text: phone));
        }
      } else {
        // Add at least one empty field
        _teacherPhoneControllers.add(TextEditingController());
      }

      setState(() {}); // Refresh UI
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    for (var controller in _teacherPhoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addTeacherPhoneField() {
    if (_teacherPhoneControllers.length < 5) {
      setState(() {
        _teacherPhoneControllers.add(TextEditingController());
      });
    }
  }

  void _removeTeacherPhoneField(int index) {
    if (_teacherPhoneControllers.length > 1) {
      setState(() {
        _teacherPhoneControllers[index].dispose();
        _teacherPhoneControllers.removeAt(index);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Choose Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              // Option Galerie
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF0066FF),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              // Option Caméra
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF0066FF),
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              // Annuler
              ListTile(
                leading: const Icon(Icons.close, color: Colors.red),
                title: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.currentUser;

        if (user != null) {
          // Upload image to Cloudinary if selected
          String? profileImageUrl = _uploadedImageUrl;
          if (_selectedImage != null && _uploadedImageUrl == null) {
            setState(() => _isUploadingImage = true);
            profileImageUrl = await _cloudinaryService.uploadParentProfileImage(
              _selectedImage!,
              user.id,
            );
            setState(() => _isUploadingImage = false);

            if (profileImageUrl == null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Failed to upload image, but profile will be saved',
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }

          final updatedUser = user.copyWith(
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            dateOfBirth: _selectedDate,
            profileImageUrl: profileImageUrl ?? user.profileImageUrl,
            teacherPhoneNumbers: _teacherPhoneControllers
                .map((c) => c.text.trim())
                .where((phone) => phone.isNotEmpty)
                .toList(),
          );

          // Save to Firestore
          final success = await authProvider.updateUserProfile(updatedUser);

          if (!mounted) return;

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile updated successfully'),
                backgroundColor: Colors.green[600],
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save: ${authProvider.error}'),
                backgroundColor: Colors.red[600],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // En-tête avec flèche de retour
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    // Flèche de retour + titre
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.black,
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Parent Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Image du parent avec option de modification
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          // Image container
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient:
                                  (_selectedImage == null &&
                                      _uploadedImageUrl == null)
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF0066FF),
                                        Color(0xFF0080FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color:
                                  (_selectedImage != null ||
                                      _uploadedImageUrl != null)
                                  ? Colors.transparent
                                  : null,
                              image: _selectedImageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_selectedImageBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_uploadedImageUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              _uploadedImageUrl!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0066FF,
                                  ).withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child:
                                (_selectedImage == null &&
                                    _uploadedImageUrl == null)
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          // Bouton d'édition
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0066FF),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap to change photo',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Formulaire
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nom complet
                      _buildFormField(
                        controller: _nameController,
                        label: 'Full Name',
                        hintText: 'Enter your full name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Numéro de téléphone
                      _buildFormField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: 'Enter your phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                            return 'Please enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Email
                      _buildFormField(
                        controller: _emailController,
                        label: 'Email Address',
                        hintText: 'Enter your email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Date de naissance
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cake_outlined,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Date of Birth',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'Select your date of birth',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0066FF),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color.fromARGB(
                                113,
                                202,
                                214,
                                255,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => _selectDate(context),
                                icon: const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Color(0xFF0066FF),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select your date of birth';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Teacher Phone Numbers Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Teacher Contact Numbers',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message:
                                    'Teachers receive SMS alerts when child stress is high',
                                child: Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(
                            _teacherPhoneControllers.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller:
                                          _teacherPhoneControllers[index],
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        hintText: '+1234567890',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[500],
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF0066FF),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: const Color.fromARGB(
                                          113,
                                          202,
                                          214,
                                          255,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                        prefixIcon: const Icon(
                                          Icons.phone_outlined,
                                          color: Color(0xFF0066FF),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return null; // Optional
                                        }
                                        if (!value.startsWith('+')) {
                                          return 'Include country code';
                                        }
                                        if (!RegExp(
                                          r'^\+[0-9]{10,15}$',
                                        ).hasMatch(value)) {
                                          return 'Invalid format';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  if (_teacherPhoneControllers.length > 1)
                                    IconButton(
                                      onPressed: () =>
                                          _removeTeacherPhoneField(index),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (_teacherPhoneControllers.length < 5)
                            TextButton.icon(
                              onPressed: _addTeacherPhoneField,
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 20,
                              ),
                              label: const Text('Add Another Teacher'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0066FF),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Bouton Mettre à jour
                      SizedBox(
                        width: 250,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 40,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35),
                            ),
                            elevation: 4,
                            shadowColor: const Color(
                              0xFF0066FF,
                            ).withOpacity(0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  'Update Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
            ),
            filled: true,
            fillColor: const Color.fromARGB(113, 202, 214, 255),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
