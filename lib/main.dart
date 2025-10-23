import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'login_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'home_page.dart';


// ----------------------------------------------------------------------------
// 1. MAIN APPLICATION START - ASYNC INITIALIZATION
// ----------------------------------------------------------------------------

void main() {
  // Ensure Flutter binding is initialized before using plugins
  WidgetsFlutterBinding.ensureInitialized();
  // Start the application with a widget that handles Firebase initialization safety
  runApp(const FirebaseInitializer());
}

// ----------------------------------------------------------------------------
// 2. FIREBASE INITIALIZER - SAFE ENTRY POINT
// ----------------------------------------------------------------------------

// This widget ensures Firebase is initialized before AuthApp is rendered.
class FirebaseInitializer extends StatelessWidget {
  const FirebaseInitializer({super.key});

  // The Future function that performs the initialization
  Future<FirebaseApp> _initializeFirebase() async {
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      // Call the initialization function
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        // If the Future is still running, show a loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // If the Future completed with an error (Firebase initialization failed)
        if (snapshot.hasError) {
          // Display the error clearly to the user
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      const Text(
                        'FIREBASE SETUP ERROR',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        // Display the error thrown by the PlatformException
                        'Initialization failed. This usually means the native configuration files are missing or incorrect.\n\nError: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ACTION REQUIRED: Please stop the app completely, run "flutterfire configure" in your terminal, and then perform a full restart (not a hot restart) of the app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // If initialization succeeded, run the main authentication app
        return const AuthApp._();
      },
    );
  }
}

// ----------------------------------------------------------------------------
// 3. THEME & ROOT WIDGET (Protected)
// ----------------------------------------------------------------------------

// Defines the root widget for the application, setting up the theme.
class AuthApp extends StatelessWidget {
  // Private constructor to ensure it is only created by FirebaseInitializer after success
  const AuthApp._({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agelink Authentication',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Agelink's primary color
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF10B981),
        fontFamily: 'Inter',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50], // Light background for inputs
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981), // Primary Button Color
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            elevation: 2,
          ),
        ),
      ),
      // Use StreamBuilder to check authentication state globally in real-time
      home: StreamBuilder<User?>(
        // This is now safe because FirebaseInitializer guarantees initialization
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show a spinner while the connection state is waiting
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // If the user is logged in (snapshot.hasData returns true), show the Home Page
          if (snapshot.hasData) {
            // THIS IS THE CRITICAL LINE
            return const HomePage();
          }
          // Otherwise, show the Authentication wrapper (Login/Signup screens)
          return const AuthWrapper();
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// 4. AUTH WRAPPER (State Management for Screen Switching and Auth Logic)
// ----------------------------------------------------------------------------

enum AuthView { login, signup, forgotPassword }

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AuthView _currentView = AuthView.login;
  // Instantiating services here is safe because the AuthApp waits for Firebase initialization.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void setView(AuthView view) {
    setState(() {
      _currentView = view;
    });
  }

  // CENTRALIZED AUTHENTICATION HANDLER
  void _handleAuthAction(String action, Map<String, dynamic> data) async {
    // Show loading indicator
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      if (action == 'Sign Up') {
        final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: data['email'],
          password: data['password'],
        );

        // Save user details (name) to Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': data['email'],
          'name': data['name'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Success dialog and navigation (pop loading dialog first)
        Navigator.of(context).pop();
        _showStatusDialog('Success', 'Account created! Logging in...');

      } else if (action == 'Log In') {
        await _auth.signInWithEmailAndPassword(
          email: data['email'],
          password: data['password'],
        );

        // Success: Pop loading, StreamBuilder handles redirect
        Navigator.of(context).pop();
        _showStatusDialog('Success', 'Log In successful! Redirecting...');

      } else if (action == 'Forgot Password') {
        await _auth.sendPasswordResetEmail(email: data['email']);

        // Success: Pop loading, show dialog, then navigate to login
        Navigator.of(context).pop();
        _showStatusDialog(
            'Password Reset Sent',
            'A password reset link has been sent to ${data['email']}. Please check your email.',
                () => setView(AuthView.login)
        );
      }
    } on FirebaseAuthException catch (e) {
      // Pop loading dialog on error
      Navigator.of(context).pop();
      String message = 'An unknown error occurred.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      _showStatusDialog('Error', message);
    } catch (e) {
      Navigator.of(context).pop();
      _showStatusDialog('Error', e.toString());
      print(e);
    }
  }

  // Custom function to display status messages (without dismissible loading)
  void _showStatusDialog(String title, String message, [VoidCallback? onDismiss]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(color: title == 'Success' ? const Color(0xFF10B981) : Colors.red)),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (onDismiss != null) {
                  onDismiss();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Renders the current view based on the state
  @override
  Widget build(BuildContext context) {
    // This is only rendered if the user is NOT logged in
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // App Header/Logo (AL - Agelink)
                const Column(
                  children: [
                    Text(
                      'AL',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'PRIORITIZE YOUR LOVED ONES',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
                // Render the selected authentication screen
                _buildAuthScreen(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Switches between the specific screen widgets
  Widget _buildAuthScreen() {
    switch (_currentView) {
      case AuthView.login:
        return LoginScreen(
          onLogin: (data) => _handleAuthAction('Log In', data),
          onNavigate: setView,
        );
      case AuthView.signup:
        return SignUpScreen(
          onSignUp: (data) => _handleAuthAction('Sign Up', data),
          onNavigate: setView,
        );
      case AuthView.forgotPassword:
        return ForgotPasswordScreen(
          onSendReset: (data) => _handleAuthAction('Forgot Password', data),
          onNavigate: setView,
        );
    }
  }
}
