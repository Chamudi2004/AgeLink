// lib/medication_history_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';
import 'package:intl/intl.dart';

import 'schedule_details_page.dart'; // We will create this file next

class MedicationHistoryPage extends StatefulWidget {
  const MedicationHistoryPage({super.key});

  @override
  State<MedicationHistoryPage> createState() => _MedicationHistoryPageState();
}

class _MedicationHistoryPageState extends State<MedicationHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late final Stream<QuerySnapshot> _historyStream;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      final String schedulesCollectionPath =
          'users/${_currentUser!.uid}/medicationSchedules';

      _historyStream = _firestore
          .collection(schedulesCollectionPath)
          .orderBy('isActive', descending: true)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      _historyStream = const Stream.empty();
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Date';
    return DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate());
  }

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
                child: const Icon(Icons.history_rounded, size: 64, color: Color(0xFF1E88E5)),
              ),
              const SizedBox(height: 24),
              Text(
                'No History Found',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Constants.darkGrey
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your saved medication schedules will appear here.',
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
    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Schedule History',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Constants.darkblue),
        centerTitle: true,
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
                  'Error: ${snapshot.error}\n\nThis query may require a composite index. Check console.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final scheduleName = data['scheduleName'] ?? 'Unnamed Schedule';
              final createdAt = data['createdAt'] as Timestamp?;
              final medications = List<Map<String, dynamic>>.from(data['medications'] ?? []);
              final bool isActive = data['isActive'] ?? false;
              final pillCount = medications.length;

              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? const Color(0xFF4CAF50).withOpacity(0.5) : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScheduleDetailsPage(
                            scheduleName: scheduleName,
                            createdAt: createdAt,
                            isActive: isActive,
                            medications: medications,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Left Icon/Badge
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isActive ? Icons.verified_rounded : Icons.history_rounded,
                              color: isActive ? const Color(0xFF4CAF50) : Constants.mediumGrey,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Middle Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        scheduleName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Constants.darkGrey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isActive)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            color: Color(0xFF2E7D32),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(createdAt),
                                  style: TextStyle(
                                    color: Constants.mediumGrey,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.medication_liquid_rounded, size: 14, color: Constants.mediumGrey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$pillCount medication${pillCount == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        color: Constants.darkblue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Right Arrow
                          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
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