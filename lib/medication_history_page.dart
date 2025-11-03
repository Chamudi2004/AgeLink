import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';
import 'package:intl/intl.dart'; // We need this to format dates

class MedicationHistoryPage extends StatefulWidget {
  const MedicationHistoryPage({super.key});

  @override
  State<MedicationHistoryPage> createState() => _MedicationHistoryPageState();
}

class _MedicationHistoryPageState extends State<MedicationHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _appId = const String.fromEnvironment('app_id', defaultValue: 'default-app-id');
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late final Stream<QuerySnapshot> _historyStream;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      // --- This is the new collection path ---
      final String schedulesCollectionPath =
          'artifacts/$_appId/users/${_currentUser!.uid}/medicationSchedules';

      // Query for all schedules that are NOT active, ordered by newest first
      _historyStream = _firestore
          .collection(schedulesCollectionPath)
      // --- THIS IS THE CORRECTED LINE ---
          .where('isActive', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      _historyStream = Stream.empty();
    }
  }

  // Helper function to format the Timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Date';
    // Using intl package for a clean date format
    return DateFormat('MMMM d, yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Schedule History',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Constants.mediumGrey),
                  const SizedBox(height: 16),
                  Text(
                    'No schedule history found.',
                    style: TextStyle(fontSize: 18, color: Constants.mediumGrey),
                  ),
                ],
              ),
            );
          }

          // We have history, build the list
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final scheduleName = data['scheduleName'] ?? 'Unnamed Schedule';
              final createdAt = data['createdAt'] as Timestamp?;
              final medications = List<Map<String, dynamic>>.from(data['medications'] ?? []);

              // Build a summary of the pills
              final pillNames = medications.map((m) => m['name'] ?? 'N/A').join(', ');

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    scheduleName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Constants.darkblue,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${_formatTimestamp(createdAt)}',
                        style: TextStyle(color: Constants.mediumGrey, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Medications: $pillNames',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Constants.darkGrey),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Could navigate to a "History Detail" page
                    // to see the full list of pills from this schedule.
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}