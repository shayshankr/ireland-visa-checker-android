import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../services/api_service.dart';
import 'home_widget_service.dart';
import 'notification_service.dart';
import 'saved_numbers_service.dart';

class WatcherService {
  static const _uniqueTaskName = 'visa_watcher_periodic';
  static const _taskName = 'visaWatcherTask';

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      _uniqueTaskName,
      _taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  // Called from the background isolate via callbackDispatcher in main.dart.
  static Future<void> checkWatchedNumbers() async {
    WidgetsFlutterBinding.ensureInitialized();

    final all = await SavedNumbersService.getAll();
    final watched = all.where((n) => n.watchEnabled).toList();
    if (watched.isEmpty) return;

    for (final saved in watched) {
      try {
        final response = await ApiService.checkApplication(saved.number);
        final newlyFound = response.found && saved.lastFound != true;

        if (newlyFound) {
          final result = response.results.first;
          await NotificationService.showFromBackground(
            number: saved.number,
            decision: result.decision,
            embassy: result.embassy,
          );
        }

        // Auto-disable watch once a decision has been found — nothing left to watch.
        await SavedNumbersService.update(
          saved.copyWith(
            lastFound: response.found,
            lastDecision: response.found && response.results.isNotEmpty
                ? response.results.first.decision
                : null,
            lastEmbassy: response.found && response.results.isNotEmpty
                ? response.results.first.embassy
                : null,
            lastChecked: DateTime.now(),
            watchEnabled: response.found ? false : null,
            lastNearest: response.found ? null : response.nearest,
          ),
        );
      } catch (_) {
        // Network error — will retry at next interval.
      }
    }
    // Update home screen widget after background checks
    final updated = await SavedNumbersService.getAll();
    await HomeWidgetService.updateWidgetData(updated);
  }
}
