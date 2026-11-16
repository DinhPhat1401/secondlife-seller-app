class SellerReputationModel {
  final String sellerId;
  final double? score;
  final int goodTransactions;
  final int badTransactions;
  final int evaluatedOrders;
  final int minimumEvaluatedOrders;
  final String assessmentStatus;
  final int confirmedIncidents;
  final int seriousIncidents;
  final bool sellingRestricted;
  final String? warningCode;
  final DateTime? updatedAt;
  final String? formulaVersion;
  final int sellerCancellationOrders;
  final int sellerReturnFaultOrders;
  final int nonFulfillmentOrders;
  final double? nonFulfillmentRate;
  final int handoverEvaluatedOrders;
  final int lateHandoverOrders;
  final double? lateHandoverRate;
  final double? transactionScore;
  final double? confirmationPenaltyPoints;

  const SellerReputationModel({
    required this.sellerId,
    this.score,
    this.goodTransactions = 0,
    this.badTransactions = 0,
    this.evaluatedOrders = 0,
    this.minimumEvaluatedOrders = 5,
    this.assessmentStatus = 'NO_TRANSACTIONS',
    this.confirmedIncidents = 0,
    this.seriousIncidents = 0,
    this.sellingRestricted = false,
    this.warningCode,
    this.updatedAt,
    this.formulaVersion,
    this.sellerCancellationOrders = 0,
    this.sellerReturnFaultOrders = 0,
    this.nonFulfillmentOrders = 0,
    this.nonFulfillmentRate,
    this.handoverEvaluatedOrders = 0,
    this.lateHandoverOrders = 0,
    this.lateHandoverRate,
    this.transactionScore,
    this.confirmationPenaltyPoints,
  });

  factory SellerReputationModel.fromJson(Map<String, dynamic> json) {
    return SellerReputationModel(
      sellerId: json['sellerId']?.toString() ?? '',
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      goodTransactions: (json['goodTransactions'] as num?)?.toInt() ?? 0,
      badTransactions: (json['badTransactions'] as num?)?.toInt() ?? 0,
      evaluatedOrders: (json['evaluatedOrders'] as num?)?.toInt() ?? 0,
      minimumEvaluatedOrders: (json['minimumEvaluatedOrders'] as num?)?.toInt() ?? 5,
      assessmentStatus: json['assessmentStatus']?.toString() ?? 'NO_TRANSACTIONS',
      confirmedIncidents: (json['confirmedIncidents'] as num?)?.toInt() ?? 0,
      seriousIncidents: (json['seriousIncidents'] as num?)?.toInt() ?? 0,
      sellingRestricted: json['sellingRestricted'] == true,
      warningCode: json['warningCode']?.toString(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      formulaVersion: json['formulaVersion']?.toString(),
      sellerCancellationOrders: (json['sellerCancellationOrders'] as num?)?.toInt() ?? 0,
      sellerReturnFaultOrders: (json['sellerReturnFaultOrders'] as num?)?.toInt() ?? 0,
      nonFulfillmentOrders: (json['nonFulfillmentOrders'] as num?)?.toInt() ?? 0,
      nonFulfillmentRate: json['nonFulfillmentRate'] != null ? (json['nonFulfillmentRate'] as num).toDouble() : null,
      handoverEvaluatedOrders: (json['handoverEvaluatedOrders'] as num?)?.toInt() ?? 0,
      lateHandoverOrders: (json['lateHandoverOrders'] as num?)?.toInt() ?? 0,
      lateHandoverRate: json['lateHandoverRate'] != null ? (json['lateHandoverRate'] as num).toDouble() : null,
      transactionScore: json['transactionScore'] != null ? (json['transactionScore'] as num).toDouble() : null,
      confirmationPenaltyPoints: json['confirmationPenaltyPoints'] != null ? (json['confirmationPenaltyPoints'] as num).toDouble() : null,
    );
  }

  /// Huy hiệu uy tín dựa trên điểm
  String get tierName {
    if (score == null) return 'Chưa xếp hạng';
    if (score! >= 90) return 'Người bán Xuất sắc (Kim cương)';
    if (score! >= 80) return 'Người bán Uy tín (Vàng)';
    if (score! >= 70) return 'Người bán Tiêu chuẩn (Bạc)';
    if (score! >= 50) return 'Cần cải thiện (Đồng)';
    return 'Rủi ro cao';
  }

  /// Trạng thái đánh giá
  String get statusDisplay {
    switch (assessmentStatus) {
      case 'NO_TRANSACTIONS':
        return 'Chưa có đơn hàng hoàn tất';
      case 'INSUFFICIENT_EVIDENCE':
        return 'Chưa đủ đơn tối thiểu ($evaluatedOrders/$minimumEvaluatedOrders đơn)';
      case 'EVALUATED':
        return 'Đã xếp hạng uy tín';
      default:
        return assessmentStatus;
    }
  }
}

class ReputationHistoryItemModel {
  final String id;
  final String eventType;
  final String? orderId;
  final String? reportId;
  final int goodBefore;
  final int badBefore;
  final int goodAfter;
  final int badAfter;
  final double? scoreBefore;
  final double? scoreAfter;
  final double? penaltyBefore;
  final double? penaltyAfter;
  final DateTime createdAt;
  final String? formulaVersion;

  const ReputationHistoryItemModel({
    required this.id,
    required this.eventType,
    this.orderId,
    this.reportId,
    this.goodBefore = 0,
    this.badBefore = 0,
    this.goodAfter = 0,
    this.badAfter = 0,
    this.scoreBefore,
    this.scoreAfter,
    this.penaltyBefore,
    this.penaltyAfter,
    required this.createdAt,
    this.formulaVersion,
  });

  factory ReputationHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return ReputationHistoryItemModel(
      id: json['id']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      reportId: json['reportId']?.toString(),
      goodBefore: (json['goodBefore'] as num?)?.toInt() ?? 0,
      badBefore: (json['badBefore'] as num?)?.toInt() ?? 0,
      goodAfter: (json['goodAfter'] as num?)?.toInt() ?? 0,
      badAfter: (json['badAfter'] as num?)?.toInt() ?? 0,
      scoreBefore: json['scoreBefore'] != null ? (json['scoreBefore'] as num).toDouble() : null,
      scoreAfter: json['scoreAfter'] != null ? (json['scoreAfter'] as num).toDouble() : null,
      penaltyBefore: json['penaltyBefore'] != null ? (json['penaltyBefore'] as num).toDouble() : null,
      penaltyAfter: json['penaltyAfter'] != null ? (json['penaltyAfter'] as num).toDouble() : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      formulaVersion: json['formulaVersion']?.toString(),
    );
  }

  String get eventTitle {
    switch (eventType) {
      case 'ORDER_SUCCESSFUL':
        return 'Giao dịch thành công (+ điểm)';
      case 'ORDER_CANCELLED_BY_SELLER':
        return 'Người bán hủy đơn hàng (- điểm)';
      case 'INSPECTION_FAILED':
        return 'Kiểm định trạm thất bại (- điểm)';
      case 'LATE_HANDOVER_PENALTY':
        return 'Bàn giao chậm trễ (Trừ phạt)';
      case 'BUYER_REPORT_CONFIRMED':
        return 'Bị báo cáo vi phạm xác thực';
      case 'ADMIN_LIFT_RESTRICTION':
        return 'Admin gỡ bỏ hạn chế tài khoản';
      default:
        return eventType;
    }
  }

  double? get scoreChange {
    if (scoreAfter == null || scoreBefore == null) return null;
    return scoreAfter! - scoreBefore!;
  }
}
