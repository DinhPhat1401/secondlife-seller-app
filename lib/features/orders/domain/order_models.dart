import 'dart:convert';

enum OrderStatus {
  pending('PENDING', 'Chờ xác nhận'),
  pendingFinalPayment('PENDING_FINAL_PAYMENT', 'Chờ buyer thanh toán (6h)'),
  confirmed('CONFIRMED', 'Đã xác nhận'),
  shipping('SHIPPING', 'Đang vận chuyển'),
  delivered('DELIVERED', 'Đã giao thành công'),
  expired('EXPIRED', 'Hết hạn thanh toán'),
  cancelled('CANCELLED', 'Đã hủy'),
  unknown('UNKNOWN', 'Không xác định');

  final String code;
  final String label;

  const OrderStatus(this.code, this.label);

  static OrderStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'PENDING_FINAL_PAYMENT':
      case 'AWAITING_PAYMENT':
        return OrderStatus.pendingFinalPayment;
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'SHIPPING':
      case 'SHIPPED':
        return OrderStatus.shipping;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'EXPIRED':
        return OrderStatus.expired;
      case 'CANCELLED':
      case 'CANCELED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unknown;
    }
  }
}

class DeliveryAddressModel {
  final String name;
  final String phone;
  final String address;
  final String? wardName;
  final String? provinceName;

  const DeliveryAddressModel({
    required this.name,
    required this.phone,
    required this.address,
    this.wardName,
    this.provinceName,
  });

  factory DeliveryAddressModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressModel(
      name: json['name'] ?? json['recipientName'] ?? '',
      phone: json['phone'] ?? json['recipientPhone'] ?? '',
      address: json['address'] ?? json['detailAddress'] ?? '',
      wardName: json['wardName'],
      provinceName: json['provinceName'],
    );
  }

  String get fullAddressText {
    final parts = [
      address,
      wardName,
      provinceName,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }
}

class SellerOrderModel {
  final String id;
  final String? orderNumber;
  final String? postId;
  final String postTitle;
  final String? postThumbnail;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final DeliveryAddressModel? deliveryAddress;
  final double itemPrice;
  final double shippingFee;
  final double platformFee;
  final double netPayout;
  final OrderStatus status;
  final DateTime? finalPaymentDeadline;
  final bool hasInspection;
  final String? shipmentId;
  final String? createdAt;
  final String? updatedAt;

