import 'package:flutter/material.dart';
import 'main.dart'; // To access AuthView

// --- SIGN UP SCREEN ---
class SignUpScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSignUp;
  final Function(AuthView) onNavigate;

  const SignUpScreen({super.key, required this.onSignUp, required this.onNavigate});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        // Show mismatch error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match!')),
        );
        return;
      }
      widget.onSignUp({
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      });
    }
  }

  Widget _buildVisibilityToggle({
    required bool isVisible,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(
        isVisible ? Icons.visibility_off : Icons.visibility,
        color: Colors.grey,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Create Your Account',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 32),

          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            decoration: const InputDecoration(
              hintText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
            ),
            validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
            ),
            validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Password (min 6 characters)',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: _buildVisibilityToggle(
                isVisible: _isPasswordVisible,
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            validator: (value) => value!.length < 6 ? 'Password is too short' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_reset_outlined, color: Colors.grey),
              suffixIcon: _buildVisibilityToggle(
                isVisible: _isConfirmPasswordVisible,
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
            validator: (value) => value != _passwordController.text ? 'Passwords must match' : null,
          ),
          const SizedBox(height: 32),

// --- UPDATED Sign Up Button ---
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
                    'Sign Up', // <-- Updated text
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
          const SizedBox(height: 35),

          // Log In Navigation
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Non-clickable part
          const Text(
            'Already have an account? ',
            style: TextStyle(color: Colors.black54, fontSize: 14), // Added font size for consistency
          ),
          // Clickable part (InkWell wrapped around Text)
          InkWell(
            onTap: () {
              widget.onNavigate(AuthView.login);
            },
            borderRadius: BorderRadius.circular(4.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
              child: Text(
                'Login here',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Consistent font size
                ),
              ),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}
