import 'package:flutter/material.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device'),
      ),
      body: const Center(
        child: Text(
          'Device Page Content Goes Here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}