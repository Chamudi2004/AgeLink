import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart'; // Make sure your gradients are in here
import 'gradient_scaffold.dart'; // Import your gradient scaffold

// --- (Copy these gradient constants from medication_schedule_page.dart) ---
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const kRedGradient = LinearGradient(
  colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
// ------------------------------------------

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final DocumentReference _userProfileRef;

  // Controllers for the "Add Contact" dialog
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isDarkMode = false;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    const appId = String.fromEnvironment('app_id', defaultValue: 'default-app-id');
    _userProfileRef = FirebaseFirestore.instance
        .doc('artifacts/$appId/users/${currentUser!.uid}/profile/details');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- (UPDATED Reusable Gradient Button) ---
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    // Added these new parameters for flexibility
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 16.0),
    double? width = double.infinity, // Default to full-width
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.bold,
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
          disabledBackgroundColor: Colors.transparent, // Handle disabled state
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: (onPressed != null)
                ? gradient
                : LinearGradient( // Gray gradient when disabled
              colors: [Colors.grey, Colors.grey.shade500],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            width: width, // Use the width parameter
            padding: padding, // Use the padding parameter
            alignment: Alignment.center,
            child: (icon != null)
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Fit content if width is null
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(text, style: TextStyle(color: Colors.white, fontWeight: fontWeight, fontSize: fontSize)),
              ],
            )
                : Text(text, style: TextStyle(color: Colors.white, fontWeight: fontWeight, fontSize: fontSize)),
          ),
        ),
      ),
    );
  }

  // --- (UPDATED Dialog to Add New Contact) ---
  void _showAddContactDialog() {
    _nameController.clear();
    _phoneController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Styled to match your theme
          backgroundColor: const Color(0xFFF0F4FF), // Light blue background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Add Emergency Contact',
            style: TextStyle(
              color: Color(0xFF0D47A1), // Dark blue
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name (e.g., Jane Doe)'),
              ),

              // --- (THIS IS THE ADDED SPACING) ---
              const SizedBox(height: 16),
              // -------------------------------------

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (e.g., +9477... )'),
              ),
            ],
          ),
          actions: [
            // "Cancel" button
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),

            // "Save" Gradient Button
            _buildGradientButton(
              onPressed: () {
                _saveContact(
                  name: _nameController.text.trim(),
                  phone: _phoneController.text.trim(),
                );
                Navigator.of(context).pop();
              },
              text: 'Save',
              gradient: kPrimaryGradient,
              width: null, // Make button fit its content
              fontSize: 14,
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0), // Smaller padding
            ),
          ],
        );
      },
    );
  }

  // --- (Firebase Logic) ---
  void _saveContact({required String name, required String phone}) {
    if (name.isEmpty || phone.isEmpty) return;
    final newContact = {'name': name, 'phone': phone};

    _userProfileRef.set({
      'emergencyContacts': FieldValue.arrayUnion([newContact])
    }, SetOptions(merge: true));
  }

  void _deleteContact(Map<String, dynamic> contact) {
    _userProfileRef.update({
      'emergencyContacts': FieldValue.arrayRemove([contact])
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Emergency Contacts Section ---
            const Text(
              'Emergency Contacts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'These numbers will be contacted when the SOS button is pressed.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            StreamBuilder<DocumentSnapshot>(
              stream: _userProfileRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists || snapshot.data!.data() == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Tap "Add New Contact" to get started.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final contacts = List<Map<String, dynamic>>.from(
                    data.containsKey('emergencyContacts')
                        ? data['emergencyContacts']
                        : []);

                if (contacts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No emergency contacts added.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(contact['name'] ?? 'No Name'),
                        subtitle: Text(contact['phone'] ?? 'No Phone'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteContact(contact),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            _buildGradientButton(
              onPressed: _showAddContactDialog,
              text: 'Add New Contact',
              icon: Icons.add,
              gradient: kPrimaryGradient,
            ),

            const Divider(height: 40),

            // --- "APP SETTINGS" SECTION ---
            const Text(
              'App Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              child: SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: Icon(
                  _isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  color: Colors.grey.shade700,
                ),
                value: _isDarkMode,
                onChanged: (bool newValue) {
                  setState(() { _isDarkMode = newValue; });
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              child: ListTile(
                leading: Icon(Icons.language_outlined, color: Colors.grey.shade700),
                title: const Text('Language'),
                trailing: Text(
                  _selectedLanguage,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                onTap: () { /* ... */ },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              child: ListTile(
                leading: Icon(Icons.notifications_none, color: Colors.grey.shade700),
                title: const Text('Notification Preferences'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () { /* ... */ },
              ),
            ),
          ],
        ),
      ),
    );
  }
}