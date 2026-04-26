import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // â”€â”€ Colores principales (basados en la imagen del dashboard) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const Color primary =
      Color(0xFF1A3A2A); // teal â€” color principal de la app
  static const Color background =
      Color(0xFFF7F9FC); // fondo general gris muy claro
  static const Color card = Color(0xFFFFFFFF); // tarjetas blanco puro
  static const Color foreground = Color(0xFF2D3748); // texto principal
  static const Color muted = Color(0xFF6B7280); // texto secundario
  static const Color mutedBg = Color(0xFFF3F4F6); // fondo muted
  static const Color accent =
      Color(0xFF1A3A2A); // teal â€” highlights, íconos activos, focus
  static const Color secondary =
      Color(0xFFEAD8B1); // beige â€” badges secundarios
  static const Color border = Color(0xFFE5E7EB); // bordes
  static const Color inputBg = Color(0xFFF9FAFB); // fondo inputs
  static const Color destructive = Color(0xFFEF4444); // rojo errores

  // â”€â”€ Colores de acción â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const Color colorView = Color(0xFF60A5FA); // azul â€” ver
  static const Color colorEdit = Color(0xFFFBBF24); // amarillo â€” editar
  static const Color colorDelete = Color(0xFFF87171); // rojo suave â€” eliminar
  static const Color colorSuccess = Color(0xFF1A3A2A); // teal â€” éxito
  static const Color colorPurple =
      Color(0xFFA78BFA); // púrpura â€” badges/stats

  // â”€â”€ Sombras (del CSS --shadow-sm/md/lg) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 2,
            offset: const Offset(0, 1)),
      ];
  static List<BoxShadow> get shadowMd => [
        BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 4)),
        BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2)),
      ];

  // â”€â”€ ThemeData â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        surface: card,
        onSurface: foreground,
        error: destructive,
        onError: Colors.white,
      ),

      // Tipografía - Inter para todo (igual que --font-display y --font-body del CSS)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
            fontSize: 32, fontWeight: FontWeight.w700, color: foreground),
        displayMedium: GoogleFonts.inter(
            fontSize: 28, fontWeight: FontWeight.w700, color: foreground),
        displaySmall: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.w600, color: foreground),
        headlineMedium: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600, color: foreground),
        titleLarge: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600, color: foreground),
        titleMedium: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, color: foreground),
        titleSmall: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: foreground),
        bodyLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w400, color: foreground),
        bodyMedium: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w400, color: foreground),
        bodySmall: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w400, color: muted),
        labelLarge: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: foreground),
        labelSmall: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600, color: muted),
      ),

      // AppBar â€” verde oscuro como el sidebar de la imagen
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Cards â€” blanco, borde sutil, sin elevación (igual que la imagen)
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),

      // Inputs â€” fondo claro, borde gris, focus teal
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: destructive, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: foreground),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: muted),
      ),

      // Botones â€” verde oscuro, radius 10px
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // BottomNav â€” fondo blanco, seleccionado verde oscuro (igual que sidebar)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        selectedLabelStyle:
            GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      dividerTheme:
          const DividerThemeData(color: border, thickness: 1, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: mutedBg,
        labelStyle: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600, color: foreground),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: muted),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: foreground,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: card,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, color: foreground),
      ),
    );
  }
}
