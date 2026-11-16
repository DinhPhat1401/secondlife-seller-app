import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import 'package:secondlife_app_seller/core/network/api_response.dart';
import '../domain/order_models.dart';

class OrderRepository {
  final ApiClient client;

  OrderRepository({required this.client});

  Future<PageResponse<SellerOrderModel>> getSellerOrders({
    OrderStatus? status,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (status != null && status != OrderStatus.unknown) {
      queryParams['status'] = status.code;
    }

    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.ordersSeller,
      queryParameters: queryParams,
    );

    return PageResponse.fromJson(
      response.data ?? {},
      (json) => SellerOrderModel.fromJson(json),
    );
  }

  Future<SellerOrderModel> markAsShipped(String orderId) async {
    final response = await client.put<Map<String, dynamic>>(
      '/api/v1/orders/$orderId/shipped',
    );
    return SellerOrderModel.fromJson(response.data!);
  }

  Future<SellerOrderModel> cancelOrder(String orderId, [String? reason]) async {
    final response = await client.put<Map<String, dynamic>>(
      '/api/v1/orders/$orderId/cancel',
      data: reason != null ? {'reason': reason} : null,
    );
    return SellerOrderModel.fromJson(response.data!);
  }

  Future<Map<String, dynamic>> getCommission(String orderId) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.orderCommission(orderId),
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getSettlement(String orderId) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.orderSettlement(orderId),
    );
    return response.data ?? {};
  }

  Future<PageResponse<SellerInspectionOrderModel>> getSellerInspectionOrders({
    int page = 0,
    int size = 20,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.inspectionMySellerOrders,
      queryParameters: {'page': page, 'size': size},
    );
    final payload = response.data?['data'] ?? response.data ?? {};
    return PageResponse.fromJson(
      payload as Map<String, dynamic>,
      (json) => SellerInspectionOrderModel.fromJson(json),
    );
  }

  Future<SellerInspectionOrderModel> getInspectionOrderDetail(String orderId) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.inspectionOrder(orderId),
    );
    final payload = response.data?['data'] ?? response.data!;
    return SellerInspectionOrderModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<SellerInspectionOrderModel> respondInspectionRequest(
    String orderId, {
    required String action,
    bool? sellerConsentZin,
    String? rejectionReason,
    String? counterFeePayer,
    String? counterOrderType,
  }) async {
    final body = <String, dynamic>{
      'action': action,
      if (sellerConsentZin != null) 'sellerConsentZin': sellerConsentZin,
      if (rejectionReason != null && rejectionReason.isNotEmpty) 'rejectionReason': rejectionReason,
      if (counterFeePayer != null) 'counterFeePayer': counterFeePayer,
      if (counterOrderType != null) 'counterOrderType': counterOrderType,
    };
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.inspectionRespond(orderId),
      data: body,
    );
    final payload = response.data?['data'] ?? response.data!;
    return SellerInspectionOrderModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<SellerInspectionOrderModel> payInspectionFee(String orderId) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.inspectionPayFee(orderId),
    );
    final payload = response.data?['data'] ?? response.data!;
    return SellerInspectionOrderModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getOrCreateHomeCheckInCode(String orderId) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.inspectionCheckInCode(orderId),
    );
    final payload = response.data?['data'] ?? response.data ?? {};
    return payload as Map<String, dynamic>;
  }

  Future<SellerInspectionOrderModel> submitInspectionAppeal(
    String orderId, {
    required String reason,
    List<String>? evidenceUrls,
    List<String>? contestedItemIds,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'reason': reason,
      if (evidenceUrls != null && evidenceUrls.isNotEmpty) 'evidenceUrls': evidenceUrls,
      if (contestedItemIds != null && contestedItemIds.isNotEmpty) 'contestedItemIds': contestedItemIds,
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.inspectionAppeal(orderId),
      data: body,
    );
    final payload = response.data?['data'] ?? response.data!;
    return SellerInspectionOrderModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<SellerInspectionOrderModel> acceptFailedInspection(String orderId) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.inspectionAcceptFailed(orderId),
    );
    final payload = response.data?['data'] ?? response.data!;
    return SellerInspectionOrderModel.fromJson(payload as Map<String, dynamic>);
  }
}
