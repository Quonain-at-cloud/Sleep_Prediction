class FactorProgress {
  final String factorName; // e.g., "Noise Levels (80 dB)"
  final String status;     // e.g., "Improved" or "Worsened"
  final String change;     // e.g., "by 5%"

  FactorProgress({
    required this.factorName,
    required this.status,
    required this.change,
  });

  factory FactorProgress.fromJson(Map<String, dynamic> json) {
    return FactorProgress(
      factorName: json['factorName'] as String,
      status: json['status'] as String,
      change: json['change'] as String,
    );
  }
}
