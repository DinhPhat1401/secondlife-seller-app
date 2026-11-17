import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/user_report_model.dart';
import '../report_providers.dart';

const _reasonLabels = <String, String>{
  'MISLEADING_DESCRIPTION': 'Mô tả sai lệch / không đúng thực tế',
  'COUNTERFEIT': 'Hàng giả / hàng nhái',
  'FRAUD': 'Dấu hiệu lừa đảo / gian lận',
  'ITEM_NOT_RECEIVED': 'Chưa nhận được hàng',
  'OTHER': 'Lý do khác',
  'LATE_HANDOVER': 'Chậm bàn giao hàng hóa',
  'SELLER_CANCELLATION': 'Người bán tự ý hủy giao dịch',
  'RETURN_NOT_AS_DESCRIBED': 'Hàng nhận được hư hỏng / khác biệt',
  'DUPLICATE_LISTING': 'Tin đăng trùng lặp',
};

class SellerDisputesScreen extends ConsumerStatefulWidget {
  const SellerDisputesScreen({super.key});

  @override
  ConsumerState<SellerDisputesScreen> createState() =>
      _SellerDisputesScreenState();
}

class _SellerDisputesScreenState extends ConsumerState<SellerDisputesScreen> {
  final _searchController = TextEditingController();
  String _status = 'ALL';
  String _target = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SellerUserReportModel> _filter(List<SellerUserReportModel> reports) {
    final query = _query.trim().toLowerCase();
    return reports
        .where((report) {
          if (_status != 'ALL' && report.status != _status) return false;
          if (_target == 'ORDER' && report.orderId == null) return false;
          if (_target == 'LISTING' && report.postId == null) return false;
          if (query.isEmpty) return true;
          return report.description.toLowerCase().contains(query) ||
              report.reasonCode.toLowerCase().contains(query) ||
              (report.orderId?.toLowerCase().contains(query) ?? false) ||
              (report.postId?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(sellerUserReportsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Khiếu nại của tôi'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () => ref.invalidate(sellerUserReportsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: reports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _errorState(error),
        data: (items) {
          final filtered = _filter(items);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sellerUserReportsProvider),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  sliver: SliverToBoxAdapter(child: _filters()),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptyState(items.isEmpty),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _reportCard(filtered[index]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filters() => Column(
    children: [
      TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Tìm theo nội dung hoặc mã đơn/bài đăng',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      const SizedBox(height: 10),
      LayoutBuilder(
        builder: (context, constraints) {
          final statusFilter = DropdownButtonFormField<String>(
            initialValue: _status,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
              DropdownMenuItem(value: 'OPEN', child: Text('Mới gửi')),
              DropdownMenuItem(value: 'IN_REVIEW', child: Text('Đang xử lý')),
              DropdownMenuItem(value: 'CONFIRMED', child: Text('Đã xác nhận')),
              DropdownMenuItem(
                value: 'DISMISSED',
                child: Text('Không được chấp nhận'),
              ),
            ],
            onChanged: (value) => setState(() => _status = value ?? 'ALL'),
          );
          final targetFilter = DropdownButtonFormField<String>(
            initialValue: _target,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Đối tượng',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
              DropdownMenuItem(value: 'ORDER', child: Text('Đơn hàng')),
              DropdownMenuItem(value: 'LISTING', child: Text('Bài đăng')),
            ],
            onChanged: (value) => setState(() => _target = value ?? 'ALL'),
          );
          if (constraints.maxWidth < 560) {
            return Column(
              children: [
                statusFilter,
                const SizedBox(height: 10),
                targetFilter,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: statusFilter),
              const SizedBox(width: 10),
              Expanded(child: targetFilter),
            ],
          );
        },
      ),
    ],
  );

  Widget _reportCard(SellerUserReportModel report) {
    final date = report.createdAt == null
        ? 'Ngày gửi chưa có dữ liệu'
        : DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt!.toLocal());
    final status = _statusLabel(report.status);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetails(report),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    label: Text(status),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: _statusColor(
                      report.status,
                    ).withValues(alpha: .12),
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _reasonLabels[report.reasonCode] ?? report.reasonCode,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                report.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                report.orderId != null
                    ? 'Đơn hàng #${report.orderId!.substring(0, report.orderId!.length.clamp(0, 8))}'
                    : 'Bài đăng #${(report.postId ?? '').substring(0, (report.postId ?? '').length.clamp(0, 8))}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(SellerUserReportModel report) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .82,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  _reasonLabels[report.reasonCode] ?? report.reasonCode,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Trạng thái: ${_statusLabel(report.status)}'),
                if (report.orderId != null) Text('Mã đơn: ${report.orderId}'),
                if (report.postId != null)
                  Text('Mã bài đăng: ${report.postId}'),
                if (report.createdAt != null)
                  Text(
                    'Ngày gửi: ${DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt!.toLocal())}',
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Nội dung',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(report.description),
                if (report.responsibleParty != null)
                  Text('Bên liên quan: ${report.responsibleParty}'),
                if (report.decisionReason?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Lý do xử lý',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(report.decisionReason!),
                ],
                if (report.resolutionAction != null)
                  Text('Hướng xử lý: ${report.resolutionAction}'),
                if (report.refundAmount != null)
                  Text(
                    'Số tiền hoàn: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(report.refundAmount)}',
                  ),
                if (report.evidenceUrls.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Bằng chứng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: report.evidenceUrls.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) =>
                          _evidenceTile(report.evidenceUrls[index]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _evidenceTile(String url) {
    final future = ref
        .read(sellerUserReportRepositoryProvider)
        .readEvidence(url);
    return FutureBuilder<List<int>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox(
            width: 88,
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.textMuted,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 88,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return GestureDetector(
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => Dialog(
              child: InteractiveViewer(
                child: Image.memory(Uint8List.fromList(snapshot.data!)),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              Uint8List.fromList(snapshot.data!),
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _errorState(Object error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44),
          const SizedBox(height: 12),
          const Text('Không thể tải danh sách khiếu nại. Vui lòng thử lại.'),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => ref.invalidate(sellerUserReportsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
          if (error.toString().isNotEmpty)
            Text(
              error.toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    ),
  );

  Widget _emptyState(bool noReports) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            noReports
                ? 'Bạn chưa có khiếu nại nào.'
                : 'Không có kết quả phù hợp.',
          ),
        ],
      ),
    ),
  );

  String _statusLabel(String status) => switch (status) {
    'OPEN' => 'Mới gửi',
    'IN_REVIEW' => 'Đang xử lý',
    'CONFIRMED' => 'Đã xác nhận',
    'DISMISSED' => 'Không được chấp nhận',
    _ => status,
  };

  Color _statusColor(String status) => switch (status) {
    'CONFIRMED' => AppColors.success,
    'DISMISSED' => AppColors.error,
    'IN_REVIEW' => AppColors.warning,
    _ => AppColors.primary,
  };
}
