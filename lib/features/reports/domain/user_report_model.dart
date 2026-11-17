class SellerUserReportModel {
  const SellerUserReportModel({
    required this.id,
    required this.reasonCode,
    required this.description,
    required this.status,
    this.postId,
    this.orderId,
    this.evidenceUrls = const [],
    this.responsibleParty,
    this.decisionReason,
    this.resolutionAction,
    this.refundAmount,
    this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String? postId;
  final String? orderId;
  final String reasonCode;
  final String description;
  final String status;
  final List<String> evidenceUrls;
  final String? responsibleParty;
  final String? decisionReason;
  final String? resolutionAction;
  final double? refundAmount;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  factory SellerUserReportModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) =>
        DateTime.tryParse(json[key]?.toString() ?? '');

    return SellerUserReportModel(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString(),
      orderId: json['orderId']?.toString(),
      reasonCode: json['reasonCode']?.toString() ?? 'OTHER',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      evidenceUrls: (json['evidenceUrls'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      responsibleParty: json['responsibleParty']?.toString(),
      decisionReason: json['decisionReason']?.toString(),
      resolutionAction: json['resolutionAction']?.toString(),
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      createdAt: parseDate('createdAt'),
      resolvedAt: parseDate('resolvedAt'),
    );
  }
}
