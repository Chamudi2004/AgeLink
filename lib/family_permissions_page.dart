import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'invite_member_page.dart';

class FamilyPermissionsPage extends StatefulWidget {
  const FamilyPermissionsPage({super.key});

  @override
  State<FamilyPermissionsPage> createState() => _FamilyPermissionsPageState();
}

class _FamilyPermissionsPageState extends State<FamilyPermissionsPage> {
  // Get the current user
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // This is the reference to the family members subcollection
  late final Stream<QuerySnapshot> _familyStream;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      // Listen to the subcollection of family members
      // TODO: Confirm this is your correct database structure
      _familyStream = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('family_members')
          .snapshots();
    } else {
      // Handle case where user is null (shouldn't happen, but safe)
      _familyStream = Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      // Safety check if user is logged out
      return Scaffold(
        appBar: AppBar(title: const Text('Family and Permission')),
        body: const Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family and Permission'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
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
                      // TODO: Add 'name' and 'mode' fields when inviting
                      return _buildMemberCard(
                        member['name'] ?? 'Unknown Name',
                        member['mode'] ?? 'View Mode',
                      );
                    },
                  );
                },
              ),
            ),

            // 2. "Edit Access" Button
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to an "Edit Access" page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Access pressed')),
                );
              },
              child: const Text('Edit Access'),
            ),
            const SizedBox(height: 24),

            // 3. "Invite Family Members" Link
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
  // UPDATED: This now navigates to your new InviteMemberPage
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