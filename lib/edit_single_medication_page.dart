// lib/edit_single_medication_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';

// --- (Gradients are unchanged) ---
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const kRedGradient = LinearGradient(
  colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

class EditSingleMedicationPage extends StatefulWidget {
  // --- scheduleId is now the RTDB *key* ---
  final String scheduleId; // e.g., "Insulin_1030"
  final Map<String, dynamic> medicationData;

  const EditSingleMedicationPage({
    super.key,
    required this.scheduleId,
    required this.medicationData,
  });

  @override
  State<EditSingleMedicationPage> createState() => _EditSingleMedicationPageState();
}

class _EditSingleMedicationPageState extends State<EditSingleMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  List<TimeOfDay> _times = [];
  String _frequency = 'Daily'; // This is no longer in the DB, but we leave it for the UI
  late String _originalKey;
  bool _isLoading = false;

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // --- Point to RTDB ---
  late final DatabaseReference _medsRef;

  @override
  void initState() {
    super.initState();

    if (_currentUser != null) {
      _medsRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app"
      ).ref('reminders/${_currentUser!.uid}/schedule/med_times');
    }

    _originalKey = widget.scheduleId;
    _nameController.text = widget.medicationData['name'] ?? 'N/A';
    _dosageController.text = widget.medicationData['dosage'] ?? '';
    _frequency = widget.medicationData['frequency'] ?? 'Daily';

    // The device structure saves 'time' as a single string
    String timeStr = widget.medicationData['time'] ?? "00:00";
    try {
      final parts = timeStr.split(':');
      _times = [TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]))];
    } catch (e) {
      _times = [TimeOfDay.now()];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    double verticalPadding = 16.0,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
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

  // --- Time Management ---
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _times = [picked]; // Replace the time, as there is only one
      });
    }
  }

  void _removeTime(TimeOfDay time) {
    if (_times.length > 1) {
      setState(() {
        _times.remove(time);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must have at least one time.')),
      );
    }
  }

  // --- Update logic for RTDB ---
  Future<void> _updateMedication() async {
    if (!_formKey.currentState!.validate() || _times.isEmpty) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final newTimeStr = '${_times[0].hour.toString().padLeft(2, '0')}:${_times[0].minute.toString().padLeft(2, '0')}';
      final newKey = "${_nameController.text}_${newTimeStr.replaceAll(":", "")}";

      final newMedData = {
        'name': _nameController.text,
        'dosage': _dosageController.text,
        'time': newTimeStr,
        'current_status': true, // Reset status
      };

      Map<String, dynamic> updates = {};

      if (newKey != _originalKey) {
        updates[_originalKey] = null; // This deletes the old key
      }
      updates[newKey] = newMedData;

      await _medsRef.update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication updated!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // --- Delete logic for RTDB ---
  Future<void> _deleteMedication() async {
    setState(() { _isLoading = true; });

    try {
      // To delete in RTDB, we set the value to null
      await _medsRef.child(_originalKey).set(null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication deleted.')),
        );
        Navigator.pop(context); // Go back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Medication?'),
          content: Text('Are you sure you want to delete "${_nameController.text}"?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMedication();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Medication',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: 'Dosage'),
              ),
              const SizedBox(height: 24),
              const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Daily', 'Weekly', 'Custom'].map((String value) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(value),
                        selected: _frequency == value,
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _frequency = value;
                            });
                          }
                        },
                        selectedColor: Constants.darkblue,
                        backgroundColor: Constants.lightBlue.withOpacity(0.5),
                        labelStyle: TextStyle(
                          color: _frequency == value ? Colors.white : Constants.darkGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Time(s)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.darkGrey)),
                  TextButton(
                    onPressed: _selectTime,
                    child: const Text('Add Time'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8.0,
                children: _times.map((time) {
                  return Chip(
                    label: Text(time.format(context)),
                    onDeleted: () => _removeTime(time),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildGradientButton(
                onPressed: _updateMedication,
                text: 'Save Changes',
                icon: Icons.save,
                gradient: kPrimaryGradient,
              ),
              const SizedBox(height: 16),
              _buildGradientButton(
                onPressed: _showDeleteConfirmation,
                text: 'Delete Medication',
                icon: Icons.delete_forever,
                gradient: kRedGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }
}