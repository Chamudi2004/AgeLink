import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: const Center(
        child: Text(
          'Help Page Content Goes Here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}