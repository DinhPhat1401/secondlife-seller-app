import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/sl_button.dart';
import '../../../shared/widgets/sl_text_field.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'seller@secondlife.com');
  final _passwordController = TextEditingController(text: 'seller@123456');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go('/dashboard');
    } else if (mounted) {
      final error = ref.read(authNotifierProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showServerUrlDialog() {
    final controller = TextEditingController(text: AppConfig.baseUrl);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Cấu hình URL Máy chủ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập địa chỉ máy chủ backend hoặc chọn nhanh:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.flash_on, size: 14, color: AppColors.primary),
                    label: const Text('Ngrok Tunnel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () => controller.text = 'https://clinking-slicing-visibly.ngrok-free.dev',
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.usb, size: 14, color: AppColors.textSecondary),
                    label: const Text('ADB USB (127.0.0.1)', style: TextStyle(fontSize: 12)),
                    onPressed: () => controller.text = 'http://127.0.0.1:8080',
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.wifi, size: 14, color: AppColors.textSecondary),
                    label: const Text('Wi-Fi PC (172.16.30.181)', style: TextStyle(fontSize: 12)),
                    onPressed: () => controller.text = 'http://172.16.30.181:8080',
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.phone_android, size: 14, color: AppColors.textSecondary),
                    label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 12)),
                    onPressed: () => controller.text = 'http://10.0.2.2:8080',
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = controller.text.trim();
                if (newUrl.isNotEmpty) {
                  await AppConfig.setCustomBaseUrl(newUrl);
                  ref.invalidate(apiClientProvider);
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã cập nhật máy chủ: ${AppConfig.baseUrl}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Brand Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.primaryLight,
                            child: const Icon(
                              Icons.storefront_rounded,
                              size: 42,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Kênh Người Bán',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đăng nhập SecondLife để bắt đầu đăng tin và quản lý đồ gia dụng',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 36),

                  // Email
                  SlTextField(
                    label: 'Email',
                    hint: 'nguoiban@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                      if (!v.contains('@')) return 'Email không đúng định dạng';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Password
                  SlTextField(
                    label: 'Mật khẩu',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                      if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  SlButton(
                    text: 'Đăng nhập',
                    isLoading: authState.status == AuthStatus.loading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 24),

                  // Footer Register CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản? ', style: TextStyle(color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Server URL indicator with Quick Switch Dialog
                  GestureDetector(
                    onTap: _showServerUrlDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.dns_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              AppConfig.baseUrl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.tune_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
