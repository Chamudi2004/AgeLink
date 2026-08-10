// lib/device_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'pair_device_page.dart';
import 'package:flutter/services.dart';

import 'constants.dart';
import 'gradient_scaffold.dart';
import 'custom_snackbar.dart';

const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const kRedGradient = LinearGradient(
  colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  DatabaseReference? _userRemindersRef;
  // --- 1. CRITICAL FIX: We must cache the stream so it doesn't rebuild ---
  Stream<DatabaseEvent>? _deviceStream;

  double? _localVolume;

  @override
  void initState() {
    super.initState();
    _setupDeviceReference();
  }

  void _setupDeviceReference() {
    if (_currentUser == null) return;

    try {
      final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app");

      _userRemindersRef = db.ref('reminders/${_currentUser!.uid}');
      // Cache the stream here in initState so it never changes during slider drag
      _deviceStream = _userRemindersRef!.onValue;
    } catch (e) {
      print("Error initializing Firebase: $e");
    }
  }

  // --- 2. CRITICAL FIX: Make this a Future so we can await it ---
  Future<void> _updateVolume(double sliderValue) async {
    if (_userRemindersRef == null) return;

    double firebaseValue = sliderValue / 100.0;

    try {
      await _userRemindersRef!.child('device').child('volume').set(firebaseValue);
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Error updating volume.',
          isError: true,
        );
      }
    }
  }

  void _disconnectDevice() async {
    if (_currentUser == null || _userRemindersRef == null) return;

    try {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({'pairedDeviceId': FieldValue.delete()});
      } on FirebaseException catch (e) {
        if (e.code == 'not-found') {
          print("User doc not found in Firestore, proceeding with RTDB cleanup.");
        }
      }

      await _userRemindersRef!.remove();

      if (mounted) {
        CustomSnackBar.show(
            context: context,
            message: 'Device unpaired successfully.'
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
            context: context,
            message: 'Failed to unpair device.',
            isError: true
        );
      }
    }
  }

  void _showDisconnectConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link_off_rounded, color: Colors.redAccent),
              ),
              const SizedBox(width: 12),
              const Text('Disconnect Device'),
            ],
          ),
          content: Text(
            'Are you sure you want to unpair this device? You will stop receiving alerts until you pair a device again.',
            style: TextStyle(color: Constants.darkGrey, fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: Constants.mediumGrey, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _disconnectDevice();
              },
              child: const Text('Disconnect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  num _parseNum(dynamic value, [num defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    double verticalPadding = 18.0,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            alignment: Alignment.center,
            child: (icon != null)
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
              ],
            )
                : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.devices_rounded, size: 64, color: Color(0xFF1E88E5)),
              ),
              const SizedBox(height: 24),
              Text(
                'No Device Paired',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Constants.darkGrey),
              ),
              const SizedBox(height: 8),
              Text(
                'Please pair a pill dispenser to manage its settings and volume here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Constants.mediumGrey, height: 1.4),
              ),
              const SizedBox(height: 32),
              _buildGradientButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PairDevicePage()),
                  );
                },
                text: 'Pair New Device',
                icon: Icons.bluetooth_searching_rounded,
                gradient: kPrimaryGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor, bool isBadge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1E88E5), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Constants.mediumGrey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (isBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (valueColor ?? Constants.darkGrey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: valueColor ?? Constants.darkGrey,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? Constants.darkGrey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const GradientScaffold(
        body: Center(child: Text("Please log in to manage your device.", style: TextStyle(fontSize: 18))),
      );
    }

    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Device Settings',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Constants.darkblue),
        centerTitle: true,
      ),
      body: _deviceStream == null
          ? _buildEmptyState()
          : StreamBuilder<DatabaseEvent>(
        stream: _deviceStream, // <-- We now use the cached stream here
        builder: (context, AsyncSnapshot<DatabaseEvent> eventSnapshot) {

          // Only show the loader if we truly have no data yet
          if (eventSnapshot.connectionState == ConnectionState.waiting && !eventSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (eventSnapshot.hasError) {
            return Center(child: Text("Error loading data: ${eventSnapshot.error.toString()}"));
          }

          if (!eventSnapshot.hasData || eventSnapshot.data!.snapshot.value == null) {
            return _buildEmptyState();
          }

          final dataMap = eventSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final data = <String, dynamic>{};
          dataMap.forEach((key, value) {
            data[key.toString()] = value;
          });

          final deviceData = data['device'] as Map<dynamic, dynamic>? ?? {};

          String deviceName = deviceData['device_id']?.toString() ?? 'Unknown Device';
          final bool isActive = deviceData['device_active'] == true;
          String status = isActive ? 'Online' : 'Offline';
          Color statusColor = isActive ? const Color(0xFF4CAF50) : Colors.redAccent;

          final String lastSyncString = deviceData['last_sync']?.toString() ?? "N/A";
          String lastSync;

          if (lastSyncString == "N/A") {
            lastSync = "Never";
          } else {
            try {
              final parts = lastSyncString.split(':');
              final dt = DateTime(2025, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
              lastSync = "Today at ${TimeOfDay.fromDateTime(dt).format(context)}";
            } catch (e) {
              lastSync = lastSyncString;
            }
          }

          final num volumeNum = _parseNum(deviceData['volume'], 0.5);
          final double currentVolume = (volumeNum.toDouble() * 100.0).clamp(0.0, 100.0);

          // Use local volume while dragging, else fallback to Firebase volume
          double sliderValue = _localVolume ?? currentVolume;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100, width: 2),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Device ID', deviceName, Icons.memory_rounded),
                            Divider(color: Colors.grey.shade200, height: 16),
                            _buildInfoRow('Connection Status', status, isActive ? Icons.wifi_rounded : Icons.wifi_off_rounded, valueColor: statusColor, isBadge: true),
                            Divider(color: Colors.grey.shade200, height: 16),
                            _buildInfoRow('Last Synchronized', lastSync, Icons.sync_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Volume Control Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E88E5).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.volume_up_rounded, color: Color(0xFF1E88E5), size: 20),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Buzzer Volume',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.darkGrey),
                                ),
                                const Spacer(),
                                Text(
                                  '${sliderValue.round()}%',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E88E5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 6,
                                activeTrackColor: const Color(0xFF1E88E5),
                                inactiveTrackColor: Colors.blue.shade100,
                                thumbColor: Colors.white,
                                overlayColor: const Color(0xFF1E88E5).withOpacity(0.2),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 4),
                              ),
                              child: Slider(
                                value: sliderValue,
                                min: 0,
                                max: 100,
                                divisions: 10,
                                onChanged: (value) {
                                  // ONLY update local state while dragging for butter-smooth UI
                                  setState(() {
                                    _localVolume = value;
                                  });
                                },
                                onChangeEnd: (value) async {
                                  // 3. CRITICAL FIX: Await the database write before clearing local state
                                  await _updateVolume(value);
                                  if (mounted) {
                                    setState(() {
                                      _localVolume = null;
                                    });
                                  }
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Mute', style: TextStyle(color: Constants.mediumGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('Max', style: TextStyle(color: Constants.mediumGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Disconnect Button
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: _buildGradientButton(
                  onPressed: _showDisconnectConfirmation,
                  text: 'Disconnect Device',
                  icon: Icons.link_off_rounded,
                  gradient: kRedGradient,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}