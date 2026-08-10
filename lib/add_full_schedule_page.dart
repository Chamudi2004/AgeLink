// lib/add_full_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';
import 'custom_snackbar.dart'; // <-- Using your new premium notification helper

// --- (Gradient constants) ---
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const kGreenGradient = LinearGradient(
  colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

class _MedicationEntry {
  final TextEditingController name;
  final TextEditingController dosage;
  final List<TimeOfDay> times;
  String frequency;

  _MedicationEntry()
      : name = TextEditingController(),
        dosage = TextEditingController(),
        times = [],
        frequency = 'Daily';
}

class AddFullSchedulePage extends StatefulWidget {
  const AddFullSchedulePage({super.key});

  @override
  State<AddFullSchedulePage> createState() => _AddFullSchedulePageState();
}

class _AddFullSchedulePageState extends State<AddFullSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final _scheduleNameController = TextEditingController();
  final List<_MedicationEntry> _medicationEntries = [_MedicationEntry()];
  bool _isLoading = false;

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late final DatabaseReference _remindersRef;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _remindersRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app"
      ).ref('reminders/${_currentUser!.uid}');
    }
  }

  // --- Premium Button Helper ---
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    double verticalPadding = 18.0, // Taller for premium feel
  }) {
    final bool isEnabled = onPressed != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          elevation: 5,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isEnabled
                ? gradient
                : LinearGradient(
              colors: [Constants.mediumGrey, Constants.mediumGrey.withOpacity(0.7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            alignment: Alignment.center,
            child: (icon != null)
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
              ],
            )
                : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }

  // --- Premium Input Field Helper ---
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: TextStyle(color: Constants.darkGrey, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Constants.mediumGrey),
          prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  void _addMedicationRow() {
    setState(() {
      _medicationEntries.add(_MedicationEntry());
    });
  }

  void _removeMedicationRow(int index) {
    if (_medicationEntries.length > 1) {
      setState(() {
        _medicationEntries.removeAt(index);
      });
    }
  }

  Future<void> _selectTime(int entryIndex) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _medicationEntries[entryIndex].times.add(picked);
        _medicationEntries[entryIndex].times.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      });
    }
  }

  void _removeTime(int entryIndex, TimeOfDay time) {
    setState(() {
      _medicationEntries[entryIndex].times.remove(time);
    });
  }

  // --- MODIFIED _saveSchedule function for RTDB & Firestore ---
  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() { _isLoading = true; });

    try {
      final Map<String, dynamic> rtdbScheduleObject = {};
      final List<Map<String, dynamic>> firestoreMedicationsList = [];

      for (final entry in _medicationEntries) {
        if (entry.name.text.isNotEmpty && entry.times.isNotEmpty) {

          final List<String> timesList = [];

          for (var time in entry.times) {
            String timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

            // CRITICAL: Generate a safe key by replacing spaces
            final String safeName = entry.name.text.replaceAll(' ', '_');
            String key = "${safeName}_${timeStr.replaceAll(":", "")}";

            // 1. Prepare data for RTDB
            rtdbScheduleObject[key] = {
              'name': entry.name.text,
              'dosage': entry.dosage.text,
              'time': timeStr,
            };

            timesList.add(timeStr);
          }

          // 2. Prepare data for Firestore
          firestoreMedicationsList.add({
            'name': entry.name.text,
            'dosage': entry.dosage.text,
            'frequency': entry.frequency,
            'times': timesList,
          });
        }
      }

      if (rtdbScheduleObject.isEmpty) {
        CustomSnackBar.show(
            context: context,
            message: 'Please add at least one valid medication with a time.',
            isError: true
        );
        setState(() { _isLoading = false; });
        return;
      }

      // --- FIRESTORE HISTORY UPDATE ---
      final firestoreRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('medicationSchedules');

      // 1. Deactivate all previously active schedules (for history logic)
      final existingSchedules = await firestoreRef.where('isActive', isEqualTo: true).get();
      for (final doc in existingSchedules.docs) {
        await doc.reference.update({'isActive': false});
      }

      // 2. Add the new schedule as the active one in Firestore
      final firestoreScheduleData = {
        'scheduleName': _scheduleNameController.text,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'medications': firestoreMedicationsList,
      };

      await firestoreRef.add(firestoreScheduleData);

      // --- RTDB ACTIVE SCHEDULE UPDATE ---
      // 3. Overwrite the current active schedule in RTDB
      await _remindersRef.child('schedule/med_times').set(rtdbScheduleObject);

      // 4. Update the device status in RTDB
      await _remindersRef.child('schedule/current_status').set("IDLE");

      if (mounted) {
        CustomSnackBar.show(
            context: context,
            message: 'New schedule saved and activated!'
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
            context: context,
            message: 'Failed to save schedule: $e',
            isError: true
        );
      }
      print("Schedule Save Error: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Create Schedule',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Constants.darkblue),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                          'Schedule Overview',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))
                      ),
                    ),
                    _buildInputField(
                      controller: _scheduleNameController,
                      label: 'Schedule Name (e.g., "Daily Pills")',
                      icon: Icons.drive_file_rename_outline_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name for the schedule';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Icon(Icons.medication_rounded, color: Constants.darkGrey, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Medications',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Constants.darkGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _medicationEntries.length,
                      itemBuilder: (context, index) {
                        return _buildMedicationFormRow(_medicationEntries[index], index);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Add Another Medication Button
                    Center(
                      child: TextButton.icon(
                        onPressed: _addMedicationRow,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                        label: const Text(
                          'Add Another Medication',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1E88E5),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: const Color(0xFF1E88E5).withOpacity(0.3), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Save Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildGradientButton(
                onPressed: _saveSchedule,
                text: 'Save & Activate Schedule',
                icon: Icons.save_rounded,
                gradient: kGreenGradient, // Using green to indicate activation
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationFormRow(_MedicationEntry entry, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medication #${index + 1}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Constants.mediumGrey
                  ),
                ),
                if (_medicationEntries.length > 1)
                  InkWell(
                    onTap: () => _removeMedicationRow(index),
                    borderRadius: BorderRadius.circular(50),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.shade200, size: 22),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),

            // Name Field
            TextFormField(
              controller: entry.name,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              style: TextStyle(color: Constants.darkGrey, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Medicine Name',
                labelStyle: TextStyle(color: Constants.mediumGrey),
                prefixIcon: const Icon(Icons.vaccines_rounded, color: Color(0xFF1E88E5)),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dosage Field
            TextFormField(
              controller: entry.dosage,
              style: TextStyle(color: Constants.darkGrey, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Dosage (e.g., 1 Pill)',
                labelStyle: TextStyle(color: Constants.mediumGrey),
                prefixIcon: const Icon(Icons.scale_rounded, color: Color(0xFF1E88E5)),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Frequency
            const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['Daily', 'Weekly', 'Custom'].map((String value) {
                  final isSelected = entry.frequency == value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ChoiceChip(
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(value),
                      ),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _medicationEntries[index].frequency = value;
                          });
                        }
                      },
                      selectedColor: const Color(0xFF1E88E5),
                      backgroundColor: Colors.white,
                      elevation: isSelected ? 3 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF1E88E5) : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Constants.darkGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Times Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reminder Times', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _selectTime(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.add_alarm_rounded, color: Color(0xFF1E88E5), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Add Time',
                            style: TextStyle(color: const Color(0xFF1E88E5), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (entry.times.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Text(
                  'Tap "Add Time" to schedule this medication.',
                  style: TextStyle(color: Constants.mediumGrey, fontStyle: FontStyle.italic, fontSize: 13),
                ),
              )
            else
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: entry.times.map((time) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.3), width: 1.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, color: Color(0xFF1E88E5), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          time.format(context),
                          style: const TextStyle(
                            color: Color(0xFF1E88E5),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _removeTime(index, time),
                          child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}