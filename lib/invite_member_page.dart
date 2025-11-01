import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitation'),
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
                border: OutlineInputBorder(),
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

            // 4. Send Invitation Button
            ElevatedButton(
              onPressed: _sendInvitation,
              child: const Text('Send Invitation'),
            ),
            const SizedBox(height: 20), // Padding from bottom
          ],
        ),
      ),
    );
  }
}