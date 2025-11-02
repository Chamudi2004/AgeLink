import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'constants.dart';

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
    return _firestore
        .collection('artifacts')
        .doc(kAppId)
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('details');
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
      // **FIX:** Check if the widget is still on screen before showing UI
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: $e')),
      );
    } finally {
      // **FIX:** Check if the widget is still on screen before updating state
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
      // **FIX:** Check if the widget is still on screen before updating state
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
      // **FIX:** Check if the widget is still on screen
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
      await _userDocRef.update({
        'name': _nameController.text,
        'profileImageUrl': newImageUrl,
      });

      // **FIX:** Check if the widget is still on screen
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      // **FIX:** Check if the widget is still on screen
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      // **FIX:** Check if the widget is still on screen
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          // We wrap the fields in a Column to control alignment
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _pickedImage != null
                    ? FileImage(_pickedImage!)
                    : _currentImageUrl != null
                    ? NetworkImage(_currentImageUrl!)
                    : null,
                child: _pickedImage == null && _currentImageUrl == null
                    ? const Icon(Icons.person, size: 60)
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
                readOnly: true,
              ),

              const SizedBox(height: 32),

              // Align the button to the left
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  // Add horizontal padding to the button
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}