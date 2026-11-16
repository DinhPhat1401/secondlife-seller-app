import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/credits/presentation/credit_providers.dart';
import 'package:secondlife_app_seller/features/listings/domain/post_models.dart';
import 'package:secondlife_app_seller/features/listings/presentation/create_listing_providers.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_text_field.dart';

class Step2AiChat extends ConsumerStatefulWidget {
  const Step2AiChat({super.key});

  @override
  ConsumerState<Step2AiChat> createState() => _Step2AiChatState();
}

class _Step2AiChatState extends ConsumerState<Step2AiChat> {
  final _chatInputController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  final _chatScrollController = ScrollController();
  bool _previewMarkdown = false;

  final List<Map<String, dynamic>> _packagePresets = [
    {'name': 'Nồi chiên / Nồi cơm', 'w': 3000, 'l': 30, 'wid': 30, 'h': 35},
    {'name': 'Lò vi sóng', 'w': 12000, 'l': 50, 'wid': 40, 'h': 35},
    {'name': 'Quạt cây đứng', 'w': 5000, 'l': 45, 'wid': 45, 'h': 85},
    {'name': 'Máy hút bụi', 'w': 4000, 'l': 40, 'wid': 30, 'h': 30},
    {'name': 'Máy giặt / Tủ lạnh mini', 'w': 28000, 'l': 60, 'wid': 60, 'h': 85},
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(createListingNotifierProvider);
    _titleController.text = state.title;
    _descController.text = state.description;

    final pkg = state.shippingPackage;
    _weightController.text = pkg.weightGrams > 0 ? pkg.weightGrams.toString() : '2500';
    _lengthController.text = pkg.lengthCm > 0 ? pkg.lengthCm.toString() : '30';
    _widthController.text = pkg.widthCm > 0 ? pkg.widthCm.toString() : '25';
    _heightController.text = pkg.heightCm > 0 ? pkg.heightCm.toString() : '20';
  }

