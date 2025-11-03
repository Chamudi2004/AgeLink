import 'package:flutter/material.dart';
import 'gradient_scaffold.dart'; // <-- 1. IMPORTED

// --- (Gradient constants) ---
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
// ------------------------------------------

class InviteMemberPage extends StatefulWidget {
  const InviteMemberPage({super.key});

  @override
  State<InviteMemberPage> createState() => _InviteMemberPageState();
}

class _InviteMemberPageState extends State<InviteMemberPage> {
  // 1. Controllers to get the data
  final TextEditingController _emailController = TextEditingController();
  // 'View Mode' is the safer default
  String _selectedMode = 'View Mode';

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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: (icon != null)
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            )
                : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  void _sendInvitation() {
    final email = _emailController.text;
    final mode = _selectedMode;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email or phone number.')),
      );
      return;
    }

    // TODO: Implement Firebase logic to send the invitation
    print('Sending invitation to: $email with mode: $mode');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invitation sent to $email')),
    );

    // Go back to the previous screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // --- 2. REPLACED Scaffold with GradientScaffold ---
    return GradientScaffold(
      appBar: AppBar(
        // 3. Made AppBar transparent
        title: const Text(
          'Invitation',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2. Email/Phone Text Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email / Phone',
                // Using the theme from main.dart
              ),
            ),
            const SizedBox(height: 24),

            // 3. Mode Selector
            const Text(
              'Select the Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Using RadioListTile for an easy-to-use selector
            RadioListTile<String>(
              title: const Text('Full Mode'),
              value: 'Full Mode',
              groupValue: _selectedMode,
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('View Mode'),
              value: 'View Mode',
              groupValue: _selectedMode,
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
            ),
            const Spacer(), // Pushes the button to the bottom

            // --- 4. REPLACED with Gradient Button ---
            _buildGradientButton(
              onPressed: _sendInvitation,
              text: 'Send Invitation',
              gradient: kPrimaryGradient,
            ),
            const SizedBox(height: 20), // Padding from bottom
          ],
        ),
      ),
    );
  }
}