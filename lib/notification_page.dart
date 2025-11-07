// lib/notification_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- 1. ADD THIS
import 'package:firebase_database/firebase_database.dart'; // <-- 1. ADD THIS
import 'package:firebase_auth/firebase_auth.dart';

class DoseNotification {
  final String docId;
  final String medicationName;
  final String time;
  final DateTime date;
  final bool isTaken;
  final String reminderState;

  DoseNotification({
    required this.docId,
    required this.medicationName,
    required this.time,
    required this.date,
    required this.isTaken,
    required this.reminderState,
  });

  factory DoseNotification.fromRTDB(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    DateTime doseDate = DateTime.now();
    if (data['date'] != null && data['date'] is int) {
      doseDate = DateTime.fromMillisecondsSinceEpoch(data['date']);
    } else if (data['confirmed_at_timestamp'] != null && data['confirmed_at_timestamp'] is int) {
      doseDate = DateTime.fromMillisecondsSinceEpoch(data['confirmed_at_timestamp']);
    }

    String state = data['reminder_state'] ?? 'Missed';
    bool taken = (state == 'Green' || state == 'Orange' || state == 'Red');

    return DoseNotification(
      docId: snapshot.key ?? '',
      medicationName: data['medicine_name'] ?? 'Unknown Medication',
      time: data['confirmed_at'] ?? 'N/A',
      date: doseDate,
      isTaken: taken,
      reminderState: state,
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
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  DatabaseReference? _alertsRef;

  @override
  void initState() {
    super.initState();

    if (userId != null) {
      // --- 2. THIS IS THE FIX ---
      _alertsRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app"
      ).ref('reminders/$userId/confirmation');
      // --- END OF FIX ---
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
    if (_alertsRef == null) {
      return const Center(child: Text("Error: Alerts collection path is invalid.", style: TextStyle(fontSize: 18)));
    }

    return StreamBuilder<DatabaseEvent>(
      stream: _alertsRef!.orderByChild('date').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading alerts: ${snapshot.error}'));
        }

        final List<DoseNotification> alerts = [];
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          for (final child in snapshot.data!.snapshot.children) {
            try {
              alerts.add(DoseNotification.fromRTDB(child));
            } catch (e) {
              print('Error parsing notification: $e');
            }
          }
          alerts.sort((a, b) => b.date.compareTo(a.date));
        }

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

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final notification = alerts[index];

            final statusColor = notification.isTaken ? Colors.green.shade600 : Colors.red.shade600;
            final statusIcon = notification.isTaken ? Icons.check_circle_outline : Icons.cancel_outlined;
            final statusText = notification.isTaken ? 'Taken (${notification.reminderState})' : 'Missed';

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