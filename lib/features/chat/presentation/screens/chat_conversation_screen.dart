import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_models.dart';
import '../chat_providers.dart';

class ChatConversationScreen extends ConsumerStatefulWidget {
  final String roomId;
  final ChatRoomModel? room;

  const ChatConversationScreen({
    super.key,
    required this.roomId,
    this.room,
  });

  @override
  ConsumerState<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends ConsumerState<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatMessagesNotifierProvider.notifier).fetchMessages(widget.roomId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final success = await ref
        .read(chatMessagesNotifierProvider.notifier)
        .sendMessage(widget.roomId, text);

    setState(() => _isSending = false);

    if (success) {
      _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                widget.room != null && widget.room!.buyerName.isNotEmpty
                    ? widget.room!.buyerName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room?.buyerName ?? 'Khách hàng',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Đang hoạt động',
                    style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(chatMessagesNotifierProvider.notifier).fetchMessages(widget.roomId),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.room?.postTitle != null) _buildProductBanner(),
          Expanded(
            child: _buildMessagesList(messagesState),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatMessagesState messagesState) {
    if (messagesState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (messagesState.errorMessage != null) {
      return Center(
        child: Text('Lỗi tải tin nhắn: ${messagesState.errorMessage}',
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    final messages = messagesState.messages;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    if (messages.isEmpty) {
      return const Center(
        child: Text('Chưa có tin nhắn nào. Hãy gửi lời chào đến người mua!',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      );
    }

    // Deduplicate duplicate/consecutive inspection proposal messages
    final List<ChatMessageModel> filtered = [];
    final Set<String> seenProposalKeys = {};

    for (final msg in messages.reversed) {
      if (msg.isSystem && msg.isInspectionProposal) {
        final orderId = msg.inspectionProposalOrderId ?? '';
        final key = orderId.isNotEmpty ? 'insp_$orderId' : 'insp_${msg.sentAt}';
        if (seenProposalKeys.contains(key)) {
          continue;
        }
        seenProposalKeys.add(key);
      }
      filtered.add(msg);
    }
    final displayMessages = filtered.reversed.toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: displayMessages.length,
      itemBuilder: (context, index) {
        final msg = displayMessages[index];
        return _buildMessageItem(msg);
      },
    );
  }

  Widget _buildProductBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: widget.room?.postImageUrl != null
                ? Image.network(
                    widget.room!.postImageUrl!,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderSquare(),
                  )
                : _buildPlaceholderSquare(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.room!.postTitle!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            icon: const Icon(Icons.handshake_outlined, size: 16, color: AppColors.primary),
            label: const Text('Xem Trả Giá', style: TextStyle(fontSize: 12, color: AppColors.primary)),
            onPressed: () => context.push('/negotiations'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderSquare() {
    return Container(
      width: 38,
      height: 38,
      color: AppColors.divider,
      child: const Icon(Icons.kitchen_outlined, size: 20, color: AppColors.textMuted),
    );
  }

  Widget _buildMessageItem(ChatMessageModel msg) {
    if (msg.isSystem) {
      if (msg.isInspectionProposal) {
        return _buildInspectionProposalBubble(msg);
      }
      if (msg.isOffer) {
        return _buildSystemOfferBubble(msg);
      }
      return _buildGenericSystemBubble(msg);
    }

    final isMe = msg.senderId == 'ME' ||
        (widget.room != null && msg.senderId == widget.room!.sellerId);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
          border: isMe ? null : Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.messageContent,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(msg.sentAt),
              style: TextStyle(
                color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionProposalBubble(ChatMessageModel msg) {
    final payload = msg.inspectionProposalPayload ?? {};
    final status = (payload['status']?.toString() ?? 'PENDING').toUpperCase();
    final orderId = payload['orderId']?.toString() ?? '';
    final method = payload['method']?.toString() ?? 'AT_CENTER';
    final isAtHome = method.toUpperCase() == 'AT_HOME';
    final feeSplit = (payload['feeSplit'] ?? payload['feePayer'])?.toString().toUpperCase() ?? 'BUYER_100';
    final totalFee = (payload['estimatedFeeVnd'] ??
            payload['totalAtCenterFee'] ??
            payload['baseInspectionFee'] as num?)
        ?.toDouble() ??
        0.0;
    final sellerFeeShare = (payload['sellerFeeShare'] as num?)?.toDouble();
    final centerName = payload['centerName']?.toString();

    final isAccepted = status == 'ACCEPTED';
    final isRejected = status == 'REJECTED';
    final isCancelled = status == 'CANCELLED';
    final isPending = status == 'PENDING' || status == 'WAITING_SELLER_APPROVAL';

    final Color bgColor;
    final Color borderColor;
    final Color accentColor;
    final String statusLabel;
    final Color statusTextColor;
    final Color statusBgColor;

    if (isAccepted) {
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      accentColor = const Color(0xFF16A34A);
      statusLabel = 'Đã chấp thuận';
      statusTextColor = const Color(0xFF15803D);
      statusBgColor = const Color(0xFFDCFCE7);
    } else if (isRejected) {
      bgColor = const Color(0xFFFFF1F2);
      borderColor = const Color(0xFFFECDD3);
      accentColor = const Color(0xFFE11D48);
      statusLabel = 'Đã từ chối';
      statusTextColor = const Color(0xFFBE123C);
      statusBgColor = const Color(0xFFFFE4E6);
    } else if (isCancelled) {
      bgColor = const Color(0xFFF9FAFB);
      borderColor = const Color(0xFFE5E7EB);
      accentColor = AppColors.textMuted;
      statusLabel = 'Đã hủy';
      statusTextColor = AppColors.textSecondary;
      statusBgColor = const Color(0xFFF3F4F6);
    } else {
      bgColor = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFFED7AA);
      accentColor = const Color(0xFFEA580C);
      statusLabel = 'Chờ bạn phản hồi';
      statusTextColor = const Color(0xFF9A3412);
      statusBgColor = const Color(0xFFFFEDD5);
    }

    final feeSplitText = (feeSplit == 'BUYER_100' || feeSplit == 'BUYER_PAYS')
        ? 'Người mua chịu 100%'
        : (feeSplit == 'SELLER_100' || feeSplit == 'SELLER_PAYS')
            ? 'Người bán chịu 100%'
            : 'Hai bên chia đôi 50/50';

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.90),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.2),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified_outlined, color: accentColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ĐỀ XUẤT KIỂM ĐỊNH SẢN PHẨM',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (orderId.isNotEmpty)
                        Text(
                          'Mã đơn: #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: statusTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(isAtHome ? Icons.home_outlined : Icons.storefront_outlined,
                          size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      const Text(
                        'Hình thức: ',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Expanded(
                        child: Text(
                          isAtHome
                              ? 'KTV kiểm định tại nhà'
                              : 'Tại Hub (${centerName ?? 'Trung tâm SecondLife'})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.pie_chart_outline_rounded,
                          size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      const Text(
                        'Phân chia phí: ',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Expanded(
                        child: Text(
                          feeSplitText,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (totalFee > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined,
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        const Text(
                          'Tổng phí dự kiến: ',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Expanded(
                          child: Text(
                            currencyFormat.format(totalFee),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (sellerFeeShare != null && sellerFeeShare > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 21),
                        const Text(
                          'Phần bạn cần trả: ',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        Text(
                          currencyFormat.format(sellerFeeShare),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC2410C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.assignment_outlined, size: 16),
                label: Text(
                  isPending ? 'Xem & Phản Hồi Đề Xuất' : 'Xem Chi Tiết Đơn Kiểm Định',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => context.push('/orders', extra: {'mode': 1}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOfferBubble(ChatMessageModel msg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          border: Border.all(color: const Color(0xFFFED7AA)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.handshake_rounded, color: Color(0xFFEA580C), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    msg.cleanText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9A3412),
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => context.push('/negotiations'),
              child: const Text(
                'Bấm vào đây để Xem & Chấp thuận hoặc Từ chối',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericSystemBubble(ChatMessageModel msg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          msg.cleanText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          softWrap: true,
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _messageController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn trả lời...',
                    hintStyle: TextStyle(fontSize: 14, color: AppColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: _handleSendMessage,
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return '';
    }
  }
}
