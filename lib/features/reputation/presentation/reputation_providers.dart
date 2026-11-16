import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/features/auth/presentation/auth_providers.dart';
import '../data/reputation_repository.dart';
import '../domain/reputation_models.dart';

final reputationRepositoryProvider = Provider<ReputationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ReputationRepository(client: client);
});

class ReputationState {
  final bool isLoading;
  final String? errorMessage;
  final SellerReputationModel? reputation;
  final List<ReputationHistoryItemModel> history;

  const ReputationState({
    this.isLoading = false,
    this.errorMessage,
    this.reputation,
    this.history = const [],
  });

  ReputationState copyWith({
    bool? isLoading,
    String? errorMessage,
    SellerReputationModel? reputation,
    List<ReputationHistoryItemModel>? history,
  }) {
    return ReputationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      reputation: reputation ?? this.reputation,
      history: history ?? this.history,
    );
  }
}

class ReputationNotifier extends Notifier<ReputationState> {
  @override
  ReputationState build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (userId != null && userId.isNotEmpty) {
      Future.microtask(() => refresh());
      return const ReputationState(isLoading: true);
    }
    return const ReputationState();
  }

  ReputationRepository get _repository => ref.read(reputationRepositoryProvider);

  Future<void> fetchReputation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final rep = await _repository.getMyReputation();
      state = state.copyWith(isLoading: false, reputation: rep);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchHistory() async {
    try {
      final history = await _repository.getMyReputationHistory();
      state = state.copyWith(history: history);
    } catch (e) {
      // Keep existing history on error
    }
  }

  Future<void> refresh() async {
    await Future.wait([
      fetchReputation(),
      fetchHistory(),
    ]);
  }
}

final reputationNotifierProvider = NotifierProvider<ReputationNotifier, ReputationState>(() {
  return ReputationNotifier();
});
