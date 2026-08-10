// lib/settings_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';
import 'custom_snackbar.dart'; // Premium notifications

// --- (Gradient constants) ---
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

  late final DatabaseReference _contactsRef;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isDarkMode = false;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();

    if (currentUser != null) {
      _contactsRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app"
      ).ref('appData/${currentUser!.uid}/emergencyContacts');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- Premium Button Helper ---
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 18.0),
    double? width = double.infinity,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    final bool isEnabled = onPressed != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isEnabled
                ? gradient
                : LinearGradient(
              colors: [Constants.mediumGrey, Constants.mediumGrey.withOpacity(0.7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: width,
            padding: padding,
            alignment: Alignment.center,
            child: (icon != null)
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(text, style: TextStyle(color: Colors.white, fontWeight: fontWeight, fontSize: fontSize, letterSpacing: 0.5)),
              ],
            )
                : Text(text, style: TextStyle(color: Colors.white, fontWeight: fontWeight, fontSize: fontSize, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }

  // --- Premium Input Field Helper ---
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Constants.darkGrey, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Constants.mediumGrey),
          prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  // --- Add Contact Dialog ---
  void _showAddContactDialog() {
    _nameController.clear();
    _phoneController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.contact_phone_rounded, color: Color(0xFF1E88E5)),
              ),
              const SizedBox(width: 12),
              const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInputField(
                controller: _nameController,
                label: 'Name (e.g., Jane Doe)',
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _phoneController,
                label: 'Phone (e.g., +9477...)',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Constants.mediumGrey, fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: () => Navigator.of(context).pop(),
            ),
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
              width: 100,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
          ],
        );
      },
    );
  }

  void _saveContact({required String name, required String phone}) {
    if (name.isEmpty || phone.isEmpty) {
      CustomSnackBar.show(context: context, message: 'Please fill in all fields.', isError: true);
      return;
    }
    if (currentUser == null) return;

    final newContact = {'name': name, 'phone': phone};
    _contactsRef.push().set(newContact);
    CustomSnackBar.show(context: context, message: 'Emergency contact saved!');
  }

  void _deleteContact(String contactKey) {
    if (currentUser == null) return;
    _contactsRef.child(contactKey).remove();
    CustomSnackBar.show(context: context, message: 'Contact removed.', isError: true);
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
        leading: BackButton(color: Constants.darkblue),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Emergency Contacts Section ---
            Row(
              children: [
                Icon(Icons.emergency_rounded, color: Colors.redAccent, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Emergency Contacts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Constants.darkGrey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'These numbers will be called when the SOS button is triggered.',
              style: TextStyle(color: Constants.mediumGrey, fontSize: 14),
            ),
            const SizedBox(height: 16),

            StreamBuilder(
              stream: _contactsRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text('No emergency contacts added yet.', style: TextStyle(color: Constants.mediumGrey, fontWeight: FontWeight.w500)),
                    ),
                  );
                }

                Map<dynamic, dynamic> contactsMap = snapshot.data!.snapshot.value as Map;

                final contactsList = contactsMap.entries.map((entry) {
                  final data = Map<String, dynamic>.from(entry.value as Map);
                  return {
                    'key': entry.key,
                    'name': (data['name'] ?? 'No Name').toString(),
                    'phone': (data['phone'] ?? 'No Phone').toString(),
                  };
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contactsList.length,
                  itemBuilder: (context, index) {
                    final contact = contactsList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100, width: 1.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phone_in_talk_rounded, color: Colors.redAccent, size: 20),
                        ),
                        title: Text(
                          contact['name']!,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Constants.darkGrey),
                        ),
                        subtitle: Text(
                          contact['phone']!,
                          style: TextStyle(color: Constants.mediumGrey, fontWeight: FontWeight.w500),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => _deleteContact(contact['key']!),
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
              icon: Icons.person_add_rounded,
              gradient: kPrimaryGradient,
            ),

            const SizedBox(height: 32),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 32),

            // --- "APP SETTINGS" SECTION ---
            Row(
              children: [
                Icon(Icons.tune_rounded, color: Constants.darkGrey, size: 24),
                const SizedBox(width: 8),
                Text(
                  'App Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Constants.darkGrey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dark Mode Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                title: Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Constants.darkGrey)),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: const Color(0xFF1E88E5),
                    size: 20,
                  ),
                ),
                value: _isDarkMode,
                onChanged: (bool newValue) {
                  setState(() { _isDarkMode = newValue; });
                },
              ),
            ),
            const SizedBox(height: 12),

            // Language Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.language_rounded, color: Color(0xFF1E88E5), size: 20),
                ),
                title: Text('Language', style: TextStyle(fontWeight: FontWeight.bold, color: Constants.darkGrey)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedLanguage, style: TextStyle(color: Constants.mediumGrey, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                  ],
                ),
                onTap: () {
                  CustomSnackBar.show(context: context, message: 'Language settings coming soon.');
                },
              ),
            ),
            const SizedBox(height: 12),

            // Notifications Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF1E88E5), size: 20),
                ),
                title: Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.bold, color: Constants.darkGrey)),
                trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                onTap: () {
                  CustomSnackBar.show(context: context, message: 'Notification settings coming soon.');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}