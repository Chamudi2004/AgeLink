// lib/family_permissions_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'invite_member_page.dart';
import 'gradient_scaffold.dart';
import 'constants.dart'; // <-- 1. ADD THIS IMPORT

// --- (Gradient constants) ---
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
// ------------------------------------------

class FamilyPermissionsPage extends StatefulWidget {
  const FamilyPermissionsPage({super.key});

  @override
  State<FamilyPermissionsPage> createState() => _FamilyPermissionsPageState();
}

class _FamilyPermissionsPageState extends State<FamilyPermissionsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final Stream<QuerySnapshot> _familyStream;

  // --- 2. ADD kAppId ---
  final String appId = kAppId;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {

      // --- 3. THIS IS THE FIX ---
      // Use the correct path that matches your rules
      _familyStream = FirebaseFirestore.instance
          .collection('artifacts') // <-- Correct
          .doc(appId)               // <-- Correct
          .collection('users')
          .doc(currentUser!.uid)
          .collection('family_members')
          .snapshots();
      // --- END OF FIX ---

    } else {
      _familyStream = Stream.empty();
    }
  }

  // --- (Reusable Gradient Button) ---
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
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
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: (icon != null)
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            )
                : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family and Permission')),
        body: const Center(child: Text('Please log in.')),
      );
    }

    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Family and Permission',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              // TODO: Add menu options
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Family Group',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 1. Dynamic List of Family Members
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _familyStream,
                builder: (context, snapshot) {
                  // A. Show loading spinner
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // B. Show error
                  if (snapshot.hasError) {
                    print('Family Stream Error: ${snapshot.error}');
                    return const Center(
                        child: Text('Error loading family members.'));
                  }

                  // C. Show "Empty" message
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // D. Show the list
                  var docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var member = docs[index].data() as Map<String, dynamic>;
                      return _buildMemberCard(
                        member['name'] ?? 'Unknown Name',
                        member['mode'] ?? 'View Mode',
                      );
                    },
                  );
                },
              ),
            ),

            _buildGradientButton(
              onPressed: () {
                // TODO: Navigate to an "Edit Access" page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Access pressed')),
                );
              },
              text: 'Edit Access',
              gradient: kPrimaryGradient,
            ),
            const SizedBox(height: 24),

            _buildInviteButton(context),
          ],
        ),
      ),
    );
  }

  // Helper widget for the "Empty" state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Your family group is empty.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first member.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Helper widget to build each member card
  Widget _buildMemberCard(String name, String mode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1,
      color: Colors.white.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              mode,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: mode == 'Full Mode'
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for the "Invite" link
  Widget _buildInviteButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to the new invite page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InviteMemberPage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Invite Family Members',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}