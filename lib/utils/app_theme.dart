import 'package:flutter/material.dart';

/// Centralised theme colours.
/// All screens should use these helpers instead of hard-coded hex values.
class AppTheme {
  AppTheme._();

  // ── Background layers ──────────────────────────────────────────────────
  /// Primary scaffold / page background
  static Color scaffoldBg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  /// Card / surface background  (dark: #1E1E1E  |  light: #F5F5F5)
  static Color cardBg(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Slightly transparent card  (used for containers, inputs, tiles)
  static Color cardBgOpaque(BuildContext context, {double opacity = 0.6}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF1E1E1E).withOpacity(opacity)
        : Colors.white.withOpacity(opacity > 0.6 ? opacity : 0.9);
  }

  // ── Accent / primary ───────────────────────────────────────────────────
  /// Cyan in dark, blue in light
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  // ── Text ───────────────────────────────────────────────────────────────
  static Color textPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black87;
  }

  static Color textSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white70 : Colors.black54;
  }

  static Color textHint(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white38 : Colors.black38;
  }

  // ── Borders / dividers ─────────────────────────────────────────────────
  static Color border(BuildContext context, {double opacity = 0.1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withOpacity(opacity)
        : Colors.black.withOpacity(opacity);
  }

  static Color accentBorder(BuildContext context, {double opacity = 0.3}) =>
      primary(context).withOpacity(opacity);

  // ── Input decoration ───────────────────────────────────────────────────
  static InputDecoration glassInputDecoration(
    BuildContext context,
    String label, {
    Widget? suffixIcon,
    Widget? prefixIcon,
    String? hintText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = primary(context);
    return InputDecoration(
      labelText: hintText == null ? label : null,
      hintText: hintText ?? label,
      labelStyle: TextStyle(color: textSecondary(context)),
      hintStyle: TextStyle(color: textHint(context)),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: isDark
          ? const Color(0xFF1E1E1E).withOpacity(0.6)
          : Colors.grey.withOpacity(0.08),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accent, width: 2),
      ),
    );
  }

  // ── Convenience booleans ───────────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
