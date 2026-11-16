class ShipmentTimelineEvent {
  final String timestamp;
  final String title;
  final String? description;
  final String? location;
  final bool isCompleted;

  const ShipmentTimelineEvent({
    required this.timestamp,
    required this.title,
    this.description,
    this.location,
    this.isCompleted = true,
  });

  factory ShipmentTimelineEvent.fromJson(Map<String, dynamic> json) {
    return ShipmentTimelineEvent(
      timestamp: (json['timestamp'] ?? json['createdAt'] ?? json['eventTime'] ?? '').toString(),
      title: (json['title'] ?? json['eventType'] ?? json['status'] ?? 'Cập nhật trạng thái').toString(),
      description: (json['description'] ?? json['message'] ?? json['rawPayload'])?.toString(),
      location: json['location']?.toString(),
      isCompleted: json['isCompleted'] as bool? ?? true,
    );
  }
}

class ShipmentTrackingModel {
  final String shipmentId;
  final String? orderId;
  final String? inspectionOrderId;
  final String? leg; // SELLER_TO_CENTER, CENTER_TO_BUYER, CENTER_TO_SELLER, SELLER_TO_BUYER
  final String? orderCode;
  final String trackingNumber;
  final String carrier; // LALAMOVE, GHN
  final String? provider;
  final String? providerStatus;
  final String? shareLink;
  final double? quotedFee;
  final double? actualFee;
  final String? deliveredAt;
  final String? lastError;
  final String? senderName;
  final String? senderPhone;
  final String? senderAddress;
  final String? receiverName;
  final String? receiverPhone;
  final String? receiverAddress;
  final String? driverName;
  final String? driverPhone;
  final String? plateNumber;
  final String status;
  final String statusDescription;
  final String? originAddress;
  final String? destinationAddress;
  final String? estimatedDelivery;
  final List<ShipmentTimelineEvent> timeline;

  const ShipmentTrackingModel({
    required this.shipmentId,
    this.orderId,
    this.inspectionOrderId,
    this.leg,
    this.orderCode,
    required this.trackingNumber,
    required this.carrier,
    this.provider,
    this.providerStatus,
    this.shareLink,
    this.quotedFee,
    this.actualFee,
    this.deliveredAt,
    this.lastError,
    this.senderName,
    this.senderPhone,
    this.senderAddress,
    this.receiverName,
    this.receiverPhone,
    this.receiverAddress,
    this.driverName,
    this.driverPhone,
    this.plateNumber,
    required this.status,
    required this.statusDescription,
    this.originAddress,
    this.destinationAddress,
    this.estimatedDelivery,
    this.timeline = const [],
  });

  String get legLabel {
    switch (leg?.toUpperCase()) {
      case 'SELLER_TO_CENTER':
        return 'Chặng 1: Người bán → Trung tâm Kiểm định';
      case 'CENTER_TO_BUYER':
        return 'Chặng 2: Trung tâm Kiểm định → Người mua';
      case 'CENTER_TO_SELLER':
        return 'Chặng hoàn trả: Trung tâm Kiểm định → Người bán';
      case 'SELLER_TO_BUYER':
        return 'Giao trực tiếp: Người bán → Người mua';
      default:
        return 'Vận chuyển tiêu chuẩn';
    }
  }

  bool get isReturnLeg => leg?.toUpperCase() == 'CENTER_TO_SELLER';

  bool get isDelivered {
    final s = status.toUpperCase();
    return s == 'DELIVERED' || s == 'COMPLETED';
  }

