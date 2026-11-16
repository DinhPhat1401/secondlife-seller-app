import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/catalog/domain/catalog_models.dart';
import 'package:secondlife_app_seller/features/catalog/presentation/catalog_providers.dart';
import 'package:secondlife_app_seller/features/listings/presentation/create_listing_providers.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';

class Step3AcceptDescription extends ConsumerStatefulWidget {
  const Step3AcceptDescription({super.key});

  @override
  ConsumerState<Step3AcceptDescription> createState() => _Step3AcceptDescriptionState();
}

class _Step3AcceptDescriptionState extends ConsumerState<Step3AcceptDescription> {
  bool _skipValuation = false;

  Future<void> _handleAccept() async {
    final notifier = ref.read(createListingNotifierProvider.notifier);
    final ok = await notifier.acceptDescription(skipValuation: _skipValuation);
    if (!ok && mounted) {
      final err = ref.read(createListingNotifierProvider).errorMessage ?? 'Lỗi xác nhận mô tả';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createListingNotifierProvider);
    final categories = ref.watch(categoriesProvider).asData?.value ?? [];
    final categoryName = categories.firstWhere(
      (c) => c.id == state.categoryId,
      orElse: () => const CategoryModel(id: '', name: 'Thiết bị gia dụng'),
    ).name;

    final pkg = state.shippingPackage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bước 3: Lưu Draft & Xác Nhận Mô Tả',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Mô tả phải được xác nhận trước khi AI định giá và gửi đăng bài.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Snapshot Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BẢN TÓM TẮT SNAPSHOT NỘI DUNG',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: state.descriptionAccepted ? AppColors.successLight : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: state.descriptionAccepted ? AppColors.success : Colors.amber.shade300),
                      ),
                      child: Text(
                        state.descriptionAccepted ? '✓ Đã xác nhận' : 'Chờ xác nhận',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: state.descriptionAccepted ? AppColors.success : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Title
                const Text('Tiêu đề bài đăng:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  state.title.isNotEmpty ? state.title : 'Chưa có tiêu đề',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                // Meta Info Grid
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Danh mục & Hãng:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '$categoryName - ${state.brand}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tình trạng máy:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            state.condition.label,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (state.purchaseTimeNote.isNotEmpty || state.purchaseYear > 0) ...[
                  Row(
                    children: [
                      if (state.purchaseYear > 0)
                        Text('Năm mua: ${state.purchaseYear}   •   ', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      if (state.purchaseTimeNote.isNotEmpty)
                        Text('Thời gian dùng: ${state.purchaseTimeNote}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Package Specs
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kiện hàng: ${(pkg.weightGrams / 1000).toStringAsFixed(1)} kg  |  ${pkg.lengthCm} × ${pkg.widthCm} × ${pkg.heightCm} cm',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Description Preview
                const Text('Nội dung mô tả chi tiết:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: state.description.isNotEmpty ? state.description : '*Chưa có mô tả*',
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Responsibility Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue.shade800),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Quy định thẩm định nội dung: Khi bạn bấm xác nhận, hệ thống sẽ lưu snapshot và khóa dữ liệu mô tả để AI tính toán khoảng giá hợp lý. Nếu sau này bạn sửa lại mô tả, trạng thái sẽ tự động đặt lại và cần xác nhận lại.',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade900, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Skip valuation option
          CheckboxListTile(
            value: _skipValuation,
            onChanged: (val) => setState(() => _skipValuation = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Tự nhập giá bán (Bỏ qua định giá AI)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Tiết kiệm 1 lượt định giá AI, chuyển thẳng sang Bước 5 để nhập giá và đăng bài.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          SlButton(
            text: _skipValuation
                ? 'Xác Nhận & Sang Bước 5 (Đăng Bài)'
                : 'Xác Nhận Mô Tả & Sang Bước 4 (Định Giá)',
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            isLoading: state.isLoading,
            onPressed: () => _handleAccept(),
          ),
          const SizedBox(height: 10),

          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ref.read(createListingNotifierProvider.notifier).goToStep(1);
            },
            child: const Text('Quay lại Bước 2 (Chỉnh sửa nội dung)', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

