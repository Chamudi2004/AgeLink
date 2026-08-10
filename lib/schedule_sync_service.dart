// lib/schedule_sync_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleSyncService {
  /// This function reads the user's *active* schedule from Firestore
  /// and syncs it to the Realtime Database.
  static Future<void> triggerSync() async {
    final _auth = FirebaseAuth.instance;
    final _firestore = FirebaseFirestore.instance;

    final _database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app"
    );

    final uid = _auth.currentUser?.uid;

    if (uid == null) return; // Not logged in

    try {
      // 1. Find the user's CURRENTLY ACTIVE schedule in Firestore
      // --- CRITICAL FIX: Updated to match your correct Firestore path ---
      final activeScheduleQuery = await _firestore
          .collection('users')
          .doc(uid)
          .collection('medicationSchedules')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      // --- END OF FIX ---

      List<Map<String, dynamic>> medicationsList = [];

      if (activeScheduleQuery.docs.isNotEmpty) {
        // If an active schedule exists, get its medication list
        final scheduleData = activeScheduleQuery.docs.first.data();
        medicationsList =
        List<Map<String, dynamic>>.from(scheduleData['medications'] ?? []);
      }

      // 2. Create the JSON object for RTDB
      final rtdbScheduleObject = <String, dynamic>{};
      for (var med in medicationsList) {
        final medName = med['name'] ?? 'Unknown';
        final medDosage = med['dosage'] ?? 'N/A';
        final medTimes = List<String>.from(med['times'] ?? []);

        for (var time in medTimes) {
          // Creates a key like "Insulin_2219"
          final key = "${medName}_${time.replaceAll(":", "")}";
          rtdbScheduleObject[key] = {
            "dosage": medDosage,
            "name": medName,
            "time": time,
          };
        }
      }

      // 3. Get the RTDB path your device reads
      final rtdbRef = _database.ref('reminders/$uid/schedule/med_times');

      // 4. Overwrite the "med_times" object with the new schedule
      await rtdbRef.set(rtdbScheduleObject);

      print('SUCCESS: Synced schedule to RTDB for user $uid');
    } catch (e) {
      print('ERROR: Failed to sync schedule to RTDB: $e');
    }
  }
}