import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:foundervers/features/auth/user_service.dart';
import 'package:foundervers/core/storage_utils.dart';
import 'package:foundervers/core/env.dart';

/// Profile editing page with avatar upload
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isSaving = false;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;

  // Current profile data
  String? _currentAvatarUrl;
  String? _userId;

  // New avatar selection
  XFile? _newAvatarFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _companyController = TextEditingController();
    _locationController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not logged in')),
          );
          Navigator.pop(context);
        }
        return;
      }

      _userId = user.id;
      final profile = await _userService.getById(user.id);

      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile['name'] as String? ?? '';
          _usernameController.text = profile['username'] as String? ?? '';
          _bioController.text = profile['bio'] as String? ?? '';
          _companyController.text = profile['company'] as String? ?? '';
          _locationController.text = profile['location'] as String? ?? '';
          _currentAvatarUrl = profile['avatar_url'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _newAvatarFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_currentAvatarUrl != null || _newAvatarFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _newAvatarFile = null;
                    _currentAvatarUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadAvatar() async {
    if (_newAvatarFile == null) return _currentAvatarUrl;

    try {
      final bucket = AppEnv.startupbuilderBucket; // Use existing bucket
      // Use consistent filename to overwrite old avatar
      final fileName = 'avatar_$_userId.jpg';
      final filePath = 'avatars/$fileName'; // Organized in avatars folder

      if (kIsWeb) {
        // Web upload using bytes with upsert to overwrite
        final bytes = await _newAvatarFile!.readAsBytes();
        await _supabase.storage.from(bucket).uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true, // Overwrite existing file
              ),
            );
      } else {
        // Mobile upload using file with upsert to overwrite
        final file = File(_newAvatarFile!.path);
        await _supabase.storage.from(bucket).upload(
              filePath,
              file,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true, // Overwrite existing file
              ),
            );
      }

      // Get public URL with cache-busting timestamp
      final baseUrl = StorageUtils.getMediaUrl(bucket: bucket, path: filePath);
      final urlWithCacheBust =
          '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('✅ Avatar uploaded successfully: $urlWithCacheBust');
      return urlWithCacheBust;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading avatar: $e')),
        );
      }
      debugPrint('❌ Avatar upload failed: $e');
      return _currentAvatarUrl;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Upload new avatar if selected
      final avatarUrl = await _uploadAvatar();

      // Update profile
      await _supabase.from('users').update({
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim().toLowerCase(),
        'bio': _bioController.text.trim(),
        'company': _companyController.text.trim(),
        'location': _locationController.text.trim(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _userId!);

      // Clear cached images to force reload
      if (_newAvatarFile != null) {
        debugPrint('🔄 Clearing image cache to reload avatar');
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedCurrentAvatar = StorageUtils.resolvePublicUrl(
      _currentAvatarUrl,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar section
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _newAvatarFile != null
                                ? (kIsWeb
                                    ? NetworkImage(_newAvatarFile!.path)
                                    : FileImage(File(_newAvatarFile!.path))
                                        as ImageProvider)
                                : (resolvedCurrentAvatar != null
                                    ? NetworkImage(resolvedCurrentAvatar)
                                    : null),
                            child: (_newAvatarFile == null &&
                                    resolvedCurrentAvatar == null)
                                ? Icon(Icons.person,
                                    size: 60, color: Colors.grey[600])
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _showImageSourceDialog,
                      child: const Text('Change Profile Photo'),
                    ),

                    const SizedBox(height: 24),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'John Doe',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Username field
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'johndoe',
                        prefixIcon: Icon(Icons.alternate_email),
                        border: OutlineInputBorder(),
                        helperText: 'Your unique handle (lowercase, no spaces)',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value.trim())) {
                          return 'Only lowercase letters, numbers, and underscores';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Bio field
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell us about yourself...',
                        prefixIcon: Icon(Icons.description_outlined),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 160,
                      textInputAction: TextInputAction.newline,
                    ),

                    const SizedBox(height: 16),

                    // Company field
                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Company',
                        hintText: 'Your Company Inc.',
                        prefixIcon: Icon(Icons.business_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 16),

                    // Location field
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'San Francisco, CA',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                    ),

                    const SizedBox(height: 32),

                    // Save button (mobile)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
