// lib/edit_single_medication_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';
import 'custom_snackbar.dart';

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
    double verticalPadding = 18.0, // Increased for premium feel
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0), // Matched UI
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
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

  // --- Time Management ---
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _times.isNotEmpty ? _times.first : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
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
        const SnackBar(content: Text('You must have at least one scheduled time.')),
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
        CustomSnackBar.show(
            context: context,
            message: 'Medication updated successfully!'
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to update: $e',
          isError: true,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              const Text('Delete Schedule?'),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete "${_nameController.text}" from your schedule?',
            style: TextStyle(color: Constants.darkGrey, fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Constants.mediumGrey,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  // Helper widget to style input fields
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
        leading: BackButton(color: Constants.darkblue),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Medication Details Card
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Medication Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
              ),
              _buildInputField(
                controller: _nameController,
                label: 'Medicine Name',
                icon: Icons.medication_rounded,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _dosageController,
                label: 'Dosage (e.g., 2 Pills, 10ml)',
                icon: Icons.scale_rounded,
              ),
              const SizedBox(height: 32),

              // Frequency Section
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Frequency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['Daily', 'Weekly', 'Custom'].map((String value) {
                    final isSelected = _frequency == value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ChoiceChip(
                        label: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(value),
                        ),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() { _frequency = value; });
                          }
                        },
                        selectedColor: const Color(0xFF1E88E5),
                        backgroundColor: Colors.white,
                        shadowColor: Colors.black.withOpacity(0.1),
                        elevation: isSelected ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF1E88E5) : Colors.transparent,
                            width: 2,
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
              const SizedBox(height: 32),

              // Time Section
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Scheduled Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _selectTime,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'Edit Time',
                            style: TextStyle(color: const Color(0xFF1E88E5), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: _times.map((time) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.3), width: 1.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, color: Color(0xFF1E88E5), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          time.format(context),
                          style: const TextStyle(
                            color: Color(0xFF1E88E5),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _removeTime(time),
                          child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),

              // Action Buttons
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  _buildGradientButton(
                    onPressed: _updateMedication,
                    text: 'Save Changes',
                    icon: Icons.save_rounded,
                    gradient: kPrimaryGradient,
                  ),
                  const SizedBox(height: 16),
                  _buildGradientButton(
                    onPressed: _showDeleteConfirmation,
                    text: 'Delete Medication',
                    icon: Icons.delete_outline_rounded,
                    gradient: kRedGradient,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}