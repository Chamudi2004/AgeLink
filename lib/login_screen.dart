import 'package:flutter/material.dart';
import 'main.dart'; // To access AuthView

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onLogin;
  final Function(AuthView) onNavigate;

  const LoginScreen({super.key, required this.onLogin, required this.onNavigate});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onLogin({
        'email': _emailController.text,
        'password': _passwordController.text,
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
          Text(
            'Welcome Back!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 32),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
            ),
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Password',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => widget.onNavigate(AuthView.forgotPassword),
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 24),

// --- UPDATED Log In Button ---
          ClipRRect( // <-- ADDED to ensure gradient respects rounded corners
            borderRadius: BorderRadius.circular(12.0),
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero, // <-- REMOVE default button padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                backgroundColor: Colors.transparent, // <-- MAKE button background transparent
                shadowColor: Colors.transparent, // <-- HIDE default shadow
                elevation: 2,
              ),
              child: Ink( // <-- ADDED Ink widget for the gradient
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  gradient: const LinearGradient( // <-- YOUR GRADIENT
                    colors: [
                      Color(0xFF1E88E5),
                      Color(0xFF0D47A1),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Container(
                  // This container re-applies the padding and alignment
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  alignment: Alignment.center,
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // <-- Explicitly set text color to white
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Sign Up Navigation
          TextButton(
            onPressed: () => widget.onNavigate(AuthView.signup),
            child: Text.rich(
              TextSpan(
                text: "Don't have an account? ",
                style: const TextStyle(color: Colors.black54),
                children: [
                  TextSpan(
                    text: 'Sign up now',
                    style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
