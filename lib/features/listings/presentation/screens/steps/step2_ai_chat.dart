import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import 'package:secondlife_app_seller/features/listings/presentation/create_listing_providers.dart';

class Step2AiChat extends ConsumerStatefulWidget {
  const Step2AiChat({super.key});

  @override
  ConsumerState<Step2AiChat> createState() => _Step2AiChatState();
}

class _Step2AiChatState extends ConsumerState<Step2AiChat> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatMarkdown(String raw) {
    var text = raw.trim();
    // Ensure clean line breaks before bold numbered points like **1. ...** or **2. ...**
    text = text.replaceAllMapped(
      RegExp(r'(?<!\n)\n\s*(\*\*\d+\.)'),
      (match) => '\n\n${match.group(1)}',
    );
    // Ensure clean line breaks before bullet points
    text = text.replaceAllMapped(
      RegExp(r'(?<!\n)\n\s*(\*|\-)\s+'),
      (match) => '\n\n${match.group(1)} ',
    );
    return text;
  }

  void _sendMessage([String? quickText]) {
    final text = quickText ?? _textController.text;
    if (text.trim().isEmpty) return;

    ref.read(createListingNotifierProvider.notifier).sendAiMessage(text);
    _textController.clear();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleFinalize() async {
    final success = await ref.read(createListingNotifierProvider.notifier).finalizeDescription();
    if (!success && mounted) {
      final err = ref.read(createListingNotifierProvider).errorMessage ?? 'Không thể tổng hợp bài mô tả từ AI';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Sang Bước 3',
            textColor: Colors.white,
            onPressed: () {
              ref.read(createListingNotifierProvider.notifier).skipToSpecs();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createListingNotifierProvider);
    final messages = state.chatMessages;

    return Column(
      children: [
        // AI Header Guide
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surface,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trợ Lý AI Phỏng Vấn Tình Trạng Thiết Bị',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Trả lời vài câu hỏi ngắn để AI sinh bài mô tả hấp dẫn, chuẩn SEO.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Chat Message List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isUser = msg.isUser;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(Icons.smart_toy, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 16),
                          ),
                          border: isUser ? null : Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isUser
                            ? Text(
                                msg.content,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              )
                            : MarkdownBody(
                                data: _formatMarkdown(msg.content),
                                selectable: true,
                                softLineBreak: true,
                                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                  p: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                                  pPadding: const EdgeInsets.only(bottom: 6),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                  em: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                  h1: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                  h2: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                  h3: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                  listBullet: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  listIndent: 16,
                                  blockSpacing: 8,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Suggested Quick Questions Chips
        if (state.suggestedQuestions.isNotEmpty)
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.suggestedQuestions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final q = state.suggestedQuestions[index];
                return ActionChip(
                  label: Text(q, style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  onPressed: () => _sendMessage(q),
                );
              },
            ),
          ),

        // Input & Actions
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Nhập câu trả lời (VD: Máy chạy êm, đủ khay vỉ)...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
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
                    ),
                    icon: const Icon(Icons.send_rounded, size: 20),
                    onPressed: () => _sendMessage(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // AI Loading status notice
              if (state.isLoading) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Trợ lý AI đang đọc nội dung khảo sát để sinh bài mô tả chuẩn SEO...',
                          style: TextStyle(fontSize: 12, color: AppColors.primaryHover, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Error banner with retry & skip actions
              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              ref.read(createListingNotifierProvider.notifier).skipToSpecs();
                            },
                            child: const Text('Bỏ qua & Sang Bước 3', style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _handleFinalize(),
                            child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Finalize Description Button
              SlButton(
                text: 'Hoàn Tất Khảo Sát & Sinh Mô Tả AI',
                icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                isLoading: state.isLoading,
                onPressed: () => _handleFinalize(),
              ),
              const SizedBox(height: 6),

              // Skip option
              TextButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        ref.read(createListingNotifierProvider.notifier).skipToSpecs();
                      },
                child: const Text(
                  'Bỏ qua khảo sát & Sang Bước 3 (Tự nhập thông số)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
