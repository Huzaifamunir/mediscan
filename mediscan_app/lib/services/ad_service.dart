import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // ── Real Ad Unit IDs ─────────────────────────────────────────────────────────
  static const String _appOpenAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/9257395921' // Google test App Open ID
      : 'ca-app-pub-5583188983618166/3916305336'; // Your real App Open ID

  static const String _bannerAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111' // Google test Banner ID
      : 'ca-app-pub-3940256099942544/6300978111'; // Add real banner ID when you create one

  // ── Singleton ────────────────────────────────────────────────────────────────
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdReady = false;
  DateTime? _appOpenAdLoadTime;

  // ── Initialize ───────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // ── App Open Ad ──────────────────────────────────────────────────────────────
  // App Open ads show when the user opens or returns to the app.
  // Ads expire after 4 hours so we check load time before showing.
  bool get _isAdAvailable {
    if (_appOpenAd == null) return false;
    if (_appOpenAdLoadTime == null) return false;
    return DateTime.now().difference(_appOpenAdLoadTime!).inHours < 4;
  }

  VoidCallback? _onAdDismissed;

  void loadAppOpenAd() {
    if (_isAppOpenAdReady) return; // already loaded

    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenAdReady = true;
          _appOpenAdLoadTime = DateTime.now();
          debugPrint('App Open Ad loaded.');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _appOpenAd = null;
              _isAppOpenAdReady = false;
              final callback = _onAdDismissed;
              _onAdDismissed = null;
              callback?.call();   // run whatever was waiting
              loadAppOpenAd();    // preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _appOpenAd = null;
              _isAppOpenAdReady = false;
              final callback = _onAdDismissed;
              _onAdDismissed = null;
              callback?.call();   // proceed even if ad fails
              loadAppOpenAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isAppOpenAdReady = false;
          debugPrint('App Open Ad failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Shows the ad, then calls [onDismissed] after the user closes it.
  /// If no ad is ready, [onDismissed] is called immediately so the
  /// app flow is never blocked.
  void showAppOpenAd({VoidCallback? onDismissed}) {
    if (_isAdAvailable && _isAppOpenAdReady) {
      _onAdDismissed = onDismissed;
      _appOpenAd!.show();
    } else {
      loadAppOpenAd();
      onDismissed?.call(); // no ad ready — proceed immediately
    }
  }

  // ── Banner Ad ────────────────────────────────────────────────────────────────
  BannerAd createBannerAd({required BannerAdListener listener}) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener,
    );
  }
}
