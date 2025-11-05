import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'firebase_options.dart';
import 'constants.dart';

import 'login_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'home_page.dart';

// 1. MAIN APPLICATION START - ASYNC INITIALIZATION

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FirebaseInitializer());
}


// 2. FIREBASE INITIALIZER - SAFE ENTRY POINT


class FirebaseInitializer extends StatelessWidget {
  const FirebaseInitializer({super.key});

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


// 3. THEME & ROOT WIDGET (Protected)


class AuthApp extends StatelessWidget {
  const AuthApp._();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgeLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF0D47A1),
        fontFamily: 'Inter',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
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
            borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1), // Primary Button Color
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

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return const AuthWrapper();
        },
      ),
    );
  }
}

// 4. AUTH WRAPPER (State Management for Screen Switching and Auth Logic)

enum AuthView { login, signup, forgotPassword }

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AuthView _currentView = AuthView.login;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _storage = const FlutterSecureStorage();

  bool _isSigningIn = false;

  void setView(AuthView view) {
    setState(() {
      _currentView = view;
    });
  }

  // CENTRALIZED AUTHENTICATION HANDLER
  void _handleAuthAction(String action, Map<String, dynamic> data) async {
    setState(() { _isSigningIn = true; });

    try {
      if (action == 'Sign Up') {
        final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: data['email'],
          password: data['password'],
        );

        // Save user details to the simple 'users/{uid}' path
        await _firestore
            .collection('artifacts')
            .doc(kAppId)
            .collection('users')
            .doc(userCredential.user!.uid)
            .collection('profile')
            .doc('details')
            .set({
          'uid': userCredential.user!.uid,
          'email': data['email'],
          'name': data['name'],
          'createdAt': FieldValue.serverTimestamp(),
        });


      } else if (action == 'Log In') {
        await _auth.signInWithEmailAndPassword(
          email: data['email'],
          password: data['password'],
        );

        if (data['rememberMe'] == true) {
          await _storage.write(key: 'remembered_email', value: data['email']);
        } else {
          await _storage.delete(key: 'remembered_email');
        }

      } else if (action == 'Google Sign In') {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          setState(() { _isSigningIn = false; });
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final userRef = _firestore
            .collection('artifacts')
            .doc(kAppId)
            .collection('users')
            .doc(userCredential.user!.uid)
            .collection('profile')
            .doc('details');
        final doc = await userRef.get();

        if (!doc.exists) {
          await userRef.set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'name': userCredential.user!.displayName ?? 'Google User',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

      } else if (action == 'Forgot Password') {
        await _auth.sendPasswordResetEmail(email: data['email']);

        setState(() { _isSigningIn = false; });
        _showStatusDialog(
            'Password Reset Sent',
            'A password reset link has been sent to ${data['email']}. Please check your email.',
                () => setView(AuthView.login)
        );
      }


    } on FirebaseAuthException catch (e) {
      setState(() { _isSigningIn = false; });

      String message = 'An unknown error occurred.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }else if (e.code == 'account-exists-with-different-credential') {
        message = 'This email is already registered using a different login method.';
      }
      _showStatusDialog('Error', message);
    } catch (e) {
      setState(() { _isSigningIn = false; });
      _showStatusDialog('Error', e.toString());
      print(e);
    }
  }


  void _showStatusDialog(String title, String message, [VoidCallback? onDismiss]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(color: title == 'Success' || title == 'Password Reset Sent' ? const Color(0xFF10B981) : Colors.red)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF7FBFF),
              Color(0xFFBCD8FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Image.asset(
                    'assets/agelink_logo.png',
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          'AgeLink',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),


                  if (_isSigningIn)
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else
                    _buildAuthScreen(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Switches between the specific screen widgets
  Widget _buildAuthScreen() {
    return switch (_currentView) {
      AuthView.login => LoginScreen(
        onLogin: (data) => _handleAuthAction('Log In', data),
        onGoogleSignIn: () => _handleAuthAction('Google Sign In', {}),
        onNavigate: setView,
      ),
      AuthView.signup => SignUpScreen(
        onSignUp: (data) => _handleAuthAction('Sign Up', data),
        onNavigate: setView,
      ),
      AuthView.forgotPassword => ForgotPasswordScreen(
        onSendReset: (data) => _handleAuthAction('Forgot Password', data),
        onNavigate: setView,
      ),
    };
  }
}
