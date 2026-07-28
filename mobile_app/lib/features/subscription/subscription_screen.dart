// subscription_screen.dart — شاشة الاشتراك المميز
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/user_provider.dart';
import '../../shared/widgets/loading_button.dart';
import '../../shared/widgets/app_snackbar.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initialize();
    // الاستماع لتحديثات الشراء
    InAppPurchase.instance.purchaseStream.listen(_handlePurchaseUpdate);
  }

  Future<void> _initialize() async {
    await _subscriptionService.initialize();
    if (mounted) setState(() => _isInitializing = false);
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _subscriptionService.handleSuccessfulPurchase(purchase);
        if (mounted) {
          AppSnackbar.showSuccess(context, '🎉 تم تفعيل الاشتراك بنجاح!');
          context.pop();
        }
      } else if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          AppSnackbar.showError(context, 'فشل الدفع. حاول مجدداً');
          setState(() => _isLoading = false);
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);
    try {
      await _subscriptionService.buySubscription();
      // المعالجة تتم في _handlePurchaseUpdate
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, e.toString());
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isSubscribed = user?.hasActivePaidSubscription ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الاشتراك المميز'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== Header =====
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 52,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'مهندس ذكي — المميز',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSubscribed
                        ? '✅ أنت مشترك حالياً'
                        : 'اشترك واستفد من جميع المزايا',
                    style: TextStyle(
                      color: isSubscribed
                          ? AppColors.accent
                          : Colors.white.withOpacity(0.85),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            // ===== السعر =====
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '\$${AppConstants.subscriptionPrice}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ شهرياً',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== المزايا =====
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ماذا تحصل بالاشتراك؟',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _FeatureItem(
                    icon: Icons.all_inclusive_rounded,
                    title: 'تقارير غير محدودة',
                    subtitle: 'بدون حد شهري على التقارير الصوتية',
                  ),
                  _FeatureItem(
                    icon: Icons.block_rounded,
                    title: 'بدون إعلانات تماماً',
                    subtitle: 'تجربة نظيفة بدون أي إعلانات',
                  ),
                  _FeatureItem(
                    icon: Icons.description_rounded,
                    title: 'قوالب غير محدودة',
                    subtitle: 'أضف كل قوالبك الهندسية',
                  ),
                  _FeatureItem(
                    icon: Icons.camera_alt_rounded,
                    title: 'كاميرا الموقع كاملة',
                    subtitle: 'صور موثقة غير محدودة',
                  ),
                  _FeatureItem(
                    icon: Icons.calculate_rounded,
                    title: 'حاسبات متقدمة',
                    subtitle: 'معادلات مخصصة غير محدودة',
                  ),
                  _FeatureItem(
                    icon: Icons.support_agent_rounded,
                    title: 'دعم فني أولوية',
                    subtitle: 'استجابة أسرع لطلباتك',
                  ),

                  const SizedBox(height: 28),

                  // ===== زر الاشتراك =====
                  if (!isSubscribed) ...[
                    _isInitializing
                        ? const Center(child: CircularProgressIndicator())
                        : LoadingButton(
                            label: 'اشترك الآن — \$${AppConstants.subscriptionPrice}/شهر',
                            isLoading: _isLoading,
                            onPressed: _subscribe,
                            backgroundColor: AppColors.accent,
                          ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'يمكنك الإلغاء في أي وقت من Google Play',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'اشتراكك نشط ✅',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                                if (user?.subscriptionExpiry != null)
                                  Text(
                                    'ينتهي: ${user!.subscriptionExpiry!.day}/${user.subscriptionExpiry!.month}/${user.subscriptionExpiry!.year}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.check_rounded, color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}
