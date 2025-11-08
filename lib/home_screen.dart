// lib/home_screen.dart

import 'package:flutter/material.dart';
// 1. REMOVED FIRESTORE
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'constants.dart';
import 'medication_schedule_page.dart' show kPrimaryGradient;
import 'package:intl/intl.dart';

import 'pair_device_page.dart';

// Helper class for today's doses
class _TodayDose {
  final String time; // e.g., "08:00"
  final String name;
  final String dosage;

  _TodayDose({
    required this.time,
    required this.name,
    required this.dosage,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentDate = 'Loading...';

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // --- 2. UPDATED RTDB REFERENCES ---
  late final DatabaseReference _remindersRef;
  late final DatabaseReference _medsRef;
  // --- END OF FIX ---

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: (icon != null)
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            )
                : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _currentDate = _formatDate(now);

    // --- 3. INITIALIZE RTDB PATHS ---
    if (_currentUser != null) {
      final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app"
      );
      // This points to the parent folder for device status
      _remindersRef = db.ref('reminders/${_currentUser!.uid}');
      // This points to the medication list
      _medsRef = db.ref('reminders/${_currentUser!.uid}/schedule/med_times');
    }
    // --- END OF FIX ---
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d').format(date);
  }

  String _formatTime12h(String time24h) {
    try {
      final parts = time24h.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2025, 1, 1, hour, minute);
      return TimeOfDay.fromDateTime(dt).format(context);
    } catch (e) {
      return time24h;
    }
  }

  Widget _buildMedicationItem(_TodayDose dose) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              _formatTime12h(dose.time),
              style: TextStyle(
                color: Constants.darkGrey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.name,
                  style: TextStyle(
                    color: Constants.darkGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  dose.dosage,
                  style: TextStyle(
                    color: Constants.mediumGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.radio_button_unchecked,
            color: Constants.mediumGrey,
            size: 20,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildGradientButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PairDevicePage(),
                  ),
                );
              },
              text: 'Connect Device',
              icon: Icons.device_hub,
              gradient: kPrimaryGradient,
            ),
          ),

          // --- 4. READ DEVICE STATUS FROM RTDB ---
          if (_currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: StreamBuilder(
                stream: _remindersRef.onValue, // Listen to the parent 'reminders' node
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Text("Connecting to device..."));
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error connecting to device."));
                  }
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text("Device not found."));
                  }

                  // Safely cast the data
                  final dataMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  final data = <String, dynamic>{};
                  dataMap.forEach((key, value) {
                    data[key.toString()] = value;
                  });

                  // Get data from the 'device' and 'schedule' sub-nodes
                  final deviceData = data['device'] as Map<dynamic, dynamic>? ?? {};
                  final scheduleData = data['schedule'] as Map<dynamic, dynamic>? ?? {};

                  final bool isOnline = (scheduleData['current_status'] ?? 'OFFLINE') != 'OFFLINE';
                  final num batteryNum = deviceData['volume'] ?? 0; // Use 'volume' as battery
                  final int battery = (batteryNum * 100).toInt(); // Convert 0.1 to 10%

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOnline ? Colors.green.shade300 : Colors.red.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isOnline ? Icons.wifi : Icons.wifi_off,
                              color: isOnline ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOnline ? 'Device Connected' : 'Device Offline',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '$battery%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              battery > 75 ? Icons.battery_full :
                              battery > 20 ? Icons.battery_std :
                              Icons.battery_alert,
                              color: battery > 20 ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          // --- END OF FIX ---

          const SizedBox(height: 16),

          // TODAY MEDICATION SCHEDULE HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Today\'s Medication Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.darkGrey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _currentDate,
              style: TextStyle(
                fontSize: 16,
                color: Constants.mediumGrey,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- 5. READ SCHEDULE FROM RTDB ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: StreamBuilder<DatabaseEvent>(
                stream: _medsRef.onValue, // Listen to the med_times path
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading schedule.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                          child: Text("No active medication schedule found.")),
                    );
                  }

                  // Parse the Map of medications
                  final medTimesMap = snapshot.data!.snapshot.value as Map;
                  final todayDoses = medTimesMap.entries.map((entry) {
                    final med = Map<String, dynamic>.from(entry.value as Map);
                    return _TodayDose(
                      time: med['time'] ?? '00:00',
                      name: med['name'] ?? 'N/A',
                      dosage: med['dosage'] ?? 'N/A',
                    );
                  }).toList();

                  // Sort the final list by time
                  todayDoses.sort((a, b) => a.time.compareTo(b.time));

                  if (todayDoses.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                          child: Text("No medication scheduled for today.")),
                    );
                  }

                  return Column(
                    children: [
                      for (int i = 0; i < todayDoses.length; i++)
                        Column(
                          children: [
                            _buildMedicationItem(todayDoses[i]),
                            if (i < todayDoses.length - 1)
                              const Divider(height: 16, thickness: 0.5, color: Colors.grey),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          // --- END OF FIX ---
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}