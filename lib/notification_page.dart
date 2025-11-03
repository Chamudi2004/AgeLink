import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class DoseNotification {
  final String docId;
  final String medicationName;
  final String time;
  final DateTime date;
  final bool isTaken;

  DoseNotification({
    required this.docId,
    required this.medicationName,
    required this.time,
    required this.date,
    required this.isTaken,
  });

  factory DoseNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

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

// Notification Page Widget
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {

  final String appId = const String.fromEnvironment('app_id', defaultValue: 'default-app-id');
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  CollectionReference? _alertsCollection;

  @override
  void initState() {
    super.initState();

    if (userId != null) {
      _alertsCollection = FirebaseFirestore.instance
          .collection('artifacts')
          .doc(appId)
          .collection('users')
          .doc(userId)
          .collection('doses');
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

    // --- (FIX: REMOVED THE Scaffold AND AppBar WIDGETS) ---
    // The GradientScaffold from home_page.dart will provide the background and app bar.

    return StreamBuilder<QuerySnapshot>(
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

        // The list will now be the main widget returned by this page
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final notification = alerts[index];

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
                  '$statusText at ${notification.time} on ${_formatDate(notification.date)}',
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
    );
  }
}