import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io'; 
import 'package:image_picker/image_picker.dart'; 
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile initialProfile;

  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  XFile? _newImageFile;
  String? _imagePathForDisplay;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.username);
    _emailController = TextEditingController(text: widget.initialProfile.email);
    _imagePathForDisplay = widget.initialProfile.imagePath;
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 800, maxHeight: 800);
    if (pickedFile != null && mounted) {
      setState(() {
        _newImageFile = pickedFile;
        _imagePathForDisplay = pickedFile.path; 
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Profile Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) setState(() => _isLoading = true);

      String? finalImagePath = widget.initialProfile.imagePath;

      if (_newImageFile != null) {
        
        finalImagePath = await userProfileService.saveProfileImage(_newImageFile!);
      }

      final updatedProfile = UserProfile(
        username: _nameController.text,
        email: _emailController.text,
        imagePath: finalImagePath,
      );

      await userProfileService.updateProfile(updatedProfile);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? backgroundImage;
    if (_imagePathForDisplay != null) {
      backgroundImage = FileImage(File(_imagePathForDisplay!));
    } else {
      backgroundImage = const AssetImage("assets/profile1.png");
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFFA8D5BA),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: backgroundImage,
                        onBackgroundImageError: (exception, stackTrace) {
                          print("Error loading image for avatar: $exception");
                        },
                        child: _imagePathForDisplay == null && _newImageFile == null
                            ? const Icon(Icons.camera_alt, size: 30, color: Colors.white70)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _showImageSourceDialog,
                      child: const Text("Change Photo", style: TextStyle(color: Color(0xFFF4A261), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4A261),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}