import 'package:flutter/material.dart';

import 'store_ui.dart';

abstract final class StoreAppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: StoreUi.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: StoreUi.primary,
      onPrimary: StoreUi.onPrimary,
      surface: StoreUi.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: StoreUi.surface,
      canvasColor: StoreUi.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: StoreUi.primary,
        foregroundColor: StoreUi.onPrimary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: StoreUi.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardTheme(
        color: StoreUi.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StoreUi.cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: StoreUi.primary,
          foregroundColor: StoreUi.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: StoreUi.primary,
          side: const BorderSide(color: StoreUi.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: StoreUi.textButton,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StoreUi.controlRadius),
          borderSide: const BorderSide(color: StoreUi.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StoreUi.controlRadius),
          borderSide: const BorderSide(color: StoreUi.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StoreUi.controlRadius),
          borderSide: const BorderSide(color: StoreUi.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StoreUi.controlRadius),
          borderSide: const BorderSide(color: StoreUi.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StoreUi.controlRadius),
          borderSide: const BorderSide(color: StoreUi.error, width: 2),
        ),
        errorStyle: const TextStyle(
          color: StoreUi.error,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return StoreUi.primary;
          }
          return const Color(0xFFE0E0E0);
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
