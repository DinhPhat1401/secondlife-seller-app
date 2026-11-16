import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import '../../domain/reputation_models.dart';
import '../reputation_providers.dart';

class SellerReputationScreen extends ConsumerWidget {
  const SellerReputationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reputationNotifierProvider);
    final rep = state.reputation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Điểm Uy Tín & Vi Phạm'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(reputationNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.isLoading && rep == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(reputationNotifierProvider.notifier).refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Score & Tier Card
                    _buildMainScoreCard(rep),
                    const SizedBox(height: 16),

                    // Restrictions / Warning Banner if active
                    if (rep != null && (rep.sellingRestricted || rep.warningCode != null))
                      _buildWarningBanner(rep),

                    // Metrics Grid
                    if (rep != null) ...[
                      const SizedBox(height: 16),
                      _buildMetricsGrid(rep),
                    ],

                    const SizedBox(height: 24),
                    // History Header
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Lịch Sử Biến Động Uy Tín',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${state.history.length} bản ghi',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // History List
                    if (state.history.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            'Chưa có lịch sử thay đổi điểm uy tín nào.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.history.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _buildHistoryItem(state.history[index]);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMainScoreCard(SellerReputationModel? rep) {
    final score = rep?.score;
    Color scoreColor = AppColors.success;
    if (score == null) {
      scoreColor = AppColors.textMuted;
    } else if (score < 50) {
      scoreColor = AppColors.error;
    } else if (score < 75) {
      scoreColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withValues(alpha: 0.1),
                  border: Border.all(color: scoreColor, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        score != null ? score.toStringAsFixed(0) : '--',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        '/100',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scoreColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            rep?.tierName ?? 'Đang tải thông tin...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            rep?.statusDisplay ?? 'Hệ thống uy tín SecondLife',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(SellerReputationModel rep) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rep.sellingRestricted
                      ? 'Tài khoản đang bị HẠN CHẾ ĐĂNG BÁN'
                      : 'Cảnh báo vi phạm uy tín người bán',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rep.warningCode != null
                      ? 'Mã vi phạm: ${rep.warningCode}. Vui lòng liên hệ CSKH hoặc cải thiện tỷ lệ hoàn tất đơn để gỡ bỏ hạn chế.'
                      : 'Điểm uy tín dưới ngưỡng tiêu chuẩn khiến quyền lợi đăng tin và nhận tiền bị hạn chế tạm thời.',
                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(SellerReputationModel rep) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chỉ Số Hoạt Động & Giao Dịch',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Đơn thành công',
                  value: '${rep.goodTransactions}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'Đơn có khiếu nại',
                  value: '${rep.badTransactions}',
                  icon: Icons.error_outline,
                  color: rep.badTransactions > 0 ? AppColors.error : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Đã đánh giá',
                  value: '${rep.evaluatedOrders} đơn',
                  icon: Icons.fact_check_outlined,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'Bàn giao chậm',
                  value: '${rep.lateHandoverOrders} đơn',
                  icon: Icons.timer_outlined,
                  color: rep.lateHandoverOrders > 0 ? AppColors.warning : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ReputationHistoryItemModel item) {
    final delta = item.scoreChange;
    final isPositive = delta != null && delta > 0;
    final isNegative = delta != null && delta < 0;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPositive
                  ? AppColors.success.withValues(alpha: 0.1)
                  : isNegative
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive
                  ? Icons.arrow_upward_rounded
                  : isNegative
                      ? Icons.arrow_downward_rounded
                      : Icons.remove_rounded,
              size: 16,
              color: isPositive
                  ? AppColors.success
                  : isNegative
                      ? AppColors.error
                      : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.eventTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(item.createdAt),
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (delta != null && delta != 0)
            Text(
              '${delta > 0 ? "+" : ""}${delta.toStringAsFixed(1)} đ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: delta > 0 ? AppColors.success : AppColors.error,
              ),
            )
          else if (item.scoreAfter != null)
            Text(
              '${item.scoreAfter!.toStringAsFixed(0)} đ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
        ],
      ),
    );
  }
}
