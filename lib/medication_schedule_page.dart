// lib/medication_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'add_full_schedule_page.dart';
import 'medication_history_page.dart';
import 'edit_single_medication_page.dart';

// ... (Gradients are unchanged) ...
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const kOrangeGradient = LinearGradient(
  colors: [Color(0xFFFFA726), Color(0xFFF57C00)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

class MedicationSchedulePage extends StatefulWidget {
  const MedicationSchedulePage({super.key});

  @override
  State<MedicationSchedulePage> createState() => _MedicationSchedulePageState();
}

class _MedicationSchedulePageState extends State<MedicationSchedulePage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // --- 1. Point to RTDB ---
  late final DatabaseReference _medsRef;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _medsRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app"
      ).ref('reminders/${_currentUser!.uid}/schedule/med_times');
    }
  }
  // --- END OF FIX ---

  void _navigateToAddSchedule() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddFullSchedulePage(),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MedicationHistoryPage(),
      ),
    );
  }

  void _navigateToEditSingleMed(Map<String, dynamic> medication, String scheduleId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditSingleMedicationPage(
          scheduleId: scheduleId, // This is the RTDB key (e.g., "Insulin_1030")
          medicationData: medication,
        ),
      ),
    );
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

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    double verticalPadding = 18.0, // Slightly taller for a premium feel
    FontWeight fontWeight = FontWeight.bold,
    double fontSize = 16,
  }) {
    final bool isEnabled = onPressed != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0), // Matched Home Screen radius
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          elevation: 5,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isEnabled
                ? gradient
                : LinearGradient(
              colors: [Constants.mediumGrey, Constants.mediumGrey.withOpacity(0.7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
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
                Text(
                  text,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: fontWeight,
                      fontSize: fontSize,
                      letterSpacing: 0.5),
                ),
              ],
            )
                : Text(
              text,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: fontWeight,
                  fontSize: fontSize,
                  letterSpacing: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text('Please log in to see your schedule.'));
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        // Title Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Icon(Icons.edit_calendar_rounded, color: Constants.darkGrey, size: 24),
              const SizedBox(width: 10),
              Text(
                'Manage Schedule',
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

        Expanded(
          // --- 2. Stream from RTDB ---
          child: StreamBuilder<DatabaseEvent>(
            stream: _medsRef.onValue, // Listen to the med_times path
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error loading data: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // --- 3. Parse RTDB data ---
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return _buildEmptyState();
              }

              // Data is a Map
              final medTimesMap = snapshot.data!.snapshot.value as Map;
              final medicationsList = medTimesMap.entries.map((entry) {
                return {
                  'key': entry.key, // This is the ID (e.g., "Insulin_1030")
                  'data': Map<String, dynamic>.from(entry.value as Map),
                };
              }).toList();
              // --- END OF FIX ---

              // Sort medications by time so they appear chronologically
              medicationsList.sort((a, b) {
                String timeA = a['data']['time'] ?? '00:00';
                String timeB = b['data']['time'] ?? '00:00';
                return timeA.compareTo(timeB);
              });

              if (medicationsList.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: medicationsList.length,
                itemBuilder: (context, index) {
                  final medEntry = medicationsList[index];
                  final String medKey = medEntry['key'];
                  final Map<String, dynamic> med = medEntry['data'];

                  final medName = med['name'] ?? 'No Name';
                  final medDosage = med['dosage'] ?? 'N/A';
                  final medTime = med['time'] ?? '00:00'; // Only one time

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Time Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatTime12h(medTime),
                            style: const TextStyle(
                              color: Color(0xFF1E88E5),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Medication Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Constants.darkGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.medication_rounded, size: 14, color: Constants.mediumGrey),
                                  const SizedBox(width: 4),
                                  Text(
                                    medDosage,
                                    style: TextStyle(
                                      color: Constants.mediumGrey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Edit Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () {
                              _navigateToEditSingleMed(med, medKey);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                color: Constants.darkGrey,
                                size: 20,
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
        ),

        // Bottom Action Buttons
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: _buildGradientButton(
                  onPressed: _navigateToHistory,
                  text: 'History',
                  icon: Icons.history_rounded,
                  gradient: kOrangeGradient,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5, // Make the Add New button slightly larger
                child: _buildGradientButton(
                  onPressed: _navigateToAddSchedule,
                  text: 'Add New',
                  icon: Icons.add_rounded,
                  gradient: kPrimaryGradient,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget for a beautiful empty state
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
                child: const Icon(Icons.calendar_month_rounded, size: 64, color: Color(0xFF1E88E5)),
              ),
              const SizedBox(height: 24),
              Text(
                'No Schedule Yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Constants.darkGrey
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Add New" below to create your first medication reminder.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Constants.mediumGrey, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}