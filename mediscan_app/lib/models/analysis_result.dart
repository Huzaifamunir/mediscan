class AnalysisResult {
  final String id;
  final String title;
  final DateTime analyzedAt;
  final String reportType;
  final String summary;
  final String? summaryUrdu;
  final List<Finding> findings;
  final List<String> recommendations;
  final List<String>? recommendationsUrdu;
  final RiskLevel riskLevel;
  final String rawResponse;
  final String? imagePath;
  final String? pdfPath;

  AnalysisResult({
    required this.id,
    required this.title,
    required this.analyzedAt,
    required this.reportType,
    required this.summary,
    this.summaryUrdu,
    required this.findings,
    required this.recommendations,
    this.recommendationsUrdu,
    required this.riskLevel,
    required this.rawResponse,
    this.imagePath,
    this.pdfPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'analyzedAt': analyzedAt.toIso8601String(),
        'reportType': reportType,
        'summary': summary,
        'summaryUrdu': summaryUrdu,
        'findings': findings.map((f) => f.toJson()).toList(),
        'recommendations': recommendations,
        'recommendationsUrdu': recommendationsUrdu,
        'riskLevel': riskLevel.name,
        'rawResponse': rawResponse,
        'imagePath': imagePath,
        'pdfPath': pdfPath,
      };

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        id: json['id'],
        title: json['title'],
        analyzedAt: DateTime.parse(json['analyzedAt']),
        reportType: json['reportType'],
        summary: json['summary'],
        summaryUrdu: json['summaryUrdu'],
        findings: (json['findings'] as List).map((f) => Finding.fromJson(f)).toList(),
        recommendations: List<String>.from(json['recommendations']),
        recommendationsUrdu: json['recommendationsUrdu'] != null
            ? List<String>.from(json['recommendationsUrdu'])
            : null,
        riskLevel: RiskLevel.values.byName(json['riskLevel']),
        rawResponse: json['rawResponse'],
        imagePath: json['imagePath'],
        pdfPath: json['pdfPath'],
      );
}

class Finding {
  final String parameter;
  final String value;
  final String normalRange;
  final FindingStatus status;
  final String? interpretation;

  Finding({
    required this.parameter,
    required this.value,
    required this.normalRange,
    required this.status,
    this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'parameter': parameter,
        'value': value,
        'normalRange': normalRange,
        'status': status.name,
        'interpretation': interpretation,
      };

  factory Finding.fromJson(Map<String, dynamic> json) => Finding(
        parameter: json['parameter'],
        value: json['value'],
        normalRange: json['normalRange'],
        status: FindingStatus.values.byName(json['status']),
        interpretation: json['interpretation'],
      );
}

enum FindingStatus { normal, low, high, critical, unknown }

enum RiskLevel { low, moderate, high, critical }

extension RiskLevelExtension on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.moderate:
        return 'Moderate Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical';
    }
  }

  String get emoji {
    switch (this) {
      case RiskLevel.low:
        return '✅';
      case RiskLevel.moderate:
        return '⚠️';
      case RiskLevel.high:
        return '🔴';
      case RiskLevel.critical:
        return '🚨';
    }
  }
}

extension FindingStatusExtension on FindingStatus {
  String get label {
    switch (this) {
      case FindingStatus.normal:
        return 'Normal';
      case FindingStatus.low:
        return 'Low';
      case FindingStatus.high:
        return 'High';
      case FindingStatus.critical:
        return 'Critical';
      case FindingStatus.unknown:
        return 'Unknown';
    }
  }
}
