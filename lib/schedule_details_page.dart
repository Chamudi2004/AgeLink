// lib/schedule_details_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';

class ScheduleDetailsPage extends StatelessWidget {
  final String scheduleName;
  final Timestamp? createdAt;
  final bool isActive;
  final List<Map<String, dynamic>> medications;

  const ScheduleDetailsPage({
    super.key,
    required this.scheduleName,
    required this.createdAt,
    required this.isActive,
    required this.medications,
  });

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Date';
    return DateFormat('MMMM d, yyyy • h:mm a').format(timestamp.toDate());
  }

  String _formatTime12h(String time24h) {
    try {
      final parts = time24h.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      // Use an arbitrary date just to utilize the formatting
      final dt = DateTime(2025, 1, 1, hour, minute);
      // Constructing time manually to avoid needing BuildContext
      final String ampm = hour >= 12 ? 'PM' : 'AM';
      final int hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final String minStr = minute.toString().padLeft(2, '0');
      return '$hour12:$minStr $ampm';
    } catch (e) {
      return time24h;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort medications by time
    final sortedMeds = List<Map<String, dynamic>>.from(medications);
    sortedMeds.sort((a, b) {
      String timeA = a['time'] ?? '00:00';
      String timeB = b['time'] ?? '00:00';
      return timeA.compareTo(timeB);
    });

    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Schedule Details',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Constants.darkblue),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                      : [Constants.darkblue.withOpacity(0.7), Constants.darkblue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? const Color(0xFF4CAF50) : Constants.darkblue).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                          isActive ? Icons.verified_rounded : Icons.history_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 32
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active Schedule' : 'Past Schedule',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    scheduleName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created on ${_formatTimestamp(createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Meds Header
            Row(
              children: [
                Icon(Icons.medication_rounded, color: Constants.darkGrey, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Medications (${sortedMeds.length})',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Constants.darkGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Meds List
            if (sortedMeds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'No medications were added to this schedule.',
                  style: TextStyle(color: Constants.mediumGrey, fontStyle: FontStyle.italic),
                ),
              )
            else
              ...sortedMeds.map((med) {
                final name = med['name'] ?? 'Unknown';
                final dosage = med['dosage'] ?? 'N/A';
                final time = med['time'] ?? '00:00';

                return Container(
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
                  ),
                  child: Row(
                    children: [
                      // Time Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatTime12h(time),
                          style: const TextStyle(
                            color: Color(0xFF1E88E5),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Med Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Constants.darkGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dosage: $dosage',
                              style: TextStyle(
                                color: Constants.mediumGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}