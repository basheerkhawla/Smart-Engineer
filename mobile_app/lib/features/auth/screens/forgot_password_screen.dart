// forgot_password_screen.dart — شاشة نسيت كلمة المرور
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/loading_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/app_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) setState(() => _emailSent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = e.code == 'user-not-found'
          ? 'البريد الإلكتروني غير مسجل'
          : 'حدث خطأ، حاول مجدداً';
      AppSnackbar.showError(context, msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إعادة تعيين كلمة المرور'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Icon(
            Icons.lock_reset_rounded,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          const Text(
            'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور',
            style: TextStyle(color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            hint: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (val) {
              if (val == null || val.isEmpty) return 'أدخل البريد الإلكتروني';
              if (!val.contains('@')) return 'بريد إلكتروني غير صالح';
              return null;
            },
          ),
          const SizedBox(height: 24),
          LoadingButton(
            label: 'إرسال رابط الإعادة',
            isLoading: _isLoading,
            onPressed: _sendReset,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline,
            size: 80, color: AppColors.success),
        const SizedBox(height: 24),
        const Text(
          'تم الإرسال!',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          'تم إرسال رابط إعادة التعيين إلى:\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 32),
        LoadingButton(
          label: 'العودة لتسجيل الدخول',
          isLoading: false,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
