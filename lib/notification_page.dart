import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get the current user ID

// --- 1. Updated Data Model for Firestore Integration ---
class DoseNotification {
  final String docId; // Document ID for reference
  final String medicationName;
  final String time; // Stored as a string (e.g., '8:00 AM')
  final DateTime date;
  final bool isTaken;

  DoseNotification({
    required this.docId,
    required this.medicationName,
    required this.time,
    required this.date,
    required this.isTaken,
  });

  // Factory constructor to create a DoseNotification from a Firestore document
  factory DoseNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Default to the current time if timestamp field is missing
    DateTime doseDate = (data['date'] is Timestamp)
        ? (data['date'] as Timestamp).toDate()
        : DateTime.now();

    return DoseNotification(
      docId: doc.id,
      medicationName: data['medicationName'] ?? 'Unknown Medication',
      time: data['time'] ?? 'N/A',
      date: doseDate,
      isTaken: data['isTaken'] ?? false,
    );
  }
}

// --- 2. Notification Page Widget (Stateful for Stream Management) ---
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Get mandatory global variables
  final String appId = const String.fromEnvironment('app_id', defaultValue: 'default-app-id');
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Reference to the Firestore collection
  CollectionReference? _alertsCollection;

  @override
  void initState() {
    super.initState();
    // Initialize collection reference only if user is logged in
    if (userId != null) {
      _alertsCollection = FirebaseFirestore.instance
          .collection('artifacts')
          .doc(appId)
          .collection('users')
          .doc(userId)
          .collection('medications');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: Text("Please log in to view alerts.", style: TextStyle(fontSize: 18)));
    }
    if (_alertsCollection == null) {
      return const Center(child: Text("Error: Alerts collection path is invalid.", style: TextStyle(fontSize: 18)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Alerts (Live)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      // --- 3. StreamBuilder replaces the static list ---
      body: StreamBuilder<QuerySnapshot>(
        // Query ordered by date descending to show most recent first
        stream: _alertsCollection!.orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading alerts: ${snapshot.error}'));
          }

          final alerts = snapshot.data!.docs.map((doc) => DoseNotification.fromFirestore(doc)).toList();

          if (alerts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No medication alerts recorded yet. All doses taken successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          // --- 4. Display the streamed list ---
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final notification = alerts[index];

              // Determine styling based on status
              final statusColor = notification.isTaken ? Colors.green.shade600 : Colors.red.shade600;
              final statusIcon = notification.isTaken ? Icons.check_circle_outline : Icons.cancel_outlined;
              final statusText = notification.isTaken ? 'Taken' : 'Missed';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 32,
                  ),
                  title: Text(
                    notification.medicationName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    '${statusText} at ${notification.time} on ${_formatDate(notification.date)}',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                  ),
                  trailing: Chip(
                    label: Text(
                      notification.time,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: statusColor.withOpacity(0.8),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
