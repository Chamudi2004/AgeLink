import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'gradient_scaffold.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // This will hold the reference to the device in RTDB
  DatabaseReference? _deviceRef;

  // Used to wait for the device ID to be fetched from Firestore
  final Completer<DatabaseReference> _refCompleter = Completer();

  // Local state for the slider to provide a smooth UI
  double? _localVolume;

  @override
  void initState() {
    super.initState();
    _setupDeviceReference();
  }

  // Step 1: Get the paired device ID from Firestore
  void _setupDeviceReference() async {
    if (currentUser == null) {
      _refCompleter.completeError("User not logged in.");
      return;
    }

    try {
      // 1. Get user's profile from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists || (userDoc.data() as Map).containsKey('pairedDeviceId') == false) {
        _refCompleter.completeError("No paired device found. Go to the Home screen to pair one.");
        return;
      }

      // 2. Get the device ID from the profile
      String deviceId = userDoc.get('pairedDeviceId');

      // 3. Create the Realtime Database reference
      final ref = FirebaseDatabase.instance.ref('devices/$deviceId');
      _deviceRef = ref;

      // Complete the future so the FutureBuilder can run
      _refCompleter.complete(ref);

    } catch (e) {
      _refCompleter.completeError("Error fetching device ID: $e");
    }
  }

  // Step 2: Write volume changes back to RTDB
  void _updateVolume(double value) {
    // Update local state immediately for a responsive feel
    setState(() {
      _localVolume = value;
    });

    // Send the final value to Firebase
    _deviceRef?.child('volume').set(value);
  }

  // Step 3: Handle disconnect logic (unpairs from Firestore)
  void _disconnectDevice() async {
    if (currentUser == null) return;
    try {
      // We just remove the pairing from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'pairedDeviceId': FieldValue.delete()});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device unpaired.')),
      );
      Navigator.pop(context); // Go back
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      // AppBar styled to match prototype
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
        title: const Text(
          'Device',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<DatabaseReference>(
        future: _refCompleter.future,
        builder: (context, snapshot) {

          // Case 1: Still waiting for device ID
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Case 2: Error (e.g., user has no paired device)
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error: ${snapshot.error.toString()}', textAlign: TextAlign.center),
              ),
            );
          }

          DatabaseReference deviceRef = snapshot.data!;
          return StreamBuilder(
            stream: deviceRef.onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> eventSnapshot) {
              if (!eventSnapshot.hasData || eventSnapshot.data!.snapshot.value == null) {
                return const Center(child: Text('Waiting for device data...'));
              }
              Map deviceData = eventSnapshot.data!.snapshot.value as Map;
              String deviceName = deviceData['deviceName'] ?? 'N/A';
              int battery = deviceData['battery'] ?? 0;
              String status = deviceData['connectionStatus'] ?? 'Unknown';
              String lastSync = deviceData['lastSynced'] ?? 'N/A';
              double firebaseVolume = (deviceData['volume'] ?? 50.0).toDouble();

              if (_localVolume == null) {
                _localVolume = firebaseVolume;
              }
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device Name',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                          Text(
                            deviceName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                '$battery%',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                  battery > 90 ? Icons.battery_full :
                                  battery > 20 ? Icons.battery_std :
                                  Icons.battery_alert,
                                  size: 20
                              ),
                              const SizedBox(width: 24),
                              Text(
                                status,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Last Synced',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                          Text(
                            lastSync,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Volume',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                          Slider(
                            value: _localVolume ?? 50.0,
                            min: 0,
                            max: 100,
                            divisions: 10,
                            label: _localVolume?.round().toString(),
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _localVolume = value;
                              });
                            },
                            onChangeEnd: _updateVolume,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
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
        },
      ),
    );
  }
}
