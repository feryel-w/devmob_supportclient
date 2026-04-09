import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales — dark theme
  static const Color background     = Color(0xFF0F1117);
  static const Color surface        = Color(0xFF1A1D27);
  static const Color surfaceBorder  = Color(0xFF2A2D3A);
  static const Color primary        = Color(0xFF6C5CE7);
  static const Color primaryLight   = Color(0xFFA29BFE);
  static const Color textPrimary    = Color(0xFFF0F0F5);
  static const Color textSecondary  = Color(0xFF8B8DA3);
  static const Color textHint       = Color(0xFF5A5C72);

  // Statuts
  static const Color statusNew        = Color(0xFF74B9FF);
  static const Color statusInProgress = Color(0xFFFDCB6E);
  static const Color statusResolved   = Color(0xFF00B894);
  static const Color statusClosed     = Color(0xFFA29BFE);

  // Priorités
  static const Color priorityLow    = Color(0xFF00B894);
  static const Color priorityMedium = Color(0xFFFDCB6E);
  static const Color priorityHigh   = Color(0xFFE17055);

  static Color getStatusColor(String status) {
    switch (status) {
      case 'new':         return statusNew;
      case 'in_progress': return statusInProgress;
      case 'resolved':    return statusResolved;
      case 'closed':      return statusClosed;
      default:            return statusNew;
    }
  }

  static String getStatusLabel(String status) {
    switch (status) {
      case 'new':         return 'NEW';
      case 'in_progress': return 'IN PROGRESS';
      case 'resolved':    return 'RESOLVED';
      case 'closed':      return 'CLOSED';
      default:            return 'NEW';
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority) {
      case 'low':    return priorityLow;
      case 'medium': return priorityMedium;
      case 'high':   return priorityHigh;
      default:       return priorityMedium;
    }
  }

  static String getPriorityLabel(String priority) {
    switch (priority) {
      case 'low':    return 'LOW';
      case 'medium': return 'MEDIUM';
      case 'high':   return 'HIGH';
      default:       return 'MEDIUM';
    }
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        background: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textHint, fontSize: 14),
        labelStyle: const TextStyle(color: textHint, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        prefixIconColor: textHint,
        suffixIconColor: textHint,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: surfaceBorder),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge:  TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall:  TextStyle(color: textSecondary),
      ),
    );
  }
}