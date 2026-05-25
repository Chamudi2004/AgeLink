// lib/home_screen.dart

import 'package:flutter/material.dart';
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

  // --- RTDB REFERENCES ---
  late final DatabaseReference _remindersRef;
  late final DatabaseReference _medsRef;
  late final DatabaseReference _historyRef; // <-- NEW: History reference
  // --- END OF RTDB REFERENCES ---

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
  }) {
    // This function remains the same as before
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

    if (_currentUser != null) {
      final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app"
      );

      final uid = _currentUser!.uid;
      final todayDate = DateFormat('yyyy-MM-dd').format(now);

      _remindersRef = db.ref('reminders/$uid');
      _medsRef = db.ref('reminders/$uid/schedule/med_times');

      // NEW: Reference to today's dose history
      _historyRef = db.ref('reminders/$uid/history/$todayDate');
    }
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

  // --- MODIFIED TO ACCEPT STATUS ---
  Widget _buildMedicationItem(_TodayDose dose, String status) {

    IconData icon;
    Color iconColor;

    if (status == 'taken') {
      icon = Icons.check_circle;
      iconColor = Constants.greenColor;
    } else if (status == 'missed') {
      icon = Icons.cancel;
      iconColor = Colors.red;
    } else { // pending or not found
      icon = Icons.radio_button_unchecked;
      iconColor = Constants.mediumGrey;
    }

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
          // --- Display the status icon ---
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ],
      ),
    );
  }
  // --- END MODIFIED _buildMedicationItem ---

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text('Please log in.'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Status StreamBuilder (Unchanged)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<DatabaseEvent>(
              stream: _remindersRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return _buildGradientButton(
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
                  );
                }

                final dataMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final data = <String, dynamic>{};
                dataMap.forEach((key, value) {
                  data[key.toString()] = value;
                });

                final deviceData = data['device'] as Map<dynamic, dynamic>? ?? {};
                final bool isOnline = deviceData['device_active'] ?? false;

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
                    ],
                  ),
                );
              },
            ),
          ),

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

          // --- MODIFIED SCHEDULE STREAM BUILDER WITH HISTORY ---
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
                stream: _medsRef.onValue, // Listen to the active schedule
                builder: (context, scheduleSnapshot) {
                  if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (scheduleSnapshot.hasError) {
                    return const Center(
                        child: Text('Error loading schedule.'));
                  }
                  if (!scheduleSnapshot.hasData || scheduleSnapshot.data!.snapshot.value == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                          child: Text("No active medication schedule found.")),
                    );
                  }

                  // 1. Parse the Map of medications from the schedule
                  final medTimesMap = scheduleSnapshot.data!.snapshot.value as Map;
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

                  // 2. Use a FutureBuilder to fetch today's history once (using .once() for efficiency)
                  return FutureBuilder<DatabaseEvent>(
                      future: _historyRef.once(), // Get history for today
                      builder: (context, historySnapshot) {
                        // We still show the doses even if history is loading or has an error
                        // They will just default to 'pending'.

                        final historyMap = historySnapshot.data?.snapshot.value as Map<dynamic, dynamic>? ?? {};

                        return Column(
                          children: [
                            for (int i = 0; i < todayDoses.length; i++)
                              Builder(
                                  builder: (context) {
                                    final dose = todayDoses[i];

                                    // Create the unique key: "{Name}_{TimeNoColons}"
                                    final String doseKey = "${dose.name.replaceAll(' ', '_')}_${dose.time.replaceAll(":", "")}";

                                    // Get the status from the history map, default to 'pending'
                                    final String status = historyMap[doseKey]?['status']?.toString() ?? 'pending';

                                    return Column(
                                      children: [
                                        _buildMedicationItem(dose, status), // Pass the status
                                        if (i < todayDoses.length - 1)
                                          const Divider(height: 16, thickness: 0.5, color: Colors.grey),
                                      ],
                                    );
                                  }
                              ),
                          ],
                        );
                      }
                  );
                },
              ),
            ),
          ),
          // --- END OF MODIFIED SCHEDULE STREAM BUILDER ---
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}