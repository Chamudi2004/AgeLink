import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';

const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const kOrangeGradient = LinearGradient(
  colors: [Color(0xFFFFA726), Color(0xFFF57C00)], // Orange gradient
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const kGreenGradient = LinearGradient(
  colors: [Color(0xFF66BB6A), Color(0xFF388E3C)], // Green gradient
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const kRedGradient = LinearGradient(
  colors: [Color(0xFFEF5350), Color(0xFFD32F2F)], // Red gradient
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);


class Medication {
  final String id;
  final String name;
  final String dosage;
  final List<String> times;
  final String frequency; // Daily, Weekly, Custom

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.frequency,
  });

  factory Medication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medication(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      dosage: data['dosage'] ?? 'N/A',
      times: List<String>.from(data['times'] ?? []),
      frequency: data['frequency'] ?? 'Daily',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'dosage': dosage,
      'times': times,
      'frequency': frequency,
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// Medication List View (Main Schedule Screen)

class MedicationSchedulePage extends StatefulWidget {
  const MedicationSchedulePage({super.key});

  @override
  State<MedicationSchedulePage> createState() => _MedicationSchedulePageState();
}

class _MedicationSchedulePageState extends State<MedicationSchedulePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _appId = const String.fromEnvironment('app_id', defaultValue: 'default-app-id');
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Medication? _selectedMedication;

  String get _medicationCollectionPath {
    return 'artifacts/$_appId/users/${_currentUser!.uid}/medications';
  }

  // Navigation and Data Handling
  void _navigateToAddEdit({Medication? medication}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditMedicationPage(
          medication: medication,
          collectionPath: _medicationCollectionPath,
        ),
      ),
    );

    // If the form returns true, deselect any item
    if (result == true) {
      setState(() {
        _selectedMedication = null;
      });
    }
  }

  // Helper function to format 24h time to 12h time (e.g., "14:30" -> "2:30 PM")
  String _formatTimes(List<String> times) {
    if (times.isEmpty) return 'No times set';
    return times.map((time) {
      try {
        final parts = time.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final dt = DateTime(2025, 1, 1, hour, minute);
        final format = TimeOfDay.fromDateTime(dt).format(context);
        return format;
      } catch (e) {
        return time;
      }
    }).join(', ');
  }

  void _showStatusSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    double verticalPadding = 16.0,
    FontWeight fontWeight = FontWeight.bold,
    double fontSize = 16,
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
                : LinearGradient( // Disabled gradient
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
                Text(
                  text,
                  style: TextStyle(color: Colors.white, fontWeight: fontWeight, fontSize: fontSize),
                ),
              ],
            )
                : Text(
              text,
              style: TextStyle(color: Colors.white, fontWeight: fontWeight, fontSize: fontSize),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text('Please log in to see your schedule.'));
    }
    return Column(
      children: [
        // 1. The list, inside an Expanded to fill available space
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection(_medicationCollectionPath)
                .where('userId', isEqualTo: _currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error loading data: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final medications = snapshot.data!.docs.map((doc) => Medication.fromFirestore(doc)).toList();

              if (medications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, size: 80, color: Constants.darkblue),
                      const SizedBox(height: 16),
                      Text(
                        'No medications scheduled.\nTap "Add New" below to start!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Constants.mediumGrey),
                      ),
                    ],
                  ),
                );
              }

              // The list view for the medications
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 16), // Added padding
                itemCount: medications.length,
                itemBuilder: (context, index) {
                  final medication = medications[index];
                  final isSelected = _selectedMedication?.id == medication.id;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Constants.darkblue : Constants.lightBlue,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        title: Text(
                          medication.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Constants.darkblue,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Dosage: ${medication.dosage}', style: TextStyle(color: Constants.darkGrey)),
                            const SizedBox(height: 2),
                            Text(
                              'Times: ${_formatTimes(medication.times)}',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Constants.mediumGrey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Frequency: ${medication.frequency}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Constants.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Constants.darkblue)
                            : Icon(Icons.radio_button_unchecked, color: Constants.mediumGrey),
                        onTap: () {
                          setState(() {
                            _selectedMedication = isSelected ? null : medication;
                          });
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // 2. The "bottomSheet" content, now a Container at the bottom
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // EDIT Button
              Expanded(
                child: _buildGradientButton(
                  onPressed: _selectedMedication != null
                      ? () => _navigateToAddEdit(medication: _selectedMedication)
                      : null,
                  text: 'Edit',
                  icon: Icons.edit,
                  gradient: kOrangeGradient,
                ),
              ),
              const SizedBox(width: 12),
              // ADD NEW Button
              Expanded(
                child: _buildGradientButton(
                  onPressed: () => _navigateToAddEdit(),
                  text: 'Add New',
                  icon: Icons.add,
                  gradient: kPrimaryGradient,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 3. Add/Edit Medication Form

class AddEditMedicationPage extends StatefulWidget {
  final Medication? medication;
  final String collectionPath;

  const AddEditMedicationPage({super.key, this.medication, required this.collectionPath});

  @override
  State<AddEditMedicationPage> createState() => _AddEditMedicationPageState();
}

class _AddEditMedicationPageState extends State<AddEditMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();

  String _frequency = 'Daily';
  List<String> _times = [];

  bool get isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final m = widget.medication!;
      _nameController.text = m.name;
      _dosageController.text = m.dosage;
      _frequency = m.frequency;
      _times = List.from(m.times);
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
    FontWeight fontWeight = FontWeight.bold,
    double fontSize = 16,
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
                : LinearGradient( // Disabled gradient
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
                Text(
                  text,
                  style: TextStyle(color: Colors.white, fontWeight: fontWeight, fontSize: fontSize),
                ),
              ],
            )
                : Text(
              text,
              style: TextStyle(color: Colors.white, fontWeight: fontWeight, fontSize: fontSize),
            ),
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

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      final newTime = '$hour:$minute';

      if (!_times.contains(newTime)) {
        setState(() {
          _times.add(newTime);
          _times.sort();
        });
      }
    }
  }

  void _removeTime(String time) {
    setState(() {
      _times.remove(time);
    });
  }

  // Helper to format 24h time to 12h time (e.g., "14:30" -> "2:30 PM")
  String _formatTime12h(String time24h) {
    try {
      final parts = time24h.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2025, 1, 1, hour, minute);
      return TimeOfDay.fromDateTime(dt).format(context);
    } catch (e) {
      return time24h;
    }
  }

  // --- Form Submission ---

  void _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one time for the medication.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEditing ? 'Saving changes...' : 'Adding medication...')),
    );

    final medicationToSave = Medication(
      id: isEditing ? widget.medication!.id : '',
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      times: _times,
      frequency: _frequency,
    );

    try {
      if (isEditing) {
        // Update existing document
        await FirebaseFirestore.instance
            .collection(widget.collectionPath)
            .doc(medicationToSave.id)
            .update(medicationToSave.toFirestore());
      } else {
        // Add new document
        await FirebaseFirestore.instance
            .collection(widget.collectionPath)
            .add(medicationToSave.toFirestore());
      }

      // Success! Pop back to the list view
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Medication updated!' : 'Medication scheduled successfully!')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save medication: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Medication' : 'Add New Schedule',
          style: TextStyle(fontWeight: FontWeight.bold, color: Constants.darkblue),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Constants.darkblue),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Color(0xFFBCD8FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 1. Medicine Name ---
                _buildInputField(
                  controller: _nameController,
                  label: 'Medicine Name',
                  hint: 'e.g., Tylenol, Insulin',
                ),
                const SizedBox(height: 20),

                // --- 2. Dosage ---
                _buildInputField(
                  controller: _dosageController,
                  label: 'Dosage',
                  hint: 'e.g., 500mg (1 tablet)',
                ),
                const SizedBox(height: 20),

                // --- 3. Frequency Selector (Radio Buttons) ---
                Text('Frequency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.darkblue)),
                const SizedBox(height: 8),
                Row(
                  children: ['Daily', 'Weekly', 'Custom'].map((String value) {
                    return Expanded(
                      child: Padding(
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
                          selectedColor: Constants.gradiantBlue,
                          backgroundColor: Constants.white,
                          labelStyle: TextStyle(
                            color: _frequency == value ? Constants.darkblue : Constants.darkGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // --- 4. Time(s) Input and Chips ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Time(s)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.darkGrey)),
                    // --- (UPDATED "ADD TIME" BUTTON) ---
                    SizedBox(
                      width: 140, // Give it a specific width
                      child: _buildGradientButton(
                        onPressed: _selectTime,
                        text: 'Add Time',
                        icon: Icons.add,
                        gradient: kGreenGradient, // Use green gradient
                        fontSize: 16, // Standard font size
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Time Chips Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Constants.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Constants.darkblue, width: 1),
                  ),
                  child: _times.isEmpty
                      ? Text('No times selected.', style: TextStyle(color: Constants.mediumGrey))
                      : Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _times.map((time) {
                      return Chip(
                        backgroundColor: Constants.lightBlue.withOpacity(0.5),
                        label: Text(
                          _formatTime12h(time),
                          style: TextStyle(fontWeight: FontWeight.w600, color: Constants.darkblue),
                        ),
                        deleteIcon: Icon(Icons.close, size: 18, color: Constants.darkblue),
                        onDeleted: () => _removeTime(time),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 40),

                // --- 5. (UPDATED "SCHEDULE" BUTTON) ---
                _buildGradientButton(
                  onPressed: _saveMedication,
                  text: isEditing ? 'Update Schedule' : 'Schedule Medication',
                  gradient: kPrimaryGradient, // Use primary blue gradient
                  fontSize: 18, // Make this one a bit bigger as it's the main action
                  fontWeight: FontWeight.w900,
                ),
                const SizedBox(height: 20),

                // Delete Button for editing mode
                if (isEditing)
                // --- (UPDATED "DELETE" BUTTON) ---
                  _buildGradientButton(
                    onPressed: () => _showDeleteConfirmation(context),
                    text: 'Delete Medication',
                    icon: Icons.delete_forever,
                    gradient: kRedGradient, // Use red gradient
                    fontWeight: FontWeight.normal, // Make it less prominent
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Deletion Handler ---
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Medication', style: TextStyle(color: Constants.redColor)),
          content: const Text('Are you sure you want to delete this scheduled medication? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Constants.darkGrey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _performDelete();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: kRedGradient, // Use red gradient
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    alignment: Alignment.center,
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performDelete() async {
    if (!isEditing) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting medication...')),
    );

    try {
      await FirebaseFirestore.instance
          .collection(widget.collectionPath)
          .doc(widget.medication!.id)
          .delete();


      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.medication!.name} deleted successfully!')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete medication: $e')),
      );
    }
  }


  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.darkGrey),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            fillColor: Constants.lightBlue.withOpacity(0.3),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Constants.darkblue, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Constants.darkblue, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Constants.darkblue, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the $label';
            }
            return null;
          },
        ),
      ],
    );
  }
}