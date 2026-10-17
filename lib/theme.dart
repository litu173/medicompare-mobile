import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sashroy palette: deep emerald, warm ivory and a restrained gold, matching the landing page.
abstract final class Brand {
  // Emerald scale (c600/c700 keep ≥4.5:1 contrast with white text).
  static const c50 = Color(0xFFECF8F2);
  static const c100 = Color(0xFFD3F1E4);
  static const c500 = Color(0xFF0F9A77);
  static const c600 = Color(0xFF0A7C60);
  static const c700 = Color(0xFF086450);
  static const c900 = Color(0xFF063D31);

  // Luxury accents.
  static const night = Color(0xFF04241C);
  static const night2 = Color(0xFF063328);
  static const night3 = Color(0xFF0A4536);
  static const mint = Color(0xFF7FE0BF);
  static const gold = Color(0xFFC9A45C);
  static const gold2 = Color(0xFFE2C88F);
  static const goldDeep = Color(0xFF8A6A2C);
  static const goldBg = Color(0xFFF7EEDB);
  static const rose = Color(0xFFE98A7A);

  // Surfaces and text.
  static const bg = Color(0xFFF7F4EC);
  static const surface = Colors.white;
  static const ink = Color(0xFF10201B);
  static const muted = Color(0xFF55655E);
  static const line = Color(0xFFECE6D8);
  static const danger = Color(0xFFC23B22);
  static const amber = Color(0xFF9A5B00);
  static const amberBg = Color(0xFFFFF6E5);

  /// Soft, wide shadow used by cards.
  static const shadow = [BoxShadow(color: Color(0x1404241C), blurRadius: 28, offset: Offset(0, 12), spreadRadius: -10)];
  static const shadowStrong = [BoxShadow(color: Color(0x2604241C), blurRadius: 40, offset: Offset(0, 18), spreadRadius: -12)];

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [night, night2, night3],
  );
  static const goldGradient = LinearGradient(colors: [gold2, gold]);
  static const emeraldGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c500, c700]);
}

/// Typography helpers: Fraunces for display numbers and headings, Plus Jakarta Sans for UI, Hind Siliguri for Bangla.
abstract final class Txt {
  static TextStyle display(double size, {Color color = Brand.ink, FontWeight weight = FontWeight.w500, FontStyle? style, double? height}) =>
      GoogleFonts.fraunces(fontSize: size, color: color, fontWeight: weight, fontStyle: style, height: height ?? 1.1);

  static TextStyle ui(double size, {Color color = Brand.ink, FontWeight weight = FontWeight.w500, double? height, double? spacing}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, color: color, fontWeight: weight, height: height, letterSpacing: spacing);

  static TextStyle bn(double size, {Color color = Brand.ink, FontWeight weight = FontWeight.w600, double? height}) =>
      GoogleFonts.hindSiliguri(fontSize: size, color: color, fontWeight: weight, height: height ?? 1.25);

  /// Small uppercase label ("eyebrow").
  static TextStyle eyebrow({Color color = Brand.goldDeep}) =>
      GoogleFonts.plusJakartaSans(fontSize: 11, color: color, fontWeight: FontWeight.w700, letterSpacing: 1.6);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.c600,
    primary: Brand.c600,
    secondary: Brand.gold,
    surface: Brand.surface,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: Brand.bg);
  // Creating the style registers and starts loading the font; the theme then refers to it by family name.
  final jakarta = GoogleFonts.plusJakartaSans();
  final text = base.textTheme.apply(fontFamily: jakarta.fontFamily, bodyColor: Brand.ink, displayColor: Brand.ink);
  final border = OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Brand.line));
  final buttonText = GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700);

  return base.copyWith(
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: Brand.bg,
      foregroundColor: Brand.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: Txt.display(22, weight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: Txt.ui(14, color: Brand.muted),
      floatingLabelStyle: Txt.ui(14, color: Brand.c700, weight: FontWeight.w600),
      hintStyle: Txt.ui(14, color: const Color(0xFF8A968F)),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: Brand.c600, width: 1.6)),
      errorBorder: border.copyWith(borderSide: const BorderSide(color: Brand.danger)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Brand.c600,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFD7DED9),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Brand.c700,
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: Brand.c600, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Brand.c700, textStyle: Txt.ui(15, weight: FontWeight.w700)),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Brand.c600 : null),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Brand.c600 : Brand.muted),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Brand.night,
      contentTextStyle: Txt.ui(14, color: Colors.white),
      actionTextColor: Brand.gold2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(color: Brand.line, space: 1, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Brand.c600),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    listTileTheme: ListTileThemeData(
      titleTextStyle: Txt.ui(15, weight: FontWeight.w600),
      subtitleTextStyle: Txt.ui(13, color: Brand.muted, weight: FontWeight.w500),
      iconColor: Brand.c700,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: Txt.display(22, weight: FontWeight.w600),
    ),
  );
}
