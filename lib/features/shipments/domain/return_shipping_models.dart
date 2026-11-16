class SellerReturnShippingDebtModel {
  final String sellerId;
  final double outstandingDebt;

  const SellerReturnShippingDebtModel({
    required this.sellerId,
    this.outstandingDebt = 0.0,
  });

  factory SellerReturnShippingDebtModel.fromJson(Map<String, dynamic> json) {
    return SellerReturnShippingDebtModel(
      sellerId: json['sellerId']?.toString() ?? '',
      outstandingDebt: json['outstandingDebt'] != null
          ? (json['outstandingDebt'] as num).toDouble()
          : 0.0,
    );
  }
}

class ReturnShippingFeeItemModel {
  final String shipmentId;
  final String orderId;
  final String? reportId;
  final String? sellerId;
  final String status;
  final double feeAmount;
  final double collectedAmount;
  final double debtAmount;
  final DateTime createdAt;
  final DateTime? assessedAt;

  const ReturnShippingFeeItemModel({
    required this.shipmentId,
    required this.orderId,
    this.reportId,
    this.sellerId,
    this.status = 'PENDING_FEE',
    this.feeAmount = 0.0,
    this.collectedAmount = 0.0,
    this.debtAmount = 0.0,
    required this.createdAt,
    this.assessedAt,
  });

  factory ReturnShippingFeeItemModel.fromJson(Map<String, dynamic> json) {
    return ReturnShippingFeeItemModel(
      shipmentId: json['shipmentId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      reportId: json['reportId']?.toString(),
      sellerId: json['sellerId']?.toString(),
      status: json['status']?.toString() ?? 'PENDING_FEE',
      feeAmount: json['feeAmount'] != null ? (json['feeAmount'] as num).toDouble() : 0.0,
      collectedAmount: json['collectedAmount'] != null ? (json['collectedAmount'] as num).toDouble() : 0.0,
      debtAmount: json['debtAmount'] != null ? (json['debtAmount'] as num).toDouble() : 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      assessedAt: json['assessedAt'] != null ? DateTime.tryParse(json['assessedAt'].toString()) : null,
    );
  }

  bool get isOutstanding => status == 'OUTSTANDING' || debtAmount > 0;

  String get statusDisplay {
    switch (status) {
      case 'PAID':
        return 'Đã thanh toán';
      case 'OUTSTANDING':
        return 'Chưa thanh toán (Còn nợ)';
      case 'PENDING_FEE':
      default:
        return 'Chờ thẩm định cước';
    }
  }
}
