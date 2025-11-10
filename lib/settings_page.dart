import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';

// --- (Gradient constants are correct) ---
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

    // This path is correct according to your logs
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

  // --- (Gradient Button helper is correct) ---
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 16.0),
    double? width = double.infinity,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    // ... (This function is correct, no changes)
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: (onPressed != null)
                ? gradient
                : LinearGradient(
              colors: [Colors.grey, Colors.grey.shade500],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12.0),
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

  // --- (Dialog to Add New Contact is correct) ---
  void _showAddContactDialog() {
    _nameController.clear();
    _phoneController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF0F4FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Add Emergency Contact',
            style: TextStyle(
              color: Color(0xFF0D47A1),
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
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (e.g., +9477... )'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
              width: null,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
            ),
          ],
        );
      },
    );
  }

  // --- (Firebase Logic for RTDB is correct) ---
  void _saveContact({required String name, required String phone}) {
    if (name.isEmpty || phone.isEmpty) return;
    if (currentUser == null) return; // Safety check

    // Save the phone number as a String, not a Number
    final newContact = {'name': name, 'phone': phone};
    _contactsRef.push().set(newContact);
  }

  void _deleteContact(String contactKey) {
    if (currentUser == null) return; // Safety check
    _contactsRef.child(contactKey).remove();
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

            // 5. UPDATED StreamBuilder for RTDB
            StreamBuilder(
              stream: _contactsRef.onValue, // Listens to the 'onValue' event
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No emergency contacts added.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                // RTDB returns data as a Map. We need to convert it.
                Map<dynamic, dynamic> contactsMap =
                snapshot.data!.snapshot.value as Map;

                // Convert the Map to a List for the ListView
                final contactsList = contactsMap.entries.map((entry) {
                  // --- THIS IS THE FIX ---
                  // We'll convert the data to Strings right here to be safe
                  final data = Map<String, dynamic>.from(entry.value as Map);
                  return {
                    'key': entry.key,
                    'name': (data['name'] ?? 'No Name').toString(),
                    'phone': (data['phone'] ?? 'No Phone').toString(),
                  };
                  // --- END OF FIX ---
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contactsList.length,
                  itemBuilder: (context, index) {
                    final contact = contactsList[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(contact['name']!),
                        subtitle: Text(contact['phone']!), // This is now safe
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
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
              icon: Icons.add,
              gradient: kPrimaryGradient,
            ),

            const Divider(height: 40),

            // --- "APP SETTINGS" SECTION (UNCHANGED) ---
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