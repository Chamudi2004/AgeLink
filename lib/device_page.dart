import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'pair_device_page.dart';
import 'package:flutter/services.dart'; // Import for status bar control
import 'package:intl/intl.dart'; // IMPORT for date formatting

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  DatabaseReference? _userRemindersRef;

  // Local state for the slider
  double? _localVolume;

  @override
  void initState() {
    super.initState();
    _setupDeviceReference();
  }

  void _setupDeviceReference() {
    if (_currentUser == null) {
      print("User not logged in, can't fetch device data.");
      return;
    }

    try {
      final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
          "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app");

      // --- THIS IS THE CORRECT PATH ---
      _userRemindersRef = db.ref('reminders/${_currentUser!.uid}');
      // --- END OF FIX ---

      print("DevicePage: Listening for data at ${_userRemindersRef!.path}");
    } catch (e) {
      print("Error initializing Firebase: $e");
    }
  }

  void _updateVolume(double sliderValue) {
    if (_userRemindersRef == null) return;

    double firebaseValue = sliderValue / 100.0;
    print("DevicePage: Updating volume to $firebaseValue");
    // This will now write to the correct path
    _userRemindersRef!
        .child('device')
        .child('volume')
        .set(firebaseValue)
        .catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating volume: $e')),
        );
      }
    });
  }

  void _disconnectDevice() async {
    if (_currentUser == null) return;
    if (_userRemindersRef == null) return; // Added safety check

    try {
      // 1. Try to remove the pairing from Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({'pairedDeviceId': FieldValue.delete()});
      } on FirebaseException catch (e) {
        if (e.code == 'not-found') {
          print(
              "DevicePage: User document not found in Firestore, proceeding with RTDB cleanup.");
        } else {
          rethrow;
        }
      }

      // 2. Remove the device's data from Realtime Database
      await _userRemindersRef!.remove();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device unpaired.')),
        );
        Navigator.pop(context); // Go back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Helper function to format the timestamp
  String _formatLastSynced(num timestamp) {
    if (timestamp == 0) {
      return "N/A";
    }
    final int milliseconds = timestamp.toInt();
    final DateTime lastSyncTime =
    DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final DateTime now = DateTime.now();
    final DateFormat timeFormat = DateFormat('h:mm a'); // e.g., 10:30 AM

    if (now.day == lastSyncTime.day &&
        now.month == lastSyncTime.month &&
        now.year == lastSyncTime.year) {
      return "Today at ${timeFormat.format(lastSyncTime)}";
    }

    final DateTime yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.day == lastSyncTime.day &&
        yesterday.month == lastSyncTime.month &&
        yesterday.year == lastSyncTime.year) {
      return "Yesterday at ${timeFormat.format(lastSyncTime)}";
    }

    // e.g., Nov 5 at 10:30 AM
    return DateFormat('MMM d \'at\' h:mm a').format(lastSyncTime);
  }

  Widget _buildPairDeviceButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Device Paired',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please pair a device to manage its settings here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PairDevicePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Pair New Device',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_userRemindersRef == null) {
      bodyContent = _buildPairDeviceButton();
    } else {
      // Use StreamBuilder for live updates
      bodyContent = StreamBuilder<DatabaseEvent>(
        stream: _userRemindersRef!.onValue, // Listens for live changes
        builder: (context, AsyncSnapshot<DatabaseEvent> eventSnapshot) {
          // Case 1: Still loading
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Case 2: An error happened
          if (eventSnapshot.hasError) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      "Error loading data. Please check your connection and Firebase Rules.\n\nError: ${eventSnapshot.error.toString()}",
                      textAlign: TextAlign.center),
                ));
          }

          // Case 3: No data found at that path
          if (!eventSnapshot.hasData ||
              eventSnapshot.data!.snapshot.value == null) {
            print("DevicePage: No data found at path.");
            return _buildPairDeviceButton();
          }

          // Case 4: Success! We got the data.
          print("DevicePage: Data loaded successfully.");
          final dataMap =
          eventSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final data = <String, dynamic>{};
          dataMap.forEach((key, value) {
            data[key.toString()] = value;
          });

          final deviceData = data['device'] as Map<dynamic, dynamic>? ?? {};

          String deviceName = deviceData['device_id']?.toString() ?? 'N/A';

          // This is your correct logic
          final bool isActive = deviceData['device_active'] ?? false;
          String status = isActive ? 'Device Active' : 'Device Inactive';

          // This is the logic for Last Synced
          final num lastSyncTimestamp = deviceData['last_synced'] ?? 0;
          String lastSync = _formatLastSynced(lastSyncTimestamp);

          final num volumeNum = deviceData['volume'] ?? 0.0;
          final double currentVolume = (volumeNum.toDouble() * 100.0);

          double sliderValue = _localVolume ?? currentVolume;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // This Column contains the device info (no white box)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Name',
                      style: TextStyle(
                          color: Color(0xFF0D47A1), // Dark text for label
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      deviceName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // Dark text for value
                      ),
                    ),
                    const SizedBox(height: 24), // Increased spacing
                    Text(
                      'Status',
                      style: TextStyle(
                          color: Color(0xFF0D47A1), // Dark text for label
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      status, // This will now update live
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87), // Dark text for value
                    ),
                    const SizedBox(height: 24), // Increased spacing
                    Text(
                      'Last Synced',
                      style: TextStyle(
                          color: Color(0xFF0D47A1), // Dark text for label
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      lastSync, // This will now update live
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87), // Dark text for value
                    ),
                    const SizedBox(height: 24), // Increased spacing
                    Text(
                      'Volume',
                      style: TextStyle(
                          color: Color(0xFF0D47A1), // Dark text for label
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: sliderValue,
                      min: 0,
                      max: 100,
                      divisions: 10,
                      label: sliderValue.round().toString(),
                      activeColor:
                      Theme.of(context).primaryColor, // Kept this color
                      onChanged: (value) {
                        setState(() {
                          // Update the slider's UI locally
                          sliderValue = value;
                          _localVolume = value;
                        });
                      },
                      onChangeEnd: (value) {
                        // Send the final value to Firebase
                        _updateVolume(value);
                      },
                    ),
                  ],
                ),
                const Spacer(),
                // This is the corrected Disconnect button
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: ElevatedButton(
                    onPressed: _disconnectDevice,
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
                          'Disconnect',
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
          );
        },
      );
    }

    // This is the main page structure
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true, // Make body draw behind app bar
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE3F2FD), // Opaque color
              const Color(0xFFBBDEFB)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea( // Adds padding to avoid status bar
          child: bodyContent,
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent, // Transparent background
      elevation: 0, // No shadow
      leading: const BackButton(color: Colors.black87), // Black back button
      title: const Text(
        'Device',
        style:
        TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold), // Dark title
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark, // Dark status bar icons
    );
  }
}