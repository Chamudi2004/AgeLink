import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'pair_device_page.dart';
// We need to import this to get the gradient button
import 'medication_schedule_page.dart' show kPrimaryGradient;
import 'package:intl/intl.dart'; // Import for date formatting

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
  String _currentDayOfWeek = ''; // e.g., "Monday"

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _appId = const String.fromEnvironment('app_id', defaultValue: 'default-app-id');
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // --- NEW: Reusable Gradient Button ---
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
  }) {
    // ... (This function is correct, no changes)
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
    // Get the full day name, e.g., "Monday"
    _currentDayOfWeek = DateFormat('EEEE').format(now);
  }

  String _formatDate(DateTime date) {
    // Use intl package for easier formatting
    return DateFormat('EEEE, MMMM d').format(date);
  }

  // (REMOVED _getDayOfWeek and _getMonth as _formatDate now handles it)

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
    // ... (This function is correct, no changes)
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
    // --- UPDATED: New collection path ---
    final String schedulesCollectionPath = 'artifacts/$_appId/users/${_currentUser!.uid}/medicationSchedules';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Gradient Button ---
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
              icon: Icons.device_hub, // Example icon
              gradient: kPrimaryGradient,
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

          // --- UPDATED: MEDICATION LIST ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white, // This white card is correct
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
              // --- UPDATED: StreamBuilder for new logic ---
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection(schedulesCollectionPath)
                    .where('isActive', isEqualTo: true) // Get all active schedules
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading schedule.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                          child: Text("No active medication schedule found.")),
                    );
                  }

                  // --- (THIS IS THE NEW LOGIC) ---
                  final List<_TodayDose> todayDoses = [];

                  // 1. Loop through all active SCHEDULES
                  for (var scheduleDoc in snapshot.data!.docs) {
                    final medications = List<Map<String, dynamic>>.from(scheduleDoc.get('medications') ?? []);

                    // 2. Loop through all PILLS in that schedule
                    for (final med in medications) {
                      final String freq = med['frequency'] ?? 'Daily';
                      bool shouldAddToday = false;

                      // 3. Check the frequency
                      if (freq == 'Daily') {
                        shouldAddToday = true;
                      } else if (freq == 'Weekly') {
                        // TODO: This assumes you save the "day" in the 'Custom' field
                        // For now, let's just check against the current day name
                        // This is a placeholder - you'll need to store which day
                        // e.g., if (med['dayOfWeek'] == _currentDayOfWeek)
                        // This is a simple example, assuming "Weekly" means today
                        if (med['dayOfWeek'] == _currentDayOfWeek) { // Example check
                          shouldAddToday = true;
                        }
                      } else if (freq == 'Custom') {
                        // TODO: Add logic to check custom dates
                      }

                      // 4. If it's for today, add its times
                      if (shouldAddToday) {
                        final times = List<String>.from(med['times'] ?? []);
                        for (final time in times) {
                          todayDoses.add(_TodayDose(
                            time: time,
                            name: med['name'] ?? 'N/A',
                            dosage: med['dosage'] ?? 'N/A',
                          ));
                        }
                      }
                    }
                  }
                  // --- (END OF NEW LOGIC) ---

                  // Sort the final list by time
                  todayDoses.sort((a, b) => a.time.compareTo(b.time));

                  if (todayDoses.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                          child: Text("No medication scheduled for today.")),
                    );
                  }

                  // Build the list view
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}