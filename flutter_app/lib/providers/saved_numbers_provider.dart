import 'package:flutter/foundation.dart';

import '../models/saved_number.dart';
import '../services/api_service.dart';
import '../services/home_widget_service.dart';
import '../services/saved_numbers_service.dart';

class SavedNumbersProvider extends ChangeNotifier {
  List<SavedNumber> _numbers = [];
  final Set<String> _checkingNow = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  bool get isAnyChecking => _checkingNow.isNotEmpty;
  bool isChecking(String number) => _checkingNow.contains(number);
  bool contains(String number) => _numbers.any((n) => n.number == number);

  // Sorted: found first, then most-recently-checked first.
  List<SavedNumber> get numbers {
    final sorted = List<SavedNumber>.from(_numbers);
    sorted.sort(_compare);
    return List.unmodifiable(sorted);
  }

  static int _compare(SavedNumber a, SavedNumber b) {
    if (a.isFound && !b.isFound) return -1;
    if (!a.isFound && b.isFound) return 1;
    final aTime = a.lastChecked;
    final bTime = b.lastChecked;
    if (aTime != null && bTime != null) return bTime.compareTo(aTime);
    if (aTime != null) return -1;
    if (bTime != null) return 1;
    return 0;
  }

  SavedNumbersProvider() {
    _init();
  }

  Future<void> _init() async {
    _numbers = await SavedNumbersService.getAll();
    _loaded = true;
    notifyListeners();
  }

  Future<void> reload() async {
    _numbers = await SavedNumbersService.getAll();
    notifyListeners();
  }

  Future<void> add(SavedNumber number) async {
    await SavedNumbersService.add(number);
    _numbers = await SavedNumbersService.getAll();
    notifyListeners();
  }

  Future<void> remove(String number) async {
    await SavedNumbersService.remove(number);
    _numbers = _numbers.where((n) => n.number != number).toList();
    notifyListeners();
  }

  Future<void> updateLabel(String number, String? label) async {
    final idx = _numbers.indexWhere((n) => n.number == number);
    if (idx == -1) return;
    final updated = _numbers[idx].copyWith(label: label);
    await SavedNumbersService.update(updated);
    _numbers = [..._numbers]..[idx] = updated;
    notifyListeners();
  }

  Future<void> toggleWatch(String number, bool enabled) async {
    final idx = _numbers.indexWhere((n) => n.number == number);
    if (idx == -1) return;
    final updated = _numbers[idx].copyWith(watchEnabled: enabled);
    await SavedNumbersService.update(updated);
    _numbers = [..._numbers]..[idx] = updated;
    notifyListeners();
  }

  Future<void> updateSubmittedDate(String number, DateTime? date) async {
    final idx = _numbers.indexWhere((n) => n.number == number);
    if (idx == -1) return;
    final updated = _numbers[idx].copyWith(submittedDate: date);
    await SavedNumbersService.update(updated);
    _numbers = [..._numbers]..[idx] = updated;
    notifyListeners();
  }

  Future<void> checkNow(String number) async {
    if (_checkingNow.contains(number)) return;
    _checkingNow.add(number);
    notifyListeners();

    try {
      final response = await ApiService.checkApplication(number);
      final idx = _numbers.indexWhere((n) => n.number == number);
      if (idx == -1) return;

      final existing = _numbers[idx];
      final newlyFound = response.found && !existing.isFound;
      final updated = SavedNumber(
        number: existing.number,
        label: existing.label,
        // Auto-disable watch when the decision is found.
        watchEnabled:
            response.found ? false : existing.watchEnabled,
        lastFound: response.found,
        lastDecision: response.found && response.results.isNotEmpty
            ? response.results.first.decision
            : existing.lastDecision,
        lastEmbassy: response.found && response.results.isNotEmpty
            ? response.results.first.embassy
            : existing.lastEmbassy,
        lastChecked: DateTime.now(),
        // Record the moment a decision first appeared.
        foundAt: newlyFound ? DateTime.now() : existing.foundAt,
        submittedDate: existing.submittedDate,
        // Store nearest-numbers data if not found, clear if found.
        lastNearest: response.found ? null : response.nearest,
      );
      await SavedNumbersService.update(updated);
      _numbers = [..._numbers]..[idx] = updated;
      // Update home screen widget after a successful check
      await HomeWidgetService.updateWidgetData(_numbers);
    } catch (_) {
      // Silently ignore; card stays as-is.
    } finally {
      _checkingNow.remove(number);
      notifyListeners();
    }
  }

  Future<void> checkAll() async {
    await Future.wait(_numbers.map((n) => checkNow(n.number)));
    // Final widget update after all checks
    await HomeWidgetService.updateWidgetData(_numbers);
  }
}
