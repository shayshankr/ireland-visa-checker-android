import 'visa_result.dart';

class SavedNumber {
  final String number;
  final String? label;
  final bool watchEnabled;
  final bool? lastFound;
  final String? lastDecision;
  final String? lastEmbassy;
  final DateTime? lastChecked;
  /// When a decision first appeared for this number (not-found → found transition).
  final DateTime? foundAt;
  /// User-entered submission date (optional), for calculating wait time.
  final DateTime? submittedDate;
  /// Nearest published application numbers (before/after) from the last check if not found.
  final Map<String, NearestResult>? lastNearest;

  const SavedNumber({
    required this.number,
    this.label,
    this.watchEnabled = false,
    this.lastFound,
    this.lastDecision,
    this.lastEmbassy,
    this.lastChecked,
    this.foundAt,
    this.submittedDate,
    this.lastNearest,
  });

  SavedNumber copyWith({
    String? label,
    bool? watchEnabled,
    bool? lastFound,
    String? lastDecision,
    String? lastEmbassy,
    DateTime? lastChecked,
    DateTime? foundAt,
    DateTime? submittedDate,
    Map<String, NearestResult>? lastNearest,
  }) =>
      SavedNumber(
        number: number,
        label: label ?? this.label,
        watchEnabled: watchEnabled ?? this.watchEnabled,
        lastFound: lastFound ?? this.lastFound,
        lastDecision: lastDecision ?? this.lastDecision,
        lastEmbassy: lastEmbassy ?? this.lastEmbassy,
        lastChecked: lastChecked ?? this.lastChecked,
        foundAt: foundAt ?? this.foundAt,
        submittedDate: submittedDate ?? this.submittedDate,
        lastNearest: lastNearest ?? this.lastNearest,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'label': label,
        'watchEnabled': watchEnabled,
        'lastFound': lastFound,
        'lastDecision': lastDecision,
        'lastEmbassy': lastEmbassy,
        'lastChecked': lastChecked?.toIso8601String(),
        'foundAt': foundAt?.toIso8601String(),
        'submittedDate': submittedDate?.toIso8601String(),
        'lastNearest': lastNearest?.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory SavedNumber.fromJson(Map<String, dynamic> json) {
    final lastNearestJson = json['lastNearest'] as Map<String, dynamic>?;
    Map<String, NearestResult>? lastNearest;
    if (lastNearestJson != null) {
      lastNearest = {};
      lastNearestJson.forEach((key, value) {
        lastNearest![key] = NearestResult.fromJson(value as Map<String, dynamic>);
      });
    }
    return SavedNumber(
      number: json['number'] as String,
      label: json['label'] as String?,
      watchEnabled: json['watchEnabled'] as bool? ?? false,
      lastFound: json['lastFound'] as bool?,
      lastDecision: json['lastDecision'] as String?,
      lastEmbassy: json['lastEmbassy'] as String?,
      lastChecked: json['lastChecked'] != null
          ? DateTime.tryParse(json['lastChecked'] as String)
          : null,
      foundAt: json['foundAt'] != null
          ? DateTime.tryParse(json['foundAt'] as String)
          : null,
      submittedDate: json['submittedDate'] != null
          ? DateTime.tryParse(json['submittedDate'] as String)
          : null,
      lastNearest: lastNearest,
    );
  }

  String get displayNumber => 'IRL$number';

  String get statusText {
    if (lastFound == null) return 'Not checked yet';
    if (lastFound!) return lastDecision ?? 'Found';
    return 'Not published yet';
  }

  bool get isFound => lastFound == true;
  bool get isApproved => lastDecision?.toUpperCase() == 'APPROVED';
  bool get isRefused => lastDecision?.toUpperCase() == 'REFUSED';
}
