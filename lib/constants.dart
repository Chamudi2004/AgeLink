import 'package:flutter/material.dart';

const String kAppId = String.fromEnvironment('app_id', defaultValue: 'default-app-id');
const String kFirebaseConfigString = String.fromEnvironment('firebase_config', defaultValue: '{}');
const String kInitialAuthToken = String.fromEnvironment('initial_auth_token', defaultValue: '');


class Constants {
  static Color darkBlue = const Color(0xFF2196F3);
  static Color lightBlue = const Color(0xFFE3F2FD);
  static Color redColor = const Color(0xFFF44336);
  static Color greenColor = const Color(0xFF4CAF50);
  static Color orangeColor = const Color(0xFFFF9800);
  static Color darkGrey = const Color(0xFF424242);
  static Color mediumGrey = const Color(0xFF757575);
  static Color darkblue = const Color(0xFF0D47A1);
  static Color gradiantBlue = const Color(0xFFBCD8FF);
  static Color white = const Color(0xFFFFFFFF);

}