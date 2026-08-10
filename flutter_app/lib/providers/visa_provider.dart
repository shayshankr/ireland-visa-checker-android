import 'package:flutter/foundation.dart';

import '../models/embassy_info.dart';
import '../models/visa_result.dart';
import '../services/api_service.dart';

enum LoadState { idle, loading, success, error }

class VisaProvider extends ChangeNotifier {
  LoadState _checkState = LoadState.idle;
  LoadState _dashboardState = LoadState.idle;

  CheckResponse? _checkResult;
  List<EmbassyInfo> _embassies = [];
  VisaStats? _stats;
  String _error = '';
  String _lastCheckedNumber = '';
  DateTime? _cacheTimestamp;
  bool _dashboardFromCache = false;

  LoadState get checkState => _checkState;
  LoadState get dashboardState => _dashboardState;
  CheckResponse? get checkResult => _checkResult;
  List<EmbassyInfo> get embassies => _embassies;
  VisaStats? get stats => _stats;
  String get error => _error;
  String get lastCheckedNumber => _lastCheckedNumber;
  DateTime? get cacheTimestamp => _cacheTimestamp;
  bool get dashboardFromCache => _dashboardFromCache;

  Future<void> checkApplication(String applicationNumber) async {
    _lastCheckedNumber = applicationNumber;
    _checkState = LoadState.loading;
    _checkResult = null;
    _error = '';
    notifyListeners();

    try {
      _checkResult = await ApiService.checkApplication(applicationNumber);
      _checkState = LoadState.success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _checkState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadDashboard() async {
    // Cache-first: show stored data immediately if available so the user
    // sees something right away instead of a spinner.
    final (cachedEmbassies, cachedStats, cacheTime) =
        await ApiService.getCachedDashboard();

    if (cachedEmbassies != null && cachedStats != null) {
      _embassies = cachedEmbassies;
      _stats = cachedStats;
      _cacheTimestamp = cacheTime;
      _dashboardFromCache = true;
      _dashboardState = LoadState.success;
      notifyListeners();
    } else {
      _dashboardState = LoadState.loading;
      notifyListeners();
    }

    // Always refresh from network in the background.
    try {
      final results = await Future.wait([
        ApiService.getEmbassies(),
        ApiService.getStats(),
      ]);
      _embassies = results[0] as List<EmbassyInfo>;
      _stats = results[1] as VisaStats;
      _cacheTimestamp = DateTime.now();
      _dashboardFromCache = false;
      _dashboardState = LoadState.success;
    } catch (e) {
      if (_embassies.isEmpty) {
        _error = e.toString().replaceFirst('Exception: ', '');
        _dashboardState = LoadState.error;
      }
      // Silently keep cached data when available.
    }
    notifyListeners();
  }

  void resetCheck() {
    _checkState = LoadState.idle;
    _checkResult = null;
    _error = '';
    notifyListeners();
  }
}
