import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/embassy_info.dart';
import '../models/visa_result.dart';

class ApiService {
  static const String baseUrl =
      'https://shayshankrathore-ireland-visa-api.hf.space';

  static const _embassiesCacheKey = 'cache_embassies_v1';
  static const _statsCacheKey = 'cache_stats_v1';
  static const _cacheTimestampKey = 'cache_timestamp_v1';

  // ── Check ──────────────────────────────────────────────────────────────────

  static Future<CheckResponse> checkApplication(String applicationNumber) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/check'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'application_number': applicationNumber}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return CheckResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    if (response.statusCode == 400) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['detail'] ?? 'Invalid application number');
    }
    throw Exception('Server error (${response.statusCode})');
  }

  // ── Embassies ──────────────────────────────────────────────────────────────

  static Future<List<EmbassyInfo>> getEmbassies() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/embassies'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      final embassies = data
          .map((e) => EmbassyInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      await _cacheEmbassies(embassies);
      return embassies;
    }
    throw Exception('Failed to load embassies (${response.statusCode})');
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  static Future<VisaStats> getStats() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/stats'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final stats =
          VisaStats.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      await _cacheStats(stats);
      return stats;
    }
    throw Exception('Failed to load stats (${response.statusCode})');
  }

  // ── Cache helpers ──────────────────────────────────────────────────────────

  static Future<void> _cacheEmbassies(List<EmbassyInfo> embassies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _embassiesCacheKey,
        jsonEncode(embassies.map((e) => e.toJson()).toList()));
    await prefs.setString(
        _cacheTimestampKey, DateTime.now().toIso8601String());
  }

  static Future<void> _cacheStats(VisaStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsCacheKey, jsonEncode(stats.toJson()));
  }

  /// Returns (embassies, stats, cacheTimestamp) from local cache, or all-null
  /// if nothing is cached.
  static Future<(List<EmbassyInfo>?, VisaStats?, DateTime?)>
      getCachedDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final embassiesRaw = prefs.getString(_embassiesCacheKey);
      final statsRaw = prefs.getString(_statsCacheKey);
      final timestampRaw = prefs.getString(_cacheTimestampKey);
      if (embassiesRaw == null || statsRaw == null) return (null, null, null);

      final embassies = (jsonDecode(embassiesRaw) as List<dynamic>)
          .map((e) => EmbassyInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      final stats = VisaStats.fromJson(
          jsonDecode(statsRaw) as Map<String, dynamic>);
      final timestamp =
          timestampRaw != null ? DateTime.tryParse(timestampRaw) : null;
      return (embassies, stats, timestamp);
    } catch (_) {
      return (null, null, null);
    }
  }
}
