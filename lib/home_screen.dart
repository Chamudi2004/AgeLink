import 'package:flutter/material.dart';
import 'constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This is the
    // from your old home_page.dart
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Missed Medication Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Missed: ',
                              style: TextStyle(
                                color: Constants.redColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '8:00 AM Lisinopril.',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'No confirmation received.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'AgeLink lights are on.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      // Handle close action
                    },
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Connect Device Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // Handle connect device action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.darkBlue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Connect Device',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Today Medication Schedule Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Today Medication Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.darkGrey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Thursday, June 6',
              style: TextStyle(
                fontSize: 16,
                color: Constants.mediumGrey,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Medication List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMedicationItem('8.00 AM', 'Metformin', '1 tablet', 'Taken', Constants.greenColor, Icons.check_circle),
                  const Divider(height: 16, thickness: 0.5, color: Colors.grey),
                  _buildMedicationItem('8.00 AM', 'Vitamin D', '1 tablet', 'Taken', Constants.greenColor, Icons.check_circle),
                  const Divider(height: 16, thickness: 0.5, color: Colors.grey),
                  _buildMedicationItem('8.00 PM', 'Metformin', '1 tablet', 'Pending', Constants.orangeColor, Icons.radio_button_unchecked),
                  const Divider(height: 16, thickness: 0.5, color: Colors.grey),
                  _buildMedicationItem('8.00 PM', 'Amlodipine', '1 tablet', 'Pending', Constants.orangeColor, Icons.radio_button_unchecked),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Moved this helper method here
  Widget _buildMedicationItem(String time, String name, String dosage, String status, Color statusColor, IconData statusIcon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80, // Fixed width for time
            child: Text(
              time,
              style: TextStyle(
                color: Constants.darkGrey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Constants.darkGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  dosage,
                  style: TextStyle(
                    color: Constants.mediumGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}