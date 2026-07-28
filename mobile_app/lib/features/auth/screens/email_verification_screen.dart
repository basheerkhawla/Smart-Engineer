// email_verification_screen.dart — شاشة التحقق من البريد الإلكتروني
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/loading_button.dart';
import '../../shared/widgets/app_snackbar.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  Timer? _timer;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // فحص دوري كل 3 ثوانٍ
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final verified = await _authService.checkEmailVerified();
      if (verified && mounted) {
        _timer?.cancel();
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);
    try {
      await _authService.resendEmailVerification();
      if (mounted) {
        AppSnackbar.showSuccess(context, 'تم إرسال رسالة التحقق مجدداً');
        // cooldown 60 ثانية
        setState(() => _resendCooldown = 60);
        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _resendCooldown--;
            if (_resendCooldown <= 0) _cooldownTimer?.cancel();
          });
        });
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'خطأ في إعادة الإرسال');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة الإيميل
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'تحقق من بريدك الإلكتروني',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'تم إرسال رسالة تفعيل إلى:\n$email\nافتح الرسالة واضغط على رابط التفعيل',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // مؤشر الفحص التلقائي
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'يتم التحقق تلقائياً...',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // إعادة إرسال
              LoadingButton(
                label: _resendCooldown > 0
                    ? 'إعادة الإرسال خلال $_resendCooldown ث'
                    : 'إعادة إرسال رسالة التحقق',
                isLoading: _isResending,
                onPressed: _resendCooldown > 0 ? null : _resendEmail,
              ),
              const SizedBox(height: 16),

              // تسجيل الخروج
              TextButton(
                onPressed: () async {
                  await _authService.signOut();
                  if (mounted) context.go('/login');
                },
                child: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
