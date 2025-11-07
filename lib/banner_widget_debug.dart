import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerWidgetDebug extends StatelessWidget {
  final bool isBannerAdReady;
  final BannerAd? bannerAd;

  const BannerWidgetDebug({
    Key? key,
    required this.isBannerAdReady,
    this.bannerAd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.yellow.shade100,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text('Banner Ad Debug: Ready=$isBannerAdReady, Ad=${bannerAd != null}'),
          if (isBannerAdReady && bannerAd != null)
            Container(
              width: bannerAd!.size.width.toDouble(),
              height: bannerAd!.size.height.toDouble(),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: AdWidget(ad: bannerAd!),
            )
          else
            Container(
              width: 320,
              height: 50,
              color: Colors.grey.shade300,
              child: const Center(
                child: Text('Reklam Yükleniyor...'),
              ),
            ),
        ],
      ),
    );
  }
}