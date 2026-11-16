import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/credits/presentation/credit_providers.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import 'package:secondlife_app_seller/features/listings/presentation/create_listing_providers.dart';

class Step5ReviewSubmit extends ConsumerWidget {
  const Step5ReviewSubmit({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createListingNotifierProvider);
    final creditState = ref.watch(creditNotifierProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final hasListingCredits = creditState.balance.postCredits > 0;

    if (state.isSubmitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đăng Bán Thành Công!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bài đăng "${state.title}" đã được nộp duyệt tự động và sẵn sàng đón nhận người mua.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SlButton(
                text: 'Về Trang Quản Lý Tin Đăng',
                icon: const Icon(Icons.dashboard_outlined, color: Colors.white, size: 20),
                onPressed: () {
                  ref.read(createListingNotifierProvider.notifier).reset();
                  context.go('/dashboard');
                },
              ),
              const SizedBox(height: 12),
              SlButton(
                text: 'Đăng Thêm Thiết Bị Khác',
                type: SlButtonType.outline,
                icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 20),
                onPressed: () {
                  ref.read(createListingNotifierProvider.notifier).reset();
                  ref.read(createListingNotifierProvider.notifier).goToStep(0);
                },
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photos Preview strip
          if (state.photos.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.photos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      state.photos[index],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // Main Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.condition.label,
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      currencyFormat.format(state.userPriceVnd),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  state.title.isNotEmpty ? state.title : 'Chưa có tiêu đề',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Thương hiệu: ${state.brand.isNotEmpty ? state.brand : "Chưa rõ"} • Model: ${state.model.isNotEmpty ? state.model : "Chưa rõ"}${state.purchaseYear > 0 ? " • Mua năm: ${state.purchaseYear}" : ""}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Divider(height: 24),

                const Text('Mô tả sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                state.description.isNotEmpty
                    ? MarkdownBody(
                        data: state.description,
                        selectable: true,
                        softLineBreak: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.45),
                          strong: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          pPadding: const EdgeInsets.only(bottom: 6),
                          listBullet: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      )
                    : const Text(
                        'Chưa có mô tả',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                const Divider(height: 24),

                const Text('Thông số kiện hàng vận chuyển Lalamove:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  'Khối lượng: ${(state.shippingPackage.weightGrams / 1000).toStringAsFixed(2)} kg (${state.shippingPackage.weightGrams}g)\nKích thước (D x R x C): ${state.shippingPackage.lengthCm} x ${state.shippingPackage.widthCm} x ${state.shippingPackage.heightCm} cm',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Listing Credit Warning / Status
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasListingCredits ? AppColors.surface : AppColors.warningLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasListingCredits ? AppColors.border : AppColors.warning,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasListingCredits ? Icons.post_add_rounded : Icons.warning_amber_rounded,
                  color: hasListingCredits ? AppColors.primary : AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số dư: ${creditState.balance.postCredits} lượt đăng tin',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        hasListingCredits
                            ? 'Đăng bài sẽ sử dụng 1 lượt đăng tin từ tài khoản của bạn.'
                            : 'Bạn đã hết lượt đăng bài. Vui lòng nạp thêm để xuất bản bài đăng.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!hasListingCredits)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => context.push('/credits/buy'),
                    child: const Text('Nạp ngay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Final Submit Button
          SlButton(
            text: 'Xác Nhận Đăng Bán Ngay (-1 Credit)',
            icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
            isLoading: state.isLoading,
            onPressed: hasListingCredits
                ? () async {
                    final success = await ref.read(createListingNotifierProvider.notifier).submitPost();
                    if (!success && context.mounted) {
                      final err = ref.read(createListingNotifierProvider).errorMessage ?? 'Lỗi khi đăng bài';
                      final lower = err.toLowerCase();
                      if (lower.contains('insufficient_credit') || lower.contains('không đủ lượt') || lower.contains('hết lượt')) {
                        showDialog(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Row(
                              children: [
                                Icon(Icons.stars_rounded, color: AppColors.error, size: 28),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text('Không đủ credit đăng bài', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            content: const Text(
                              'Số dư lượt Đăng Bài của bạn không đủ để xuất bản bài đăng này. Vui lòng nạp thêm lượt đăng bài.',
                              style: TextStyle(fontSize: 13),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: const Text('Để sau', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  context.push('/credits/buy');
                                },
                                child: const Text('Nạp Lượt Đăng Bài', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  }
                : () {
                    context.push('/credits/buy');
                  },
          ),
        ],
      ),
    );
  }
}

