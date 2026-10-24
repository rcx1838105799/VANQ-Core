import 'package:material_ui/material_ui.dart';

/// VANQ Core matte dark theme tokens, matching the VANQ-Aurora website theme.
///
/// Obsidian matte black base, platinum + violet accents. Used by the custom
/// VANQ home page; FlClash pages keep their own theme.
abstract final class VanqTheme {
  static const Color background = Color(0xFF0A0A0B);
  static const Color card = Color(0xFF141416);
  static const Color cardBorder = Color(0xFF232326);
  static const Color platinum = Color(0xFFE8E8EC);
  static const Color violet = Color(0xFF6C5CE7);
  static const Color violetSoft = Color(0xFF8B7FF0);
  static const Color pink = Color(0xFFFD79A8);
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF636366);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color danger = Color(0xFFFF453A);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [violet, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient companionPlaceholder = LinearGradient(
    colors: [Color(0xFF2D2A4A), Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get themeData {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: violet,
        secondary: pink,
        surface: card,
        onSurface: textPrimary,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}
