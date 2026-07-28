// ad_constants.dart — مفاتيح إعلانات AdMob
class AdConstants {
  // ===== مفاتيح الإنتاج (Production) =====
  static const String admobAppId =
      'ca-app-pub-3851944836228328~4983040969';

  static const String appOpenAdUnitId =
      'ca-app-pub-3851944836228328/2688050116';

  static const String nativeAdUnitId =
      'ca-app-pub-3851944836228328/6104550945';

  static const String interstitialAdUnitId =
      'ca-app-pub-3851944836228328/2684180682';

  static const String bannerAdUnitId =
      'ca-app-pub-3851944836228328/5321686381';

  // ===== مفاتيح الاختبار (Test) =====
  // استخدمها أثناء التطوير فقط لتجنب مخالفة سياسة AdMob
  static const String testAppOpenAdUnitId =
      'ca-app-pub-3938971750740880/3409468edral';
  static const String testInterstitialAdUnitId =
      'ca-app-pub-3938971750740880/1033173712';
  static const String testBannerAdUnitId =
      'ca-app-pub-3938971750740880/6300978111';
  static const String testNativeAdUnitId =
      'ca-app-pub-3938971750740880/2247696110';

  // ===== إعدادات الإعلانات =====
  /// الفترة الزمنية بين الإعلانات البينية (6 دقائق)
  static const int interstitialIntervalMinutes = 6;

  /// عرض إعلانات الاختبار بدلاً من الحقيقية
  /// غيّر إلى false عند الرفع على Play Store
  static const bool useTestAds = true;

  // المفاتيح الفعلية حسب وضع التطوير
  static String get activeAppOpenAdUnitId =>
      useTestAds ? testAppOpenAdUnitId : appOpenAdUnitId;

  static String get activeInterstitialAdUnitId =>
      useTestAds ? testInterstitialAdUnitId : interstitialAdUnitId;

  static String get activeBannerAdUnitId =>
      useTestAds ? testBannerAdUnitId : bannerAdUnitId;

  static String get activeNativeAdUnitId =>
      useTestAds ? testNativeAdUnitId : nativeAdUnitId;
}
