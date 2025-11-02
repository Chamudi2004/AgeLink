import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'medication_schedule_page.dart' show Medication;
import 'pair_device_page.dart';


class _TodayDose {
  final String time;
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


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _appId = const String.fromEnvironment('app_id', defaultValue: 'default-app-id');
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _currentDate = _formatDate(DateTime.now());
  }

  String _formatDate(DateTime date) {
    final dayOfWeek = _getDayOfWeek(date.weekday);
    final month = _getMonth(date.month);
    return '$dayOfWeek, $month ${date.day}';
  }

  String _getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _getMonth(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
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
    final String medicationCollectionPath = 'artifacts/$_appId/users/${_currentUser!.uid}/medications';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PairDevicePage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 2,
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
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    alignment: Alignment.center,
                    child: const Text(
                      'Connect Device',
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

          // MEDICATION LIST
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

              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection(medicationCollectionPath).snapshots(),
                builder: (context, snapshot) {
                  // Show loading spinner
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Show error
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading schedule.'));
                  }

                  // Handle no data
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                          child: Text("No medication scheduled for today.")),
                    );
                  }

                  // 1. Convert Firestore docs to 'Medication' objects
                  final medications = snapshot.data!.docs
                      .map((doc) => Medication.fromFirestore(doc))
                      .toList();

                  // 2. Flatten the schedule
                  final List<_TodayDose> todayDoses = [];
                  for (final med in medications) {
                    // TODO: Add logic for 'frequency'
                    if (med.frequency == 'Daily') {
                      for (final time in med.times) {
                        todayDoses.add(_TodayDose(
                          time: time,
                          name: med.name,
                          dosage: med.dosage,
                        ));
                      }
                    }
                  }

                  // 3. Sort the flattened list by time
                  todayDoses.sort((a, b) => a.time.compareTo(b.time));


                  // If the processed list is empty (e.g., no 'Daily' meds)
                  if (todayDoses.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                          child: Text("No medication scheduled for today.")),
                    );
                  }

                  // Build the list view from the processed 'todayDoses'
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