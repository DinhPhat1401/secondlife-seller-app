import 'dart:convert';
import 'package:intl/intl.dart';

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
        final type = parsed['type']?.toString().toUpperCase();
        final status = parsed['status']?.toString().toUpperCase();
        final price = (parsed['price'] as num?)?.toDouble();
        final formattedPrice = price != null
            ? NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(price)
            : '';

        if (type == 'OFFER' || type == 'COUNTER_OFFER') {
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
      }
    } catch (_) {}
    return payloadStr;
  }

  // Handle raw JSON format: {"type":"OFFER", ...}
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    try {
      final parsed = jsonDecode(trimmed);
      if (parsed is Map) {
        final type = parsed['type']?.toString().toUpperCase();
        final status = parsed['status']?.toString().toUpperCase();
        final price = (parsed['price'] as num?)?.toDouble();
        final formattedPrice = price != null
            ? NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(price)
            : '';

        if (type == 'OFFER' || type == 'COUNTER_OFFER') {
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
      }
    } catch (_) {}
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
      postTitle: json['postTitle']?.toString() ?? 'Sản phẩm gia dụng',
      postImageUrl: json['postImageUrl']?.toString() ?? json['thumbnailUrl']?.toString(),
      buyerId: json['buyerId']?.toString() ?? '',
      buyerName: json['buyerName']?.toString() ?? 'Khách hàng',
      buyerAvatar: json['buyerAvatar']?.toString(),
      sellerId: json['sellerId']?.toString() ?? '',
      sellerName: json['sellerName']?.toString() ?? 'Cửa hàng của tôi',
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

  bool get isSystem => messageContent.trim().startsWith('SYSTEM:');

  String get cleanText => formatChatPreview(messageContent);

  bool get isOffer {
    if (!isSystem) return false;
    final raw = messageContent.trim().substring(7).trim();
    try {
      final parsed = jsonDecode(raw);
      return parsed is Map && parsed['type'] == 'OFFER';
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? get offerPayload {
    if (!isOffer) return null;
    final raw = messageContent.trim().substring(7).trim();
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {}
    return null;
  }

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
