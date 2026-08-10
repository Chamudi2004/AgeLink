// lib/app_menu_drawer.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'family_permissions_page.dart';
import 'device_page.dart';
import 'settings_page.dart';
import 'help_page.dart';
import 'edit_profile_page.dart';
import 'constants.dart';
import 'custom_snackbar.dart'; // Using the premium notification helper

class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  final String appId = kAppId;

  void _logout(BuildContext context) async {
    Navigator.of(context).pop();
    CustomSnackBar.show(
        context: context,
        message: 'Logging out...'
    );
    await FirebaseAuth.instance.signOut();
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  // Premium Menu Item Builder
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    bool isLogout = false,
  }) {
    final itemColor = color ?? Constants.darkGrey;
    final bgColor = color?.withOpacity(0.1) ?? const Color(0xFF1E88E5).withOpacity(0.1);
    final iconColor = color ?? const Color(0xFF1E88E5);

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: itemColor
                    ),
                  ),
                ),
                if (!isLogout)
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Drawer(child: Center(child: Text('Not logged in.')));
    }

    // --- 1. FIRESTORE PATH ---
    final userDocRef = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(appId)
        .collection('users')
        .doc(user.uid)
        .collection('profile')
        .doc('details');
    // --- END OF PATH ---

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA), // Very light clean background
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header & Close Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 12.0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --- CHANGED TO LOGO ---
                    Image.asset(
                      'assets/agelink_logo.png',
                      height: 32, // Adjust this height if needed
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Text(
                        'AgeLink', // Fallback if image path is wrong
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                    // --- END OF LOGO ---

                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded, color: Constants.darkGrey, size: 20),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // 2. Profile Card StreamBuilder
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
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF1E88E5), const Color(0xFF0D47A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D47A1).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white,
                                  backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                      ? NetworkImage(profileImageUrl)
                                      : null,
                                  child: (profileImageUrl == null || profileImageUrl.isEmpty)
                                      ? const Icon(Icons.person_rounded, size: 34, color: Color(0xFF0D47A1))
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _navigateTo(context, const EditProfilePage()),
                              icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF0D47A1)),
                              label: const Text(
                                'Edit Profile',
                                style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0D47A1),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 3. Main Menu Items
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.family_restroom_rounded,
                        title: 'Family & Permissions',
                        onTap: () => _navigateTo(context, const FamilyPermissionsPage()),
                      ),
                      _buildMenuItem(
                        icon: Icons.devices_rounded,
                        title: 'Device Settings',
                        onTap: () => _navigateTo(context, const DevicePage()),
                      ),
                      _buildMenuItem(
                        icon: Icons.settings_rounded,
                        title: 'App Settings',
                        onTap: () => _navigateTo(context, const SettingsPage()),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        child: Divider(color: Colors.grey.shade300, height: 1),
                      ),

                      _buildMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: () => _navigateTo(context, const HelpPage()),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Log Out Button at Bottom
              Container(
                padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                child: _buildMenuItem(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  color: Colors.redAccent,
                  isLogout: true,
                  onTap: () => _showLogoutConfirmation(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Safe Logout Confirmation Dialog
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              ),
              const SizedBox(width: 12),
              const Text('Log Out'),
            ],
          ),
          content: Text(
            'Are you sure you want to log out of AgeLink?',
            style: TextStyle(color: Constants.darkGrey, fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: Constants.mediumGrey, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                _logout(context); // Run actual logout
              },
              child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }
}