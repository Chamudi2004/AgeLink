import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';
import 'package:intl/intl.dart';

class MedicationHistoryPage extends StatefulWidget {
  const MedicationHistoryPage({super.key});

  @override
  State<MedicationHistoryPage> createState() => _MedicationHistoryPageState();
}

class _MedicationHistoryPageState extends State<MedicationHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // --- REMOVED _appId variable ---
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late final Stream<QuerySnapshot> _historyStream;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      // --- THIS IS THE CORRECT FIRESTORE PATH ---
      // It now matches your firestore.rules and add_full_schedule_page.dart
      final String schedulesCollectionPath =
          'users/${_currentUser!.uid}/medicationSchedules';
      // --- END OF FIX ---

      _historyStream = _firestore
          .collection(schedulesCollectionPath)
          .orderBy('isActive', descending: true)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      _historyStream = Stream.empty();
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Date';
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error: ${snapshot.error}\n\nThis query may require a composite index. Please copy the link from your debug console and open it in a browser to create the index.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Constants.darkblue),
                  const SizedBox(height: 16),
                  Text(
                    'No schedule history found.',
                    style: TextStyle(fontSize: 18, color: Constants.mediumGrey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final scheduleName = data['scheduleName'] ?? 'Unnamed Schedule';
              final createdAt = data['createdAt'] as Timestamp?;
              final medications = List<Map<String, dynamic>>.from(data['medications'] ?? []);
              final bool isActive = data['isActive'] ?? false;
              final pillNames = medications.map((m) => m['name'] ?? 'N/A').join(', ');

              // --- APPLY CONDITIONAL STYLING
              return Card(
                elevation: isActive ? 4 : 2,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isActive ? Constants.darkblue : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: isActive
                      ? Icon(Icons.check_circle, color: Constants.greenColor)
                      : null,
                  title: Text(
                    scheduleName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isActive ? Constants.darkblue : Colors.grey.shade700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        isActive ? 'Current Active Schedule' : 'Created: ${_formatTimestamp(createdAt)}',
                        style: TextStyle(
                          color: isActive ? Constants.greenColor : Constants.mediumGrey,
                          fontStyle: FontStyle.italic,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
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