import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PairDevicePage extends StatefulWidget {
  const PairDevicePage({super.key});

  @override
  State<PairDevicePage> createState() => _PairDevicePageState();
}

class _PairDevicePageState extends State<PairDevicePage> {
  final TextEditingController _deviceIdController = TextEditingController();
  bool _isLoading = false;

  // This is the function that saves the ID to Firestore
  void _pairDevice() async {
    final String deviceId = _deviceIdController.text.trim();
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Device ID.')),
      );
      return;
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Not logged in.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // --- This is the key ---
      // Save the device ID to the user's profile in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'pairedDeviceId': deviceId,
      });
      // -------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device $deviceId paired successfully!')),
      );

      // Go back to the previous screen
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error pairing device: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Styled AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
        title: const Text(
          'Connect Your Device',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
      ),
      // 2. Gradient Background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF0F4FF),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Enter the unique ID from your AgeLink device. You can find this on the back of the device or in its settings.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              // 3. Text Field for the ID
              TextField(
                controller: _deviceIdController,
                decoration: const InputDecoration(
                  labelText: 'Device ID (e.g., AgeLink_00987)',
                ),
              ),
              const SizedBox(height: 40),

              // 4. Loading indicator or Gradient Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: ElevatedButton(
                  onPressed: _pairDevice,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1E88E5), // Blue
                          Color(0xFF0D47A1), // Darker Blue
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      alignment: Alignment.center,
                      child: const Text(
                        'Pair Device',
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
            ],
          ),
        ),
      ),
    );
  }
}