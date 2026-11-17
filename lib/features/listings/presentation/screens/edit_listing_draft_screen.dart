import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/post_models.dart';
import '../create_listing_providers.dart';

class EditListingDraftScreen extends ConsumerStatefulWidget {
  const EditListingDraftScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<EditListingDraftScreen> createState() =>
      _EditListingDraftScreenState();
}

class _EditListingDraftScreenState
    extends ConsumerState<EditListingDraftScreen> {
  late Future<Map<String, dynamic>> _detail;

  @override
  void initState() {
    super.initState();
    _detail = _load();
  }

  Future<Map<String, dynamic>> _load() =>
      ref.read(postRepositoryProvider).getMyPostDetail(widget.postId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chỉnh sửa tin đăng')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Không tải được tin đăng: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _detail = _load()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _EditListingDraftForm(
            postId: widget.postId,
            listing: snapshot.requireData,
          );
        },
      ),
    );
  }
}

class _EditListingDraftForm extends ConsumerStatefulWidget {
  const _EditListingDraftForm({required this.postId, required this.listing});

  final String postId;
  final Map<String, dynamic> listing;

  @override
  ConsumerState<_EditListingDraftForm> createState() =>
      _EditListingDraftFormState();
}

class _EditListingDraftFormState extends ConsumerState<_EditListingDraftForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _weight;
  late final TextEditingController _length;
  late final TextEditingController _width;
  late final TextEditingController _height;
  late ApplianceCondition _condition;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.listing;
    _title = TextEditingController(text: data['title']?.toString() ?? '');
    _description = TextEditingController(
      text: data['description']?.toString() ?? '',
    );
    _price = TextEditingController(text: data['price']?.toString() ?? '');
    _weight = TextEditingController(
      text: (data['shippingWeight'] ?? '').toString(),
    );
    _length = TextEditingController(
      text: (data['shippingLength'] ?? '').toString(),
    );
    _width = TextEditingController(
      text: (data['shippingWidth'] ?? '').toString(),
    );
    _height = TextEditingController(
      text: (data['shippingHeight'] ?? '').toString(),
    );
    _condition = ApplianceCondition.fromCode(data['itemCondition']?.toString());
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _weight.dispose();
    _length.dispose();
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(postRepositoryProvider)
          .updateDraft(postId: widget.postId, data: _draftPayload());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thay đổi tin đăng.')),
      );
      context.pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lưu tin đăng: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _validate() {
    if (!_formKey.currentState!.validate()) return false;
    if (int.parse(_length.text) >= int.parse(_width.text)) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chiều dài phải lớn hơn hoặc bằng chiều rộng.'),
        backgroundColor: AppColors.error,
      ),
    );
    return false;
  }

  Map<String, dynamic> _draftPayload() => {
    'title': _title.text.trim(),
    'description': _description.text.trim(),
    'itemCondition': _condition.code,
    'price': double.parse(_price.text.trim()),
    'shippingWeight': int.parse(_weight.text),
    'shippingLength': int.parse(_length.text),
    'shippingWidth': int.parse(_width.text),
    'shippingHeight': int.parse(_height.text),
  };

  Future<void> _continueDraft() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final repository = ref.read(postRepositoryProvider);
      await repository.updateDraft(
        postId: widget.postId,
        data: _draftPayload(),
      );
      await repository.acceptDescription(
        postId: widget.postId,
        description: _description.text.trim(),
      );
      final images = (widget.listing['imageUrls'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .where((url) => url.isNotEmpty)
          .toList(growable: false);
      ref
          .read(createListingNotifierProvider.notifier)
          .prepareExistingDraftForSubmission(
            postId: widget.postId,
            title: _title.text.trim(),
            description: _description.text.trim(),
            itemCondition: _condition.code,
            price: double.parse(_price.text.trim()),
            shippingPackage: ShippingPackageModel(
              weightGrams: int.parse(_weight.text),
              lengthCm: int.parse(_length.text),
              widthCm: int.parse(_width.text),
              heightCm: int.parse(_height.text),
            ),
            imageUrls: images,
          );
      if (mounted) context.pushReplacement('/create-listing');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tiếp tục đăng tin: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
    ),
  );

  String? _positiveInt(String? value, String label) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < 1 ? '$label phải từ 1 trở lên.' : null;
  }

  @override
  Widget build(BuildContext context) {
    final images = (widget.listing['imageUrls'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (images.isNotEmpty) ...[
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      images[index],
                      width: 112,
                      height: 112,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 112,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _field(
              'Tiêu đề *',
              _title,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập tiêu đề.'
                  : value.trim().length > 255
                  ? 'Tiêu đề tối đa 255 ký tự.'
                  : null,
            ),
            _field(
              'Mô tả *',
              _description,
              maxLines: 6,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập mô tả.'
                  : value.trim().length > 10000
                  ? 'Mô tả tối đa 10.000 ký tự.'
                  : null,
            ),
            DropdownButtonFormField<ApplianceCondition>(
              initialValue: _condition,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tình trạng sản phẩm',
                border: OutlineInputBorder(),
              ),
              items: ApplianceCondition.values
                  .map(
                    (condition) => DropdownMenuItem(
                      value: condition,
                      child: Text(
                        condition.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _condition = value);
                    },
            ),
            const SizedBox(height: 14),
            _field(
              'Giá bán (VND) *',
              _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final price = double.tryParse(value ?? '');
                final validFormat = RegExp(
                  r'^\d{1,16}(\.\d{1,2})?$',
                ).hasMatch(value?.trim() ?? '');
                return !validFormat ||
                        price == null ||
                        price < 1000 ||
                        price > 1000000000
                    ? 'Giá bán phải từ 1.000 đến 1.000.000.000 VND.'
                    : null;
              },
            ),
            _field(
              'Khối lượng kiện (gram) *',
              _weight,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => _positiveInt(value, 'Khối lượng'),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final fields = [
                  _field(
                    'Dài (cm) *',
                    _length,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => _positiveInt(value, 'Chiều dài'),
                  ),
                  _field(
                    'Rộng (cm) *',
                    _width,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => _positiveInt(value, 'Chiều rộng'),
                  ),
                  _field(
                    'Cao (cm) *',
                    _height,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => _positiveInt(value, 'Chiều cao'),
                  ),
                ];
                if (constraints.maxWidth < 560) {
                  return Column(children: fields);
                }
                return Row(
                  children: [
                    for (var index = 0; index < fields.length; index++) ...[
                      if (index > 0) const SizedBox(width: 10),
                      Expanded(child: fields[index]),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Lưu thay đổi'),
            ),
            if (widget.listing['status']?.toString().toUpperCase() ==
                'DRAFT') ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _saving ? null : _continueDraft,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: const Text('Tiếp tục đăng bài'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
