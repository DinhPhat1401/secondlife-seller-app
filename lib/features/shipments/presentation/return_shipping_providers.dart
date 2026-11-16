import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/features/auth/presentation/auth_providers.dart';
import '../data/shipment_repository.dart';
import '../domain/return_shipping_models.dart';

class ReturnShippingDebtState {
  final bool isLoading;
  final String? errorMessage;
  final SellerReturnShippingDebtModel debt;
  final List<ReturnShippingFeeItemModel> fees;

  const ReturnShippingDebtState({
    this.isLoading = false,
    this.errorMessage,
    this.debt = const SellerReturnShippingDebtModel(sellerId: '', outstandingDebt: 0.0),
    this.fees = const [],
  });

  ReturnShippingDebtState copyWith({
    bool? isLoading,
    String? errorMessage,
    SellerReturnShippingDebtModel? debt,
    List<ReturnShippingFeeItemModel>? fees,
  }) {
    return ReturnShippingDebtState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      debt: debt ?? this.debt,
      fees: fees ?? this.fees,
    );
  }
}

class ReturnShippingDebtNotifier extends Notifier<ReturnShippingDebtState> {
  @override
  ReturnShippingDebtState build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (userId != null && userId.isNotEmpty) {
      Future.microtask(() => refresh());
      return const ReturnShippingDebtState(isLoading: true);
    }
    return const ReturnShippingDebtState();
  }

  ShipmentRepository get _repo => ref.read(shipmentRepositoryProvider);

  Future<void> fetchDebt() async {
    try {
      final debt = await _repo.getReturnShippingDebt();
      state = state.copyWith(debt: debt);
    } catch (e) {
      // Keep existing
    }
  }

  Future<void> fetchFees({bool outstandingOnly = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final fees = await _repo.getMyReturnShippingFees(outstandingOnly: outstandingOnly);
      state = state.copyWith(isLoading: false, fees: fees);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    await Future.wait([
      fetchDebt(),
      fetchFees(),
    ]);
  }
}

final returnShippingDebtProvider = NotifierProvider<ReturnShippingDebtNotifier, ReturnShippingDebtState>(() {
  return ReturnShippingDebtNotifier();
});
