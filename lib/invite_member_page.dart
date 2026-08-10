// lib/invite_member_page.dart

import 'package:flutter/material.dart';
import 'gradient_scaffold.dart';
import 'constants.dart';
import 'custom_snackbar.dart'; // Using the premium notification helper

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

  // --- Premium Button Helper ---
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    double verticalPadding = 18.0,
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
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            alignment: Alignment.center,
            child: (icon != null)
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
              ],
            )
                : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
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
        keyboardType: TextInputType.emailAddress,
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

  // --- Premium Selection Card Helper ---
  Widget _buildModeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color activeColor,
  }) {
    final bool isSelected = _selectedMode == title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedMode = title;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withOpacity(0.1) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? activeColor : Constants.mediumGrey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? activeColor : Constants.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Constants.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? activeColor : Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendInvitation() {
    final email = _emailController.text.trim();
    final mode = _selectedMode;

    if (email.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'Please enter an email or phone number.',
        isError: true,
      );
      return;
    }

    // TODO: Implement Firebase logic to send the invitation
    print('Sending invitation to: $email with mode: $mode');

    CustomSnackBar.show(
        context: context,
        message: 'Invitation sent to $email successfully!'
    );

    // Go back to the previous screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Invite Member',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Constants.darkblue),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Icon and Text
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded, size: 48, color: Color(0xFF1E88E5)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add to Family Group',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Constants.darkGrey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send an invitation to allow someone to view or manage the medication schedules.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Constants.mediumGrey, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Contact Input Field
                  _buildInputField(
                    controller: _emailController,
                    label: 'Email Address or Phone',
                    icon: Icons.contact_mail_rounded,
                  ),
                  const SizedBox(height: 32),

                  // Mode Selector
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, color: Constants.darkGrey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Select Permission Level',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Constants.darkGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildModeCard(
                    title: 'View Mode',
                    description: 'Can only view the schedule, history, and notifications.',
                    icon: Icons.visibility_rounded,
                    activeColor: const Color(0xFF1E88E5),
                  ),
                  const SizedBox(height: 12),

                  _buildModeCard(
                    title: 'Full Mode',
                    description: 'Can add, edit, and delete medications from the schedule.',
                    icon: Icons.edit_note_rounded,
                    activeColor: const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: _buildGradientButton(
              onPressed: _sendInvitation,
              text: 'Send Invitation',
              icon: Icons.send_rounded,
              gradient: kPrimaryGradient,
            ),
          ),
        ],
      ),
    );
  }
}