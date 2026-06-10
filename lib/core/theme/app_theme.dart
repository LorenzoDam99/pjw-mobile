import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Light Material 3 theme. Neutral palette matching the web app
/// (Inter font, monochrome accents, rounded surfaces).
class AppTheme {
  static const _bg = Color(0xFFFAFAFA);
  static const _fg = Color(0xFF0A0A0A);
  static const _muted = Color(0xFF737373);
  static const _border = Color(0xFFE5E5E5);
  static const _surface = Colors.white;
  static const _amber = Color(0xFFF59E0B);
  static const _destructive = Color(0xFFDC2626);

  static Color get bg => _bg;
  static Color get fg => _fg;
  static Color get muted => _muted;
  static Color get border => _border;
  static Color get surface => _surface;
  static Color get amber => _amber;
  static Color get destructive => _destructive;

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _fg,
        brightness: Brightness.light,
        primary: _fg,
        onPrimary: Colors.white,
        surface: _surface,
        onSurface: _fg,
        error: _destructive,
      ),
      scaffoldBackgroundColor: _bg,
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: _fg,
        displayColor: _fg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _bg.withOpacity(0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: _fg,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: _fg),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _border),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _fg, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          color: _muted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _fg,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _fg,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: _border),
          foregroundColor: _fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _fg),
      ),
      dividerTheme: DividerThemeData(color: _border, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: _surface,
        side: BorderSide(color: _border),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 1.2,
          color: _muted,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _fg,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _fg,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// Eyebrow text: tiny uppercase muted, like the web's `tracking-[0.2em] uppercase` style.
TextStyle eyebrowStyle() => GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 2,
      color: AppTheme.muted,
    );
