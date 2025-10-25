import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  // Function to handle logging out (moved from old menu.dart)
  void _logout(BuildContext context) async {
    // Close the drawer first
    Navigator.of(context).pop();

    // Show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging out...')),
    );

    // Sign out
    await FirebaseAuth.instance.signOut();

    // main.dart's StreamBuilder will handle navigation to LoginScreen
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Safety check, though the drawer shouldn't be reachable if user is null
    if (user == null) {
      return const Drawer(child: Center(child: Text('Not logged in.')));
    }

    // --- This is the same Firebase logic from your old menu.dart
    // It gets the 'name' from your signup_screen.dart
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    // --- End Firebase logic ---

    return Drawer(
      child: Container(
        // Gradient background from your image
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE6F0FF), // Lighter blue
              Color(0xFFF7FAFF), // Fading to very light blue/white
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with Logo and Close Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Your Logo (update path if needed)
                    Image.asset(
                      'assets/agelink_logo.png',
                      height: 24, // Adjusted for drawer size
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF0D47A1)),
                      onPressed: () {
                        // Closes the drawer
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              // 2. Profile Section (using your StreamBuilder)
              StreamBuilder<DocumentSnapshot>(
                stream: userDocRef.snapshots(),
                builder: (context, snapshot) {
                  // Default placeholders
                  String name = 'Loading...';
                  String email = user.email ?? 'No email';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    // This pulls the 'name' field you saved during sign up
                    name = data['name'] ?? 'Caregiver User';
                    email = data['email'] ?? user.email;
                  } else if (snapshot.hasError) {
                    name = 'Error loading name';
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
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
                        // Email (from Firebase Auth or Firestore)
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Edit Profile Text
                        InkWell(
                          onTap: () {
                            // TODO: Navigate to Edit Profile Page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit Profile Tapped')),
                            );
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
                  // TODO: Navigate
                },
              ),
              _buildMenuItem(
                icon: Icons.devices_other_outlined,
                title: 'Device',
                onTap: () {
                  // TODO: Navigate
                },
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  // TODO: Navigate
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
                  // TODO: Navigate
                },
              ),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'Log Out',
                color: Colors.red, // Red color for logout
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for menu items
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? Colors.black87; // Default color

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
}