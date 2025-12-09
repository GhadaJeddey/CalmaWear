// First, add these dependencies to your pubspec.yaml:
// dependencies:
//   record: ^5.0.0
//   path_provider: ^2.1.0
//   audioplayers: ^5.2.0

// screens/profile/child_profile.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_service.dart';
import 'package:go_router/go_router.dart';

class ChildProfileScreen extends StatefulWidget {
  final bool isSetupMode;

  const ChildProfileScreen({Key? key, this.isSetupMode = false})
    : super(key: key);

  @override
  _ChildProfileScreenState createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  late TextEditingController _nameController;
  late TextEditingController _dobController;
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isUploadingAudio = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes; // For web compatibility
  String? _uploadedImageUrl; // Store uploaded image URL
  List<ChildTrigger> _triggers = [];

  // Voice memo related
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _voiceMemoPath; // Local file path
  String? _voiceMemoUrl; // Cloudinary URL
  Duration _recordDuration = Duration.zero;

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
    // Initialize controllers first
    _nameController = TextEditingController();
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
      _nameController.text = user.childName ?? '';
      _selectedGender = user.childGender;

      if (user.childDateOfBirth != null) {
        _selectedDate = user.childDateOfBirth;
        _dobController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      }

      _triggers = user.childTriggers;

      // Load existing child profile image URL
      _uploadedImageUrl = user.childProfileImageUrl;

      // Load existing voice memo URL
      _voiceMemoUrl = user.childVoiceMemoUrl;

