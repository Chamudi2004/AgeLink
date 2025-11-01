import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'family_permissions_page.dart';
import 'device_page.dart';
import 'settings_page.dart';
import 'help_page.dart';
import 'edit_profile_page.dart';

class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  final String appId = const String.fromEnvironment(
      'app_id', defaultValue: 'default-app-id');

  void _logout(BuildContext context) async {
    Navigator.of(context).pop();

    // Show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging out...')),
    );

    // Sign out
    await FirebaseAuth.instance.signOut();
  }

  // Helper widget for menu items
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

  // Helper function to handle navigation
  void _navigateTo(BuildContext context, Widget page) {
    // 1. Close the drawer
    Navigator.pop(context);

    // 2. Navigate to the new page
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

    // UPDATED: Using the simple path we fixed before
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

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

              // 2. Profile Section
              StreamBuilder<DocumentSnapshot>(
                stream: userDocRef.snapshots(),
                builder: (context, snapshot) {
                  String name = 'Loading...';
                  String email = user.email ?? 'No email';

                  if (snapshot.connectionState == ConnectionState.active && snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    name = data['name'] ?? 'Caregiver User'; // Use fallback
                    email = data['email'] ?? user.email!; // Use fallback
                  } else if (snapshot.hasError) {
                    name = 'Error loading name';
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person_outline,
                            size: 36,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name (from Firestore)
                        Text(
                          name,
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
                            // UPDATED: Navigate to Edit Profile Page
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

              // 3. Menu Items
              _buildMenuItem(
                icon: Icons.people_outline,
                title: 'Family & Permissions',
                onTap: () {
                  // UPDATED
                  _navigateTo(context, const FamilyPermissionsPage());
                },
              ),
              _buildMenuItem(
                icon: Icons.devices_other_outlined,
                title: 'Device',
                onTap: () {
                  // UPDATED
                  _navigateTo(context, const DevicePage());
                },
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  // UPDATED
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
                  // UPDATED
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