  String getReturnReserveMessage(double? reserveFee) {
    if (isReturnLeg) {
      if (actualFee != null && reserveFee != null && reserveFee > 0) {
        if (actualFee! < reserveFee) {
          final diff = reserveFee - actualFee!;
          return 'Cước trả hàng thực tế (${actualFee!.toStringAsFixed(0)}đ) thấp hơn quỹ dự phòng (${reserveFee.toStringAsFixed(0)}đ). Đã hoàn chênh lệch ${diff.toStringAsFixed(0)}đ.';
        } else if (actualFee! > reserveFee) {
          return 'Cước trả hàng thực tế (${actualFee!.toStringAsFixed(0)}đ) vượt quỹ dự phòng (${reserveFee.toStringAsFixed(0)}đ). Phần phát sinh được sàn hỗ trợ.';
        } else {
          return 'Cước trả hàng thực tế khớp với quỹ dự phòng (${reserveFee.toStringAsFixed(0)}đ).';
        }
      }
      if (reserveFee != null && reserveFee > 0) {
        return 'Sử dụng quỹ dự phòng trả hàng (${reserveFee.toStringAsFixed(0)}đ). Đang chờ đối soát phí thực tế từ đơn vị vận chuyển.';
      }
      return 'Vận đơn hoàn trả thiết bị về cho Người bán sau kiểm định.';
    }

    if (reserveFee != null && reserveFee > 0) {
      return 'Quỹ dự phòng vận chuyển chiều về: ${reserveFee.toStringAsFixed(0)}đ (Hoàn lại 100% nếu kiểm định ĐẠT).';
    }
    return 'Không áp dụng phí dự phòng trả hàng.';
  }

  factory ShipmentTrackingModel.fromJson(Map<String, dynamic> json) {
    final rawTimeline = json['timeline'] ?? json['events'];
    List<ShipmentTimelineEvent> events = [];
    if (rawTimeline is List) {
      events = rawTimeline
          .whereType<Map<String, dynamic>>()
          .map((e) => ShipmentTimelineEvent.fromJson(e))
          .toList();
    }

    final senderAddr = json['senderAddress']?.toString();
    final receiverAddr = (json['receiverAddress'] ?? json['recipientAddress'])?.toString();
    final orderCodeVal = json['orderCode']?.toString();
    final providerVal = json['provider']?.toString();

    return ShipmentTrackingModel(
      shipmentId: json['shipmentId']?.toString() ?? json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      inspectionOrderId: json['inspectionOrderId']?.toString(),
      leg: json['leg']?.toString(),
      orderCode: orderCodeVal,
      trackingNumber: (json['trackingNumber'] ??
              orderCodeVal ??
              json['orderNumber'] ??
              '')
          .toString(),
      carrier: (json['carrier'] ?? providerVal ?? '').toString(),
      provider: providerVal ?? json['carrier']?.toString(),
      providerStatus: json['providerStatus']?.toString(),
      shareLink: json['shareLink']?.toString(),
      quotedFee: (json['quotedFee'] as num?)?.toDouble(),
      actualFee: (json['actualFee'] as num?)?.toDouble(),
      deliveredAt: json['deliveredAt']?.toString(),
      lastError: json['lastError']?.toString(),
      senderName: json['senderName']?.toString(),
      senderPhone: json['senderPhone']?.toString(),
      senderAddress: senderAddr,
      receiverName: (json['receiverName'] ?? json['recipientName'])?.toString(),
      receiverPhone: (json['receiverPhone'] ?? json['recipientPhone'])?.toString(),
      receiverAddress: receiverAddr,
      driverName: (json['driverName'] ?? json['shipperName'])?.toString(),
      driverPhone: (json['driverPhone'] ?? json['shipperPhone'])?.toString(),
      plateNumber: (json['plateNumber'] ?? json['licensePlate'])?.toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      statusDescription: (json['statusDescription'] ?? json['statusText'] ?? '').toString(),
      originAddress: (json['originAddress'] ?? senderAddr)?.toString(),
      destinationAddress: (json['destinationAddress'] ?? receiverAddr)?.toString(),
      estimatedDelivery: (json['estimatedDelivery'] ?? json['estimatedDeliveryTime'])?.toString(),
      timeline: events,
    );
  }
}
