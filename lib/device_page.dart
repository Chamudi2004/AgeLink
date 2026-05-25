import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'pair_device_page.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  DatabaseReference? _userRemindersRef;

  // Local state for the slider
  // We keep this to ensure the slider updates smoothly while dragging
  double? _localVolume;

  @override
  void initState() {
    super.initState();
    _setupDeviceReference();
  }

  void _setupDeviceReference() {
    if (_currentUser == null) {
      print("DevicePage: User not logged in, can't fetch device data.");
      return;
    }

    print("DevicePage: Initializing DB reference for UID: ${_currentUser!.uid}");

    try {
      final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
          "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app");

      _userRemindersRef = db.ref('reminders/${_currentUser!.uid}');

      print("DevicePage: Listening for data at ${_userRemindersRef!.path}");
    } catch (e) {
      print("Error initializing Firebase: $e");
    }
  }

  // NOTE: This function is now called continuously from onChanged.
  void _updateVolume(double sliderValue) {
    if (_userRemindersRef == null) {
      print("DevicePage: ERROR - Database reference is null. Cannot update volume.");
      return;
    }

    double firebaseValue = sliderValue / 100.0;

    // print("DevicePage: Attempting to write volume: $firebaseValue"); // Suppress continuous logging

    _userRemindersRef!
        .child('device')
        .child('volume')
        .set(firebaseValue)
        .then((_) {
      // print("DevicePage: Volume update successful."); // Suppress continuous logging
    })
        .catchError((e) {
      print("DevicePage: ERROR updating volume: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating volume. Error: $e')),
        );
      }
    });
  }

  void _disconnectDevice() async {
    if (_currentUser == null) return;
    if (_userRemindersRef == null) return;

    try {
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

      await _userRemindersRef!.remove();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device unpaired.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  num _parseNum(dynamic value, [num defaultValue = 0]) {
    if (value == null) {
      return defaultValue;
    }
    if (value is num) {
      return value;
    }
    if (value is String) {
      return num.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
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
      bodyContent = StreamBuilder<DatabaseEvent>(
        stream: _userRemindersRef!.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (eventSnapshot.hasError) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      "Error loading data: ${eventSnapshot.error.toString()}",
                      textAlign: TextAlign.center),
                ));
          }

          if (!eventSnapshot.hasData ||
              eventSnapshot.data!.snapshot.value == null) {
            return _buildPairDeviceButton();
          }

          final dataMap =
          eventSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final data = <String, dynamic>{};
          dataMap.forEach((key, value) {
            data[key.toString()] = value;
          });

          final deviceData = data['device'] as Map<dynamic, dynamic>? ?? {};

          String deviceName = deviceData['device_id']?.toString() ?? 'N/A';
          final bool isActive = deviceData['device_active'] ?? false;
          String status = isActive ? 'Device Active' : 'Device Inactive';

          final String lastSyncString = deviceData['last_sync']?.toString() ?? "N/A";
          String lastSync;

          if (lastSyncString == "N/A") {
            lastSync = "N/A";
          } else {
            try {
              final parts = lastSyncString.split(':');
              final hour = int.parse(parts[0]);
              final minute = int.parse(parts[1]);
              final dt = DateTime(2025, 1, 1, hour, minute);
              lastSync = "Today at ${TimeOfDay.fromDateTime(dt).format(context)}";
            } catch (e) {
              lastSync = lastSyncString;
            }
          }

          final num volumeNum = _parseNum(deviceData['volume'], 0.0);
          final double currentVolume = (volumeNum.toDouble() * 100.0);

          // Priority: 1. Local drag value, 2. Live Firebase value
          double sliderValue = _localVolume ?? currentVolume;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Name',
                      style: TextStyle(
                          color: Color(0xFF0D47A1),
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      deviceName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Status',
                      style: TextStyle(
                          color: Color(0xFF0D47A1),
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      status,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Last Sync',
                      style: TextStyle(
                          color: Color(0xFF0D47A1),
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      lastSync,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Volume',
                      style: TextStyle(
                          color: Color(0xFF0D47A1),
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: sliderValue,
                      min: 0,
                      max: 100,
                      divisions: 10,
                      label: sliderValue.round().toString(),
                      activeColor: Theme.of(context).primaryColor,

                      // *** FIX: Update local state AND write to Firebase continuously ***
                      onChanged: (value) {
                        // 1. Update the local UI state for smooth dragging
                        setState(() {
                          _localVolume = value;
                        });

                        // 2. Immediately write the value to the database on every change
                        // This ensures the database reflects the position without lifting the finger.
                        _updateVolume(value);
                      },

                      // Optional: Clear local state on drag end to rely fully on stream
                      onChangeEnd: (value) {
                        setState(() {
                          _localVolume = null;
                        });
                        // NOTE: _updateVolume is already called by onChanged, so we don't need it here.
                      },
                    ),
                  ],
                ),
                const Spacer(),
                // Disconnect button
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

    // Main page structure
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE3F2FD),
              const Color(0xFFBBDEFB)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: bodyContent,
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const BackButton(color: Colors.black87),
      title: const Text(
        'Device',
        style:
        TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }
}