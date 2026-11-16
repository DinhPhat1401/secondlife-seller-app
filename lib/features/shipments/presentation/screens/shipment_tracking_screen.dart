import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_badge.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import '../../data/shipment_repository.dart';
import '../../domain/shipment_models.dart';
import '../widgets/tamper_seal_lookup_sheet.dart';

class ShipmentTrackingScreen extends ConsumerStatefulWidget {
  final String shipmentId;

  const ShipmentTrackingScreen({
    super.key,
    required this.shipmentId,
  });

  @override
  ConsumerState<ShipmentTrackingScreen> createState() => _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState extends ConsumerState<ShipmentTrackingScreen> {
  bool _isLoading = true;
  ShipmentTrackingModel? _tracking;
  List<ShipmentTimelineEvent> _events = [];
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  Future<void> _loadTracking() async {
    setState(() => _isLoading = true);
    final repo = ref.read(shipmentRepositoryProvider);
    try {
      final res = await repo.getTracking(widget.shipmentId);
      List<ShipmentTimelineEvent> timeline = res.timeline;
      if (timeline.isEmpty) {
        try {
          timeline = await repo.getShipmentEvents(widget.shipmentId);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _tracking = res;
          _events = timeline;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSync() async {
    setState(() => _isLoading = true);
    final repo = ref.read(shipmentRepositoryProvider);
    try {
      final res = await repo.syncTracking(widget.shipmentId);
      List<ShipmentTimelineEvent> timeline = res.timeline;
      if (timeline.isEmpty) {
        try {
          timeline = await repo.getShipmentEvents(widget.shipmentId);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _tracking = res;
          _events = timeline;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật dữ liệu mới nhất từ Lalamove'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể đồng bộ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildDynamicStatusBadge(ShipmentTrackingModel t) {
    final s = t.status.toUpperCase();
    final isReturn = t.isReturnLeg;

    if (s == 'DELIVERED' || s == 'COMPLETED') {
      return SlBadge.success(isReturn ? 'Đã trả về người bán' : 'Đã giao thành công');
    }
    if (s == 'CREATION_UNCERTAIN') {
      return SlBadge.warning('Đang xác minh tạo đơn');
    }
    if (s == 'CANCELLED' || s == 'CANCELED' || s == 'REJECTED' || s == 'EXPIRED') {
      return SlBadge.error('Đã hủy vận đơn');
    }
    if (s == 'ASSIGNING_DRIVER' || s == 'PENDING') {
      return SlBadge.warning(isReturn ? 'Đang tìm tài xế trả hàng' : 'Đang tìm tài xế');
    }
    if (isReturn) {
      return SlBadge.warning('Đang trả về người bán');
    }
    return SlBadge.info(t.statusDescription.isNotEmpty ? t.statusDescription : 'Đang giao hàng');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Theo Dõi Vận Đơn Lalamove'),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_outlined, color: Color(0xFF059669)),
            tooltip: 'Tra cứu tem niêm phong',
            onPressed: () {
              final repo = ref.read(shipmentRepositoryProvider);
              TamperSealLookupSheet.show(context, repository: repo);
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Đồng bộ hành trình',
            onPressed: _handleSync,
          ),
        ],
      ),
      body: _isLoading && _tracking == null
          ? const Center(child: CircularProgressIndicator())
          : _tracking == null
              ? const Center(child: Text('Không tìm thấy thông tin vận đơn'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      _buildHeaderCard(_tracking!),
                      const SizedBox(height: 16),

                      // Route & Fee Reconciliation Card
                      _buildRouteAndFeeCard(_tracking!),
                      const SizedBox(height: 16),

                      // Driver Card
                      _buildDriverCard(_tracking!),
                      const SizedBox(height: 20),

                      // Timeline Header
                      const Text(
                        'Hành Trình Giao Nhận Chi Tiết',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),

                      // Timeline
                      _buildTimeline(_events.isNotEmpty ? _events : _tracking!.timeline),
                      const SizedBox(height: 24),

                      // Sync button
                      SlButton(
                        text: 'Đồng Bộ Lại Hành Trình Từ Lalamove',
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        isLoading: _isLoading,
                        onPressed: _handleSync,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard(ShipmentTrackingModel t) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.carrier.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFEA580C),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        t.trackingNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
                tooltip: 'Sao chép mã',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: t.trackingNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép mã vận đơn'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.legLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildDynamicStatusBadge(t),
          if (t.providerStatus != null && t.providerStatus!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Trạng thái đối tác: ${t.providerStatus}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
          if (t.deliveredAt != null && t.deliveredAt!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Thời gian hoàn tất: ${t.deliveredAt}',
              style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
            ),
          ] else if (t.estimatedDelivery != null) ...[
            const SizedBox(height: 6),
            Text(
              'Dự kiến giao: ${t.estimatedDelivery}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          if (t.lastError != null && t.lastError!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Cảnh báo: ${t.lastError}',
                style: const TextStyle(fontSize: 11, color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteAndFeeCard(ShipmentTrackingModel t) {
    final actualFeeText = t.actualFee != null
        ? _currencyFormat.format(t.actualFee)
        : 'Chờ cập nhật';
    final quotedFeeText = t.quotedFee != null
        ? _currencyFormat.format(t.quotedFee)
        : 'Chưa báo giá';

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
            'Điểm Giao Nhận & Đối Soát Cước Phí',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.my_location, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Người gửi: ${t.senderName ?? "Người bán"} ${t.senderPhone != null ? "• ${t.senderPhone}" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    if (t.originAddress != null && t.originAddress!.isNotEmpty)
                      Text(
                        t.originAddress!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Người nhận: ${t.receiverName ?? "Điểm nhận"} ${t.receiverPhone != null ? "• ${t.receiverPhone}" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    if (t.destinationAddress != null && t.destinationAddress!.isNotEmpty)
                      Text(
                        t.destinationAddress!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Phí dự kiến (Quoted)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(quotedFeeText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Phí thực tế (Actual)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    actualFeeText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: t.actualFee != null ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (t.isReturnLeg) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Text(
                t.getReturnReserveMessage(t.quotedFee),
                style: const TextStyle(fontSize: 11, color: Color(0xFF9A3412), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverCard(ShipmentTrackingModel t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.driverName ?? 'Tài xế Lalamove',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Biển số: ${t.plateNumber ?? "Đang cập nhật"}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (t.driverPhone != null && t.driverPhone!.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.phone_in_talk, color: AppColors.success, size: 20),
                tooltip: 'Gọi tài xế',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: t.driverPhone!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('SĐT tài xế: ${t.driverPhone} (Đã sao chép)')),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<ShipmentTimelineEvent> events) {
    if (events.isEmpty) {
      return const Text('Chưa có sự kiện vận chuyển nào', style: TextStyle(color: AppColors.textSecondary));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final event = events[index];
          final isLast = index == events.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isLast ? AppColors.primary : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isLast ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    if (event.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.description!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      event.timestamp,
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
