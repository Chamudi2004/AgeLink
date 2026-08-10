// lib/family_permissions_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'invite_member_page.dart';
import 'gradient_scaffold.dart';
import 'constants.dart'; // <-- 1. ADD THIS IMPORT
import 'custom_snackbar.dart'; // Using the premium notification helper

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
      _familyStream = const Stream.empty();
    }
  }

  // --- Premium Button Helper ---
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    required Gradient gradient,
    double verticalPadding = 18.0,
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

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const GradientScaffold(
        body: Center(child: Text('Please log in to view family members.')),
      );
    }

    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Family & Permissions',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Constants.darkblue),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 16.0),
            child: Row(
              children: [
                Icon(Icons.family_restroom_rounded, color: Constants.darkGrey, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Family Group',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Constants.darkGrey),
                ),
              ],
            ),
          ),

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
                  return Center(
                    child: Text('Error loading family members.', style: TextStyle(color: Constants.mediumGrey)),
                  );
                }

                // C. Show "Empty" message
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(context);
                }

                // D. Show the list
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
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

          // Action Buttons Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Column(
              children: [
                _buildInviteButton(context),
                const SizedBox(height: 16),
                _buildGradientButton(
                  onPressed: () {
                    CustomSnackBar.show(
                        context: context,
                        message: 'Edit Access is under construction.'
                    );
                  },
                  text: 'Edit Access',
                  icon: Icons.edit_note_rounded,
                  gradient: kPrimaryGradient,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Premium Empty State
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_add_rounded, size: 64, color: Color(0xFF1E88E5)),
              ),
              const SizedBox(height: 24),
              Text(
                'No Family Members',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Constants.darkGrey
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Invite family members to share schedules and alerts.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Constants.mediumGrey, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Premium Member Card
  Widget _buildMemberCard(String name, String mode) {
    final bool isFullMode = mode == 'Full Mode';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // User Icon Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Color(0xFF1E88E5), size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Constants.darkGrey,
                ),
              ),
            ],
          ),

          // Mode Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFullMode
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFullMode
                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              mode,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isFullMode ? const Color(0xFF2E7D32) : Constants.mediumGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Premium Invite Action Button
  Widget _buildInviteButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InviteMemberPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1E88E5).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E88E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Invite Family Members',
                    style: TextStyle(
                      color: Color(0xFF0D47A1),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF0D47A1),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}