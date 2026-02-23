import 'package:flutter/material.dart';

/// Store app UI tokens based on ui-ux-rules.
abstract final class StoreUi {
  static const Color primary = Color(0xFFFF6B35);
  static const Color surface = Color(0xFFFBF6F2);
  static const Color onPrimary = Colors.white;
  static const Color card = Colors.white;
  static const Color border = Color(0xFFD9D9D9);
  static const Color textButton = Colors.blue;
  static const Color error = Colors.red;

  static const double cardRadius = 16;
  static const double controlRadius = 12;
}
