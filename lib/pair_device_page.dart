// lib/pair_device_page.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_service.dart'; // <-- 1. Import the new service
import 'package:firebase_auth/firebase_auth.dart';     // <-- ADD THIS
import 'package:cloud_firestore/cloud_firestore.dart';

class PairDevicePage extends StatefulWidget {
  const PairDevicePage({super.key});

  @override
  State<PairDevicePage> createState() => _PairDevicePageState();
}

class _PairDevicePageState extends State<PairDevicePage> {
  // 2. Create an instance of the service
  final BleService _bleService = BleService();

  // State variables
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  StreamSubscription? _scanSub;
  bool _isLoading = false;

  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bleService.listenToAdapterState(() {
      if (mounted) {
        _showBluetoothOffDialog();
      }
    });

    // This delays _startScan() until AFTER the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startScan();
      }
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _bleService.dispose(); // 3. Dispose the service
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showBluetoothOffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bluetooth is Off'),
        content: const Text('Please turn on Bluetooth to connect your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startScan() {
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      _showBluetoothOffDialog();
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    _scanSub = _bleService.scanForDevices().listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    }, onError: (e) {
      print('Scan Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scan Error: $e')));
      }
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _bleService.stopScan();
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() { _isLoading = true; });

    try {
      await _bleService.connectToDevice(device);
      if (!mounted) return;
      _showWifiDialog(device.remoteId.toString());

    } catch (e) {
      print('Connection Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e'))
      );
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _sendWifiCredentials(String deviceId) async {
    if (_ssidController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: You are not logged in.')),
      );
      setState(() { _isLoading = false; });
      return;
    }

    final String ssid = _ssidController.text;
    final String pass = _passwordController.text;
    final String userId = currentUser.uid;

    const String fbHost = "agelink-f4680-default-rtdb.asia-southeast1.firebasedatabase.app";
    const String fbAuth = "iVNn4iHyjp2TizXHcx0QgrwGyEboJba8pxuDVLGm"; // <-- See security warning below

    final Map<String, dynamic> provisioningData = {
      "ssid": ssid,
      "pass": pass,
      "user_id": userId,
      "fb_host": fbHost,
      "fb_auth": fbAuth,
    };

    final String jsonString = jsonEncode(provisioningData);

    try {
      await _bleService.sendWifiCredentials(jsonString);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({'pairedDeviceId': deviceId}, SetOptions(merge: true));

      await _bleService.disconnect();

      if (!mounted) return;
      Navigator.pop(context); // Close the WiFi dialog
      Navigator.pop(context); // Go back to the home screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device paired successfully!')),
      );

    } catch (e) {
      print('Error sending credentials or saving to Firestore: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not complete pairing.')),
      );
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showWifiDialog(String deviceId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Home WiFi Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(labelText: 'WiFi Name (SSID)'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _bleService.disconnect();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _sendWifiCredentials(deviceId),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Device'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
            onPressed: _startScan,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: _scanResults.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isScanning) const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Scanning for "AgeLink" devices...'),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                var result = _scanResults[index];
                return ListTile(
                  title: Text(result.device.localName),
                  subtitle: Text(result.device.remoteId.toString()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _connectToDevice(result.device),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}