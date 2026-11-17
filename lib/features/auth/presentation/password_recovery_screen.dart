import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/sl_button.dart';
import '../../../shared/widgets/sl_text_field.dart';
import 'auth_providers.dart';

class PasswordRecoveryScreen extends ConsumerStatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  ConsumerState<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState
    extends ConsumerState<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  Timer? _timer;
  int _resendSeconds = 0;
  bool _sending = false;
  bool _submitting = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  bool get _emailValid =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim());

  bool _strongPassword(String value) =>
      value.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(value) &&
      RegExp(r'[a-z]').hasMatch(value) &&
      RegExp(r'\d').hasMatch(value) &&
      RegExp(r'[^A-Za-z0-9]').hasMatch(value);

  Future<void> _sendOtp() async {
    if (!_emailValid) {
      setState(() => _error = 'Vui lòng nhập địa chỉ email hợp lệ.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .requestPasswordReset(_email.text);
      if (!mounted) return;
      setState(() => _resendSeconds = 60);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return timer.cancel();
        if (_resendSeconds <= 1) {
          timer.cancel();
          setState(() => _resendSeconds = 0);
        } else {
          setState(() => _resendSeconds--);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nếu email tồn tại, hướng dẫn đặt lại đã được gửi.'),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .resetPassword(
            email: _email.text,
            otp: _otp.text,
            newPassword: _password.text,
            confirmPassword: _confirmPassword.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại.'),
        ),
      );
      context.go('/login');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khôi phục mật khẩu'),
        leading: IconButton(
          tooltip: 'Quay lại đăng nhập',
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_reset,
                      size: 52,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Đặt lại mật khẩu',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nhập email, mã OTP và mật khẩu mới để khôi phục tài khoản người bán.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SlTextField(
                      label: 'Địa chỉ Email tài khoản *',
                      hint: 'nguoiban@example.com',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_sending && !_submitting,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'Vui lòng nhập email';
                        if (!RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(value.trim()))
                          return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: _sending || _submitting || _resendSeconds > 0
                            ? null
                            : _sendOtp,
                        child: _sending
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _resendSeconds > 0
                                    ? 'Gửi lại sau ${_resendSeconds}s'
                                    : 'Gửi mã OTP',
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SlTextField(
                      label: 'Mã xác thực OTP (6 chữ số) *',
                      hint: '123456',
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value != null && RegExp(r'^\d{6}$').hasMatch(value)
                          ? null
                          : 'OTP phải gồm đúng 6 chữ số',
                    ),
                    const SizedBox(height: 12),
                    SlTextField(
                      label: 'Mật khẩu mới *',
                      controller: _password,
                      obscureText: _hidePassword,
                      suffixIcon: IconButton(
                        tooltip: _hidePassword
                            ? 'Hiện mật khẩu'
                            : 'Ẩn mật khẩu',
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      validator: (value) =>
                          value != null && _strongPassword(value)
                          ? null
                          : 'Cần ít nhất 8 ký tự gồm chữ hoa, chữ thường, số và ký tự đặc biệt',
                    ),
                    const SizedBox(height: 12),
                    SlTextField(
                      label: 'Nhập lại mật khẩu mới *',
                      controller: _confirmPassword,
                      obscureText: _hideConfirmation,
                      suffixIcon: IconButton(
                        tooltip: _hideConfirmation
                            ? 'Hiện mật khẩu'
                            : 'Ẩn mật khẩu',
                        onPressed: () => setState(
                          () => _hideConfirmation = !_hideConfirmation,
                        ),
                        icon: Icon(
                          _hideConfirmation
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      validator: (value) =>
                          value != null &&
                              value.isNotEmpty &&
                              value == _password.text
                          ? null
                          : 'Mật khẩu xác nhận không khớp',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SlButton(
                      text: 'Xác nhận đổi mật khẩu',
                      isLoading: _submitting,
                      onPressed: _resetPassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
