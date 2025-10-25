import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  // Function to handle logging out
  void _logout(BuildContext context) async {
    // Show loading indicator temporarily
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging out...')),
    );

    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // No explicit navigation needed; main.dart's StreamBuilder automatically
    // detects the signed-out state and switches back to the login screen.
  }

  // Helper widget to build grouped list tiles
  Widget _buildMenuSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20.0, left: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Constants.mediumGrey,
            ),
          ),
        ),
        // Container for the list items to give a grouped background look
        Container(
          decoration: BoxDecoration(
            color: Colors.white, // Using raw white for backgroundWhite
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Helper for a standard menu item ListTile
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    // FIX: Removed the default assignment here to avoid the compile-time error.
    Color? iconColor,
  }) {
    // Determine the color: use the passed color or default to Constants.darkBlue.
    // This assignment happens at runtime and resolves the error.
    final effectiveIconColor = iconColor ?? Constants.darkBlue;

    return ListTile(
      leading: Icon(icon, color: effectiveIconColor, size: 24),
      // Using Constants.darkGrey for the main title text
      title: Text(title, style: TextStyle(fontSize: 16, color: Constants.darkGrey)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Constants.mediumGrey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the current signed-in user
    final user = FirebaseAuth.instance.currentUser;
    // We rely on the user object to get the UID for Firestore
    if (user == null) {
      // Should not happen if routed correctly, but good for safety
      return const Center(child: Text('User not logged in.'));
    }

    // 1. Get the Firebase app ID (Must be used for security rules)
    const appId = String.fromEnvironment('app_id', defaultValue: 'default-app-id');
    // 2. Define the secure Firestore path for the user's private data:
    final userProfilePath = 'artifacts/$appId/users/${user.uid}/profile/details';
    // 3. Get the Firestore document reference for the profile
    final userDocRef = FirebaseFirestore.instance.doc(userProfilePath);

    return Scaffold(
      // Using a slightly off-white/light grey for the background (like softGrey)
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ----------------------------------------
            // 1. PROFILE HEADER
            // ----------------------------------------
            StreamBuilder<DocumentSnapshot>(
              stream: userDocRef.snapshots(),
              builder: (context, snapshot) {
                // Default placeholders if data is not ready
                String name = 'Loading Name...';
                String email = user.email ?? 'Loading Email...';

                // If data is ready and exists, update name and email
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  name = data['name'] ?? 'Caregiver User';
                  email = data['email'] ?? user.email ?? 'user@agelink.com';
                } else if (snapshot.hasError) {
                  name = 'Error Loading Profile';
                }

                return Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white, // Using raw white for backgroundWhite
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Profile Avatar
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Constants.lightBlue,
                        child: Icon(
                          Icons.person,
                          color: Constants.darkBlue,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name and Email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Constants.darkGrey, // Using darkGrey for Name
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Constants.mediumGrey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Edit Profile Icon
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: Constants.mediumGrey),
                        onPressed: () {
                          // Action: Navigate to Edit Profile screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit Profile Pressed')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ----------------------------------------
            // 2. SETTINGS SECTION
            // ----------------------------------------
            _buildMenuSection(
              title: 'SETTINGS',
              children: [
                _buildMenuItem(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  onTap: () {
                    // Action: Navigate to Notification Settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications Settings')),
                    );
                  },
                ),
                const Divider(height: 0, indent: 20, endIndent: 20),
                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: 'Privacy',
                  onTap: () {
                    // Action: Navigate to Privacy Policy/Settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy Settings')),
                    );
                  },
                ),
              ],
            ),

            // 3. SUPPORT SECTION
            // ----------------------------------------
            _buildMenuSection(
              title: 'SUPPORT',
              children: [
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () {
                    // Action: Navigate to Help/FAQ screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help Center')),
                    );
                  },
                ),
                const Divider(height: 0, indent: 20, endIndent: 20),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'About Agelink',
                  onTap: () {
                    // Action: Navigate to About screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('About Agelink')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ----------------------------------------
            // 4. LOGOUT BUTTON
            // ----------------------------------------
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('LOGOUT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Constants.redColor, // Using redColor for the text/icon
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(color: Constants.redColor, width: 1), // Using redColor for the border
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
