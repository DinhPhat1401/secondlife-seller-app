import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/core/network/api_response.dart';
import 'package:secondlife_app_seller/features/auth/presentation/auth_providers.dart';
import 'package:secondlife_app_seller/features/shipments/data/shipment_repository.dart';
import 'package:secondlife_app_seller/features/shipments/domain/shipment_models.dart';
import '../data/order_repository.dart';
import '../domain/order_models.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return OrderRepository(client: client);
});

class OrderListState {
  final bool isLoading;
  final String? errorMessage;
  final OrderStatus? selectedStatus;
  final List<SellerOrderModel> orders;
  final List<SellerInspectionOrderModel> inspectionOrders;
  final Map<String, List<ShipmentTrackingModel>> inspectionShipmentsByOrder;
  final Map<String, String> homeCheckInCodes;

  const OrderListState({
    this.isLoading = false,
    this.errorMessage,
    this.selectedStatus,
    this.orders = const [],
    this.inspectionOrders = const [],
    this.inspectionShipmentsByOrder = const {},
    this.homeCheckInCodes = const {},
  });

  OrderListState copyWith({
    bool? isLoading,
    String? errorMessage,
    OrderStatus? selectedStatus,
    bool clearStatus = false,
    List<SellerOrderModel>? orders,
    List<SellerInspectionOrderModel>? inspectionOrders,
    Map<String, List<ShipmentTrackingModel>>? inspectionShipmentsByOrder,
    Map<String, String>? homeCheckInCodes,
  }) {
    return OrderListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      orders: orders ?? this.orders,
      inspectionOrders: inspectionOrders ?? this.inspectionOrders,
      inspectionShipmentsByOrder: inspectionShipmentsByOrder ?? this.inspectionShipmentsByOrder,
      homeCheckInCodes: homeCheckInCodes ?? this.homeCheckInCodes,
    );
  }
}

class OrderListNotifier extends Notifier<OrderListState> {
  @override
  OrderListState build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (userId != null && userId.isNotEmpty) {
      Future.microtask(() => loadOrders());
      return const OrderListState(isLoading: true);
    }
    return const OrderListState();
  }

  OrderRepository get _repo => ref.read(orderRepositoryProvider);
  ShipmentRepository get _shipmentRepo => ref.read(shipmentRepositoryProvider);

  Future<void> loadOrders({OrderStatus? status}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      selectedStatus: status,
      clearStatus: status == null,
    );
    try {
      final results = await Future.wait([
        _repo.getSellerOrders(status: status, page: 0, size: 50),
        _repo.getSellerInspectionOrders(page: 0, size: 50),
      ]);

      final ordersPage = results[0] as PageResponse<SellerOrderModel>;
      final inspPage = results[1] as PageResponse<SellerInspectionOrderModel>;

      state = state.copyWith(
        isLoading: false,
        orders: ordersPage.items,
        inspectionOrders: inspPage.items,
      );

      // Pre-fetch shipments for active inspection orders
      for (final insp in inspPage.items) {
        if (insp.isAtCenter) {
          loadInspectionShipments(insp.id);
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<List<ShipmentTrackingModel>> loadInspectionShipments(String inspectionOrderId) async {
    try {
      final list = await _shipmentRepo.getInspectionShipments(inspectionOrderId);
      final updated = Map<String, List<ShipmentTrackingModel>>.from(state.inspectionShipmentsByOrder);
      updated[inspectionOrderId] = list;
      state = state.copyWith(inspectionShipmentsByOrder: updated);
      return list;
    } catch (_) {
      return state.inspectionShipmentsByOrder[inspectionOrderId] ?? const [];
    }
  }

  Future<bool> respondInspection(
    String orderId, {
    required String action,
    bool? sellerConsentZin,
    String? rejectionReason,
    String? counterFeePayer,
    String? counterOrderType,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.respondInspectionRequest(
        orderId,
        action: action,
        sellerConsentZin: sellerConsentZin,
        rejectionReason: rejectionReason,
        counterFeePayer: counterFeePayer,
        counterOrderType: counterOrderType,
      );
      await loadOrders(status: state.selectedStatus);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> payInspectionFee(String orderId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.payInspectionFee(orderId);
      await loadOrders(status: state.selectedStatus);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<String?> fetchHomeCheckInCode(String orderId) async {
    try {
      final res = await _repo.getOrCreateHomeCheckInCode(orderId);
      final code = res['code']?.toString() ?? '';
      if (code.isNotEmpty) {
        final updated = Map<String, String>.from(state.homeCheckInCodes);
        updated[orderId] = code;
        state = state.copyWith(homeCheckInCodes: updated);
      }
      return code;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> submitInspectionAppeal(
    String orderId, {
    required String reason,
    List<String>? evidenceUrls,
    List<String>? contestedItemIds,
    String? note,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.submitInspectionAppeal(
        orderId,
        reason: reason,
        evidenceUrls: evidenceUrls,
        contestedItemIds: contestedItemIds,
        note: note,
      );
      await loadOrders(status: state.selectedStatus);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> markAsShipped(String orderId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.markAsShipped(orderId);
      await loadOrders(status: state.selectedStatus);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId, [String? reason]) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.cancelOrder(orderId, reason);
      await loadOrders(status: state.selectedStatus);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final orderListNotifierProvider =
    NotifierProvider<OrderListNotifier, OrderListState>(OrderListNotifier.new);