  @override
  void dispose() {
    _chatInputController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _syncPackage() {
    final w = int.tryParse(_weightController.text) ?? 2500;
    final l = int.tryParse(_lengthController.text) ?? 30;
    final wid = int.tryParse(_widthController.text) ?? 25;
    final h = int.tryParse(_heightController.text) ?? 20;

    ref.read(createListingNotifierProvider.notifier).setShippingPackage(
          ShippingPackageModel(
            weightGrams: w,
            lengthCm: l,
            widthCm: wid,
            heightCm: h,
          ),
        );
  }

  void _applyPreset(Map<String, dynamic> p) {
    setState(() {
      _weightController.text = p['w'].toString();
      _lengthController.text = p['l'].toString();
      _widthController.text = p['wid'].toString();
      _heightController.text = p['h'].toString();
    });
    _syncPackage();
  }

  void _sendMessage([String? quickText]) {
    final text = quickText ?? _chatInputController.text;
    if (text.trim().isEmpty) return;

    ref.read(createListingNotifierProvider.notifier).sendAiMessage(text);
    _chatInputController.clear();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleFinalize() async {
    final creditState = ref.read(creditNotifierProvider);
    if (creditState.balance.chatCredits < 1) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.stars_rounded, color: AppColors.error, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text('Hết lượt AI Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: const Text(
            'Bạn đã sử dụng hết số dư AI Chat. Vui lòng nạp thêm lượt để AI hỗ trợ viết bài mô tả hoàn chỉnh.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                ref.read(createListingNotifierProvider.notifier).skipToSpecs();
              },
              child: const Text('Bỏ qua AI, tự viết', style: TextStyle(color: AppColors.textSecondary)),
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
              child: const Text('Nạp Thêm Lượt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final success = await ref.read(createListingNotifierProvider.notifier).finalizeDescription();
    if (success && mounted) {
      final updatedState = ref.read(createListingNotifierProvider);
      setState(() {
        _descController.text = updatedState.description;
        if (updatedState.title.isNotEmpty) {
          _titleController.text = updatedState.title;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI đã tổng hợp mô tả và tiêu đề thành công! Hãy kiểm tra và điều chỉnh bên dưới.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      final err = ref.read(createListingNotifierProvider).errorMessage ?? 'Không thể tổng hợp bài mô tả từ AI';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _proceedToStep3() async {
    final notifier = ref.read(createListingNotifierProvider.notifier);
    notifier.setTitle(_titleController.text.trim());
    notifier.setDescription(_descController.text.trim());
    _syncPackage();

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Tiêu Đề Bài Viết'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Nội Dung Mô Tả Sản Phẩm'), backgroundColor: AppColors.error),
      );
      return;
    }

    final ok = await notifier.saveAndProceedToAccept();
    if (!ok && mounted) {
      final err = ref.read(createListingNotifierProvider).errorMessage ?? 'Lỗi lưu thông tin';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createListingNotifierProvider);
    final messages = state.chatMessages;

    final w = int.tryParse(_weightController.text) ?? 0;
    final l = int.tryParse(_lengthController.text) ?? 0;
    final wid = int.tryParse(_widthController.text) ?? 0;
    final h = int.tryParse(_heightController.text) ?? 0;
    final volumetricWeightKg = (l * wid * h) / 5000;
    final actualWeightKg = w / 1000;
    final isMotorbikeFriendly = actualWeightKg <= 30 && volumetricWeightKg <= 30;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================
          // 1. AI CHAT & SURVEY SECTION
          // ==========================================
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trợ Lý AI Phỏng Vấn (-1 Credit)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                            ),
                            Text(
                              'Trả lời ngắn để AI tổng hợp thành bài đăng chuẩn SEO.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Chat Messages Box
                Container(
                  height: 190,
                  padding: const EdgeInsets.all(12),
                  child: messages.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có tin nhắn khảo sát. Bạn có thể tự gõ mô tả bên dưới.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          controller: _chatScrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isUser = msg.isUser;
                            return Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                                decoration: BoxDecoration(
                                  color: isUser ? AppColors.primary : AppColors.background,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: Radius.circular(isUser ? 12 : 2),
                                    bottomRight: Radius.circular(isUser ? 2 : 12),
                                  ),
                                  border: isUser ? null : Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  msg.content,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isUser ? Colors.white : AppColors.textPrimary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Quick Questions Chips
                if (state.suggestedQuestions.isNotEmpty)
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.suggestedQuestions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final q = state.suggestedQuestions[index];
                        return ActionChip(
                          label: Text(q, style: const TextStyle(fontSize: 10)),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          onPressed: () => _sendMessage(q),
                        );
                      },
                    ),
                  ),

                // Input Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatInputController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Gõ trả lời (VD: Máy chạy êm, nguyên zin, đủ phụ kiện)...',
                            hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: AppColors.background,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                          minimumSize: Size.zero,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        onPressed: () => _sendMessage(),
                      ),
                    ],
                  ),
                ),

                // Trigger Finalize Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: SlButton(
                          text: '✨ Hoàn Tất & Sinh Mô Tả AI (-1 Credit)',
                          isLoading: state.isLoading,
                          onPressed: () => _handleFinalize(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ref.read(createListingNotifierProvider.notifier).skipToSpecs();
                          final s = ref.read(createListingNotifierProvider);
                          setState(() {
                            _descController.text = s.description;
                            if (s.title.isNotEmpty) _titleController.text = s.title;
                          });
                        },
                        child: const Text('Bỏ qua AI', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ==========================================
          // 2. TITLE & DESCRIPTION SECTION
          // ==========================================
          Container(
            padding: const EdgeInsets.all(14),
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
                    const Text('Tiêu Đề Bài Viết *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      icon: const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                      label: const Text('Gợi Ý AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      onPressed: () async {
                        await ref.read(createListingNotifierProvider.notifier).suggestTitle();
                        final t = ref.read(createListingNotifierProvider).title;
                        if (t.isNotEmpty) {
                          setState(() => _titleController.text = t);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SlTextField(
                  label: '',
                  hint: 'VD: Nồi Cơm Điện BlueStone 1.8L - Hàng Lướt Like New 99%',
                  controller: _titleController,
                  onChanged: (v) => ref.read(createListingNotifierProvider.notifier).setTitle(v),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nội Dung Mô Tả Sản Phẩm *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    InkWell(
                      onTap: () => setState(() => _previewMarkdown = !_previewMarkdown),
                      child: Text(
                        _previewMarkdown ? 'Chỉnh sửa' : 'Xem trước',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _previewMarkdown
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        constraints: const BoxConstraints(minHeight: 120),
                        child: MarkdownBody(
                          data: _descController.text.isNotEmpty ? _descController.text : '*Chưa có nội dung*',
                        ),
                      )
                    : TextField(
                        controller: _descController,
                        maxLines: 6,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Nhập mô tả chi tiết: tình trạng thực tế, linh kiện, lý do thanh lý...',
                          hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        onChanged: (v) => ref.read(createListingNotifierProvider.notifier).setDescription(v),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ==========================================
          // 3. SHIPPING PACKAGE (LALAMOVE)
          // ==========================================
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thông Số Đóng Gói Kiện Hàng (Bắt buộc)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hệ thống tự động liên kết cước phí vận chuyển Lalamove / GHN dựa trên số liệu này.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                // Presets
                const Text('Chọn Nhanh Gói Chuẩn:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _packagePresets.map((p) {
                    return ActionChip(
                      label: Text(p['name'] as String, style: const TextStyle(fontSize: 10)),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      onPressed: () => _applyPreset(p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Weight & Dimensions Inputs
                Row(
                  children: [
                    Expanded(
                      child: SlTextField(
                        label: 'Trọng lượng (gram) *',
                        hint: 'VD: 3500',
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _syncPackage(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SlTextField(
                        label: 'Chiều dài (cm) *',
                        hint: 'VD: 35',
                        controller: _lengthController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _syncPackage(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SlTextField(
                        label: 'Chiều rộng (cm) *',
                        hint: 'VD: 25',
                        controller: _widthController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _syncPackage(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SlTextField(
                        label: 'Chiều cao (cm) *',
                        hint: 'VD: 20',
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _syncPackage(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Vehicle suggestion badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isMotorbikeFriendly ? AppColors.successLight : AppColors.infoLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isMotorbikeFriendly ? AppColors.success.withValues(alpha: 0.3) : AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isMotorbikeFriendly ? Icons.two_wheeler_outlined : Icons.local_shipping_outlined,
                        size: 20,
                        color: isMotorbikeFriendly ? AppColors.success : AppColors.info,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isMotorbikeFriendly
                              ? 'Khối lượng: ${(w / 1000).toStringAsFixed(1)} kg - Phù hợp giao bằng Xe Máy Lalamove (Tiết kiệm)'
                              : 'Khối lượng: ${(w / 1000).toStringAsFixed(1)} kg - Yêu cầu Xe Bán Tải / Xe Tải Lalamove',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isMotorbikeFriendly ? AppColors.success : AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Next Step Button
          SlButton(
            text: 'Tiếp Tục: Sang Bước 3 (Xác Nhận Mô Tả)',
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            isLoading: state.isLoading,
            onPressed: () => _proceedToStep3(),
          ),
        ],
      ),
    );
  }
}
