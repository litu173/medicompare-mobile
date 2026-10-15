import 'package:flutter/material.dart';

/// Brand palette, matching web/src/app/globals.css.
abstract final class Brand {
  static const c50 = Color(0xFFECFDF7);
  static const c100 = Color(0xFFD1FAE9);
  static const c500 = Color(0xFF10A37F);
  static const c600 = Color(0xFF0B8A6B);
  static const c700 = Color(0xFF0A6F57);
  static const c900 = Color(0xFF063D31);

  static const bg = Color(0xFFF6F7F8);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFF1F2F4);
  static const danger = Color(0xFFDC2626);
  static const amber = Color(0xFFB45309);
  static const amberBg = Color(0xFFFFFBEB);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Brand.c600, primary: Brand.c600, surface: Colors.white);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: Brand.bg);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Brand.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Brand.ink),
    ),
    textTheme: base.textTheme.apply(bodyColor: Brand.ink, displayColor: Brand.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: Brand.c600, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Brand.c600,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Brand.c700,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Brand.c600, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Brand.c50,
      surfaceTintColor: Colors.transparent,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: s.contains(WidgetState.selected) ? Brand.c700 : Brand.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Brand.c700 : Brand.muted),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: const DividerThemeData(color: Brand.line, space: 1, thickness: 1),
  );
}
