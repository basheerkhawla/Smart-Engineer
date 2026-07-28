// register_screen.dart — شاشة التسجيل مع موافقة الخصوصية الإلزامية
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/loading_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/app_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // الموافقات الإلزامية (3 موافقات مستقلة)
  bool _privacyAccepted = false;
  bool _locationConsentAccepted = false;
  bool _aiConsentAccepted = false;

  bool get _allConsentsAccepted =>
      _privacyAccepted && _locationConsentAccepted && _aiConsentAccepted;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_allConsentsAccepted) {
      AppSnackbar.showError(
          context, 'يجب الموافقة على جميع الشروط للمتابعة');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        privacyAccepted: _privacyAccepted,
        locationConsentAccepted: _locationConsentAccepted,
        aiConsentAccepted: _aiConsentAccepted,
      );
      // التوجيه لصفحة التحقق من الإيميل
      if (mounted) context.go('/verify-email');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = _getErrorMessage(e.code);
      AppSnackbar.showError(context, message);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'حدث خطأ. حاول مجدداً');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مسجل مسبقاً';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      default:
        return 'خطأ في إنشاء الحساب: $code';
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(AppConstants.privacyPolicyUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // الاسم
                    CustomTextField(
                      controller: _nameController,
                      label: 'الاسم الكامل',
                      hint: 'م. أحمد محمد',
                      prefixIcon: Icons.person_outline,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'أدخل اسمك الكامل';
                        if (val.length < 3) return 'الاسم قصير جداً';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // البريد الإلكتروني
                    CustomTextField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      hint: 'example@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'أدخل البريد الإلكتروني';
                        if (!val.contains('@') || !val.contains('.'))
                          return 'بريد إلكتروني غير صالح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // كلمة المرور
                    CustomTextField(
                      controller: _passwordController,
                      label: 'كلمة المرور',
                      hint: '••••••••',
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'أدخل كلمة المرور';
                        if (val.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // تأكيد كلمة المرور
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'تأكيد كلمة المرور',
                      hint: '••••••••',
                      obscureText: _obscureConfirm,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (val) {
                        if (val != _passwordController.text)
                          return 'كلمتا المرور غير متطابقتان';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // ===== قسم الموافقات الإلزامية =====
                    _buildConsentsSection(),
                    const SizedBox(height: 28),

                    // زر التسجيل
                    LoadingButton(
                      label: 'إنشاء الحساب',
                      isLoading: _isLoading,
                      onPressed: _allConsentsAccepted ? _register : null,
                    ),
                    const SizedBox(height: 16),

                    // رابط الدخول
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'لديك حساب؟ ',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الموافقات الإلزامية',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),

          // 1. سياسة الخصوصية
          _buildConsentItem(
            value: _privacyAccepted,
            onChanged: (val) => setState(() => _privacyAccepted = val!),
            text: 'أوافق على ',
            linkText: 'سياسة الخصوصية وشروط الاستخدام',
            onLinkTap: _openPrivacyPolicy,
          ),
          const SizedBox(height: 10),

          // 2. الموقع الجغرافي
          _buildConsentItem(
            value: _locationConsentAccepted,
            onChanged: (val) =>
                setState(() => _locationConsentAccepted = val!),
            text: 'أوافق على استخدام موقعي الجغرافي (GPS) لختم الصور وتوثيق الموقع الميداني',
            linkText: '',
            onLinkTap: null,
          ),
          const SizedBox(height: 10),

          // 3. الذكاء الاصطناعي
          _buildConsentItem(
            value: _aiConsentAccepted,
            onChanged: (val) => setState(() => _aiConsentAccepted = val!),
            text: 'أوافق على إرسال ملاحظاتي الصوتية/النصية لمعالجتها بالذكاء الاصطناعي (Gemini AI)',
            linkText: '',
            onLinkTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildConsentItem({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
    required String linkText,
    VoidCallback? onLinkTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: linkText.isNotEmpty ? onLinkTap : null,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(text: text),
                  if (linkText.isNotEmpty)
                    TextSpan(
                      text: linkText,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
