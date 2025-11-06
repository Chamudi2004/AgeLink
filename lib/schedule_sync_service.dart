// lib/schedule_sync_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class ScheduleSyncService {

  /// This function is called *after* any change.
  /// It reads the user's *active* schedule from Firestore
  /// and syncs it to the Realtime Database.
  static Future<void> triggerSync() async {
    final _auth = FirebaseAuth.instance;
    final _firestore = FirebaseFirestore.instance;
    final _database = FirebaseDatabase.instance;
    final uid = _auth.currentUser?.uid;

    if (uid == null) return; // Not logged in

    try {
      // 1. Find the user's CURRENTLY ACTIVE schedule in Firestore
      final activeScheduleQuery = await _firestore
          .collection('artifacts')
          .doc(const String.fromEnvironment('app_id', defaultValue: 'default-app-id'))
          .collection('users')
          .doc(uid)
          .collection('medicationSchedules')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      List<Map<String, dynamic>> medicationsList = [];

      if (activeScheduleQuery.docs.isNotEmpty) {
        // If an active schedule exists, get its medication list
        final scheduleData = activeScheduleQuery.docs.first.data();
        medicationsList = List<Map<String, dynamic>>.from(scheduleData['medications'] ?? []);
      }

      // 2. Create the JSON object for RTDB
      final rtdbScheduleObject = <String, dynamic>{};
      for (var med in medicationsList) {
        final medName = med['name'] ?? 'Unknown';
        final medDosage = med['dosage'] ?? 'N/A';
        final medTimes = List<String>.from(med['times'] ?? []);

        for (var time in medTimes) {
          final key = "${medName}_${time.replaceAll(":", "")}";
          rtdbScheduleObject[key] = {
            "dosage": medDosage,
            "name": medName,
            "time": time,
          };
        }
      }

      // 3. Get the RTDB path
      final rtdbRef = _database.ref('reminders/$uid/schedule/med_times');

      // 4. Overwrite the "med_times" object with the new schedule
      // If the list is empty (no active schedule), this will correctly
      // send an empty object, clearing the device's schedule.
      await rtdbRef.set(rtdbScheduleObject);

      print('SUCCESS: Synced schedule to RTDB for user $uid');

    } catch (e) {
      print('ERROR: Failed to sync schedule to RTDB: $e');
    }
  }
}