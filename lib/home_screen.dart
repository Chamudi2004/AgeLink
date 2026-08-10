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

  late final DatabaseReference _deviceRef; // Changed to target only the device node
  late final DatabaseReference _medsRef;
  late final DatabaseReference _historyRef;

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
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
            padding: const EdgeInsets.symmetric(vertical: 18.0),
            alignment: Alignment.center,
            child: (icon != null)
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5)),
              ],
            )
                : Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5)),
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
          databaseURL:
          "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app");

      final uid = _currentUser!.uid;
      // Get today's date in 'YYYY-MM-DD' format for the history path
      final todayDate = DateFormat('yyyy-MM-dd').format(now);

      // We now listen DIRECTLY to the device node for instantaneous real-time updates
      _deviceRef = db.ref('reminders/$uid/device');

      _medsRef = db.ref('reminders/$uid/schedule/med_times');
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

  Widget _buildMedicationItem(_TodayDose dose, String status) {
    IconData icon;
    Color iconColor;
    Color bgColor;
    Color timeColor;

    if (status == 'taken') {
      icon = Icons.check_circle_rounded;
      iconColor = Constants.greenColor;
      bgColor = Constants.greenColor.withOpacity(0.08);
      timeColor = Constants.greenColor;
    } else if (status == 'missed') {
      icon = Icons.cancel_rounded;
      iconColor = Colors.redAccent;
      bgColor = Colors.redAccent.withOpacity(0.08);
      timeColor = Colors.redAccent;
    } else {
      // pending or not found
      icon = Icons.access_time_rounded;
      iconColor = Constants.mediumGrey;
      bgColor = Colors.white;
      timeColor = Constants.darkGrey;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: status == 'pending'
            ? Border.all(color: Colors.grey.shade200, width: 1.5)
            : Border.all(color: Colors.transparent, width: 1.5),
        boxShadow: status == 'pending'
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
            : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: status == 'pending' ? Colors.grey.shade100 : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _formatTime12h(dose.time),
              style: TextStyle(
                color: timeColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.name,
                  style: TextStyle(
                    color: Constants.darkGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dose.dosage,
                  style: TextStyle(
                    color: Constants.mediumGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.1),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text('Please log in.'));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Constants.mediumGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentDate,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Constants.darkGrey,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Device Status StreamBuilder - Now strictly listening to the `device` node
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: StreamBuilder<DatabaseEvent>(
              stream: _deviceRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If device node doesn't exist at all, prompt to pair
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
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

                // Parse the specific device node data
                final deviceData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                // Explicitly check for the boolean value to ensure real-time accuracy
                final bool isOnline = deviceData['device_active'] == true;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOnline
                          ? [Constants.greenColor.withOpacity(0.8), Constants.greenColor]
                          : [Colors.redAccent.shade200, Colors.redAccent.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isOnline ? Constants.greenColor : Colors.redAccent)
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOnline ? 'Device Connected' : 'Device Offline',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOnline ? 'Ready for today\'s schedule' : 'Please check connection',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // TODAY MEDICATION SCHEDULE HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Icon(Icons.medication_liquid_rounded, color: Constants.darkGrey, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Daily Schedule',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Constants.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- MODIFIED SCHEDULE STREAM BUILDER WITH HISTORY AND MISSED LOGIC ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: StreamBuilder<DatabaseEvent>(
              stream: _medsRef.onValue,
              builder: (context, scheduleSnapshot) {
                if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (scheduleSnapshot.hasError) {
                  return const Center(child: Text('Error loading schedule.'));
                }
                if (!scheduleSnapshot.hasData ||
                    scheduleSnapshot.data!.snapshot.value == null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          "No active medication schedule found.",
                          style: TextStyle(color: Constants.mediumGrey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final medTimesMap =
                scheduleSnapshot.data!.snapshot.value as Map;
                final todayDoses = medTimesMap.entries.map((entry) {
                  final med = Map<String, dynamic>.from(entry.value as Map);
                  return _TodayDose(
                    time: med['time'] ?? '00:00',
                    name: med['name'] ?? 'N/A',
                    dosage: med['dosage'] ?? 'N/A',
                  );
                }).toList();

                todayDoses.sort((a, b) => a.time.compareTo(b.time));

                if (todayDoses.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          "No medication scheduled for today.",
                          style: TextStyle(color: Constants.mediumGrey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return FutureBuilder<DatabaseEvent>(
                    future: _historyRef.once(),
                    builder: (context, historySnapshot) {
                      final historyMap = historySnapshot.data?.snapshot.value
                      as Map<dynamic, dynamic>? ??
                          {};

                      return Column(
                        children: [
                          for (int i = 0; i < todayDoses.length; i++)
                            Builder(builder: (context) {
                              final dose = todayDoses[i];

                              // CRITICAL: Create the unique key, ensuring spaces are replaced
                              final String safeName =
                              dose.name.replaceAll(' ', '_');
                              final String doseKey =
                                  "${safeName}_${dose.time.replaceAll(":", "")}";

                              String status = historyMap[doseKey]?['status']
                                  ?.toString() ??
                                  'pending';

                              // CRITICAL: Infer 'missed' status if dose is in the past and no record exists
                              if (status == 'pending') {
                                try {
                                  final timeParts = dose.time.split(':');
                                  final scheduledTime = DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day,
                                    int.parse(timeParts[0]),
                                    int.parse(timeParts[1]),
                                  );

                                  // If scheduled time is in the past, mark as 'missed'
                                  if (scheduledTime
                                      .isBefore(DateTime.now())) {
                                    status = 'missed';
                                  }
                                } catch (e) {
                                  // Keep status as 'pending' on parsing error
                                }
                              }

                              return _buildMedicationItem(dose, status);
                            }),
                        ],
                      );
                    });
              },
            ),
          ),
          // --- END OF MODIFIED SCHEDULE STREAM BUILDER ---
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}