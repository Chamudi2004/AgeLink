import 'package:flutter/material.dart';
import 'main.dart'; // To access AuthView enum

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
          const Text(
            'Welcome Back!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
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
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Log In Button
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Log In'),
          ),
          const SizedBox(height: 24),

          // Sign Up Navigation
          TextButton(
            onPressed: () => widget.onNavigate(AuthView.signup),
            child: const Text.rich(
              TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(color: Colors.black54),
                children: [
                  TextSpan(
                    text: 'Sign up now',
                    style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
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
