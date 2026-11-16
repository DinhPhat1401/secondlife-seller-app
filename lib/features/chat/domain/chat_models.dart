import 'dart:convert';
import 'package:intl/intl.dart';

String? _parseSystemPayloadToPreview(Map parsed) {
  final type = parsed['type']?.toString().toUpperCase();
  final status = parsed['status']?.toString().toUpperCase();

  if (type == 'OFFER' || type == 'COUNTER_OFFER') {
    final price = (parsed['price'] as num?)?.toDouble();
    final formattedPrice = price != null
        ? NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(price)
        : '';

    if (status == 'ACCEPTED') {
      return formattedPrice.isNotEmpty
          ? 'Đã chấp thuận đề xuất giá: $formattedPrice'
          : 'Đã chấp thuận đề xuất giá';
    } else if (status == 'REJECTED') {
      return formattedPrice.isNotEmpty
          ? 'Đã từ chối đề xuất giá: $formattedPrice'
          : 'Đã từ chối đề xuất giá';
    } else if (status == 'CANCELLED' || status == 'EXPIRED') {
      return 'Đề xuất giá đã hết hiệu lực';
    } else {
      return formattedPrice.isNotEmpty
          ? 'Đề xuất giá mới: $formattedPrice'
          : 'Đã gửi đề xuất giá mới';
    }
  }

  if (type == 'INSPECTION_PROPOSAL') {
    final method = parsed['method']?.toString().toUpperCase();
    final methodLabel = method == 'AT_HOME' ? 'tại nhà' : 'tại Hub';
    final feeSplit = (parsed['feeSplit'] ?? parsed['feePayer'])?.toString().toUpperCase();
    final splitLabel = (feeSplit == 'BUYER_100' || feeSplit == 'BUYER_PAYS')
        ? 'Người mua chịu 100%'
        : (feeSplit == 'SELLER_100' || feeSplit == 'SELLER_PAYS')
            ? 'Người bán chịu 100%'
            : 'Chia đôi 50/50';

    final fee = (parsed['estimatedFeeVnd'] ??
            parsed['totalAtCenterFee'] ??
            parsed['baseInspectionFee'] as num?)
        ?.toDouble();
    final formattedFee = fee != null && fee > 0
        ? ' (${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(fee)})'
        : '';

    if (status == 'ACCEPTED') {
      return 'Đã chấp thuận đề xuất kiểm định $methodLabel';
    } else if (status == 'REJECTED') {
      return 'Đã từ chối đề xuất kiểm định $methodLabel';
    } else if (status == 'CANCELLED') {
      return 'Đề xuất kiểm định đã bị hủy';
    } else {
      return 'Đề xuất kiểm định $methodLabel • $splitLabel$formattedFee';
    }
  }

  if (parsed.containsKey('message') && parsed['message'] != null) {
    return parsed['message'].toString();
  }
  if (parsed.containsKey('text') && parsed['text'] != null) {
    return parsed['text'].toString();
  }

  return 'Thông báo hệ thống';
}

String formatChatPreview(String? rawMessage) {
  if (rawMessage == null || rawMessage.trim().isEmpty) {
    return 'Bắt đầu cuộc trò chuyện...';
  }
  final trimmed = rawMessage.trim();

  // Handle "SYSTEM: {...}" format
  if (trimmed.startsWith('SYSTEM:')) {
    final payloadStr = trimmed.length > 7 ? trimmed.substring(7).trim() : '';
    if (payloadStr.isEmpty) {
      return 'Thông báo hệ thống';
    }
    try {
      final parsed = jsonDecode(payloadStr);
      if (parsed is Map) {
        final preview = _parseSystemPayloadToPreview(parsed);
        if (preview != null) return preview;
      }
    } catch (_) {}
    return 'Thông báo hệ thống';
  }

  // Handle raw JSON format: {"type":"OFFER", ...}
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    try {
      final parsed = jsonDecode(trimmed);
      if (parsed is Map) {
        final preview = _parseSystemPayloadToPreview(parsed);
        if (preview != null) return preview;
      }
    } catch (_) {}
    return 'Thông báo hệ thống';
  }

  return rawMessage;
}

class ChatRoomModel {
  final String id;
  final String postId;
  final String? postTitle;
  final String? postImageUrl;
  final String buyerId;
  final String buyerName;
  final String? buyerAvatar;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatar;
  final String? lastMessage;
  final String? updatedAt;

  const ChatRoomModel({
    required this.id,
    required this.postId,
    this.postTitle,
    this.postImageUrl,
    required this.buyerId,
    this.buyerName = 'Người mua',
    this.buyerAvatar,
    required this.sellerId,
    this.sellerName = 'Người bán',
    this.sellerAvatar,
    this.lastMessage,
    this.updatedAt,
  });

  String get displayLastMessage => formatChatPreview(lastMessage);

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      postTitle: json['postTitle']?.toString() ?? '',
      postImageUrl: json['postImageUrl']?.toString() ?? json['thumbnailUrl']?.toString(),
      buyerId: json['buyerId']?.toString() ?? '',
      buyerName: json['buyerName']?.toString() ?? '',
      buyerAvatar: json['buyerAvatar']?.toString(),
      sellerId: json['sellerId']?.toString() ?? '',
      sellerName: json['sellerName']?.toString() ?? '',
      sellerAvatar: json['sellerAvatar']?.toString(),
      lastMessage: json['lastMessage']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String messageContent;
  final String sentAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageContent,
    required this.sentAt,
  });

  bool get isSystem {
    final trimmed = messageContent.trim();
    if (trimmed.startsWith('SYSTEM:')) return true;
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final parsed = jsonDecode(trimmed);
        if (parsed is Map && parsed.containsKey('type')) return true;
      } catch (_) {}
    }
    return false;
  }

  String get cleanText => formatChatPreview(messageContent);

  Map<String, dynamic>? get systemPayload {
    final trimmed = messageContent.trim();
    String jsonStr = '';
    if (trimmed.startsWith('SYSTEM:')) {
      jsonStr = trimmed.substring(7).trim();
    } else if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      jsonStr = trimmed;
    }
    if (jsonStr.isEmpty) return null;
    try {
      final parsed = jsonDecode(jsonStr);
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
    } catch (_) {}
    return null;
  }

  String? get systemType => systemPayload?['type']?.toString().toUpperCase();

  bool get isOffer {
    final type = systemType;
    return type == 'OFFER' || type == 'COUNTER_OFFER';
  }

  Map<String, dynamic>? get offerPayload => isOffer ? systemPayload : null;

  double? get offerPrice {
    final payload = offerPayload;
    if (payload != null && payload['price'] != null) {
      return (payload['price'] as num).toDouble();
    }
    return null;
  }

  String? get offerNegotiationId {
    final payload = offerPayload;
    return payload?['negotiationId']?.toString() ?? payload?['id']?.toString();
  }

  String? get offerStatus {
    final payload = offerPayload;
    return payload?['status']?.toString().toUpperCase();
  }

  bool get isInspectionProposal {
    return systemType == 'INSPECTION_PROPOSAL';
  }

  Map<String, dynamic>? get inspectionProposalPayload =>
      isInspectionProposal ? systemPayload : null;

  String? get inspectionProposalStatus =>
      inspectionProposalPayload?['status']?.toString().toUpperCase();

  String? get inspectionProposalOrderId =>
      inspectionProposalPayload?['orderId']?.toString();

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      messageContent: json['messageContent']?.toString() ?? '',
      sentAt: json['sentAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}
