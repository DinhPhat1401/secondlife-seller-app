import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import '../../domain/return_shipping_models.dart';
import '../return_shipping_providers.dart';

class ReturnShippingDebtScreen extends ConsumerWidget {
  const ReturnShippingDebtScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(returnShippingDebtProvider);
    final debt = state.debt;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nợ Cước Hoàn Hàng'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(returnShippingDebtProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(returnShippingDebtProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Debt Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: debt.outstandingDebt > 0 ? AppColors.warning : AppColors.border,
                    width: debt.outstandingDebt > 0 ? 1.5 : 1,
                  ),
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
                    Icon(
                      debt.outstandingDebt > 0 ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                      size: 48,
                      color: debt.outstandingDebt > 0 ? AppColors.warning : AppColors.success,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tổng Cước Hoàn Chưa Thanh Toán',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormat.format(debt.outstandingDebt),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: debt.outstandingDebt > 0 ? AppColors.error : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Theo chính sách SecondLife, khi kiện hàng bị hoàn trả do lỗi từ phía người bán (kiểm định không đạt hoặc từ chối bàn giao), cước phí vận chuyển hoàn sẽ được ghi nhận vào nợ cước của người bán.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (debt.outstandingDebt > 0) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                          label: const Text('Xem Ví & Tất Toán Nợ Cước'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => context.push('/wallet'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Return Shipments Header
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Danh Sách Kiện Hàng Hoàn Trả',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${state.fees.length} kiện',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // List of return fees
              if (state.isLoading && state.fees.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
              else if (state.fees.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'Bạn không có kiện hàng hoàn trả nào cần thanh toán.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.fees.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = state.fees[index];
                    return _buildFeeItem(context, item, currencyFormat);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeItem(
    BuildContext context,
    ReturnShippingFeeItemModel item,
    NumberFormat currencyFormat,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isUnpaid = item.isOutstanding;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnpaid ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kiện: ${item.shipmentId.length > 12 ? '${item.shipmentId.substring(0, 12)}...' : item.shipmentId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUnpaid ? AppColors.warningLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isUnpaid ? AppColors.warning : AppColors.success,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  item.statusDisplay,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUnpaid ? Colors.amber.shade900 : Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã đơn hàng: ${item.orderId.length > 8 ? '${item.orderId.substring(0, 8)}...' : item.orderId}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                dateFormat.format(item.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cước vận chuyển hoàn:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                currencyFormat.format(item.feeAmount),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
              ),
            ],
          ),
          if (item.debtAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Còn nợ chưa trừ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
                Text(
                  currencyFormat.format(item.debtAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
