// home_screen.dart — الشاشة الرئيسية (مع الإعلانات - المرحلة الثانية)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/user_provider.dart';
import '../core/services/ad_service.dart';
import '../shared/widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _adService = AdService();
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAds();
  }

  Future<void> _initAds() async {
    final userProvider = context.read<UserProvider>();
    if (!userProvider.shouldShowAds) return;
    await _adService.initialize();

    // عرض App Open Ad عند أول تحميل
    if (_isFirstLoad) {
      _isFirstLoad = false;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && userProvider.shouldShowAds) {
          _adService.showAppOpenAd();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // عرض App Open Ad عند العودة للتطبيق من الخلفية
    if (state == AppLifecycleState.resumed) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.shouldShowAds) {
        _adService.showAppOpenAd();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// الانتقال للخدمة المميزة مع إعلان بيني
  void _navigateToPremiumService(String serviceId, String route) {
    final userProvider = context.read<UserProvider>();
    if (!userProvider.shouldShowAds) {
      context.push(route);
      return;
    }

    _adService.showPremiumServiceAd(serviceId, onComplete: () {
      if (mounted) context.push(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,

      // Banner Ad أسفل الشاشة (دائماً - للمستخدمين غير المشتركين)
      bottomNavigationBar: const BannerAdWidget(),

      body: CustomScrollView(
        slivers: [
          // ===== App Bar مع ترحيب =====
          SliverAppBar(
            expandedHeight: 190,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'مرحباً 👷',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14),
                                ),
                                Text(
                                  user?.displayName ?? 'مهندس',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // أيقونة الأدمن (للأدمن فقط)
                                if (userProvider.isAdmin)
                                  IconButton(
                                    icon: const Icon(
                                        Icons.admin_panel_settings,
                                        color: AppColors.accent),
                                    onPressed: () => context.push('/admin'),
                                    tooltip: 'لوحة التحكم',
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.settings_outlined,
                                      color: Colors.white),
                                  onPressed: () =>
                                      context.push('/home/settings'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // شريط استهلاك التقارير
                        if (user != null && !user.hasActivePaidSubscription)
                          _buildUsageBar(
                              user.usagePercentage,
                              user.reportsUsed,
                              user.maxReports),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: const Text('مهندس ذكي'),
          ),

          // ===== محتوى الشاشة =====
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // تنبيه الاقتراب من الحد
                if (user != null && user.usagePercentage >= 0.8)
                  _buildSubscriptionBanner(context),

                const SizedBox(height: 4),
                const Text(
                  'الخدمات الرئيسية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // شبكة الخدمات
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: [
                    // ✅ خدمات مميزة — تعرض إعلاناً بينياً
                    _buildServiceCard(
                      context,
                      icon: Icons.mic_rounded,
                      label: 'تقرير صوتي',
                      subtitle: 'سجّل ملاحظاتك',
                      color: const Color(0xFF2E86AB),
                      isPremium: true,
                      onTap: () => _navigateToPremiumService(
                          'voice_report', '/home/voice-report'),
                    ),
                    _buildServiceCard(
                      context,
                      icon: Icons.camera_alt_rounded,
                      label: 'كاميرا الموقع',
                      subtitle: 'صورة بختم',
                      color: const Color(0xFF1B5E20),
                      isPremium: true,
                      onTap: () => _navigateToPremiumService(
                          'stamped_camera', '/home/camera'),
                    ),

                    // خدمات عادية
                    _buildServiceCard(
                      context,
                      icon: Icons.description_outlined,
                      label: 'القوالب',
                      subtitle: 'قوالبك الشخصية',
                      color: const Color(0xFF6A1B9A),
                      isPremium: false,
                      onTap: () => context.push('/home/templates'),
                    ),
                    _buildServiceCard(
                      context,
                      icon: Icons.calculate_outlined,
                      label: 'حاسبة الكميات',
                      subtitle: 'معادلاتك المخصصة',
                      color: const Color(0xFFE65100),
                      isPremium: false,
                      onTap: () => context.push('/home/calculator'),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),

      // زر الاشتراك (للمجانيين فقط)
      floatingActionButton: user != null && !user.hasActivePaidSubscription
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/home/subscription'),
              backgroundColor: AppColors.accent,
              label: const Text('⭐ اشترك',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              icon: const Icon(Icons.workspace_premium_rounded),
            )
          : null,
    );
  }

  Widget _buildUsageBar(double percentage, int used, int max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التقارير: $used / $max هذا الشهر',
          style:
              TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 0.8 ? AppColors.warning : AppColors.accent),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'اشترك للحصول على تقارير غير محدودة',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/home/subscription'),
            child: const Text('اشترك',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isPremium,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isPremium)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('⭐ مميز',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
