import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/post_repository.dart';
import '../domain/post_models.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PostRepository(client: client);
});

class SellerListingsState {
  final List<SellerListingItemModel> listings;
  final bool isLoading;
  final String selectedStatus;
  final String searchQuery;
  final String? errorMessage;
  final String? actionSuccessMessage;

  const SellerListingsState({
    this.listings = const [],
    this.isLoading = false,
    this.selectedStatus = 'ALL',
    this.searchQuery = '',
    this.errorMessage,
    this.actionSuccessMessage,
  });

  SellerListingsState copyWith({
    List<SellerListingItemModel>? listings,
    bool? isLoading,
    String? selectedStatus,
    String? searchQuery,
    String? errorMessage,
    String? actionSuccessMessage,
  }) {
    return SellerListingsState(
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      actionSuccessMessage: actionSuccessMessage,
    );
  }

  List<SellerListingItemModel> get filteredListings {
    var result = listings;

    // Filter strictly by selected tab status
    if (selectedStatus != 'ALL') {
      result = result.where((item) {
        switch (selectedStatus) {
          case 'ACTIVE':
            return item.status == ListingStatus.active;
          case 'PENDING':
            return item.status == ListingStatus.pending;
          case 'RESERVED':
            return item.status == ListingStatus.reserved;
          case 'SOLD':
            return item.status == ListingStatus.sold;
          case 'DRAFT':
            return item.status == ListingStatus.draft;
          case 'REJECTED':
            return item.status == ListingStatus.rejected;
          case 'HIDDEN':
            return item.status == ListingStatus.hidden;
          default:
            return true;
        }
      }).toList();
    }

    if (searchQuery.trim().isEmpty) return result;
    final q = searchQuery.toLowerCase().trim();
    return result.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();
  }
}

class SellerListingsNotifier extends Notifier<SellerListingsState> {
  @override
  SellerListingsState build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (userId != null && userId.isNotEmpty) {
      Future.microtask(() => loadListings());
      return const SellerListingsState(isLoading: true);
    }
    return const SellerListingsState();
  }

  PostRepository get _repository => ref.read(postRepositoryProvider);

  Future<void> loadListings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.getMyPosts();
      state = state.copyWith(listings: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách tin đăng. Vui lòng thử lại.',
      );
    }
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> boostListing(String postId) async {
    try {
      await _repository.boostListing(postId);
      state = state.copyWith(
        actionSuccessMessage: 'Đã đẩy tin thành công! Tin đăng được ưu tiên tiếp cận người mua.',
      );
      await loadListings();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteListing(String postId) async {
    try {
      await _repository.deletePost(postId);
      state = state.copyWith(
        listings: state.listings.where((item) => item.id != postId).toList(),
        actionSuccessMessage: 'Đã gỡ bài đăng thành công.',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final sellerListingsNotifierProvider =
    NotifierProvider<SellerListingsNotifier, SellerListingsState>(
  SellerListingsNotifier.new,
);
