import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  static const String rewardedAdUnitId = String.fromEnvironment(
    'REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  ); // Test ID, override with --dart-define

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isLoaded = false;

  void loadAd(VoidCallback? onLoaded, {VoidCallback? onFailed}) {
    if (_isLoading) return; // Don't start another load if already loading
    if (_isLoaded) {
      // If already loaded, call onLoaded immediately
      onLoaded?.call();
      return;
    }

    _isLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoaded = true;
          _isLoading = false;
          onLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _isLoaded = false;
          _rewardedAd = null;
          print('AdMob Error: ${error.code} - ${error.message}');
          onFailed?.call();
        },
      ),
    );
  }

  void showAd({
    required VoidCallback onRewarded,
    VoidCallback? onClosed,
    VoidCallback? onFailed,
  }) {
    if (_rewardedAd == null) {
      onFailed?.call();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _rewardedAd = null;
        _isLoaded = false;
        onClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _rewardedAd = null;
        _isLoaded = false;
        onFailed?.call();
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded();
      },
    );
  }

  bool get isLoaded => _isLoaded;
}
