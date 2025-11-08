// lib/ble_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// These are the correct UUIDs from your friend's code
final Guid AGE_LINK_SERVICE_UUID = Guid("4FAFC201-1FB5-459E-8FCC-C5C9C331914B");
final Guid WIFI_CHAR_UUID = Guid("BEB5483E-36E1-4688-B7F5-EA07361B26A8");

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
    // ignore: missing_permission
    FlutterBluePlus.startScan(
      withServices: [AGE_LINK_SERVICE_UUID],
      timeout: const Duration(seconds: 10),
    );

    return FlutterBluePlus.scanResults.map((results) =>
        results.where((r) => r.device.localName.startsWith('AgeLink')).toList());
  }

  // 3. Stop scanning
  void stopScan() {
    // ignore: missing_permission
    FlutterBluePlus.stopScan();
  }

  // 4. Connect to a device
  Future<void> connectToDevice(BluetoothDevice device) async {
    // ignore: missing_permission
    await device.connect();
    _connectedDevice = device;
  }

  // 5. Disconnect
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      // ignore: missing_permission
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }

  // 6. Send credentials
  Future<void> sendWifiCredentials(String ssid, String password) async {
    if (_connectedDevice == null) {
      throw Exception("Device is not connected.");
    }

    try {
      // ignore: missing_permission
      List<BluetoothService> services = await _connectedDevice!.discoverServices();

      BluetoothService ourService = services.firstWhere(
              (s) => s.uuid == AGE_LINK_SERVICE_UUID
      );

      BluetoothCharacteristic wifiChar = ourService.characteristics.firstWhere(
              (c) => c.uuid == WIFI_CHAR_UUID
      );

      // This is the format guess, your friend must confirm this
      String wifiData = "$ssid|$password";

      print('Sending BLE data: $wifiData');

      // ignore: missing_permission
      await wifiChar.write(utf8.encode(wifiData));

      await Future.delayed(const Duration(seconds: 1)); // Give device time

    } catch (e) {
      print('Error sending credentials: $e');
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