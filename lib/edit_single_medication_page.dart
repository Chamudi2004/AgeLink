import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'gradient_scaffold.dart';

// --- (Gradient constants) ---
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
// ------------------------------

class EditSingleMedicationPage extends StatefulWidget {
  final String scheduleId;
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

  late String _originalName; // To find the pill in the array
  bool _isLoading = false;

  final String _appId = const String.fromEnvironment('app_id', defaultValue: 'default-app-id');
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late final DocumentReference _scheduleDocRef;

  @override
  void initState() {
    super.initState();

    // Set the path to the active schedule document
    _scheduleDocRef = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('medicationSchedules')
        .doc(widget.scheduleId);

    // Pre-fill the form with the medication data
    _originalName = widget.medicationData['name'] ?? 'N/A';
    _nameController.text = _originalName;
    _dosageController.text = widget.medicationData['dosage'] ?? '';
    _times = (widget.medicationData['times'] as List<dynamic>? ?? [])
        .map((timeStr) {
      try {
        final parts = (timeStr as String).split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        return TimeOfDay.now(); // Fallback
      }
    })
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  // --- (Reusable Gradient Button) ---
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    double verticalPadding = 16.0,
  }) {
    // ... (This function is correct, no changes needed)
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
        _times.add(picked);
        _times.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      });
    }
  }

  void _removeTime(TimeOfDay time) {
    setState(() {
      _times.remove(time);
    });
  }

  // --- (This is the new "Save" logic) ---
  Future<void> _updateMedication() async {
    if (!_formKey.currentState!.validate() || _times.isEmpty) {
      if (_times.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one time.')),
        );
      }
      return;
    }
    setState(() { _isLoading = true; });

    try {
      // Create the new medication map
      final newMedData = {
        'name': _nameController.text,
        'dosage': _dosageController.text,
        'times': _times.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList(),
      };

      // Get the current schedule document
      final doc = await _scheduleDocRef.get();
      if (!doc.exists) {
        throw Exception("Schedule document not found.");
      }

      // Get the full list of medications
      final allMeds = List<Map<String, dynamic>>.from(
          (doc.data() as Map<String, dynamic>)['medications'] ?? []);

      // Find the index of the pill we are editing
      final int medIndex = allMeds.indexWhere((m) => m['name'] == _originalName);

      if (medIndex == -1) {
        throw Exception("Could not find the medication to update.");
      }

      // Replace the old pill data with the new pill data
      allMeds[medIndex] = newMedData;

      // Update the entire 'medications' array in Firestore
      await _scheduleDocRef.update({'medications': allMeds});

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

              // --- Time(s) Input and Chips ---
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

              // --- "Save Changes" Button ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildGradientButton(
                onPressed: _updateMedication,
                text: 'Save Changes',
                icon: Icons.save,
                gradient: kPrimaryGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }
}