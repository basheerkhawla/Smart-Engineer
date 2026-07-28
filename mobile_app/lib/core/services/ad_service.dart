// ad_service.dart — خدمة الإعلانات الكاملة (AdMob - Google Policy Compliant)
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/ad_constants.dart';

class AdService {
  // ===== Singleton =====
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // ===== حالة الإعلانات =====
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  bool _isAppOpenAdLoading = false;
  bool _isInterstitialLoading = false;

  /// آخر وقت ظهر فيه إعلان بيني
  DateTime? _lastInterstitialTime;

  // ===== App Open Ad =====
  Future<void> loadAppOpenAd() async {
    if (_isAppOpenAdLoading || _appOpenAd != null) return;
    _isAppOpenAdLoading = true;

    await AppOpenAd.load(
      adUnitId: AdConstants.activeAppOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isAppOpenAdLoading = false;
          debugPrint('App Open Ad failed: ${error.message}');
        },
      ),
    );
  }

  /// عرض App Open Ad (عند فتح التطبيق من الخلفية)
  void showAppOpenAd() {
    if (_appOpenAd == null) {
      loadAppOpenAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd(); // تحميل إعلان جديد للمرة القادمة
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  // ===== Interstitial Ad (6 دقائق) =====
  Future<void> loadInterstitialAd() async {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    await InterstitialAd.load(
      adUnitId: AdConstants.activeInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint('Interstitial Ad failed: ${error.message}');
        },
      ),
    );
  }

  /// هل يمكن عرض الإعلان البيني؟ (6 دقائق على الأقل بين كل إعلان)
  bool canShowInterstitial() {
    if (_interstitialAd == null) return false;
    if (_lastInterstitialTime == null) return true;

    final elapsed = DateTime.now().difference(_lastInterstitialTime!);
    return elapsed.inMinutes >= AdConstants.interstitialIntervalMinutes;
  }

  /// عرض الإعلان البيني
  /// [onComplete] — يُستدعى بعد إغلاق الإعلان أو إذا لم يكن جاهزاً
  void showInterstitialAd({VoidCallback? onComplete}) {
    if (!canShowInterstitial()) {
      onComplete?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _lastInterstitialTime = DateTime.now();
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd(); // تحميل جديد
        onComplete?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onComplete?.call();
      },
    );

    _interstitialAd!.show();
  }

  /// عرض إعلان بيني عند الخدمات المميزة (مرة واحدة لكل جلسة لكل خدمة)
  final Set<String> _shownPremiumAds = {};

  void showPremiumServiceAd(String serviceId, {VoidCallback? onComplete}) {
    // إذا سبق عرضه لهذه الخدمة في الجلسة الحالية
    if (_shownPremiumAds.contains(serviceId)) {
      onComplete?.call();
      return;
    }

    if (_interstitialAd == null) {
      onComplete?.call();
      return;
    }

    _shownPremiumAds.add(serviceId);

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _lastInterstitialTime = DateTime.now();
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onComplete?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onComplete?.call();
      },
    );

    _interstitialAd!.show();
  }

  /// إعادة تعيين إعلانات الجلسة (عند تسجيل الدخول من جديد)
  void resetSessionAds() {
    _shownPremiumAds.clear();
    _lastInterstitialTime = null;
  }

  // ===== تهيئة عند البداية =====
  Future<void> initialize() async {
    await loadAppOpenAd();
    await loadInterstitialAd();
  }

  void dispose() {
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
  }
}
