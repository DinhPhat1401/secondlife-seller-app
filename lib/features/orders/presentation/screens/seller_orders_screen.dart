import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/auth/presentation/auth_providers.dart';
import 'package:secondlife_app_seller/features/shipments/data/shipment_repository.dart';
import 'package:secondlife_app_seller/features/shipments/domain/shipment_models.dart';
import 'package:secondlife_app_seller/features/shipments/presentation/widgets/tamper_seal_lookup_sheet.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_badge.dart';
import 'package:secondlife_app_seller/shared/widgets/inspection_deadline_countdown.dart';
import '../../domain/order_models.dart';
import '../order_providers.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  final int initialMode;
  const SellerOrdersScreen({super.key, this.initialMode = 0});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late int _mainModeIndex; // 0: Đơn hàng, 1: Đơn kiểm định

  final List<({String label, OrderStatus? status})> _tabs = [
    (label: 'Tất cả', status: null),
    (label: 'Chờ xử lý', status: OrderStatus.pending),
    (label: 'Chờ Buyer (6h)', status: OrderStatus.pendingFinalPayment),
    (label: 'Đang giao', status: OrderStatus.shipping),
    (label: 'Hoàn tất', status: OrderStatus.delivered),
    (label: 'Đã hủy / Quá hạn', status: OrderStatus.cancelled),
  ];

  @override
  void initState() {
    super.initState();
    _mainModeIndex = widget.initialMode;
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final selectedTab = _tabs[_tabController.index];
        ref
            .read(orderListNotifierProvider.notifier)
            .loadOrders(status: selectedTab.status);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy Đơn Hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn có chắc chắn muốn hủy đơn hàng này? Tiền ký quỹ sẽ được hoàn trả 100% cho người mua.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do hủy (hết hàng, người mua đổi ý)...',
                hintStyle: TextStyle(fontSize: 12),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(orderListNotifierProvider.notifier)
                  .cancelOrder(orderId, reasonController.text.trim());
              if (context.mounted && !success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lỗi khi hủy đơn hàng'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text(
              'Xác nhận hủy',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRespondInspectionDialog(
    SellerInspectionOrderModel order,
    String action,
  ) {
    bool consentZin = false;
    final reasonCtrl = TextEditingController();
    String counterFeePayer = 'SPLIT_50_50';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          String title = 'Phê Duyệt Kiểm Định';
          if (action == 'REJECT') title = 'Từ Chối Kiểm Định';
          if (action == 'COUNTER') title = 'Đề Xuất Chia Lại Phí';

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (action == 'ACCEPT') ...[
                    const Text(
                      'Bằng việc đồng ý, bạn xác nhận sản phẩm đúng như mô tả và sẵn sàng cho quy trình kiểm định.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: consentZin,
                      activeColor: AppColors.primary,
                      title: const Text(
                        'Tôi cam kết máy nguyên zin / đúng tình trạng mô tả',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onChanged: (val) =>
                          setDialogState(() => consentZin = val ?? false),
                    ),
                  ] else if (action == 'REJECT') ...[
                    const Text(
                      'Vui lòng nhập lý do từ chối yêu cầu kiểm định từ người mua:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Lý do từ chối...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else if (action == 'COUNTER') ...[
                    const Text(
                      'Chọn phương án chia phí bạn muốn đề xuất lại cho người mua:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: counterFeePayer,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'BUYER_PAYS',
                          child: Text('Người mua chịu 100%'),
                        ),
                        DropdownMenuItem(
                          value: 'SPLIT_50_50',
                          child: Text('Chia đều 50 / 50'),
                        ),
                        DropdownMenuItem(
                          value: 'SELLER_PAYS',
                          child: Text('Người bán chịu 100%'),
                        ),
                      ],
                      onChanged: (val) => setDialogState(
                        () => counterFeePayer = val ?? 'SPLIT_50_50',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: action == 'REJECT'
                      ? AppColors.error
                      : AppColors.primary,
                ),
                onPressed: () async {
                  if (action == 'ACCEPT' && !consentZin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng tích cam kết máy nguyên zin'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }
                  if (action == 'REJECT' && reasonCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập lý do từ chối'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  final ok = await ref
                      .read(orderListNotifierProvider.notifier)
                      .respondInspection(
                        order.id,
                        action: action,
                        sellerConsentZin: action == 'ACCEPT' ? true : null,
                        rejectionReason: action == 'REJECT'
                            ? reasonCtrl.text.trim()
                            : null,
                        counterFeePayer: action == 'COUNTER'
                            ? counterFeePayer
                            : null,
                      );
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật phản hồi kiểm định'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: Text(
                  action == 'REJECT' ? 'Xác nhận từ chối' : 'Xác nhận',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showHomeCheckInCodeSheet(SellerInspectionOrderModel order) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final state = ref.watch(orderListNotifierProvider);
          final code = state.homeCheckInCodes[order.id];

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Icon(
                  Icons.qr_code_scanner,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mã Check-In Kỹ Thuật Viên Tại Nhà',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cung cấp mã này cho Kỹ thuật viên khi đến nhà để xác nhận bắt đầu buổi kiểm định.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                if (code == null) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: const Icon(
                      Icons.vpn_key,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Lấy Mã Check-In',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      final generated = await ref
                          .read(orderListNotifierProvider.notifier)
                          .fetchHomeCheckInCode(order.id);
                      if (generated == null && ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không thể lấy mã check-in'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SelectableText(
                          code,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép mã check-in'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (order.homeCheckedInAt != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'KTV đã check-in lúc: ${DateFormat('HH:mm - dd/MM/yyyy').format(order.homeCheckedInAt!)}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAppealDialog(SellerInspectionOrderModel order) {
    final reasonCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Khiếu Nại Kết Quả Kiểm Định (24h)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nếu bạn cho rằng kết quả kiểm định chưa chính xác, hãy gửi yêu cầu khiếu nại để ban quản trị SecondLife xem xét.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lý do khiếu nại *',
                  hintText:
                      'VD: Máy hoạt động bình thường, tiêu chí nhiệt độ không chính xác...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú thêm',
                  hintText: 'Mô tả thêm bằng chứng hoặc trao đổi với admin...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do khiếu nại'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              final ok = await ref
                  .read(orderListNotifierProvider.notifier)
                  .submitInspectionAppeal(
                    order.id,
                    reason: reasonCtrl.text.trim(),
                    note: noteCtrl.text.trim().isNotEmpty
                        ? noteCtrl.text.trim()
                        : null,
                  );
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đã gửi khiếu nại thành công. BQT sẽ xem xét trong 24h.',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text(
              'Gửi khiếu nại',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListNotifierProvider);
    final orders = state.orders;
    final inspectionOrders = state.inspectionOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản Lý Bán Hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () {
              final selectedTab = _tabs[_tabController.index];
              ref
                  .read(orderListNotifierProvider.notifier)
                  .loadOrders(status: selectedTab.status);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_mainModeIndex == 0 ? 98 : 50),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _mainModeIndex = 0),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(9),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _mainModeIndex == 0
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(9),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Đơn Mua Bán (${orders.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _mainModeIndex == 0
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _mainModeIndex = 1),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(9),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _mainModeIndex == 1
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(9),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Đơn Kiểm Định (${inspectionOrders.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _mainModeIndex == 1
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_mainModeIndex == 0)
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
                ),
            ],
          ),
        ),
      ),
      body: _mainModeIndex == 0
          ? (state.isLoading && orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppColors.divider,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Không có đơn hàng nào trong mục này',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(order);
                    },
                  ))
          : (state.isLoading && inspectionOrders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : inspectionOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppColors.divider,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có đơn kiểm định nào',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: inspectionOrders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = inspectionOrders[index];
                      return _buildInspectionOrderCard(order, state);
                    },
                  )),
    );
  }

  Widget _buildOrderCard(SellerOrderModel order) {
    return Container(
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
          // Header: Code & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đơn #${order.orderNumber ?? (order.id.length > 8 ? order.id.substring(0, 8) : order.id)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          const Divider(height: 20),

          // Product Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: order.postThumbnail != null
                    ? Image.network(
                        order.postThumbnail!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.postTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Người mua: ${order.buyerName} • ${order.buyerPhone}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (order.deliveryAddress != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Giao tới: ${order.deliveryAddress!.fullAddressText}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Payout Calculation Row
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giá bán hàng',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(order.itemPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phí sàn',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '-${_currencyFormat.format(order.platformFee)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Thực nhận vào Ví',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(order.netPayout),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (order.isPendingFinalPayment) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: Color(0xFFC2410C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sản phẩm đã kiểm định ĐẠT. Người mua cần thanh toán trước hạn; nếu quá hạn, tiền cọc được xử lý theo trạng thái backend.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9A3412),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (order.finalPaymentDeadline != null) ...[
                          const SizedBox(height: 4),
                          InspectionDeadlineCountdown(
                            deadline: order.finalPaymentDeadline!,
                            onExpired: () => ref
                                .read(orderListNotifierProvider.notifier)
                                .loadOrders(),
                          ),
                        ] else
                          const Text(
                            'Chưa nhận được hạn thanh toán; làm mới danh sách để cập nhật.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (order.isExpiredOrForfeited) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.monetization_on_outlined,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đơn hàng kiểm định đã hủy do Người mua quá hạn thanh toán 6 giờ. Tiền cọc kiểm định đã được giải ngân bồi thường vào Ví SecondLife của bạn.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (order.hasInspection) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text(
                    'Tem niêm phong',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    TamperSealLookupSheet.show(
                      context,
                      repository: ShipmentRepository(
                        client: ref.read(apiClientProvider),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              if (order.status == OrderStatus.pending) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => _showCancelDialog(context, order.id),
                  child: const Text('Hủy Đơn', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'Bàn Giao Shipper',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    final success = await ref
                        .read(orderListNotifierProvider.notifier)
                        .markAsShipped(order.id);
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã cập nhật trạng thái giao cho shipper',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              ] else if (order.status == OrderStatus.shipping ||
                  order.status == OrderStatus.delivered) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(
                    Icons.route_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'Theo Dõi Vận Đơn',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    final shipmentId = order.shipmentId ?? order.id;
                    context.push('/shipments/$shipmentId/tracking');
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.divider,
      child: const Icon(
        Icons.kitchen_outlined,
        color: AppColors.textMuted,
        size: 28,
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return SlBadge.warning('Chờ xác nhận');
      case OrderStatus.pendingFinalPayment:
        return SlBadge.warning('Chờ Buyer TT (6h)');
      case OrderStatus.confirmed:
        return SlBadge.info('Đã xác nhận');
      case OrderStatus.shipping:
        return SlBadge.info('Đang giao hàng');
      case OrderStatus.delivered:
        return SlBadge.success('Đã giao thành công');
      case OrderStatus.expired:
        return SlBadge.error('Quá hạn 6h');
      case OrderStatus.cancelled:
        return SlBadge.error('Đã hủy');
      default:
        return SlBadge.neutral(status.label);
    }
  }

  Widget _buildInspectionStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'WAITING_SELLER_APPROVAL':
        return SlBadge.warning('Chờ bạn duyệt');
      case 'WAITING_BUYER_APPROVAL':
        return SlBadge.warning('Chờ buyer xác nhận');
      case 'WAITING_FEE_PAYMENT':
        return SlBadge.warning('Chờ nộp phí');
      case 'CONFIRMED_PENDING_DISPATCH':
        return SlBadge.info('Đủ phí - Chờ gửi');
      case 'DISPATCHED':
        return SlBadge.info('Đang chuyển tới trạm');
      case 'SCHEDULED':
        return SlBadge.info('Đã hẹn lịch');
      case 'INSPECTING':
        return SlBadge.info('Đang kiểm định');
      case 'PASSED':
        return SlBadge.success('Kiểm định ĐẠT');
      case 'FAILED':
        return SlBadge.error('Không đạt');
      case 'CANCELLED':
        return SlBadge.error('Đã hủy');
      case 'DELIVERING_TO_BUYER':
        return SlBadge.success('Đang giao Buyer');
      default:
        return SlBadge.neutral(status);
    }
  }

  Widget _buildInspectionOrderCard(
    SellerInspectionOrderModel order,
    OrderListState state,
  ) {
    final shipments = state.inspectionShipmentsByOrder[order.id] ?? const [];
    ShipmentTrackingModel? returnShipment;
    try {
      returnShipment = shipments.firstWhere((s) => s.leg == 'CENTER_TO_SELLER');
    } catch (_) {
      returnShipment = null;
    }

    return Container(
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
              Text(
                'KĐ #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              _buildInspectionStatusBadge(order.status),
            ],
          ),
          const Divider(height: 20),

          // Product Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: order.postImageUrls.isNotEmpty
                    ? Image.network(
                        order.postImageUrls.first,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.postTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hình thức: ${order.isAtCenter ? "Tại Trung Tâm" : "Tại Nhà"} • ${order.feePayerLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (order.inspectionCenterName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Trạm: ${order.inspectionCenterName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Fee Breakdown Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Phí kiểm định:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(order.inspectionFee),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (order.isAtCenter) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cước gửi trạm (chiều đi):',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(order.shippingFee),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dự phòng cước trả hàng (chiều về):',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(order.returnShippingReserveFee),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Phần Người bán cần trả:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(order.sellerFeeShare),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: order.sellerPaidAt != null
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.sellerPaidAt != null
                          ? 'Trạng thái: Đã thanh toán (${DateFormat('dd/MM HH:mm').format(order.sellerPaidAt!)})'
                          : (order.sellerFeeShare == 0
                                ? 'Trạng thái: Miễn phí cho người bán'
                                : 'Trạng thái: Chưa thanh toán'),
                      style: TextStyle(
                        fontSize: 11,
                        color: order.sellerPaidAt != null
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (order.status == 'WAITING_FEE_PAYMENT' &&
              order.sellerFeeShare > 0 &&
              order.sellerPaidAt == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: Color(0xFFC2410C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hãy thanh toán phần phí kiểm định của bạn trước hạn.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                        if (order.paymentDeadline != null) ...[
                          const SizedBox(height: 4),
                          InspectionDeadlineCountdown(
                            key: ValueKey('${order.id}-fee-deadline'),
                            deadline: order.paymentDeadline!,
                            onExpired: () => ref
                                .read(orderListNotifierProvider.notifier)
                                .loadOrders(),
                          ),
                        ] else
                          const Text(
                            'Chưa nhận được hạn thanh toán; làm mới danh sách để cập nhật.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (order.status == 'PASSED' && order.finalPaymentPaidAt == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: Color(0xFFC2410C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kiểm định đạt. Người mua cần thanh toán tiền hàng trước hạn; nếu quá hạn, khoản cọc được xử lý theo quy định.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9A3412),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (order.finalPaymentDeadline != null) ...[
                          const SizedBox(height: 4),
                          InspectionDeadlineCountdown(
                            key: ValueKey('${order.id}-final-payment-deadline'),
                            deadline: order.finalPaymentDeadline!,
                            onExpired: () => ref
                                .read(orderListNotifierProvider.notifier)
                                .loadOrders(),
                          ),
                        ] else
                          const Text(
                            'Chưa nhận được hạn thanh toán; làm mới danh sách để cập nhật.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Evidence Photos Strip
          if (order.evidencePhotoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Ảnh bằng chứng hiện trạng kiểm định:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.evidencePhotoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final photo = order.evidencePhotoUrls[idx];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photo,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: AppColors.divider,
                        child: const Icon(Icons.broken_image, size: 20),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Return Shipment Card (CENTER_TO_SELLER)
          if (returnShipment != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.assignment_return_outlined,
                            size: 16,
                            color: Color(0xFFB45309),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Vận Đơn Hoàn Trả Về Seller',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      SlBadge.warning(returnShipment.statusDescription),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mã vận đơn: ${returnShipment.orderCode ?? returnShipment.trackingNumber}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF78350F),
                    ),
                  ),
                  if (returnShipment.senderAddress != null &&
                      returnShipment.receiverAddress != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tuyến: ${returnShipment.senderAddress} → ${returnShipment.receiverAddress}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF78350F),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    returnShipment.getReturnReserveMessage(
                      order.returnShippingReserveFee,
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (order.canSellerRespond) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () =>
                      _showRespondInspectionDialog(order, 'REJECT'),
                  child: const Text('Từ Chối', style: TextStyle(fontSize: 12)),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _showRespondInspectionDialog(order, 'COUNTER'),
                  child: const Text(
                    'Đổi Chia Phí',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () =>
                      _showRespondInspectionDialog(order, 'ACCEPT'),
                  child: const Text(
                    'Đồng Ý Kiểm Định',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
              if (order.isSellerFeePaymentPending) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  icon: const Icon(
                    Icons.payment,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Nộp Phí (${_currencyFormat.format(order.sellerFeeShare)})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    final ok = await ref
                        .read(orderListNotifierProvider.notifier)
                        .payInspectionFee(order.id);
                    if (mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã nộp phí kiểm định thành công'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              ],
              if (order.canRequestHomeCheckInCode) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text(
                    'Mã Check-In KTV',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _showHomeCheckInCodeSheet(order),
                ),
              ],
              if (order.canSellerAppeal) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                  ),
                  icon: const Icon(Icons.gavel, size: 16, color: Colors.white),
                  label: const Text(
                    'Khiếu Nại Kết Quả (24h)',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  onPressed: () => _showAppealDialog(order),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
