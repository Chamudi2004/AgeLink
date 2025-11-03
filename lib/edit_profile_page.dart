import 'dart:io';
import 'package:flutter/material.dart'; // <-- THIS WAS THE MISSING LINE
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';

// --- (Gradient constant) ---
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
// ------------------------------------------

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  bool _isLoading = false;
  File? _pickedImage;
  String? _currentImageUrl;

  DocumentReference get _userDocRef {
    final uid = _auth.currentUser!.uid;
    // --- UPDATED PATH (to match your settings_page) ---
    const appId = String.fromEnvironment('app_id', defaultValue: 'default-app-id');
    return _firestore
        .doc('artifacts/$appId/users/$uid/profile/details');
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- (Reusable Gradient Button) ---
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            // Make button width fit its content
            width: null,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), // Added horizontal padding
            alignment: Alignment.center,
            child: (icon != null)
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Fit content
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            )
                : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // --- CORE FUNCTIONS (Now with Safety Checks) ---

  Future<void> _loadUserData() async {
    setState(() { _isLoading = true; });
    try {
      final doc = await _userDocRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? _auth.currentUser?.email ?? '';
        _currentImageUrl = data['profileImageUrl'];
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: source);
    if (pickedFile != null) {
      if (!mounted) return;
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return _currentImageUrl;

    final uid = _auth.currentUser!.uid;
    final ref = _storage.ref().child('profile_pictures').child('$uid.jpg');

    try {
      await ref.putFile(_pickedImage!);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final newImageUrl = await _uploadImage();
      // Use .set() with merge: true to safely create/update fields
      await _userDocRef.set({
        'name': _nameController.text,
        'profileImageUrl': newImageUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 2. REPLACED Scaffold with GradientScaffold ---
    return GradientScaffold(
      appBar: AppBar(
        // --- 3. Made AppBar transparent ---
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                // Make the background transparent to show placeholder
                backgroundColor: Colors.white.withOpacity(0.5),
                backgroundImage: _pickedImage != null
                    ? FileImage(_pickedImage!)
                    : _currentImageUrl != null
                    ? NetworkImage(_currentImageUrl!)
                    : null,
                child: _pickedImage == null && _currentImageUrl == null
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
              TextButton(
                onPressed: _showImageSourceActionSheet,
                child: const Text('Change Photo'),
              ),

              const SizedBox(height: 32),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter your name' : null,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                readOnly: true, // Email is not editable
              ),

              const SizedBox(height: 32),

              // Align the button to the left
              Align(
                alignment: Alignment.centerLeft,
                // --- 4. REPLACED with Gradient Button ---
                child: _buildGradientButton(
                  onPressed: _saveProfile,
                  text: 'Save Changes',
                  gradient: kPrimaryGradient,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}