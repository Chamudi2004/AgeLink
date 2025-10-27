import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/gestures.dart';
import 'main.dart'; // To access AuthView

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onLogin;
  final VoidCallback onGoogleSignIn;
  final Function(AuthView) onNavigate;

  const LoginScreen({super.key,
    required this.onLogin,
    required this.onNavigate,
    required this.onGoogleSignIn,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _rememberMe = false;

  // --- 1. ADD THIS ---
  final _storage = const FlutterSecureStorage();
  // -------------------

  // --- 2. ADD THIS METHOD ---
  // This runs once when the screen is first created
  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }
  // -------------------

  // --- 3. ADD THIS METHOD ---
  // This loads the email from storage and fills the fields
  void _loadRememberedEmail() async {
    String? email = await _storage.read(key: 'remembered_email');
    if (email != null) {
      setState(() {
        _emailController.text = email;
        _rememberMe = true;
      });
    }
  }
  // -------------------

  // --- 4. UPDATE THIS METHOD ---
  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onLogin({
        'email': _emailController.text,
        'password': _passwordController.text,
        'rememberMe': _rememberMe, // Pass the checkbox value
      });
    }
  }
  // -------------------

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1. Welcome Text
          Text(
            'Welcome to AgeLink',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 32),

          // 2. Google Sign-In Button
          ElevatedButton.icon(
            onPressed: widget.onGoogleSignIn,
            icon: Image.asset('assets/google_logo.png', height: 24),
            label: const Text('Continue with Google'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: const BorderSide(color: Colors.grey, width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 24),

          // 3. OR divider
          const Row(
            children: [
              Expanded(child: Divider(color: Colors.grey)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Text('OR', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Email Field
          TextFormField(
            controller: _emailController, // Now loads saved email
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

          // 5. Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _isPasswordObscured,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // 6. Remember Me & Forgot Password Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _rememberMe = newValue ?? false;
                        });
                      },
                    ),
                    Flexible(
                      child: const Text('Remember me', style: TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
              ),


              TextButton(
                onPressed: () => widget.onNavigate(AuthView.forgotPassword),
                child: const Text( // Added const for efficiency
                  'Forgot Password?',
                  style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),



          // 7. Log In Button
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: ElevatedButton(
              onPressed: _submit, // This now passes the rememberMe value
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 2,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E88E5),
                      Color(0xFF0D47A1),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  alignment: Alignment.center,
                  child: const Text(
                    'Log In',
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

          // 8. Sign Up Navigation
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Non-clickable part
            const Text(
              "Don't have an account? ",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            // Clickable part (InkWell wrapped around Text)
            InkWell(
              onTap: () {
                widget.onNavigate(AuthView.signup);
              },
              borderRadius: BorderRadius.circular(4.0), // Optional: for visual feedback
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0), // Padding for better tap area
                child: Text(
                  'Sign up now',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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