  const SellerOrderModel({
    required this.id,
    this.orderNumber,
    this.postId,
    required this.postTitle,
    this.postThumbnail,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    this.deliveryAddress,
    required this.itemPrice,
    this.shippingFee = 0.0,
    this.platformFee = 0.0,
    required this.netPayout,
    required this.status,
    this.finalPaymentDeadline,
    this.hasInspection = false,
    this.shipmentId,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerOrderModel.fromJson(Map<String, dynamic> json) {
    final itemPrice =
        (json['finalPrice'] as num?)?.toDouble() ??
        (json['itemPrice'] as num?)?.toDouble() ??
        (json['totalPaid'] as num?)?.toDouble() ??
        (json['totalAmount'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0.0;
    final platformFee =
        (json['platformFee'] as num?)?.toDouble() ??
        (json['commissionFee'] as num?)?.toDouble() ??
        0.0;
    final shippingFee = (json['shippingFee'] as num?)?.toDouble() ?? 0.0;
    final netPayout =
        (json['netPayout'] as num?)?.toDouble() ?? (itemPrice - platformFee);

    return SellerOrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber'] ?? json['code'],
      postId: json['postId']?.toString(),
      postTitle:
          json['postTitle'] ??
          json['productTitle'] ??
          json['listingTitle'] ??
          '',
      postThumbnail:
          json['postThumbnail'] ?? json['productImageUrl'] ?? json['imageUrl'],
      buyerId: json['buyerId']?.toString() ?? '',
      buyerName: json['buyerName'] ?? json['recipientName'] ?? '',
      buyerPhone: json['buyerPhone'] ?? json['recipientPhone'] ?? '',
      deliveryAddress: json['deliveryAddress'] != null
          ? DeliveryAddressModel.fromJson(
              json['deliveryAddress'] as Map<String, dynamic>,
            )
          : null,
      itemPrice: itemPrice,
      shippingFee: shippingFee,
      platformFee: platformFee,
      netPayout: netPayout,
      status: OrderStatus.fromString(json['status'] as String?),
      finalPaymentDeadline: DateTime.tryParse(
        json['finalPaymentDeadline']?.toString() ?? '',
      ),
      hasInspection: json['hasInspection'] as bool? ?? false,
      shipmentId: json['shipmentId']?.toString(),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'],
    );
  }

  bool get isPendingFinalPayment => status == OrderStatus.pendingFinalPayment;
  bool get isExpiredOrForfeited =>
      status == OrderStatus.expired ||
      (status == OrderStatus.cancelled && hasInspection);
}

List<String> parseEvidencePhotosFromNote(String? note) {
  if (note == null || note.isEmpty) return const [];
  final match = RegExp(r'\[Photos:\s*(\[[\s\S]*?\])\]').firstMatch(note);
  if (match == null) return const [];
  try {
    final decoded = jsonDecode(match.group(1)!);
    if (decoded is List) {
      return decoded
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
  } catch (_) {}
  return const [];
}

class SellerInspectionOrderModel {
  final String id;
  final String postId;
  final String postTitle;
  final List<String> postImageUrls;
  final double postPrice;
  final String buyerId;
  final String buyerName;
  final String? buyerEmail;
  final String? buyerPhone;
  final String? buyerAddress;
  final String sellerId;
  final String? sellerName;
  final String? sellerPhone;
  final String? sellerAddress;
  final String? inspectorId;
  final String? inspectorName;
  final String? inspectorPhone;
  final String? inspectorAvatarUrl;
  final String orderType; // 'AT_HOME' | 'AT_CENTER'
  final String feePayer; // 'BUYER_PAYS' | 'SELLER_PAYS' | 'SPLIT_50_50'
  final String status;
  final String? customerStatus;
  final String? note;

  // Fee & Reserve Fields
  final double inspectionFee;
  final double shippingFee;
  final double? travelDistanceKm;
  final double? travelFee;
  final double returnShippingReserveFee;
  final double atCenterTotalFee;
  final double? buyerCommitmentDeposit;
  final double? initialDepositPaid;
  final double buyerFeeShare;
  final double sellerFeeShare;

  // Payment & Settlement Timestamps
  final DateTime? approvalDeadline;
  final DateTime? paymentDeadline;
  final DateTime? buyerPaidAt;
  final DateTime? sellerPaidAt;
  final DateTime? feeSettledAt;
  final DateTime? finalPaymentDeadline;
  final DateTime? finalPaymentPaidAt;
  final double? finalItemPrice;
  final double? finalShippingFee;
  final String? linkedOrderId;

  // AT_HOME Check-in & Schedule
  final DateTime? appointmentScheduledAt;
  final String? homeCheckInCode;
  final DateTime? homeCheckedInAt;

  // Inspection Result & Evidence
  final double? conditionScore;
  final String? conditionGrade;
  final String? tamperSealId;
  final String? barcode;
  final String? checklistResultJson;
  final List<String> evidencePhotoUrls;
  final String? videoProofUrl;
  final String? unboxingVideoUrl;

  // Appeal Fields
  final String?
  appealStatus; // 'NONE' | 'PENDING_REVIEW' | 'UPHELD' | 'OVERTURNED'
  final String? appealReason;
  final DateTime? appealDeadline;
  final bool? reputationPenaltyApplied;
  final int? reputationPenaltyPoints;

  // Inspection Center Metadata
  final String? inspectionCenterId;
  final String? inspectionCenterName;
  final String? inspectionCenterAddress;
  final String? inspectionCenterPhone;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  const SellerInspectionOrderModel({
    required this.id,
    required this.postId,
    required this.postTitle,
    this.postImageUrls = const [],
    this.postPrice = 0.0,
    required this.buyerId,
    required this.buyerName,
    this.buyerEmail,
    this.buyerPhone,
    this.buyerAddress,
    required this.sellerId,
    this.sellerName,
    this.sellerPhone,
    this.sellerAddress,
    this.inspectorId,
    this.inspectorName,
    this.inspectorPhone,
    this.inspectorAvatarUrl,
    required this.orderType,
    required this.feePayer,
    required this.status,
    this.customerStatus,
    this.note,
    this.inspectionFee = 0.0,
    this.shippingFee = 0.0,
    this.travelDistanceKm,
    this.travelFee,
    this.returnShippingReserveFee = 0.0,
    this.atCenterTotalFee = 0.0,
    this.buyerCommitmentDeposit,
    this.initialDepositPaid,
    this.buyerFeeShare = 0.0,
    this.sellerFeeShare = 0.0,
    this.approvalDeadline,
    this.paymentDeadline,
    this.buyerPaidAt,
    this.sellerPaidAt,
    this.feeSettledAt,
    this.finalPaymentDeadline,
    this.finalPaymentPaidAt,
    this.finalItemPrice,
    this.finalShippingFee,
    this.linkedOrderId,
    this.appointmentScheduledAt,
    this.homeCheckInCode,
    this.homeCheckedInAt,
    this.conditionScore,
    this.conditionGrade,
    this.tamperSealId,
    this.barcode,
    this.checklistResultJson,
    this.evidencePhotoUrls = const [],
    this.videoProofUrl,
    this.unboxingVideoUrl,
    this.appealStatus,
    this.appealReason,
    this.appealDeadline,
    this.reputationPenaltyApplied,
    this.reputationPenaltyPoints,
    this.inspectionCenterId,
    this.inspectionCenterName,
    this.inspectionCenterAddress,
    this.inspectionCenterPhone,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    return DateTime.tryParse(val.toString());
  }

  factory SellerInspectionOrderModel.fromJson(Map<String, dynamic> json) {
    final rawPhotos =
        json['evidencePhotoUrls'] ??
        json['proofPhotos'] ??
        json['inspectorPhotos'];
    List<String> photos = [];
    if (rawPhotos is List) {
      photos = rawPhotos
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    if (photos.isEmpty) {
      photos = parseEvidencePhotosFromNote(json['note']?.toString());
    }

    final rawImages =
        json['postImageUrls'] ?? json['postImages'] ?? json['images'];
    List<String> postImages = [];
    if (rawImages is List) {
      postImages = rawImages
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList();
    } else if (json['postThumbnail'] != null) {
      postImages = [json['postThumbnail'].toString()];
    }

    final inspFee = _parseDouble(
      json['inspectionFee'] ?? json['baseInspectionFee'],
    );
    final shipFee = _parseDouble(
      json['shippingFee'] ?? json['shippingToCenterFee'],
    );
    final reserveFee = _parseDouble(json['returnShippingReserveFee']);
    final centerTotal = json['atCenterTotalFee'] != null
        ? _parseDouble(json['atCenterTotalFee'])
        : (inspFee + shipFee + reserveFee);

    return SellerInspectionOrderModel(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      postTitle:
          json['postTitle']?.toString() ??
          json['productTitle']?.toString() ??
          '',
      postImageUrls: postImages,
      postPrice: _parseDouble(
        json['postPrice'] ?? json['productPrice'] ?? json['price'],
      ),
      buyerId: json['buyerId']?.toString() ?? '',
      buyerName: json['buyerName']?.toString() ?? '',
      buyerEmail: json['buyerEmail']?.toString(),
      buyerPhone: json['buyerPhone']?.toString(),
      buyerAddress: json['buyerAddress']?.toString(),
      sellerId: json['sellerId']?.toString() ?? '',
      sellerName: json['sellerName']?.toString(),
      sellerPhone: json['sellerPhone']?.toString(),
      sellerAddress: json['sellerAddress']?.toString(),
      inspectorId: json['inspectorId']?.toString(),
      inspectorName: json['inspectorName']?.toString(),
      inspectorPhone: json['inspectorPhone']?.toString(),
      inspectorAvatarUrl: json['inspectorAvatarUrl']?.toString(),
      orderType: json['orderType']?.toString() ?? 'AT_CENTER',
      feePayer: json['feePayer']?.toString() ?? 'BUYER_PAYS',
      status: json['status']?.toString() ?? 'WAITING_SELLER_APPROVAL',
      customerStatus: json['customerStatus']?.toString(),
      note: json['note']?.toString(),
      inspectionFee: inspFee,
      shippingFee: shipFee,
      travelDistanceKm: json['travelDistanceKm'] != null
          ? _parseDouble(json['travelDistanceKm'])
          : null,
      travelFee: json['travelFee'] != null
          ? _parseDouble(json['travelFee'])
          : null,
      returnShippingReserveFee: reserveFee,
      atCenterTotalFee: centerTotal,
      buyerCommitmentDeposit: json['buyerCommitmentDeposit'] != null
          ? _parseDouble(json['buyerCommitmentDeposit'])
          : null,
      initialDepositPaid: json['initialDepositPaid'] != null
          ? _parseDouble(json['initialDepositPaid'])
          : null,
      buyerFeeShare: _parseDouble(json['buyerFeeShare']),
      sellerFeeShare: _parseDouble(json['sellerFeeShare']),
      approvalDeadline: _parseDate(json['approvalDeadline']),
      paymentDeadline: _parseDate(json['paymentDeadline']),
      buyerPaidAt: _parseDate(json['buyerPaidAt']),
      sellerPaidAt: _parseDate(json['sellerPaidAt']),
      feeSettledAt: _parseDate(json['feeSettledAt']),
      finalPaymentDeadline: _parseDate(json['finalPaymentDeadline']),
      finalPaymentPaidAt: _parseDate(json['finalPaymentPaidAt']),
      finalItemPrice: json['finalItemPrice'] != null
          ? _parseDouble(json['finalItemPrice'])
          : null,
      finalShippingFee: json['finalShippingFee'] != null
          ? _parseDouble(json['finalShippingFee'])
          : null,
      linkedOrderId: json['linkedOrderId']?.toString(),
      appointmentScheduledAt: _parseDate(json['appointmentScheduledAt']),
      homeCheckInCode: json['homeCheckInCode']?.toString(),
      homeCheckedInAt: _parseDate(json['homeCheckedInAt']),
      conditionScore: json['conditionScore'] != null
          ? _parseDouble(json['conditionScore'])
          : null,
      conditionGrade: json['conditionGrade']?.toString(),
      tamperSealId: json['tamperSealId']?.toString(),
      barcode: json['barcode']?.toString(),
      checklistResultJson: json['checklistResultJson']?.toString(),
      evidencePhotoUrls: photos,
      videoProofUrl: json['videoProofUrl']?.toString(),
      unboxingVideoUrl: json['unboxingVideoUrl']?.toString(),
      appealStatus: json['appealStatus']?.toString() ?? 'NONE',
      appealReason: json['appealReason']?.toString(),
      appealDeadline: _parseDate(json['appealDeadline']),
      reputationPenaltyApplied: json['reputationPenaltyApplied'] as bool?,
      reputationPenaltyPoints: json['reputationPenaltyPoints'] as int?,
      inspectionCenterId: json['inspectionCenterId']?.toString(),
      inspectionCenterName: json['inspectionCenterName']?.toString(),
      inspectionCenterAddress: json['inspectionCenterAddress']?.toString(),
      inspectionCenterPhone: json['inspectionCenterPhone']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      completedAt: _parseDate(json['completedAt']),
    );
  }

  bool get isAtCenter => orderType.toUpperCase() == 'AT_CENTER';
  bool get isAtHome => orderType.toUpperCase() == 'AT_HOME';
  bool get canSellerRespond => status == 'WAITING_SELLER_APPROVAL';
  bool get isPaymentDeadlineExpired =>
      paymentDeadline != null && paymentDeadline!.isBefore(DateTime.now());
  bool get isSellerFeePaymentPending =>
      status == 'WAITING_FEE_PAYMENT' &&
      sellerFeeShare > 0 &&
      sellerPaidAt == null &&
      !isPaymentDeadlineExpired;
  bool get canRequestHomeCheckInCode =>
      isAtHome &&
      const [
        'CONFIRMED_PENDING_DISPATCH',
        'DISPATCHED',
        'SCHEDULED',
        'INSPECTING',
      ].contains(status);
  bool get canSellerAppeal =>
      status == 'FAILED' &&
      (appealStatus == null || appealStatus == 'NONE') &&
      appealDeadline != null &&
      appealDeadline!.isAfter(DateTime.now());

  String get feePayerLabel {
    switch (feePayer.toUpperCase()) {
      case 'BUYER_PAYS':
        return 'Người mua chịu toàn bộ';
      case 'SELLER_PAYS':
        return 'Người bán chịu toàn bộ';
      case 'SPLIT_50_50':
        return 'Chia đều 50 / 50';
      default:
        return feePayer;
    }
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'WAITING_SELLER_APPROVAL':
        return 'Chờ bạn phê duyệt';
      case 'WAITING_BUYER_APPROVAL':
        return 'Chờ người mua xác nhận';
      case 'WAITING_FEE_PAYMENT':
        return 'Chờ nộp phí kiểm định';
      case 'CONFIRMED_PENDING_DISPATCH':
        return 'Đã đủ phí - Chờ gửi hàng';
      case 'DISPATCHED':
        return isAtHome ? 'Đã phân công KTV' : 'Đang chuyển tới trung tâm';
      case 'SCHEDULED':
        return 'Đã lên lịch hẹn';
      case 'INSPECTING':
        return 'Đang thực hiện kiểm định';
      case 'PASSED':
        return 'Kiểm định ĐẠT';
      case 'FAILED':
        return 'Kiểm định KHÔNG ĐẠT';
      case 'CANCELLED':
        return 'Đã hủy kiểm định';
      case 'DELIVERING_TO_BUYER':
        return 'Đang giao tới người mua';
      default:
        return status;
    }
  }
}
