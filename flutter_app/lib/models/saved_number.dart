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

  const SavedNumber({
    required this.number,
    this.label,
    this.watchEnabled = false,
    this.lastFound,
    this.lastDecision,
    this.lastEmbassy,
    this.lastChecked,
    this.foundAt,
  });

  SavedNumber copyWith({
    String? label,
    bool? watchEnabled,
    bool? lastFound,
    String? lastDecision,
    String? lastEmbassy,
    DateTime? lastChecked,
    DateTime? foundAt,
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
      };

  factory SavedNumber.fromJson(Map<String, dynamic> json) => SavedNumber(
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
      );

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
