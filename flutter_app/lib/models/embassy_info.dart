class EmbassyInfo {
  final String name;
  final String cadence;
  final int recordCount;
  final String source;
  final bool available;

  const EmbassyInfo({
    required this.name,
    required this.cadence,
    required this.recordCount,
    required this.source,
    required this.available,
  });

  factory EmbassyInfo.fromJson(Map<String, dynamic> json) => EmbassyInfo(
        name: json['name'] as String,
        cadence: json['cadence'] as String,
        recordCount: json['record_count'] as int,
        source: json['source'] as String,
        available: json['available'] as bool,
      );
}

class VisaStats {
  final int total;
  final int approved;
  final int refused;

  const VisaStats({
    required this.total,
    required this.approved,
    required this.refused,
  });

  factory VisaStats.fromJson(Map<String, dynamic> json) => VisaStats(
        total: json['total'] as int,
        approved: json['approved'] as int,
        refused: json['refused'] as int,
      );

  double get approvalRate =>
      total == 0 ? 0 : (approved / total * 100);
}
