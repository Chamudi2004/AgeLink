// lib/app_menu_drawer.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Make sure you have these files and the imports are correct
import 'family_permissions_page.dart';
import 'device_page.dart';
import 'settings_page.dart';
import 'help_page.dart';
import 'edit_profile_page.dart';
import 'constants.dart'; // Make sure you import constants.dart for kAppId

class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  // Use kAppId from constants.dart
  final String appId = kAppId;

  void _logout(BuildContext context) async {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging out...')),
    );
    await FirebaseAuth.instance.signOut();
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? Colors.black87;
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, color: itemColor),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Drawer(child: Center(child: Text('Not logged in.')));
    }

    // --- 1. THIS IS THE FIX ---
    // This is the CORRECT path that your EditProfilePage saves to.
    final userDocRef = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(appId)
        .collection('users')
        .doc(user.uid)
        .collection('profile')
        .doc('details');
    // --- END OF FIX ---

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE6F0FF),
              Color(0xFFF7FAFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //1. Header section
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/agelink_logo.png',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Text('AgeLink'), // Fallback text
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF0D47A1)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              // --- 2. THIS IS THE SECOND FIX ---
              // This StreamBuilder logic correctly handles all cases
              StreamBuilder<DocumentSnapshot>(
                stream: userDocRef.snapshots(),
                builder: (context, snapshot) {
                  String name;
                  String email = user.email ?? 'No email';
                  String? profileImageUrl;

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    name = 'Loading...';
                  } else if (snapshot.hasError) {
                    name = 'Error';
                  } else if (!snapshot.hasData || !snapshot.data!.exists) {
                    name = user.displayName ?? 'New User';
                  } else {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    name = data['name'] ?? user.displayName ?? 'Caregiver User';
                    email = data['email'] ?? user.email!;
                    profileImageUrl = data['profileImageUrl'];
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          backgroundImage: (profileImageUrl != null)
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: (profileImageUrl == null)
                              ? const Icon(
                            Icons.person_outline,
                            size: 36,
                            color: Color(0xFF0D47A1),
                          )
                              : null,
                        ),
                        const SizedBox(height: 16),

                        Text(
                          name, // This will now be correct
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            _navigateTo(context, const EditProfilePage());
                          },
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // --- END OF FIX ---

              // 3. Menu Items
              _buildMenuItem(
                icon: Icons.people_outline,
                title: 'Family & Permissions',
                onTap: () {
                  _navigateTo(context, const FamilyPermissionsPage());
                },
              ),
              _buildMenuItem(
                icon: Icons.devices_other_outlined,
                title: 'Device',
                onTap: () {
                  _navigateTo(context, const DevicePage());
                },
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  _navigateTo(context, const SettingsPage());
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Divider(color: Colors.grey),
              ),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Help',
                onTap: () {
                  _navigateTo(context, const HelpPage());
                },
              ),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'Log Out',
                color: Colors.red,
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}