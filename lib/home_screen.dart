// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'constants.dart';
import 'medication_schedule_page.dart' show kPrimaryGradient;
import 'package:intl/intl.dart';
import 'pair_device_page.dart';
import 'chat_screen.dart'; // <-- ADDED for navigation

// Helper class for today's doses
class _TodayDose {
  final String time; // e.g., "08:00"
  final String name;
  final String dosage;
  final String key; // Unique key for history matching

  _TodayDose({
    required this.time,
    required this.name,
    required this.dosage,
    required this.key,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // --- RTDB REFERENCES ---
  late final DatabaseReference _deviceRef; // Specific ref for device
  late final DatabaseReference _medsRef;
  late final DatabaseReference _historyRef;
  // --- END OF RTDB REFERENCES ---

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
          "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app");

      final uid = _currentUser!.uid;
      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Be more specific with your references
      _deviceRef = db.ref('reminders/$uid/device');
      _medsRef = db.ref('reminders/$uid/schedule/med_times');
      _historyRef = db.ref('reminders/$uid/history/$todayDate');
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text('Please log in.'));
    }

    final String currentDate = _formatDate(DateTime.now());

    return Column(
      children: [
        // 1. DEVICE BANNER
        DeviceOfflineBanner(
          deviceRef: _deviceRef,
        ),

        // 2. AI BANNER
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), // Spacing
          child: AiChatNotificationCard(), // The AI banner
        ),

        // 3. TITLE (NOW SEPARATE)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4), // More top spacing
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Today's Medication Schedule",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.darkGrey,
              ),
            ),
          ),
        ),

        // 4. DATE (NOW SEPARATE)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              currentDate,
              style: TextStyle(
                fontSize: 16,
                color: Constants.mediumGrey,
              ),
            ),
          ),
        ),

        // 5. THE "WINDOW" FOR YOUR MEDICATION LIST
        Expanded(
          child: MedicationScheduleWindow(
            medsRef: _medsRef,
            historyRef: _historyRef,
          ), // This new widget holds the scrollable list
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------
// WIDGET 1: THE AI BANNER (Tappable)
// (This is the updated version with white background and your logo)
// -------------------------------------------------------------------
class AiChatNotificationCard extends StatelessWidget {
  const AiChatNotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // --- ⭐️ CHANGE 1: NAVIGATION ADDED ⭐️ ---
        onTap: () {
          // This code will push the new screen on top
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        },
        // --- ⭐️ END OF CHANGE ⭐️ ---
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // --- ⭐️ CHANGE 2: LOGO STYLE UPDATED ⭐️ ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade300, // A light, thin border
                    width: 1,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white, // White background

                  // We REMOVED the extra Padding widget from here
                  // to let the logo fit the circle.
                  child: Image.asset(
                    'assets/ai_logo.png', // <-- Uses your file
                    fit: BoxFit.contain, // Ensures it fits
                  ),
                ),
              ),
              // --- ⭐️ END OF CHANGE ⭐️ ---
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Daily Plan is Ready!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Tap here for your new activity and meal ideas.",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// WIDGET 2: THE DEVICE BANNER
// (No changes)
// -------------------------------------------------------------------
class DeviceOfflineBanner extends StatelessWidget {
  final DatabaseReference deviceRef;
  const DeviceOfflineBanner({super.key, required this.deviceRef});

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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
                Text(text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ],
            )
                : Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The outer padding is correct and matches the AI banner
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: StreamBuilder<DatabaseEvent>(
        stream: deviceRef.onValue, // Listens only to device status
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Use a specific height to prevent layout jump
            return const SizedBox(
              height: 50,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            // This is the "Connect Device" button, it's fine
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

          final deviceData =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final bool isOnline = deviceData['device_active'] ?? false;

          // --- PROFESSIONAL BANNER DESIGN ---
          final Color backgroundColor = isOnline
              ? Color(0xFFE8F5E9) // Soft Green
              : Color(0xFFFFEBEE); // Soft Red
          final Color contentColor = isOnline
              ? Color(0xFF1B5E20) // Dark Green
              : Color(0xFFC62828); // Dark Red
          final IconData icon = isOnline ? Icons.wifi : Icons.wifi_off;
          final String text = isOnline ? 'Device Connected' : 'Device Offline';

          return Card(
            elevation: 0, // No shadow, just a clean container
            color: backgroundColor, // Use the soft background color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              // Use symmetric padding for a cleaner look
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start, // Left-align
                children: [
                  Icon(
                    icon,
                    color: contentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: contentColor, // Match text color to icon
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------------
// WIDGET 3: THE SCROLLABLE MEDICATION "WINDOW"
// (This widget contains the highlight logic)
// -------------------------------------------------------------------
class MedicationScheduleWindow extends StatelessWidget {
  final DatabaseReference medsRef;
  final DatabaseReference historyRef;

  const MedicationScheduleWindow({
    super.key,
    required this.medsRef,
    required this.historyRef,
  });

  String _formatTime12h(BuildContext context, String time24h) {
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

  // --- WIDGET HAS BEEN UPDATED ---
  Widget _buildMedicationItem(
      BuildContext context,
      _TodayDose dose,
      String status,
      bool isNext, // <-- New parameter
      ) {
    IconData icon;
    Color iconColor;

    if (status == 'taken') {
      icon = Icons.check_circle;
      iconColor = Constants.greenColor;
    } else if (status == 'missed') {
      icon = Icons.cancel;
      iconColor = Colors.red;
    } else {
      // pending or not found
      icon = Icons.radio_button_unchecked;
      iconColor = Constants.mediumGrey;
    }

    // --- ⭐️ UPDATED HIGHLIGHT LOGIC (YELLOW) ⭐️ ---
    // If it's the next dose AND it's not taken/missed, highlight it
    final bool highlight = isNext && status == 'pending';
    final Color highlightColor = highlight
        ? Colors.amber.shade100 // Soft yellow/amber highlight
        : Colors.transparent;

    return Container(
      color: highlightColor,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              _formatTime12h(context, dose.time),
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
            icon,
            color: iconColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      clipBehavior: Clip.antiAlias, // Ensures list scrolls inside the card
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The SCROLLABLE List
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: medsRef.onValue, // 1. Listen to the SCHEDULE
              builder: (context, scheduleSnapshot) {
                if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (scheduleSnapshot.hasError) {
                  return const Center(child: Text('Error loading schedule.'));
                }
                if (!scheduleSnapshot.hasData ||
                    scheduleSnapshot.data!.snapshot.value == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                        child: Text("No active medication schedule found.")),
                  );
                }

                // Parse the schedule
                final medTimesMap = scheduleSnapshot.data!.snapshot.value as Map;
                final allDoses = medTimesMap.entries.map((entry) {
                  final med = Map<String, dynamic>.from(entry.value as Map);
                  final name = med['name'] ?? 'N/A';
                  final time = med['time'] ?? '00:00';
                  // Create the unique key: "{Name}_{TimeNoColons}"
                  final String doseKey =
                      "${name.replaceAll(' ', '_')}_${time.replaceAll(":", "")}";

                  return _TodayDose(
                    time: time,
                    name: name,
                    dosage: med['dosage'] ?? 'N/A',
                    key: doseKey,
                  );
                }).toList();

                if (allDoses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                        child: Text("No medication scheduled for today.")),
                  );
                }

                // --- "ROLL-OVER" SORTING LOGIC ---
                final now = DateTime.now();
                final currentTime = DateFormat('HH:mm').format(now);

                final upcomingDoses = <_TodayDose>[];
                final pastDoses = <_TodayDose>[];

                for (final dose in allDoses) {
                  if (dose.time.compareTo(currentTime) >= 0) {
                    upcomingDoses.add(dose);
                  } else {
                    pastDoses.add(dose);
                  }
                }

                // Sort both lists individually by time (ascending)
                upcomingDoses.sort((a, b) => a.time.compareTo(b.time));
                pastDoses.sort((a, b) => a.time.compareTo(b.time));

                // Combine them: upcoming first, then past
                final todayDoses = [...upcomingDoses, ...pastDoses];
                // --- END OF SORTING LOGLOGIC ---


                // 2. Listen to the HISTORY inside the schedule builder
                return StreamBuilder<DatabaseEvent>(
                  stream: historyRef.onValue,
                  builder: (context, historySnapshot) {
                    final historyMap =
                        historySnapshot.data?.snapshot.value as Map? ?? {};

                    return ListView.builder(
                      itemCount: todayDoses.length,
                      itemBuilder: (context, index) {
                        final dose = todayDoses[index];

                        // Get status from the real-time history map
                        final String status =
                            historyMap[dose.key]?['status']?.toString() ??
                                'pending';

                        // --- HIGHLIGHT LOGIC ---
                        // The "next" dose is the first one in the list (index 0)
                        // AND it must be in the "upcoming" list.
                        final bool isNext =
                            index == 0 && upcomingDoses.isNotEmpty;

                        return Column(
                          children: [
                            // Pass the new 'isNext' flag
                            _buildMedicationItem(context, dose, status, isNext),
                            if (index < todayDoses.length -
                                1) // Add divider
                              const Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Colors.black12,
                                indent: 16, // Match padding
                                endIndent: 16, // Match padding
                              ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}