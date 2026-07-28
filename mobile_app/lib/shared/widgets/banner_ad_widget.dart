// banner_ad_widget.dart — Widget إعلان البانر المشترك
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ad_constants.dart';
import '../../core/services/user_provider.dart';

/// استخدمه في أي شاشة:
/// Scaffold(
///   bottomNavigationBar: const BannerAdWidget(),
///   ...
/// )
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // لا تحمّل الإعلان إذا المستخدم مشترك أو معفى
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.shouldShowAds) return;

    _bannerAd = BannerAd(
      adUnitId: AdConstants.activeBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner Ad failed: ${error.message}');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    // المستخدم المشترك لا يرى الإعلانات
    if (!userProvider.shouldShowAds) return const SizedBox.shrink();

    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFEAEFF5), width: 1),
          ),
        ),
        height: _bannerAd!.size.height.toDouble(),
        width: _bannerAd!.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
