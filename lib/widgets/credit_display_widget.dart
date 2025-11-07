import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/credit_service.dart';

class CreditDisplayWidget extends StatefulWidget {
  final String userEmail;
  final bool showDetails;

  const CreditDisplayWidget({
    Key? key,
    required this.userEmail,
    this.showDetails = false,
  }) : super(key: key);

  @override
  _CreditDisplayWidgetState createState() => _CreditDisplayWidgetState();
}

class _CreditDisplayWidgetState extends State<CreditDisplayWidget> {
  Map<String, dynamic> _userCredits = {};
  bool _isExpanded = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadUserCredits();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadUserCredits() async {
    if (widget.userEmail.isNotEmpty) {
      final credits = await CreditService.getUserCredits(widget.userEmail);
      if (mounted) {
        setState(() {
          _userCredits = credits;
        });
      }
    }
  }

  void _loadRewardedAd() {
    // Reklam yüklemeyi devre dışı bırak (performans için)
    // RewardedAd.load(...)
  }

  void _showRewardedAd() {
    // Basit kredi ekleme (reklam olmadan test için)
    CreditService.addCreditsForAd(widget.userEmail).then((success) {
      if (success) {
        _loadUserCredits();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('1 kredi eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showRewardMessage() {
    final adsWatched = _userCredits['adsWatched'] ?? 0;
    final remainingAds = 5 - (adsWatched % 5);

    String message;
    if (remainingAds == 5) {
      message = 'Tebrikler! 1 kredi kazandınız! 🎉';
    } else {
      message =
          'Reklam izlendi! $remainingAds reklam daha izleyerek 1 kredi kazanabilirsiniz.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userEmail.isEmpty) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Ana kredi göstergesi (her zaman görünür, küçük)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade600, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Kredi: ${_userCredits['availableCredits'] ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Reklam izle butonu
                    IconButton(
                      onPressed: _isRewardedAdReady ? _showRewardedAd : null,
                      icon: Icon(
                        Icons.play_circle_fill,
                        color: _isRewardedAdReady ? Colors.yellow : Colors.grey,
                        size: 24,
                      ),
                      tooltip: 'Reklam İzle (5 reklam = 1 kredi)',
                    ),
                    // Genişlet/daralt butonu
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Detaylı bilgiler (genişletildiğinde görünür)
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCreditRow('Toplam Kredi',
                      '${_userCredits['totalCredits'] ?? 0}', Icons.stars),
                  _buildCreditRow('Kullanılan Kredi',
                      '${_userCredits['usedCredits'] ?? 0}', Icons.download),
                  _buildCreditRow(
                      'Mevcut Kredi',
                      '${_userCredits['availableCredits'] ?? 0}',
                      Icons.account_balance_wallet),
                  const Divider(),
                  _buildCreditRow('Paylaşım Sayısı',
                      '${_userCredits['totalShares'] ?? 0}', Icons.share),
                  _buildCreditRow(
                      'İndirme Sayısı',
                      '${_userCredits['totalDownloads'] ?? 0}',
                      Icons.file_download),
                  _buildCreditRow('İzlenen Reklam',
                      '${_userCredits['adsWatched'] ?? 0}', Icons.play_circle),
                  _buildCreditRow('Alınan Beğeni',
                      '${_userCredits['likesReceived'] ?? 0}', Icons.thumb_up),
                  _buildCreditRow(
                      'Alınan Beğenmeme',
                      '${_userCredits['dislikesReceived'] ?? 0}',
                      Icons.thumb_down),
                  const SizedBox(height: 16),

                  // Kredi kazanma bilgileri
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kredi Kazanma Yolları:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            '5 reklam izle', '+1 kredi', Icons.play_circle),
                        _buildInfoRow(
                            '10 beğeni al', '+1 kredi', Icons.thumb_up),
                        _buildInfoRow('Not paylaş', '+5 kredi', Icons.share),
                        const SizedBox(height: 8),
                        const Text(
                          'Kredi Kaybı:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.red),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                            '10 beğenmeme al', '-1 kredi', Icons.thumb_down,
                            isNegative: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isRewardedAdReady ? _showRewardedAd : null,
                      icon: const Icon(Icons.play_circle_fill),
                      label: Text(
                        _isRewardedAdReady
                            ? 'Reklam İzle ve Kredi Kazan'
                            : 'Reklam Yükleniyor...',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isRewardedAdReady ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreditRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String action, String reward, IconData icon,
      {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isNegative ? Colors.red : Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            reward,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
