// screens/profile/child_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({Key? key}) : super(key: key);

  @override
  _ChildProfileScreenState createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = false;
  File? _selectedImage;
  List<ChildTrigger> _triggers = [];

  // Liste des triggers disponibles pré-définis
  final List<ChildTrigger> _availableTriggers = [
    ChildTrigger(name: 'Noise', intensity: 0, icon: Icons.volume_up),
    ChildTrigger(name: 'Light', intensity: 0, icon: Icons.lightbulb_outline),
    ChildTrigger(name: 'Crowd', intensity: 0, icon: Icons.people_outline),
    ChildTrigger(
      name: 'Temperature',
      intensity: 0,
      icon: Icons.thermostat_outlined,
    ),
    ChildTrigger(name: 'Hunger', intensity: 0, icon: Icons.restaurant_outlined),
    ChildTrigger(name: 'Fatigue', intensity: 0, icon: Icons.bedtime_outlined),
    ChildTrigger(
      name: 'Overstimulation',
      intensity: 0,
      icon: Icons.waves_outlined,
    ),
    ChildTrigger(
      name: 'Change in Routine',
      intensity: 0,
      icon: Icons.change_circle_outlined,
    ),
    ChildTrigger(
      name: 'Loud Sounds',
      intensity: 0,
      icon: Icons.hearing_outlined,
    ),
    ChildTrigger(
      name: 'Strong Smells',
      intensity: 0,
      icon: Icons.smoke_free_outlined,
    ),
    ChildTrigger(
      name: 'Tactile Sensitivity',
      intensity: 0,
      icon: Icons.touch_app_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    _nameController = TextEditingController(text: user?.childName ?? '');
    _dobController = TextEditingController();
    _selectedGender = user?.childGender;

    // Initialiser la date de naissance
    if (user?.childDateOfBirth != null) {
      _selectedDate = user!.childDateOfBirth;
      _dobController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    }

    // Initialiser les triggers
    _triggers = user?.childTriggers ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
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
      setState(() {
        _selectedImage = File(pickedFile.path);
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
      setState(() {
        _selectedImage = File(pickedFile.path);
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
                'Choose Child Photo',
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

  void _updateTriggerIntensity(int index, int intensity) {
    setState(() {
      _triggers[index] = _triggers[index].copyWith(intensity: intensity);
    });
  }

  void _showAddTriggerDialog() {
    final triggersNotSelected = _availableTriggers
        .where((trigger) => !_triggers.any((t) => t.name == trigger.name))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Add Triggers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select triggers or add a custom one',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      // Liste des triggers disponibles
                      if (triggersNotSelected.isNotEmpty)
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: triggersNotSelected.length,
                            itemBuilder: (context, index) {
                              final trigger = triggersNotSelected[index];
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFF0066FF,
                                    ).withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    trigger.icon,
                                    color: const Color(0xFF0066FF),
                                    size: 22,
                                  ),
                                ),
                                title: Text(trigger.name),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Color(0xFF0066FF),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _triggers.add(
                                        trigger.copyWith(intensity: 0),
                                      );
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'All predefined triggers have been added',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),

                const Divider(height: 0),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _addCustomTrigger,
                        child: const Text(
                          'Add Custom Trigger',
                          style: TextStyle(
                            color: Color(0xFF0066FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 48, color: Colors.grey[300]),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addCustomTrigger() {
    final triggerNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Custom Trigger'),
          content: TextField(
            controller: triggerNameController,
            decoration: const InputDecoration(
              hintText: 'Enter custom trigger name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (triggerNameController.text.trim().isNotEmpty) {
                  setState(() {
                    _triggers.add(
                      ChildTrigger(
                        name: triggerNameController.text.trim(),
                        intensity: 0,
                        icon: Icons.add_circle_outline,
                      ),
                    );
                  });
                  Navigator.pop(context);
                  Navigator.pop(context); // Fermer aussi le premier dialogue
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCAD6FF),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeTrigger(int index) {
    setState(() {
      _triggers.removeAt(index);
    });
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.currentUser;

        if (user != null) {
          // Calculer l'âge à partir de la date de naissance
          String? calculatedAge;
          if (_selectedDate != null) {
            final now = DateTime.now();
            final difference = now.difference(_selectedDate!);
            final years = difference.inDays ~/ 365;
            calculatedAge = '$years years';
          }

          // Mettre à jour le user
          final updatedUser = user.copyWith(
            childName: _nameController.text.trim(),
            childDateOfBirth: _selectedDate,
            childGender: _selectedGender,
            childAge: calculatedAge,
            childTriggers: _triggers,
          );

          // TODO: Sauvegarder l'image et le profil dans le backend
          // await authProvider.updateUserProfile(updatedUser);

          await Future.delayed(const Duration(seconds: 1)); // Simulation

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Child profile saved successfully'),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context);
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
                            'Child Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Image de l'enfant modifiable
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _selectedImage == null
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF0066FF),
                                        Color(0xFF0080FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: _selectedImage != null
                                  ? Colors.transparent
                                  : null,
                              image: _selectedImage != null
                                  ? DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
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
                            child: _selectedImage == null
                                ? const Icon(
                                    Icons.child_care,
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
                    const SizedBox(height: 8),
                    const Text(
                      'Tap to change photo',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Formulaire de base
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom complet
                      _buildFormField(
                        controller: _nameController,
                        label: 'Child\'s Full Name',
                        hintText: 'Enter child\'s full name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter child\'s name';
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
                              hintText: 'Select date of birth',
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
                                return 'Please select date of birth';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Genre
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.transgender,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Gender',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              hintText: 'Select gender',
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
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Female'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select gender';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Section Triggers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Personalized Triggers',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Configure sensitivity levels',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddTriggerDialog,
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCAD6FF),
                              foregroundColor: const Color(0xFF0066FF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Liste des triggers (seulement ceux ajoutés)
                      Center(
                        child: Column(
                          children: [
                            if (_triggers.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.add_chart_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No triggers added yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Click "Add" to configure triggers for your child',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._triggers.asMap().entries.map((entry) {
                                final index = entry.key;
                                final trigger = entry.value;
                                return _buildTriggerItem(trigger, index);
                              }).toList(),

                            const SizedBox(height: 40),

                            // Bouton Save
                            SizedBox(
                              width: 250,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProfile,
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
                                        'Save Profile',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
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

  Widget _buildTriggerItem(ChildTrigger trigger, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0066FF).withOpacity(0.1),
                    ),
                    child: Icon(
                      trigger.icon,
                      color: const Color(0xFF0066FF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trigger.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sensitivity: ${trigger.intensity}/10',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _removeTrigger(index),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: trigger.intensity.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '${trigger.intensity}',
            activeColor: const Color(0xFF0066FF),
            inactiveColor: Colors.grey[300],
            onChanged: (value) {
              _updateTriggerIntensity(index, value.toInt());
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Low', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                'Medium',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text('High', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
