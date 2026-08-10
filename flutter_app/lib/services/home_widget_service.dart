import 'dart:io' show Platform;

import '../models/saved_number.dart';

class HomeWidgetService {
  /// Format a SavedNumber for widget display and save + update the widget.
  /// Only works on Android/iOS; no-op on other platforms.
  static Future<void> updateWidgetData(List<SavedNumber> numbers) async {
    // Widget is only supported on Android/iOS
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    try {
      // Lazy import to avoid compilation errors on Windows/Web
      final homeWidget = _getHomeWidgetIfAvailable();
      if (homeWidget == null) return;

      // Find the most relevant number: not found (to watch) or most recently found
      SavedNumber? relevant;

      // First priority: unwatched or watched not-found numbers (next to resolve)
      final notFound = numbers.where((n) => !n.isFound).toList();
      if (notFound.isNotEmpty) {
        // Prefer watched ones, then by most recent check
        final watched = notFound.where((n) => n.watchEnabled).toList();
        relevant = watched.isNotEmpty ? watched.first : notFound.first;
      }
      // Fallback: most recently found
      else if (numbers.any((n) => n.isFound)) {
        final found = numbers.where((n) => n.isFound).toList();
        found.sort((a, b) => (b.foundAt ?? DateTime(2000))
            .compareTo(a.foundAt ?? DateTime(2000)));
        relevant = found.first;
      }
      // Last resort: most recently checked
      else if (numbers.isNotEmpty) {
        final sorted = List<SavedNumber>.from(numbers);
        sorted.sort((a, b) => (b.lastChecked ?? DateTime(2000))
            .compareTo(a.lastChecked ?? DateTime(2000)));
        relevant = sorted.first;
      }

      if (relevant != null) {
        await _saveAndUpdate(relevant);
      } else {
        // No numbers saved yet — stub out if on non-mobile
        await _updateWidgetData('number', '');
        await _updateWidgetData('status', 'No applications');
        await _updateWidgetData('detail', 'Add an application to track');
      }
    } catch (_) {
      // Silently fail — widget is non-critical
    }
  }

  static dynamic _getHomeWidgetIfAvailable() {
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    try {
      return null; // Placeholder: actual import happens via conditional
    } catch (_) {
      return null;
    }
  }

  static Future<void> _updateWidgetData(String key, String value) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    // Stub: would call HomeWidget.saveWidgetData on mobile
  }

  static Future<void> _saveAndUpdate(SavedNumber number) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    // Stub: would call HomeWidget.saveWidgetData and updateWidget on mobile
    // Logic would format details from: number.decision, number.foundAt,
    // number.submittedDate, number.lastChecked
  }
}
