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
    double verticalPadding = 16.0,
    FontWeight fontWeight = FontWeight.bold,
    double fontSize = 16,
  }) {
    // ... (This function is unchanged)
    final bool isEnabled = onPressed != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            alignment: Alignment.center,
            child: (icon != null)
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(color: Colors.white, fontWeight: fontWeight, fontSize: fontSize),
                ),
              ],
            )
                : Text(
              text,
              style: TextStyle(color: Colors.white, fontWeight: fontWeight, fontSize: fontSize),
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, size: 80, color: Constants.darkblue),
                      const SizedBox(height: 16),
                      Text(
                        'No active schedule found.\nTap "Add New" to create one!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Constants.mediumGrey),
                      ),
                    ],
                  ),
                );
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

              if (medicationsList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, size: 80, color: Constants.darkblue),
                      const SizedBox(height: 16),
                      Text(
                        'No active schedule found.\nTap "Add New" to create one!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Constants.mediumGrey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                itemCount: medicationsList.length,
                itemBuilder: (context, index) {
                  final medEntry = medicationsList[index];
                  final String medKey = medEntry['key'];
                  final Map<String, dynamic> med = medEntry['data'];

                  final medName = med['name'] ?? 'No Name';
                  final medDosage = med['dosage'] ?? 'N/A';
                  final medTime = med['time'] ?? '00:00'; // Only one time

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                          title: Text(
                            medName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Constants.darkblue,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Dosage: $medDosage', style: TextStyle(color: Constants.darkGrey)),
                              const SizedBox(height: 2),
                              Text(
                                'Time: ${_formatTime12h(medTime)}',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Constants.mediumGrey,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.edit_outlined, color: Constants.darkblue),
                            onPressed: () {
                              // Pass the original map data and the key
                              _navigateToEditSingleMed(med, medKey);
                            },
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

        // ... (Bottom buttons are unchanged) ...
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildGradientButton(
                  onPressed: _navigateToHistory,
                  text: 'History',
                  icon: Icons.history,
                  gradient: kOrangeGradient,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGradientButton(
                  onPressed: _navigateToAddSchedule,
                  text: 'Add New',
                  icon: Icons.add,
                  gradient: kPrimaryGradient,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}