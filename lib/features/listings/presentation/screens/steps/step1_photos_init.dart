import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/responsive/responsive.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_text_field.dart';
import 'package:secondlife_app_seller/features/catalog/domain/catalog_models.dart';
import 'package:secondlife_app_seller/features/catalog/presentation/catalog_providers.dart';
import 'package:secondlife_app_seller/features/credits/presentation/credit_providers.dart';
import 'package:secondlife_app_seller/features/listings/domain/post_models.dart';
import 'package:secondlife_app_seller/features/listings/presentation/create_listing_providers.dart';

class Step1PhotosInit extends ConsumerStatefulWidget {
  const Step1PhotosInit({super.key});

  @override
  ConsumerState<Step1PhotosInit> createState() => _Step1PhotosInitState();
}

class _Step1PhotosInitState extends ConsumerState<Step1PhotosInit> {
  final ImagePicker _picker = ImagePicker();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _purchaseTimeNoteController = TextEditingController();

  final List<String> _popularBrands = [
    'Panasonic',
    'Electrolux',
    'Sunhouse',
    'Philips',
    'BlueStone',
    'Sharp',
    'Kangaroo',
    'Cuckoo',
    'Lock&Lock',
    'Tefal',
    'Toshiba',
    'Samsung',
    'LG',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(createListingNotifierProvider);
    _brandController.text = state.brand;
    _modelController.text = state.model;
    _purchaseTimeNoteController.text = state.purchaseTimeNote;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _purchaseTimeNoteController.dispose();
    super.dispose();
  }

  void _syncInputs() {
    ref
        .read(createListingNotifierProvider.notifier)
        .updateBasicSpecs(
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
        );
    ref
        .read(createListingNotifierProvider.notifier)
        .setPurchaseTimeNote(_purchaseTimeNoteController.text.trim());
  }

  final List<String> _photoSlotLabels = [
    'Mặt trước tổng quan *',
    'Mặt sau / Dây nguồn *',
    'Tem thông số kỹ thuật *',
    'Khoang bên trong',
    'Góc cạnh / Trầy xước',
    'Phụ kiện & Dụng cụ',
  ];

