// lib/ble_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// These are the correct UUIDs from your friend's code
final Guid ageLinkServiceUuid = Guid("4FAFC201-1FB5-459E-8FCC-C5C9C331914B");
final Guid wifiCharUuid = Guid("BEB5483E-36E1-4688-B7F5-EA07361B26A8");

class BleService {
  StreamSubscription? _stateSub;
  BluetoothDevice? _connectedDevice;

  // 1. Check if Bluetooth is on
  Stream<BluetoothAdapterState> get adapterState => FlutterBluePlus.adapterState;

  void listenToAdapterState(void Function() onBluetoothOff) {
    _stateSub = FlutterBluePlus.adapterState.listen((s) {
      if (s == BluetoothAdapterState.off) {
        onBluetoothOff();
      }
    });
  }

  // 2. Scan for devices
  Stream<List<ScanResult>> scanForDevices() {
    FlutterBluePlus.startScan(
      withServices: [ageLinkServiceUuid],
      timeout: const Duration(seconds: 10),
    );

    return FlutterBluePlus.scanResults.map((results) =>
        results.where((r) => r.device.platformName.startsWith('AgeLink')).toList());
  }

  // 3. Stop scanning
  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  // 4. Connect to a device
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    _connectedDevice = device;
  }

  // 5. Disconnect
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }

  // 6. Send credentials
  Future<void> sendWifiCredentials(String jsonData) async {
    if (_connectedDevice == null) {
      throw Exception("Device is not connected.");
    }

    try {
      List<BluetoothService> services = await _connectedDevice!.discoverServices();

      BluetoothService ourService = services.firstWhere(
            (s) => s.uuid == ageLinkServiceUuid
      );

      BluetoothCharacteristic wifiChar = ourService.characteristics.firstWhere(
            (c) => c.uuid == wifiCharUuid
      );

      await wifiChar.write(utf8.encode(jsonData));

      await Future.delayed(const Duration(seconds: 1)); // Give device time

    } catch (e) {
      developer.log('Error sending credentials', name: 'BleService', error: e);
      rethrow; // Re-throw the error so the UI can catch it
    }
  }

  // 7. Clean up
  void dispose() {
    _stateSub?.cancel();
    stopScan();
    disconnect();
  }
}