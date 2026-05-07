import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/embassy_info.dart';
import '../models/visa_result.dart';

class ApiService {
  // Update this to your deployed backend URL before releasing to Play Store.
  // For local testing use: http://10.0.2.2:8000  (Android emulator → host machine)
  static const String baseUrl = 'http://10.0.2.2:8000';

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

  static Future<List<EmbassyInfo>> getEmbassies() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/embassies'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => EmbassyInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load embassies (${response.statusCode})');
  }

  static Future<VisaStats> getStats() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/stats'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return VisaStats.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load stats (${response.statusCode})');
  }
}
