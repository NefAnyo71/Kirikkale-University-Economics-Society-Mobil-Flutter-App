import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/badge_service.dart';
import 'services/credit_service.dart';
import 'models/badge_model.dart';
import 'widgets/credit_display_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class DersNotlari1 extends StatefulWidget {
  const DersNotlari1({Key? key}) : super(key: key);

  @override
  _DersNotlari1State createState() => _DersNotlari1State();
}

class _DersNotlari1State extends State<DersNotlari1> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> userFavorites = [];
  String userId = 'guest';

  // Kullanıcı bilgileri
  String _userName = '';
  String _userSurname = '';
  String _userEmail = '';
  
  // Kredi bilgileri
  Map<String, dynamic> _userCredits = {
    'totalCredits': 0,
    'usedCredits': 0,
    'availableCredits': 0,
    'totalShares': 0,
    'totalDownloads': 0,
  };

  bool _isDisclaimerAccepted = false;
  
  // Arama için
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // AdMob Banner Ad
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // AdMob Interstitial Ad
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  int _adShowCount = 0;
  static const int _maxAdShows = 2;

  final Color primaryColor = const Color(0xFF5E35B1);
  final Color secondaryColor = const Color(0xFFEDE7F6);
  final Color accentColor = const Color(0xFFFBC02D);



  @override
  void initState() {
    super.initState();
    _checkLegalDisclaimerStatus();
    _loadUserData();
    _loadUserCredits();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    print('🔄 Banner ad yükleniyor...');
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-9077319357175271/3312244062', // Gerçek ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print('✅ Banner ad başarıyla yüklendi!');
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner ad yüklenemedi: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  void _loadInterstitialAd() {
    print('🔄 Interstitial ad yükleniyor...');
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-9077319357175271/8308068804', // Gerçek ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Interstitial ad başarıyla yüklendi!');
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          // Sayfa açılır açılmaz otomatik reklam göster (zorunlu)
          if (_adShowCount < _maxAdShows) {
            _showAutoAd();
          }
        },
        onAdFailedToLoad: (error) {
          print('❌ Interstitial ad yüklenemedi: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  // Otomatik zorunlu reklam (kredi kazandırmaz)
  void _showAutoAd() {
    if (_adShowCount >= _maxAdShows) {
      return;
    }
    
    if (_isInterstitialAdReady && _interstitialAd != null) {
      print('📱 Zorunlu reklam gösteriliyor! (${_adShowCount + 1}/$_maxAdShows)');
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _adShowCount++;
          print('📊 Zorunlu reklam sayacı: $_adShowCount/$_maxAdShows');
          
          // Bir sonraki zorunlu reklamı yükle
          if (_adShowCount < _maxAdShows) {
            _loadInterstitialAd();
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _adShowCount++;
          if (_adShowCount < _maxAdShows) {
            _loadInterstitialAd();
          }
        },
      );
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
    }
  }

  // Reklam izle butonu için (KREDİ KAZANDIRAN)
  void _showRewardedAd() async {
    if (_userEmail.isEmpty) {
      _showCustomSnackBar('Lütfen giriş yapınız.', isError: true);
      return;
    }

    // Yeni reklam yükle (kredi kazandıran)
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-9077319357175271/8308068804',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) async {
              ad.dispose();
              
              // Kredi ekle (sadece butona tıklayarak izlenen reklamlar)
              final success = await CreditService.addCreditsForAd(_userEmail);
              if (success) {
                _loadUserCredits();
                final adsWatched = await CreditService.getAdsWatchedCount(_userEmail);
                final remaining = 5 - (adsWatched % 5);
                
                if (remaining == 5) {
                  _showCustomSnackBar('Tebrikler! 1 kredi kazandınız! 🎉');
                } else {
                  _showCustomSnackBar('Reklam izlendi! $remaining reklam daha izleyerek 1 kredi kazanabilirsiniz.');
                }
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _showCustomSnackBar('Reklam gösterilemedi.', isError: true);
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          _showCustomSnackBar('Reklam yüklenemedi.', isError: true);
        },
      ),
    );
  }



  // Kullanıcı bilgilerini yükle
  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? '';
      _userSurname = prefs.getString('surname') ?? '';
      _userEmail = prefs.getString('email') ?? '';
    });
  }

  // Kullanıcı kredi bilgilerini yükle
  void _loadUserCredits() async {
    if (_userEmail.isNotEmpty) {
      final credits = await CreditService.getUserCredits(_userEmail);
      if (mounted) {
        setState(() {
          _userCredits = credits;
        });
      }
    }
  }

  void _signInAnonymously() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        userId = userCredential.user!.uid;
      });
      print("Anonim olarak oturum açıldı: $userId");
      _getFavorites();
    } catch (e) {
      print("Anonim oturum açma hatası: $e");
    }
  }

  void _getFavorites() async {
    try {
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();
      setState(() {
        userFavorites = favoritesSnapshot.docs.map((doc) => doc.id).toList();
      });
      print("Favoriler güncellendi: $userFavorites");
    } catch (e) {
      print("Favori bilgisi alınırken hata oluştu: $e");
    }
  }

  Future<void> _updateReaction(String docId, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String reactionKey = 'reaction_$docId';
      final String? currentReaction = prefs.getString(reactionKey);

      final docRef = _firestore.collection('ders_notlari').doc(docId);
      final isLike = type == 'likes';

      // Basitçe sadece reaction'u güncelle
      if ((isLike && currentReaction == 'like') ||
          (!isLike && currentReaction == 'dislike')) {
        await docRef.update({type: FieldValue.increment(-1)});
        await prefs.remove(reactionKey);
      } else {
        if (currentReaction != null) {
          await docRef.update({
            type: FieldValue.increment(1),
            (isLike ? 'dislikes' : 'likes'): FieldValue.increment(-1),
          });
        } else {
          await docRef.update({type: FieldValue.increment(1)});
        }
        await prefs.setString(reactionKey, isLike ? 'like' : 'dislike');
      }

      setState(() {});
    } catch (error) {
      print("Beğeni işlemi hatası: $error");
    }
  }

  Future<String?> _getUserReaction(String docId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('reaction_$docId');
  }

  void _toggleFavorite(String docId) async {
    final favRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(docId);
    bool isFavorite = userFavorites.contains(docId);

    try {
      if (isFavorite) {
        await favRef.delete();
        setState(() {
          userFavorites.remove(docId);
        });
        _showCustomSnackBar('Favorilerden kaldırıldı.');
      } else {
        await favRef.set({
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() {
          userFavorites.add(docId);
        });
        _showCustomSnackBar('Favorilere eklendi!');
      }
    } catch (e) {
      print("Favori işlemi sırasında hata oluştu: $e");
    }
  }

  void _incrementDownloadCount(String docId) async {
    final docRef = _firestore.collection('ders_notlari').doc(docId);
    try {
      await docRef.update({
        'downloads': FieldValue.increment(1),
      });
    } catch (e) {
      print("İndirme sayacı güncellenirken hata oluştu: $e");
    }
  }

  // İndirme işlemini yönet (kredi sistemi ile)
  Future<void> _handleDownload(String docId, String pdfUrl, Map<String, dynamic> noteData) async {
    if (_userEmail.isEmpty) {
      _showCustomSnackBar('Lütfen giriş yapınız.', isError: true);
      return;
    }

    // Kendi paylaştığı not mu kontrol et
    final noteOwnerEmail = noteData['paylasan_kullanici_email'] ?? '';
    final isOwnNote = noteOwnerEmail == _userEmail;

    if (isOwnNote) {
      // Kendi notu - kredi kullanmadan aç
      try {
        if (!await launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication)) {
          _showCustomSnackBar('Dosya açılamadı.', isError: true);
        } else {
          _incrementDownloadCount(docId);
          _showCustomSnackBar('Kendi notunuz açıldı - kredi kullanılmadı!');
        }
      } catch (e) {
        _showCustomSnackBar('Dosya açılırken hata oluştu.', isError: true);
      }
      return;
    }

    // Başkasının notu - kredi kontrolü
    final canDownload = await CreditService.canUserDownload(_userEmail);
    
    if (!canDownload) {
      _showInsufficientCreditsDialog();
      return;
    }

    // Kredi kullan ve harici tarayıcıda aç
    final creditUsed = await CreditService.useCreditsForDownload(_userEmail);
    
    if (creditUsed) {
      try {
        if (!await launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication)) {
          _showCustomSnackBar('Dosya açılamadı.', isError: true);
        } else {
          _incrementDownloadCount(docId);
          _loadUserCredits(); // Kredileri yenile
          _showCustomSnackBar('Not harici tarayıcıda açıldı! Kalan krediniz: ${_userCredits['availableCredits'] - 1}');
        }
      } catch (e) {
        _showCustomSnackBar('Dosya açılırken hata oluştu.', isError: true);
      }
    } else {
      _showCustomSnackBar('Kredi kullanılırken hata oluştu.', isError: true);
    }
  }

  // Yetersiz kredi uyarısı
  void _showInsufficientCreditsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yetersiz Kredi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mevcut krediniz: ${_userCredits['availableCredits']}'),
            const SizedBox(height: 8),
            const Text('Daha fazla not indirmek için:'),
            const SizedBox(height: 4),
            Text('• Not paylaşın (+${CreditService.CREDIT_PER_SHARE} kredi)'),
            const Text('• Topluluk etkinliklerine katılın'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showNotPaylasDialog(context);
            },
            child: const Text('Not Paylaş'),
          ),
        ],
      ),
    );
  }

  void _checkLegalDisclaimerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasAccepted =
        prefs.getBool('legal_disclaimer_accepted') ?? false;

    if (!hasAccepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final accepted = await _showLegalDisclaimerDialog();
        if (accepted == true) {
          setState(() {
            _isDisclaimerAccepted = true;
          });
          _signInAnonymously();
        }
      });
    } else {
      setState(() {
        _isDisclaimerAccepted = true;
      });
      _signInAnonymously();
    }
  }

  Future<bool?> _showLegalDisclaimerDialog() {
    bool hasScrolledToEnd = false;
    final ScrollController scrollController = ScrollController();
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        int countdown = 15;
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            void scrollListener() {
              if (scrollController.offset >=
                      scrollController.position.maxScrollExtent &&
                  !scrollController.position.outOfRange) {
                if (!hasScrolledToEnd) {
                  setStateInDialog(() => hasScrolledToEnd = true);
                }
              }
            }

            scrollController.addListener(scrollListener);

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              titlePadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.only(
                  top: 16, bottom: 0, left: 24, right: 24),
              title: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'Yasal Uyarı',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bu Ders Notu Paylaşım Sistemi, sadece Kırıkkale Üniversitesi öğrencilerine yönelik bir bilgi paylaşım platformudur. Notları kullanırken ve paylaşırken aşağıdaki kurallara dikkat etmeniz gerekmektedir:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    _buildDisclaimerSection(
                      icon: Icons.gavel,
                      title: 'Telif Hakkı Uyarısı',
                      description:
                          'Özellikle akademisyenler tarafından yüklenen ders notları ve materyaller, telif hakkı kapsamında olabilir. Bu tür notları, kişisel kullanımınız dışında (örneğin başka bir platformda izinsiz yayımlamak veya ticari amaçla kullanmak gibi) paylaşırken dikkatli olmanız gerekmektedir. Bu platformdaki notların telif hakları ile ilgili sorumluluklar, notu yükleyen kullanıcıya aittir.',
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerSection(
                      icon: Icons.policy,
                      title: 'Usulsüzlük ve Yasal Süreç',
                      description:
                          'Bu platformda paylaşılan ders notları sürekli olarak denetlenmektedir. Herhangi bir usulsüz kullanım, intihal, sınav sorularının paylaşımı veya yasalara aykırı başka bir davranış tespit edildiğinde, sistem yöneticileri olarak yasal süreç başlatma ve ilgili kullanıcıyı sistemden kalıcı olarak engelleme hakkımızı saklı tutarız.',
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerSection(
                      icon: Icons.info_outline,
                      title: 'Gizlilik ve Güvenlik',
                      description:
                          'Bu platform, kişisel verilerinizi korumak için gerekli önlemleri almaktadır. Not paylaşımı sırasında paylaştığınız tüm veriler gizlilik politikamız kapsamında değerlendirilmektedir. Ancak, kullanıcı tarafından paylaşılan bilgilerin doğruluğu ve içeriği tamamen kullanıcının kendi sorumluluğundadır.',
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerSection(
                      icon: Icons.check_circle_outline,
                      title: 'Kabul Beyanı',
                      description:
                          '“Onaylıyorum” diyerek bu sisteme giriş yaptığınızda, yukarıdaki tüm kullanım koşullarını ve yasal uyarıları okuduğunuzu, anladığınızı ve kabul ettiğinizi beyan etmiş olursunuz.',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Bu koşulları kabul etmemeniz halinde, platformu kullanmaya devam etmemeniz gerekmektedir.',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        child: const Text('Okudum, Onaylıyorum'),
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          elevation: 5,
                        ),
                        onPressed: hasScrolledToEnd
                            ? () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool(
                                    'legal_disclaimer_accepted', true);
                                Navigator.of(context).pop(true);
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          scrollController.removeListener(scrollListener);
                          Navigator.of(context).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Reddediyorum'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDisclaimerSection(
      {required IconData icon,
      required String title,
      required String description}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showNotPaylasDialog(BuildContext context) {
    if (!_isDisclaimerAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce kullanım koşullarını kabul ediniz.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final _fakulteController = TextEditingController();
    final _bolumController = TextEditingController();
    final _dersController = TextEditingController();
    final _donemController = TextEditingController();
    final _aciklamaController = TextEditingController();
    final _pdfUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Yeni Not Paylaş',
                  style: TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _fakulteController,
                      decoration: InputDecoration(
                        labelText: 'Fakülte *',
                        hintText: 'Örn: İktisadi ve İdari Bilimler Fakültesi',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        labelStyle: const TextStyle(color: Colors.black54),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bolumController,
                      decoration: InputDecoration(
                        labelText: 'Bölüm *',
                        hintText: 'Örn: İktisat, Bilgisayar Mühendisliği',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        labelStyle: const TextStyle(color: Colors.black54),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dersController,
                      decoration: InputDecoration(
                        labelText: 'Ders Adı *',
                        hintText: 'Örn: Mikro İktisat, Veri Yapıları',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        labelStyle: const TextStyle(color: Colors.black54),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _donemController,
                      decoration: InputDecoration(
                        labelText: 'Dönem *',
                        hintText: 'Örn: Güz, Bahar',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        labelStyle: const TextStyle(color: Colors.black54),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _aciklamaController,
                      decoration: InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        labelStyle: const TextStyle(color: Colors.black54),
                      ),
                      style: const TextStyle(color: Colors.black87),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pdfUrlController,
                      decoration: InputDecoration(
                        labelText: 'PDF URL',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        labelStyle: const TextStyle(color: Colors.black54),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child:
                      const Text('İptal', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_fakulteController.text.isNotEmpty &&
                        _bolumController.text.isNotEmpty &&
                        _dersController.text.isNotEmpty &&
                        _donemController.text.isNotEmpty &&
                        _aciklamaController.text.isNotEmpty &&
                        _pdfUrlController.text.isNotEmpty) {
                      try {
                        // Notu onay bekleyen koleksiyona gönder
                        await _firestore.collection('pending_notes').add({
                          'fakulte': _fakulteController.text.trim(),
                          'bolum': _bolumController.text.trim(),
                          'ders_adi': _dersController.text.trim(),
                          'aciklama': _aciklamaController.text.trim(),
                          'donem': _donemController.text.trim(),
                          'pdf_url': _pdfUrlController.text.trim(),
                          'eklenme_tarihi': Timestamp.now(),
                          'onay_durumu': 'bekliyor',
                          // Paylaşan kullanıcı bilgileri
                          'paylasan_kullanici_adi': _userName,
                          'paylasan_kullanici_soyadi': _userSurname,
                          'paylasan_kullanici_email': _userEmail,
                        });

                        Navigator.pop(context);
                        _showCustomSnackBar('Notunuz admin onayına gönderildi! Onaylandıktan sonra kredi kazanacaksınız.');
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata oluştu: $e')),
                        );
                      }
                    } else {
                      _showCustomSnackBar(
                          'Lütfen tüm gerekli alanları doldurunuz.',
                          isError: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Paylaş'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Kredi bilgi dialogı
  void _showCreditInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kredi Sistemi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Krediniz: ${_userCredits['totalCredits']}'),
            Text('Kullanılan Kredi: ${_userCredits['usedCredits']}'),
            Text('Mevcut Kredi: ${_userCredits['availableCredits']}'),
            const Divider(),
            Text('Toplam Paylaşım: ${_userCredits['totalShares']}'),
            Text('Toplam İndirme: ${_userCredits['totalDownloads']}'),
            const Divider(),
            const Text('Kredi Kazanma:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Her not paylaşımı: +${CreditService.CREDIT_PER_SHARE} kredi'),
            Text('• İlk kayıt: +${CreditService.FREE_DOWNLOAD_LIMIT} kredi'),
            const SizedBox(height: 8),
            const Text('Kredi Kullanımı:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Her not indirme: -${CreditService.CREDIT_PER_DOWNLOAD} kredi'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showUserBadges() async {
    if (_userEmail.isEmpty) {
      _showCustomSnackBar('Kullanıcı bilgisi bulunamadı.', isError: true);
      return;
    }

    final userBadges = await BadgeService.getUserBadges(_userEmail);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rozetlerim'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: userBadges.isEmpty
              ? const Center(child: Text('Henüz rozet kazanmadınız'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                  ),
                  itemCount: userBadges.length,
                  itemBuilder: (context, index) {
                    final userBadge = userBadges[index];
                    final badge = BadgeService.getBadgeById(userBadge.badgeId);
                    if (badge == null) return const SizedBox();

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              badge.icon,
                              size: 32,
                              color: badge.color,
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                badge.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                badge.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 9),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCardHeader(Map<String, dynamic> data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['paylasan_kullanici_adi'] != null)
                InkWell(
                  onTap: () {
                    if (data['paylasan_kullanici_email'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(
                            userEmail: data['paylasan_kullanici_email'],
                            userName: data['paylasan_kullanici_adi'],
                            userSurname:
                                data['paylasan_kullanici_soyadi'] ?? '',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Paylaşan: ${data['paylasan_kullanici_adi']} ${data['paylasan_kullanici_soyadi'] ?? ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryColor,
                    ),
                  ),
                ),
              if (data['eklenme_tarihi'] != null)
                Text(
                  'Tarih: ${DateFormat('dd.MM.yyyy').format(data['eklenme_tarihi'].toDate())}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
        ),
        if (data['paylasan_kullanici_email'] != null)
          FutureBuilder<List<UserBadge>>(
            future:
                BadgeService.getUserBadges(data['paylasan_kullanici_email']),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const SizedBox();
              final badges =
                  snapshot.data!.take(3).toList(); // Show max 3 badges
              return Wrap(
                spacing: 4,
                children: badges.map((userBadge) {
                  final badge = BadgeService.getBadgeById(userBadge.badgeId);
                  if (badge == null) return const SizedBox();
                  return Tooltip(
                    message: '${badge.name}: ${badge.description}',
                    child: Icon(badge.icon, size: 20, color: badge.color),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNoteCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    final isFavorite = userFavorites.contains(doc.id);
    final isPending = doc.reference.parent.id == 'pending_notes';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNoteCardHeader(data),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['ders_adi'] ?? 'Ders Adı Yok',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: primaryColor),
                  ),
                ),
                if (isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Onay Bekliyor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Fakülte: ${data['fakulte'] ?? '-'}',
                style: const TextStyle(color: Colors.black87)),
            Text('Bölüm: ${data['bolum'] ?? '-'}',
                style: const TextStyle(color: Colors.black87)),
            Text('Dönem: ${data['donem'] ?? '-'}',
                style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 4),
            Text(data['aciklama'] ?? '',
                style: const TextStyle(color: Colors.black54)),
            if (data['sinav_turu'] != null)
              Text('Sınav Türü: ${data['sinav_turu']}',
                  style: const TextStyle(color: Colors.black87)),
            const Divider(height: 20),
            if (data['pdf_url'] != null && data['pdf_url'].isNotEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _handleDownload(doc.id, data['pdf_url'], data);
                  },
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  label: Text('Notu İndir (${data['downloads'] ?? 0})',
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            FutureBuilder<String?>(
              future: _getUserReaction(doc.id),
              builder: (context, snapshot) {
                final userReaction = snapshot.data;
                final isLikedByUser = userReaction == 'like';
                final isDislikedByUser = userReaction == 'dislike';

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLikedByUser
                                ? Icons.thumb_up
                                : Icons.thumb_up_alt_outlined,
                            color: isLikedByUser ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => _updateReaction(doc.id, 'likes'),
                        ),
                        Text('${data['likes'] ?? 0}',
                            style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isDislikedByUser
                                ? Icons.thumb_down
                                : Icons.thumb_down_alt_outlined,
                            color: isDislikedByUser ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _updateReaction(doc.id, 'dislikes'),
                        ),
                        Text('${data['dislikes'] ?? 0}',
                            style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleFavorite(doc.id),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = _firestore.collection('ders_notlari');
    return query.orderBy('eklenme_tarihi', descending: true);
  }

  // Pending notes da dahil et
  Stream<List<DocumentSnapshot>> _getAllNotesStream() async* {
    while (true) {
      try {
        final dersNotlari = await _firestore.collection('ders_notlari').orderBy('eklenme_tarihi', descending: true).get();
        final pendingNotes = await _firestore.collection('pending_notes').orderBy('eklenme_tarihi', descending: true).get();
        
        List<DocumentSnapshot> allDocs = [];
        allDocs.addAll(dersNotlari.docs);
        allDocs.addAll(pendingNotes.docs);
        
        // Tarihe göre sırala
        allDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['eklenme_tarihi'] as Timestamp?;
          final bTime = bData['eklenme_tarihi'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
        
        yield allDocs;
        await Future.delayed(const Duration(seconds: 2)); // 2 saniyede bir güncelle
      } catch (e) {
        print('Veri çekme hatası: $e');
        yield [];
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  List<DocumentSnapshot> _filterNotes(List<DocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) return docs;
    
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final dersAdi = (data['ders_adi'] ?? '').toString().toLowerCase();
      final fakulte = (data['fakulte'] ?? '').toString().toLowerCase();
      final bolum = (data['bolum'] ?? '').toString().toLowerCase();
      final aciklama = (data['aciklama'] ?? '').toString().toLowerCase();
      final paylasenAdi = (data['paylasan_kullanici_adi'] ?? '').toString().toLowerCase();
      
      final searchLower = _searchQuery.toLowerCase();
      
      return dersAdi.contains(searchLower) ||
             fakulte.contains(searchLower) ||
             bolum.contains(searchLower) ||
             aciklama.contains(searchLower) ||
             paylasenAdi.contains(searchLower);
    }).toList();
  }

  Widget _buildFiltreDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: const TextStyle(color: Colors.black54)),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
          style: const TextStyle(color: Colors.black87),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KKU Ders Notları',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          // Kredi göstergesi
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_userCredits['availableCredits']}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: _isDisclaimerAccepted
            ? Column(
                children: [

                  // Kredi durumu göstergesi (sadece gerektiğinde yükle)
                  if (_userEmail.isNotEmpty)
                    FutureBuilder<Map<String, dynamic>>(
                      future: CreditService.getUserCredits(_userEmail),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final credits = snapshot.data!;
                        return Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_balance_wallet, size: 16),
                              const SizedBox(width: 4),
                              Text('Kredi: ${credits['availableCredits']}'),
                            ],
                          ),
                        );
                      },
                    ),
                  
                  // Arama çubuğu ve butonlar
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Arama çubuğu
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Ders adı, fakülte, bölüm ara...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reklam İzle Butonu
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                            onPressed: _showRewardedAd,
                            tooltip: 'Reklam İzle\n(5 reklam = 1 kredi)',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Not Paylaş Butonu
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green, Colors.teal],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                            onPressed: () => _showNotPaylasDialog(context),
                            tooltip: 'Yeni Not Paylaş',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<DocumentSnapshot>>(
                      stream: _getAllNotesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text(
                                  'Veri çekme hatası! Lütfen Firebase dizinlerini kontrol edin.'));
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildShimmerList();
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyState();
                        }
                        final filteredDocs = _filterNotes(snapshot.data!);
                        
                        if (filteredDocs.isEmpty && _searchQuery.isNotEmpty) {
                          return _buildNoSearchResultsState();
                        }
                        
                        return ListView.builder(
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            var doc = filteredDocs[index];
                            return _buildNoteCard(doc);
                          },
                        );
                      },
                    ),
                  ),
                  // Banner Ad
                  if (_isBannerAdReady && _bannerAd != null)
                    Container(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                ],
              )
            : _buildDisclaimerPendingState(),
      ),
    );
  }

  Widget _buildAnimatedNoteCard(DocumentSnapshot doc, int index) {
    return _buildNoteCard(doc);
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Arama Sonucu Bulunamadı',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '"$_searchQuery" için sonuç bulunamadı. Farklı anahtar kelimeler deneyebilirsiniz.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Ders Notu Bulunamadı',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Seçtiğiniz filtrelere uygun bir ders notu bulunmuyor. Farklı filtreler deneyebilir veya ilk notu siz paylaşabilirsiniz!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerPendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 80, color: accentColor),
            const SizedBox(height: 24),
            const Text(
              'Lütfen devam etmek için yasal uyarı metnini kabul edin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _showLegalDisclaimerDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Anlaşmayı Oku ve Kabul Et'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => _buildShimmerCard(),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 180, height: 14, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(width: 100, height: 12, color: Colors.white),
                    ],
                  ),
                ),
                Container(width: 50, height: 20, color: Colors.white),
              ],
            ),
            const Divider(height: 20),
            Container(width: double.infinity, height: 18, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: 200, height: 14, color: Colors.white),
            const SizedBox(height: 4),
            Container(width: 150, height: 14, color: Colors.white),
            const SizedBox(height: 4),
            Container(width: 100, height: 14, color: Colors.white),
            const Divider(height: 20),
            Center(
              child: Container(
                width: 150,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfilePage extends StatelessWidget {
  final String userEmail;
  final String userName;
  final String userSurname;

  const UserProfilePage({
    Key? key,
    required this.userEmail,
    required this.userName,
    required this.userSurname,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF5E35B1);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$userName $userSurname',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rozetler Bölümü
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Kazanılan Rozetler',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          _buildBadgesSection(),
          const Divider(height: 24, thickness: 1),
          // Paylaşılan Notlar Bölümü
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Paylaştığı Notlar',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: _buildUserNotesList()),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    return FutureBuilder<List<UserBadge>>(
      future: BadgeService.getUserBadges(userEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Henüz kazanılmış bir rozet yok.'),
          );
        }

        final badges = snapshot.data!;
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final userBadge = badges[index];
              final badge = BadgeService.getBadgeById(userBadge.badgeId);
              if (badge == null) return const SizedBox();

              return Container(
                width: 90,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Card(
                  elevation: 2,
                  child: Tooltip(
                    message: badge.description,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(badge.icon, color: badge.color, size: 30),
                        const SizedBox(height: 4),
                        Text(
                          badge.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUserNotesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ders_notlari')
          .where('paylasan_kullanici_email', isEqualTo: userEmail)
          .orderBy('eklenme_tarihi', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('Bu özellik yakında gelicek.'));
        }

        final notes = snapshot.data!.docs;
        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final noteData = notes[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(Icons.menu_book, color: const Color(0xFF5E35B1)),
                title: Text(
                  noteData['ders_adi'] ?? 'İsimsiz Not',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${noteData['fakulte'] ?? ''} - ${noteData['bolum'] ?? ''}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.thumb_up, size: 16, color: Colors.green),
                    Text('${noteData['likes'] ?? 0}'),
                  ],
                ),
                onTap: () {},
              ),
            );
          },
        );
      },
    );
  }
}
