import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import 'package:secondlife_app_seller/core/network/error_handler.dart';
import 'package:secondlife_app_seller/features/auth/presentation/auth_providers.dart';
import '../domain/return_shipping_models.dart';
import '../domain/shipment_models.dart';
import '../domain/tamper_seal_model.dart';

final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ShipmentRepository(client: client);
});

class ShipmentRepository {
  final ApiClient client;

  ShipmentRepository({required this.client});

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw['items'] ?? raw['content'] ?? raw['shipments'] ?? raw['events'];
      if (inner is List) {
        return inner.whereType<Map<String, dynamic>>().toList();
      }
    }
    return [];
  }

  Future<ShipmentTrackingModel> getTracking(String shipmentId) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.shipmentTracking(shipmentId),
    );
    if (response.data == null) {
      throw AppException(message: 'Không tìm thấy thông tin vận chuyển cho đơn $shipmentId');
    }
    final payload = response.data!['data'] ?? response.data!;
    return ShipmentTrackingModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<ShipmentTrackingModel> syncTracking(String shipmentId) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.shipmentSync(shipmentId),
    );
    if (response.data == null) {
      throw AppException(message: 'Đồng bộ hành trình vận chuyển thất bại');
    }
    final payload = response.data!['data'] ?? response.data!;
    return ShipmentTrackingModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<List<ShipmentTrackingModel>> getInspectionShipments(String inspectionOrderId) async {
    final response = await client.get<dynamic>(
      ApiEndpoints.inspectionOrderShipments(inspectionOrderId),
    );
    final list = _extractList(response.data);
    return list.map(ShipmentTrackingModel.fromJson).toList();
  }

  Future<List<ShipmentTrackingModel>> getOrderShipments(String orderId) async {
    final response = await client.get<dynamic>(
      ApiEndpoints.orderShipments(orderId),
    );
    final list = _extractList(response.data);
    return list.map(ShipmentTrackingModel.fromJson).toList();
  }

  Future<List<ShipmentTimelineEvent>> getShipmentEvents(String shipmentId) async {
    final response = await client.get<dynamic>(
      ApiEndpoints.shipmentEvents(shipmentId),
    );
    final list = _extractList(response.data);
    return list.map(ShipmentTimelineEvent.fromJson).toList();
  }

  Future<TamperSealModel?> verifyTamperSeal(String sealId) async {
    final cleanId = sealId.trim();
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.inspectionSealLookup(cleanId),
    );
    if (response.data == null) {
      throw AppException(message: 'Không tìm thấy thông tin tem niêm phong $cleanId');
    }
    final data = response.data!['data'] ?? response.data!;
    return TamperSealModel.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/v1/seller/return-shipping-fees/debt
  Future<SellerReturnShippingDebtModel> getReturnShippingDebt() async {
    try {
      final response = await client.get<Map<String, dynamic>>(
        ApiEndpoints.returnShippingFeesDebt,
      );
      final data = response.data;
      if (data == null) {
        return const SellerReturnShippingDebtModel(sellerId: '', outstandingDebt: 0.0);
      }
      final payload = data['data'] ?? data;
      return SellerReturnShippingDebtModel.fromJson(payload as Map<String, dynamic>);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Lỗi tải nợ cước hoàn hàng: $e');
    }
  }

  /// GET /api/v1/seller/return-shipping-fees
  Future<List<ReturnShippingFeeItemModel>> getMyReturnShippingFees({
    int page = 0,
    int size = 20,
    bool outstandingOnly = false,
  }) async {
    try {
      final response = await client.get<Map<String, dynamic>>(
        '${ApiEndpoints.returnShippingFees}?page=$page&size=$size&outstandingOnly=$outstandingOnly',
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

      return items.map((e) => ReturnShippingFeeItemModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Lỗi tải danh sách cước hoàn hàng: $e');
    }
  }

  /// GET /api/v1/shipments/{shipmentId}/return-shipping-fee
  Future<ReturnShippingFeeItemModel?> getReturnShippingFee(String shipmentId) async {
    try {
      final response = await client.get<Map<String, dynamic>>(
        ApiEndpoints.returnShippingFee(shipmentId),
      );
      final data = response.data;
      if (data == null) return null;
      final payload = data['data'] ?? data;
      return ReturnShippingFeeItemModel.fromJson(payload as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}
