import 'package:flutter/material.dart';

class StatusColors {
  final Color background;
  final Color foreground;
  final Color border;

  const StatusColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  static StatusColors approved(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StatusColors(
      background: isDark ? Colors.green.shade900.withAlpha(51) : Colors.green.shade50,
      foreground: isDark ? Colors.green.shade300 : Colors.green.shade900,
      border: isDark ? Colors.green.shade700 : Colors.green.shade300,
    );
  }

  static StatusColors refused(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StatusColors(
      background: isDark ? Colors.red.shade900.withAlpha(51) : Colors.red.shade50,
      foreground: isDark ? Colors.red.shade300 : Colors.red.shade900,
      border: isDark ? Colors.red.shade700 : Colors.red.shade300,
    );
  }

  static StatusColors pending(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StatusColors(
      background: isDark ? Colors.orange.shade900.withAlpha(51) : Colors.orange.shade50,
      foreground: isDark ? Colors.orange.shade300 : Colors.orange.shade900,
      border: isDark ? Colors.orange.shade700 : Colors.orange.shade300,
    );
  }

  static StatusColors neutral(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StatusColors(
      background: isDark ? Colors.grey.shade800.withAlpha(51) : Colors.grey.shade100,
      foreground: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
      border: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
    );
  }

  static StatusColors notCheckedYet(BuildContext context) => neutral(context);

  static StatusColors notPublishedYet(BuildContext context) => pending(context);
}
