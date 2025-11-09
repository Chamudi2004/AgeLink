// lib/add_full_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';

// --- (Gradient constants are correct) ---
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

  // --- 1. Point to the RTDB ---
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
  // --- END OF FIX ---


  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    double verticalPadding = 16.0,
  }) {
    final bool isEnabled = onPressed != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            alignment: Alignment.center,
            child: (icon != null)
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            )
                : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
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

  // --- 2. Save logic is rewritten for RTDB ---
  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() { _isLoading = true; });

    try {
      // This is the new RTDB data structure
      final Map<String, dynamic> rtdbScheduleObject = {};

      for (final entry in _medicationEntries) {
        if (entry.name.text.isNotEmpty && entry.times.isNotEmpty) {

          for (var time in entry.times) {
            String timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
            // Create the key your device expects (e.g., "Insulin_1030")
            String key = "${entry.name.text}_${timeStr.replaceAll(":", "")}";

            rtdbScheduleObject[key] = {
              'name': entry.name.text,
              'dosage': entry.dosage.text,
              'time': timeStr,
            };
          }
        }
      }

      if (rtdbScheduleObject.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one valid medication.')),
        );
        setState(() { _isLoading = false; });
        return;
      }

      // 1. Write to the 'med_times' path
      await _remindersRef.child('schedule/med_times').set(rtdbScheduleObject);

      // 2. Update the 'current_status'
      await _remindersRef.child('schedule/current_status').set("IDLE"); // Set to idle

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New schedule saved!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save schedule: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
  // --- END OF FIX ---

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Create New Schedule',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _scheduleNameController,
                      decoration: const InputDecoration(
                        labelText: 'Schedule Name (e.g., "Daily Pills")',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name for the schedule';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Medications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _medicationEntries.length,
                      itemBuilder: (context, index) {
                        return _buildMedicationFormRow(_medicationEntries[index], index);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _addMedicationRow,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add Another Medication'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildGradientButton(
                onPressed: _saveSchedule,
                text: 'Save Schedule',
                icon: Icons.save,
                gradient: kPrimaryGradient,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationFormRow(_MedicationEntry entry, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.name,
                    decoration: const InputDecoration(labelText: 'Medicine Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: entry.dosage,
                    decoration: const InputDecoration(labelText: 'Dosage'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Daily', 'Weekly', 'Custom'].map((String value) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(value),
                      selected: entry.frequency == value,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _medicationEntries[index].frequency = value;
                          });
                        }
                      },
                      selectedColor: Constants.darkblue,
                      backgroundColor: Constants.lightBlue.withOpacity(0.5),
                      labelStyle: TextStyle(
                        color: entry.frequency == value ? Colors.white : Constants.darkGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Times:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _selectTime(index),
                  child: const Text('Add Time'),
                ),
              ],
            ),
            Wrap(
              spacing: 8.0,
              children: entry.times.map((time) {
                return Chip(
                  label: Text(time.format(context)),
                  onDeleted: () => _removeTime(index, time),
                );
              }).toList(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _medicationEntries.length > 1
                    ? () => _removeMedicationRow(index)
                    : null,
                child: Text(
                  'Remove',
                  style: TextStyle(
                    color: _medicationEntries.length > 1
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}