import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import 'package:secondlife_app_seller/core/network/error_handler.dart';
import '../domain/reputation_models.dart';

class ReputationRepository {
  final ApiClient client;

  ReputationRepository({required this.client});

  /// Lấy thông tin điểm uy tín hiện tại của chính người bán đang đăng nhập
  Future<SellerReputationModel> getMyReputation() async {
    try {
      final response = await client.get<Map<String, dynamic>>(ApiEndpoints.sellerReputationMe);
      final data = response.data;
      if (data == null) {
        throw AppException(message: 'Không nhận được dữ liệu uy tín từ máy chủ');
      }
      final payload = data['data'] ?? data;
      return SellerReputationModel.fromJson(payload as Map<String, dynamic>);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Lỗi tải điểm uy tín: $e');
    }
  }

  /// Lấy lịch sử biến động điểm uy tín và các sự cố vi phạm
  Future<List<ReputationHistoryItemModel>> getMyReputationHistory({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await client.get<Map<String, dynamic>>(
        '${ApiEndpoints.sellerReputationHistory}?page=$page&size=$size',
      );
      final data = response.data;
      if (data == null) return [];
      final payload = data['data'] ?? data;

      List items = [];
      if (payload is Map && payload.containsKey('content') && payload['content'] is List) {
        items = payload['content'] as List;
      } else if (payload is Map && payload.containsKey('items') && payload['items'] is List) {
        items = payload['items'] as List;
      } else if (payload is List) {
        items = payload;
      }

      return items.map((e) => ReputationHistoryItemModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Lỗi tải lịch sử uy tín: $e');
    }
  }
}
