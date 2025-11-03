import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';

// --- Import your new pages ---
import 'add_full_schedule_page.dart';
import 'medication_history_page.dart';
import 'edit_single_medication_page.dart';

// --- (Constants for our Gradients) ---
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const kOrangeGradient = LinearGradient(
  colors: [Color(0xFFFFA726), Color(0xFFF57C00)], // Orange gradient
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
// ------------------------------------------

class MedicationSchedulePage extends StatefulWidget {
  const MedicationSchedulePage({super.key});

  @override
  State<MedicationSchedulePage> createState() => _MedicationSchedulePageState();
}

class _MedicationSchedulePageState extends State<MedicationSchedulePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _appId = const String.fromEnvironment('app_id', defaultValue: 'default-app-id');
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // --- This is the new collection path ---
  String get _schedulesCollectionPath {
    return 'artifacts/$_appId/users/${_currentUser!.uid}/medicationSchedules';
  }

  // --- This function now navigates to the new page ---
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

  // --- Navigation for the new Edit button ---
  void _navigateToEditSingleMed(Map<String, dynamic> medication, String scheduleId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditSingleMedicationPage(
          scheduleId: scheduleId,
          medicationData: medication,
        ),
      ),
    );
  }

  // --- (HELPER FUNCTION) ---
  String _formatTime12h(String time24h) {
    try {
      final parts = time24h.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2025, 1, 1, hour, minute);
      return TimeOfDay.fromDateTime(dt).format(context);
    } catch (e) {
      return time24h; // Return original string if formatting fails
    }
  }

  // --- (HELPER FUNCTION) ---
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    double verticalPadding = 16.0,
    FontWeight fontWeight = FontWeight.bold,
    double fontSize = 16,
  }) {
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
                : LinearGradient( // Disabled gradient
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

    // --- The build method is now a Column ---
    return Column(
      children: [
        // 1. The list, inside an Expanded to fill available space
        Expanded(
          // --- UPDATED STREAMBUILDER ---
          child: StreamBuilder<QuerySnapshot>(
            // Query for the ONE active schedule
            stream: _firestore
                .collection(_schedulesCollectionPath)
                .where('isActive', isEqualTo: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error loading data: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // --- UPDATED LOGIC ---
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                // This is the "Empty" state
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

              // We found the active schedule, now display its pills
              final activeScheduleDoc = snapshot.data!.docs.first;
              final scheduleId = activeScheduleDoc.id; // <-- Get the schedule ID
              final scheduleData = activeScheduleDoc.data() as Map<String, dynamic>;
              final scheduleName = scheduleData['scheduleName'] ?? 'Current Schedule';
              final medicationsList = List<Map<String, dynamic>>.from(scheduleData['medications'] ?? []);

              if (medicationsList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, size: 80, color: Constants.darkblue),
                      const SizedBox(height: 16),
                      Text(
                        'Your schedule is empty.\nTap "Add New" to create one!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Constants.mediumGrey),
                      ),
                    ],
                  ),
                );
              }

              // --- The list view for the medications ---
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), // Added padding for buttons
                itemCount: medicationsList.length + 1,
                itemBuilder: (context, index) {

                  // --- ADDED A HEADER ---
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        scheduleName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Constants.darkblue
                        ),
                      ),
                    );
                  }

                  // --- This is the medication item ---
                  final med = medicationsList[index - 1]; // -1 to account for header
                  final medName = med['name'] ?? 'No Name';
                  final medDosage = med['dosage'] ?? 'N/A';
                  final medTimes = List<String>.from(med['times'] ?? []);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                            // --- THIS IS THE FIX for the "Too many arguments" error ---
                            Text(
                              'Times: ${medTimes.map(_formatTime12h).join(', ')}',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Constants.mediumGrey,
                              ),
                            ),
                          ],
                        ),

                        // --- Added the Edit button ---
                        trailing: IconButton(
                          icon: Icon(Icons.edit_outlined, color: Constants.darkblue),
                          onPressed: () {
                            // Find the original medication map in the list
                            final originalMedData = medicationsList.firstWhere(
                                  (m) => m['name'] == medName,
                              orElse: () => med, // Fallback
                            );

                            _navigateToEditSingleMed(originalMedData, scheduleId);
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // --- UPDATED BUTTONS ---
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // "View History" Button
              Expanded(
                child: _buildGradientButton(
                  onPressed: _navigateToHistory,
                  text: 'History',
                  icon: Icons.history,
                  gradient: kOrangeGradient, // Use orange gradient
                ),
              ),
              const SizedBox(width: 12),
              // "Add New Schedule" Button
              Expanded(
                child: _buildGradientButton(
                  onPressed: _navigateToAddSchedule,
                  text: 'Add New',
                  icon: Icons.add,
                  gradient: kPrimaryGradient, // Use primary blue gradient
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}