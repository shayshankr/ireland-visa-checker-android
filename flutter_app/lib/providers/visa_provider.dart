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

  LoadState get checkState => _checkState;
  LoadState get dashboardState => _dashboardState;
  CheckResponse? get checkResult => _checkResult;
  List<EmbassyInfo> get embassies => _embassies;
  VisaStats? get stats => _stats;
  String get error => _error;

  Future<void> checkApplication(String applicationNumber) async {
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
    _dashboardState = LoadState.loading;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.getEmbassies(),
        ApiService.getStats(),
      ]);
      _embassies = results[0] as List<EmbassyInfo>;
      _stats = results[1] as VisaStats;
      _dashboardState = LoadState.success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _dashboardState = LoadState.error;
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