      setState(() {}); // Refresh UI
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/voice_memo_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);

        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });

        // Update duration
        Future.doWhile(() async {
          await Future.delayed(const Duration(seconds: 1));
          if (_isRecording) {
            setState(() {
              _recordDuration += const Duration(seconds: 1);
            });
            return true;
          }
          return false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _voiceMemoPath = path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice memo recorded successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error stopping recording: $e')));
    }
  }

  Future<void> _playVoiceMemo() async {
    if (_voiceMemoPath == null && _voiceMemoUrl == null) return;

    try {
      setState(() => _isPlaying = true);

      // Play from URL if available (works on web), otherwise from local path
      if (_voiceMemoUrl != null) {
        await _audioPlayer.play(UrlSource(_voiceMemoUrl!));
      } else if (_voiceMemoPath != null) {
        await _audioPlayer.play(DeviceFileSource(_voiceMemoPath!));
      }

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() => _isPlaying = false);
      });
    } catch (e) {
      setState(() => _isPlaying = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
    }
  }

  Future<void> _stopPlaying() async {
    await _audioPlayer.stop();
    setState(() => _isPlaying = false);
  }

  Future<void> _deleteVoiceMemo() async {
    if (_voiceMemoPath != null) {
      try {
        // On web, we can't delete files, just clear the path
        setState(() => _voiceMemoPath = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice memo deleted'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting voice memo: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
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
                backgroundColor: const Color(0xFF0066FF),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
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
          String? calculatedAge;
          if (_selectedDate != null) {
            final now = DateTime.now();
            final difference = now.difference(_selectedDate!);
            final years = difference.inDays ~/ 365;
            calculatedAge = '$years years';
          }

          // Upload image to Cloudinary if selected
          String? childImageUrl = _uploadedImageUrl;
          if (_selectedImage != null && _uploadedImageUrl == null) {
            setState(() => _isUploadingImage = true);
            childImageUrl = await _cloudinaryService.uploadChildProfileImage(
              _selectedImage!,
              user.id,
            );
            setState(() => _isUploadingImage = false);

            if (childImageUrl == null && mounted) {
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

          // Upload voice memo to Cloudinary if recorded
          String? voiceMemoUrl;
          if (_voiceMemoPath != null) {
            setState(() => _isUploadingAudio = true);
            voiceMemoUrl = await _cloudinaryService.uploadVoiceMemo(
              _voiceMemoPath!,
              user.id,
            );
            setState(() => _isUploadingAudio = false);

            if (voiceMemoUrl == null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Failed to upload voice memo, but profile will be saved',
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }

          final updatedUser = user.copyWith(
            childName: _nameController.text.trim(),
            childDateOfBirth: _selectedDate,
            childGender: _selectedGender,
            childAge: calculatedAge,
            childProfileImageUrl: childImageUrl ?? user.childProfileImageUrl,
            childTriggers: _triggers,
          );

          // Save to Firestore
          final success = await authProvider.updateUserProfile(updatedUser);

          if (!mounted) return;

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Child profile saved successfully'),
                backgroundColor: Colors.green[600],
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Navigate based on mode
            if (widget.isSetupMode) {
              context.go('/home');
            } else {
              context.pop();
            }
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (!widget.isSetupMode)
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.black,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        if (!widget.isSetupMode) const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.isSetupMode
                                ? 'Set Up Child Profile'
                                : 'Child Profile',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Child Photo
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
                                    Icons.child_care,
                                    size: 50,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
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

              // Voice Memo Section
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0066FF).withOpacity(0.1),
                      const Color(0xFF0080FF).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF0066FF).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parent Voice Memo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0066FF),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Record a calming message for your child',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_isRecording)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Recording... ${_formatDuration(_recordDuration)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if ((_voiceMemoPath != null || _voiceMemoUrl != null) &&
                        !_isRecording)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Voice memo recorded',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _isPlaying
                                  ? _stopPlaying
                                  : _playVoiceMemo,
                              icon: Icon(
                                _isPlaying ? Icons.stop : Icons.play_arrow,
                                color: const Color(0xFF0066FF),
                              ),
                            ),
                            IconButton(
                              onPressed: _deleteVoiceMemo,
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRecording
                            ? _stopRecording
                            : _startRecording,
                        icon: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          size: 24,
                        ),
                        label: Text(
                          _isRecording ? 'Stop Recording' : 'Start Recording',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording
                              ? Colors.red
                              : const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name, DOB, Gender fields (same as before)
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

                      // Date of Birth (same as before)
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

                      // Gender (same as before)
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

                      // Triggers Section
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Triggers',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _showAddTriggerDialog,
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                            label: const Text('Add Trigger'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0066FF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Display triggers
                      if (_triggers.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Center(
                            child: Text(
                              'No triggers added yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        ...List.generate(_triggers.length, (index) {
                          final trigger = _triggers[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(113, 202, 214, 255),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF0066FF).withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(
                                          0xFF0066FF,
                                        ).withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        trigger.icon,
                                        color: const Color(0xFF0066FF),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        trigger.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeTrigger(index),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          trigger.icon,
                                          color: const Color(0xFF0066FF),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            trigger.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE3F2FD),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '${trigger.intensity}%',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0066FF),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: const Color(
                                          0xFF0066FF,
                                        ),
                                        inactiveTrackColor: Colors.grey[300],
                                        thumbColor: const Color(0xFF0066FF),
                                        overlayColor: const Color(
                                          0xFF0066FF,
                                        ).withOpacity(0.2),
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 12.0,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 24.0,
                                            ),
                                        trackHeight: 8.0,
                                        valueIndicatorColor: const Color(
                                          0xFF0066FF,
                                        ),
                                        valueIndicatorTextStyle:
                                            const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      child: Slider(
                                        value: trigger.intensity.toDouble(),
                                        min: 0,
                                        max: 100,
                                        divisions: 100,
                                        label: '${trigger.intensity}%',
                                        onChanged: (double value) {
                                          _updateTriggerIntensity(
                                            index,
                                            value.round(),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),

                      const SizedBox(height: 40),

                      Center(
                        child: SizedBox(
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
                                : Text(
                                    widget.isSetupMode
                                        ? 'Continue'
                                        : 'Save Profile',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      // Skip option for setup mode
                      if (widget.isSetupMode) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/home'),
                            child: Text(
                              'Skip for now',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],

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
}
