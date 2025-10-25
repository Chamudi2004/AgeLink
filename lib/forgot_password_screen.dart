import 'package:flutter/material.dart';
import 'main.dart'; // To access AuthView enum

// --- FORGOT PASSWORD SCREEN ---
class ForgotPasswordScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSendReset;
  final Function(AuthView) onNavigate;

  const ForgotPasswordScreen({super.key, required this.onSendReset, required this.onNavigate});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSendReset({
        'email': _emailController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Reset Password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter the email address associated with your account and we\'ll send you a link to reset your password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 32),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
            ),
            validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 32),

// --- UPDATED Send Reset Link Button ---
          ClipRRect( // Wrap with ClipRRect for rounded corners
            borderRadius: BorderRadius.circular(12.0),
            child: ElevatedButton(
              onPressed: _submit, // This is your submit function
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero, // Remove default padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                backgroundColor: Colors.transparent, // Make button transparent
                shadowColor: Colors.transparent, // Hide default shadow
                elevation: 2,
              ),
              child: Ink( // Use Ink for the gradient and splash effect
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  gradient: const LinearGradient( // Your gradient
                    colors: [
                      Color(0xFF1E88E5), // Blue
                      Color(0xFF0D47A1), // Darker Blue
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Container(
                  // This container holds the text and re-applies the padding
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  alignment: Alignment.center,
                  child: const Text(
                    'Send Reset Link', // <-- Updated text
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Back to Login Navigation
          TextButton(
            onPressed: () => widget.onNavigate(AuthView.login),
            child: const Text(
              'Back to Login',
              style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
