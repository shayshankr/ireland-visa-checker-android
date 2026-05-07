class VisaResult {
  final String embassy;
  final String decision;
  final String source;

  const VisaResult({
    required this.embassy,
    required this.decision,
    required this.source,
  });

  factory VisaResult.fromJson(Map<String, dynamic> json) => VisaResult(
        embassy: json['embassy'] as String,
        decision: json['decision'] as String,
        source: json['source'] as String,
      );

  bool get isApproved => decision.toUpperCase() == 'APPROVED';
  bool get isRefused => decision.toUpperCase() == 'REFUSED';
}

class NearestResult {
  final String number;
  final String embassy;
  final String decision;
  final int? difference;

  const NearestResult({
    required this.number,
    required this.embassy,
    required this.decision,
    this.difference,
  });

  factory NearestResult.fromJson(Map<String, dynamic> json) => NearestResult(
        number: json['number'] as String,
        embassy: json['embassy'] as String,
        decision: json['decision'] as String,
        difference: json['difference'] as int?,
      );

  bool get isApproved => decision.toUpperCase() == 'APPROVED';
}

class CheckResponse {
  final String applicationNumber;
  final bool found;
  final List<VisaResult> results;
  final Map<String, NearestResult>? nearest;

  const CheckResponse({
    required this.applicationNumber,
    required this.found,
    required this.results,
    this.nearest,
  });

  factory CheckResponse.fromJson(Map<String, dynamic> json) {
    final nearestJson = json['nearest'] as Map<String, dynamic>?;
    Map<String, NearestResult>? nearest;
    if (nearestJson != null) {
      nearest = {};
      if (nearestJson['before'] != null) {
        nearest['before'] = NearestResult.fromJson(
            nearestJson['before'] as Map<String, dynamic>);
      }
      if (nearestJson['after'] != null) {
        nearest['after'] = NearestResult.fromJson(
            nearestJson['after'] as Map<String, dynamic>);
      }
    }
    return CheckResponse(
      applicationNumber: json['application_number'] as String,
      found: json['found'] as bool,
      results: (json['results'] as List<dynamic>)
          .map((e) => VisaResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      nearest: nearest,
    );
  }
}