  Future<void> _pickImage(int index, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked != null) {
        File finalFile = File(picked.path);
        try {
          final tempDir = await getTemporaryDirectory();
          final targetPath =
              '${tempDir.path}/listing_photo_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
          final compressed = await FlutterImageCompress.compressAndGetFile(
            picked.path,
            targetPath,
            format: CompressFormat.jpeg,
            quality: 85,
            minWidth: 1080,
            minHeight: 1080,
            keepExif: false,
          );
          if (compressed != null && await File(compressed.path).exists()) {
            finalFile = File(compressed.path);
          }
        } catch (_) {}

        final bytes = await finalFile.length();
        if (bytes > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Dung lượng ảnh vượt quá 10MB. Vui lòng chọn ảnh nhỏ hơn.',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
        final currentPhotos = List<File>.from(
          ref.read(createListingNotifierProvider).photos,
        );
        if (index < currentPhotos.length) {
          currentPhotos[index] = finalFile;
        } else {
          currentPhotos.add(finalFile);
        }
        ref
            .read(createListingNotifierProvider.notifier)
            .setPhotos(currentPhotos);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Chụp ảnh thực tế bằng Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(index, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Chọn ảnh từ Thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(index, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    final currentPhotos = List<File>.from(
      ref.read(createListingNotifierProvider).photos,
    );
    if (index < currentPhotos.length) {
      currentPhotos.removeAt(index);
      ref.read(createListingNotifierProvider.notifier).setPhotos(currentPhotos);
    }
  }

  void _handleInitPostError(String errMsg) {
    final lower = errMsg.toLowerCase();
    if (lower.contains('không khớp thương hiệu') ||
        lower.contains('detected_brand')) {
      final match = RegExp(
        r'\[DETECTED_BRAND:\s*([^\]]+)\]',
        caseSensitive: false,
      ).firstMatch(errMsg);
      final detectedBrand = match?.group(1)?.trim() ?? 'Thương hiệu nhận diện';
      _showBrandMismatchDialog(detectedBrand, errMsg);
      return;
    }

    if (lower.contains('insufficient_credit') ||
        lower.contains('hết lượt') ||
        lower.contains('không đủ lượt')) {
      _showNoCreditsDialog();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errMsg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showBrandMismatchDialog(String detectedBrand, String rawErr) {
    final currentBrand = ref.read(createListingNotifierProvider).brand;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 28,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hình ảnh không khớp thương hiệu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hệ thống AI nhận diện hình ảnh của bạn có logo hoặc đặc điểm thuộc thương hiệu khác với thương hiệu bạn đã nhập.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'AI phát hiện: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        detectedBrand,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (currentBrand.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Bạn đã chọn: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currentBrand,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Chọn lại ảnh khác',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              ref
                  .read(createListingNotifierProvider.notifier)
                  .updateBasicSpecs(brand: detectedBrand);
              final ok = await ref
                  .read(createListingNotifierProvider.notifier)
                  .initPost();
              if (!ok && mounted) {
                final err =
                    ref.read(createListingNotifierProvider).errorMessage ?? '';
                _handleInitPostError(err);
              }
            },
            child: Text(
              'Đổi thành $detectedBrand & Tiếp tục',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoCreditsDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hết lượt sử dụng AI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Tài khoản của bạn đã hết lượt AI để phân tích hình ảnh và hỗ trợ đăng bài. Bạn có thể nạp thêm lượt hoặc bỏ qua trợ lý AI để tự nhập thông số thiết bị.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(createListingNotifierProvider.notifier).skipToSpecs();
            },
            child: const Text(
              'Bỏ qua AI, tự nhập',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.push('/credits/buy');
            },
            child: const Text(
              'Nạp Thêm Lượt',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAiScanConfirmModal() {
    final state = ref.read(createListingNotifierProvider);
    final creditState = ref.read(creditNotifierProvider);
    final categories = ref.read(categoriesProvider).value ?? [];
    final categoryName = categories
        .firstWhere(
          (c) => c.id == state.categoryId,
          orElse: () => const CategoryModel(id: '', name: 'Thiết bị gia dụng'),
        )
        .name;
    final brand = state.brand.trim().isNotEmpty
        ? state.brand.trim()
        : 'Chưa điền thương hiệu';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                'Chi Phí: 1 Credit AI Chat',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Xác Nhận Quét Hình Ảnh Bằng AI?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Summary table
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Danh mục:', categoryName),
                  const Divider(height: 12),
                  _buildSummaryRow('Thương hiệu:', brand, isHighlight: true),
                  const Divider(height: 12),
                  _buildSummaryRow(
                    'Số lượng ảnh:',
                    '${state.photos.length} ảnh',
                  ),
                  const Divider(height: 12),
                  _buildSummaryRow(
                    'Số dư AI Chat:',
                    '${creditState.balance.chatCredits} lượt',
                    isSuccess: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Warning Banner: Resource Consumption
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lưu ý: Quá trình quét ảnh tiêu tốn tài nguyên AI thực tế. Nếu thông tin bạn nhập (loại máy hoặc thương hiệu) không khớp với ảnh, 1 credit vẫn sẽ bị trừ. Vui lòng đảm bảo thông tin trên là chính xác!',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Warning Banner: Locked Step 1
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Không thể quay lại: Sau khi xác nhận quét AI và chuyển sang Bước 2, bạn sẽ không thể quay lại Bước 1 để thay đổi danh mục hoặc chọn lại ảnh sản phẩm.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Kiểm Tra Lại',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final ok = await ref
                        .read(createListingNotifierProvider.notifier)
                        .initPost();
                    if (!ok && mounted) {
                      final err =
                          ref
                              .read(createListingNotifierProvider)
                              .errorMessage ??
                          '';
                      _handleInitPostError(err);
                    }
                  },
                  icon: const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Xác Nhận & Quét (-1)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isHighlight = false,
    bool isSuccess = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isHighlight
                ? AppColors.primary
                : isSuccess
                ? Colors.green.shade700
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createListingNotifierProvider);
    final photos = state.photos;
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = state.categoryId ?? '';
    final itemsAsync = ref.watch(itemsByCategoryProvider(selectedCategoryId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'AI Vision Nhận Diện Thiết Bị',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Chọn danh mục và chụp đủ tối thiểu 3 ảnh rõ nét (đặc biệt là tem thông số) để trợ lý AI tự động nhận diện model, năm sản xuất và gợi ý mô tả chi tiết.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category & Item Selector Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    (state.errorMessage != null &&
                        (state.categoryId == null || state.categoryId!.isEmpty))
                    ? AppColors.error
                    : AppColors.border,
              ),
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
                  children: const [
                    Icon(
                      Icons.category_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Danh Mục Thiết Bị Gia Dụng *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      hintText: 'Chọn danh mục thiết bị',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    initialValue:
                        categories.any((c) => c.id == state.categoryId)
                        ? state.categoryId
                        : null,
                    items: categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Text(
                          cat.name,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(createListingNotifierProvider.notifier)
                            .updateBasicSpecs(categoryId: val, itemId: '');
                      }
                    },
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
                  ),
                  error: (err, stack) => const Text(
                    'Không thể tải danh mục. Vui lòng kiểm tra kết nối.',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),

                if (selectedCategoryId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Loại Thiết Bị Cụ Thể (Tùy chọn)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  itemsAsync.when(
                    data: (items) => DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText: 'Chọn loại thiết bị (Nồi cơm, Lò vi sóng...)',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      initialValue: items.any((i) => i.id == state.itemId)
                          ? state.itemId
                          : null,
                      items: items.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(createListingNotifierProvider.notifier)
                              .updateBasicSpecs(itemId: val);
                        }
                      },
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                    error: (err, stack) => const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Brand & Model Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.branding_watermark_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Thương Hiệu & Dòng Máy *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SlTextField(
                        label: 'Thương hiệu *',
                        hint: 'VD: Panasonic, Sunhouse',
                        controller: _brandController,
                        onChanged: (v) => ref
                            .read(createListingNotifierProvider.notifier)
                            .updateBasicSpecs(brand: v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SlTextField(
                        label: 'Mã Model',
                        hint: 'VD: SHD7723',
                        controller: _modelController,
                        onChanged: (v) => ref
                            .read(createListingNotifierProvider.notifier)
                            .updateBasicSpecs(model: v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _popularBrands.take(6).map((b) {
                    return ActionChip(
                      label: Text(b, style: const TextStyle(fontSize: 10)),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      onPressed: () {
                        _brandController.text = b;
                        ref
                            .read(createListingNotifierProvider.notifier)
                            .updateBasicSpecs(brand: b);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Condition Grade Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.verified_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Tình Trạng Thiết Bị Thực Tế *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  children: ApplianceCondition.values.map((cond) {
                    final isSelected = state.condition == cond;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        ref
                            .read(createListingNotifierProvider.notifier)
                            .updateBasicSpecs(condition: cond);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.06)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cond.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    cond.description,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Purchase Time Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Thời Điểm Mua & Thời Gian Sử Dụng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<int>(
                        value: state.purchaseYear > 0
                            ? state.purchaseYear
                            : DateTime.now().year,
                        isDense: true,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Năm mua',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                        items: List.generate(11, (i) {
                          final yr = DateTime.now().year - i;
                          return DropdownMenuItem(
                            value: yr,
                            child: Text(
                              'Năm $yr',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            ref
                                .read(createListingNotifierProvider.notifier)
                                .setPurchaseYear(val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _purchaseTimeNoteController,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Chi tiết thời gian dùng',
                          hintText: 'VD: Dùng khoảng 6 tháng...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          ref
                              .read(createListingNotifierProvider.notifier)
                              .setPurchaseTimeNote(val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children:
                      [
                        'Dưới 6 tháng',
                        'Khoảng 6 - 12 tháng',
                        'Khoảng 1 - 2 năm',
                        'Trên 2 năm',
                        'Mua mới đầu năm nay',
                        'Mua cuối năm ngoái',
                      ].map((chip) {
                        return ActionChip(
                          label: Text(
                            chip,
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.border),
                          onPressed: () {
                            _purchaseTimeNoteController.text = chip;
                            ref
                                .read(createListingNotifierProvider.notifier)
                                .setPurchaseTimeNote(chip);
                          },
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Photos Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hình Ảnh Thiết Bị Thực Tế *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${photos.length}/6 ảnh (Tối thiểu 3)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: photos.length >= 3
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Photo Grid (6 slots)
          ResponsiveGrid(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            minTileWidth: 150,
            maxColumns: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            itemCount: 6,
            itemBuilder: (context, index) {
              final hasImage = index < photos.length;
              final label = _photoSlotLabels[index];

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showImageSourceDialog(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasImage ? AppColors.primary : AppColors.border,
                      width: hasImage ? 1.5 : 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasImage)
                          Image.file(photos[index], fit: BoxFit.cover)
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_outlined,
                                  color: AppColors.textSecondary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: label.contains('*')
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: label.contains('*')
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),

                        // Delete button overlay
                        if (hasImage)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),

                        // Label footer
                        if (hasImage)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 6,
                              ),
                              color: Colors.black.withValues(alpha: 0.6),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Error message
          if (state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // AI Processing notice
          if (state.isLoading) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đang gửi ảnh và trợ lý AI đang phân tích chi tiết sản phẩm... Quá trình có thể mất 15-30 giây.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryHover,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit Step 1 Button
          SlButton(
            text: 'Tiếp Tục: Phân Tích Với AI (${photos.length}/6 ảnh)',
            icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            isLoading: state.isLoading,
            onPressed: photos.length >= 3
                ? () {
                    _syncInputs();
                    if (state.categoryId == null || state.categoryId!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng chọn Danh Mục Thiết Bị trước khi phân tích AI',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    if (_brandController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng nhập Thương hiệu thiết bị hoặc chọn gợi ý có sẵn',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    final creditState = ref.read(creditNotifierProvider);
                    if (creditState.balance.chatCredits < 1) {
                      _showNoCreditsDialog();
                      return;
                    }
                    _showAiScanConfirmModal();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
