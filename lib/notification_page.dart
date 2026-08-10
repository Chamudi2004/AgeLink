// lib/notification_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';

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

    String state = (data['reminder_state'] ?? 'Missed').toString();
    String medName = (data['medicine_name'] ?? 'Unknown Medication').toString();
    String confirmedAt = (data['confirmed_at'] ?? 'N/A').toString();

    bool taken = (state == 'Green' || state == 'Orange' || state == 'Red');

    return DoseNotification(
      docId: snapshot.key ?? '',
      medicationName: medName,
      time: confirmedAt,
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
      _alertsRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app"
      ).ref('reminders/$userId/confirmation');
    }
  }

  // Improved date formatting helper
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final doseDay = DateTime(date.year, date.month, date.day);

    if (doseDay.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (doseDay.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  // Premium Date Header
  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.grey.shade300],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Constants.darkGrey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade300, Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Premium Empty State
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
                child: const Icon(Icons.notifications_off_rounded, size: 64, color: Color(0xFF1E88E5)),
              ),
              const SizedBox(height: 24),
              Text(
                'No Alerts Yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Constants.darkGrey
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your medication history and alerts will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Constants.mediumGrey, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const GradientScaffold(
          body: Center(
              child: Text("Please log in to view alerts.", style: TextStyle(fontSize: 18))
          )
      );
    }

    if (_alertsRef == null) {
      return const GradientScaffold(
          body: Center(
              child: Text("Error: Alerts collection path is invalid.", style: TextStyle(fontSize: 18))
          )
      );
    }

    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF0D47A1)),
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
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
            // Sort by date (Newest first)
            alerts.sort((a, b) => b.date.compareTo(a.date));
          }

          if (alerts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final notification = alerts[index];
              final DateTime currentDoseDate = DateTime(notification.date.year, notification.date.month, notification.date.day);

              // Check if this item should display a date header
              bool showDateHeader = true;
              if (index > 0) {
                final previousNotification = alerts[index - 1];
                final DateTime previousDoseDate = DateTime(previousNotification.date.year, previousNotification.date.month, previousNotification.date.day);

                if (currentDoseDate.isAtSameMomentAs(previousDoseDate)) {
                  showDateHeader = false;
                }
              }

              final Color statusColor = notification.isTaken ? const Color(0xFF4CAF50) : Colors.redAccent;
              final Color bgColor = notification.isTaken ? const Color(0xFF4CAF50).withOpacity(0.08) : Colors.redAccent.withOpacity(0.08);
              final IconData statusIcon = notification.isTaken ? Icons.check_circle_rounded : Icons.cancel_rounded;
              final String statusText = notification.isTaken ? 'Taken (${notification.reminderState})' : 'Missed';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDateHeader) _buildDateHeader(notification.date),

                  // Notification Card
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                      border: Border.all(color: Colors.grey.shade100, width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Badge
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            statusIcon,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.medicationName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Constants.darkGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Time Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: Constants.mediumGrey),
                              const SizedBox(width: 4),
                              Text(
                                notification.time,
                                style: TextStyle(
                                  color: Constants.darkGrey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}