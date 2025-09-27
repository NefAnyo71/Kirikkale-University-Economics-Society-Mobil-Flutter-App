import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/badge_service.dart';
import 'models/badge_model.dart';

class DersNotlari1 extends StatefulWidget { 
  const DersNotlari1({Key? key}) : super(key: key);

  @override
  _DersNotlari1State createState() => _DersNotlari1State();
}

class _DersNotlari1State extends State<DersNotlari1> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedFakulte;
  String? selectedBolum;
  String? selectedDonem;
  String? selectedDers;
  List<String> userFavorites = [];
  String userId = 'guest';

  // Kullanıcı bilgileri
  String _userName = '';
  String _userSurname = '';
  String _userEmail = '';

  bool _showFilters = false;
  bool _isDisclaimerAccepted = false;

  final Color primaryColor = const Color(0xFF5E35B1);
  final Color secondaryColor = const Color(0xFFEDE7F6);
  final Color accentColor = const Color(0xFFFBC02D);

  final Map<String, Map<String, List<String>>> fakulteBolumDersEslemesi = {
    'Tüm Fakülteler': {
      'Tüm Bölümler': [
        'Tüm Dersler', 'İstatistik', 'Mikro İktisat', 'Veri Yapıları ve Algoritmalar', 'Nesne Yönelimli Programlama',
        'Siyaset Bilimine Giriş', 'Ceza Hukuku', 'Türk Edebiyatı Tarihi', 'Anatomi', 'Fizyoloji',
        'Temel Hemşirelik', 'Anesteziye Giriş', 'Algoritma ve Programlama', 'Yapay Zeka', 'Makine Öğrenimi',
        'Gelişim Psikolojisi', 'İnsan Hakları Hukuku', 'Türk İslam Edebiyatı', 'Biyoteknoloji', 'Nanoteknoloji',
      ],
    },
    'İktisadi ve İdari Bilimler Fakültesi': {
      'Tüm Bölümler': ['Tüm Dersler', 'İktisat', 'İşletme', 'Siyaset Bilimi ve Kamu Yönetimi', 'Uluslararası İlişkiler'],
      'İktisat': ['Tüm Dersler', 'Mikro İktisat', 'Makro İktisat', 'Ekonometri', 'İstatistik', 'Uluslararası Ticaret', 'Parasal İktisat', 'Oyun Teorisi', 'Maliye Politikası', 'Gelişme İktisadı'],
      'İşletme': ['Tüm Dersler', 'İşletme Yönetimi', 'Pazarlama İlkeleri', 'Muhasebe', 'Finansal Yönetim', 'Stratejik Yönetim', 'İnsan Kaynakları Yönetimi', 'Örgütsel Davranış', 'Üretim Yönetimi', 'İş Hukuku'],
      'Siyaset Bilimi ve Kamu Yönetimi': ['Tüm Dersler', 'Siyaset Bilimine Giriş', 'Anayasa Hukuku', 'Yerel Yönetimler', 'Türk Siyasal Hayatı', 'Siyasi Düşünceler Tarihi', 'Karşılaştrmalı Siyaset', 'İdari Yargı', 'Kamu Yönetimi'],
      'Ekonometri': ['Tüm Dersler', 'İstatistik','Maliye Politikası', 'Gelişme İktisadı', 'Regresyon',''],
      'Uluslararası İlişkiler': ['Tüm Dersler', 'Uluslararası İlişkiler Teorileri', 'Diplomasi Tarihi', 'Küresel Ekonomi', 'Türk Dış Politikası', 'Uluslararası Hukuk', 'Güvenlik Politikaları', 'Savaş ve Barış Çalışmaları'],
    },
    'Mühendislik Fakültesi': {
      'Tüm Bölümler': ['Tüm Dersler', 'Bilgisayar Mühendisliği', 'Elektrik-Elektronik Mühendisliği', 'Makine Mühendisliği', 'İnşaat Mühendisliği', 'Biyomedikal Mühendisliği'],
      'Bilgisayar Mühendisliği': ['Tüm Dersler', 'Veri Yapıları ve Algoritmalar', 'Nesne Yönelimli Programlama', 'Veritabanı Yönetim Sistemleri', 'İşletim Sistemleri', 'Yazılım Mühendisliği', 'Bilgisayar Ağları', 'Yapay Zeka', 'Makine Öğrenimi', 'Mobil Uygulama Geliştirme'],
      'Elektrik-Elektronik Mühendisliği': ['Tüm Dersler', 'Devre Analizi', 'Elektronik Devreler', 'Sinyaller ve Sistemler', 'Kontrol Sistemleri', 'Mikroişlemciler', 'Sayisal Haberleşme', 'Güç Sistemleri'],
      'Makine Mühendisliği': ['Tüm Dersler', 'Termodinamik', 'Akışkanlar Mekaniği', 'Malzeme Bilimi', 'Dinamik', 'Mekanizma Tekniği', 'Isı Transferi', 'Titresim Analizi', 'Makine Elemanları'],
      'İnşaat Mühendisliği': ['Tüm Dersler', 'Statik', 'Mukavemet', 'Yapı Malzemeleri', 'Hidrolik', 'Zemin Mekaniği', 'Çelik Yapılar', 'Ulaştırma', 'Betonarme'],
      'Biyomedikal Mühendisliği': ['Tüm Dersler', 'Biyofizik', 'Tıbbi Görüntüleme', 'Biyomalzemeler', 'Biyosinyal İşleme', 'Biyomekanik', 'Rehabilitasyon Teknolojileri', 'Klinik Mühendislik'],
    },
    'Fen Edebiyat Fakültesi': {
      'Tüm Bölümler': ['Tüm Dersler', 'Matematik', 'Türk Dili ve Edebiyatı', 'Tarih', 'Sosyoloji', 'Psikoloji', 'Fizik', 'Kimya'],
      'Matematik': ['Tüm Dersler', 'Analiz I', 'Soyut Cebir', 'Diferansiyel Denklemler', 'Lineer Cebir', 'Olasılık ve İstatistik', 'Topoloji', 'Matematiksel Mantık'],
      'Türk Dili ve Edebiyatı': ['Tüm Dersler', 'Türk Edebiyatı Tarihi', 'Osmanlı Türkçesi', 'Eski Türk Edebiyatı', 'Yeni Türk Edebiyatı', 'Çağdaş Türk Lehçeleri', 'Halk Edebiyatı'],
      'Tarih': ['Tüm Dersler', 'Tarih Metodolojisi', 'Türk İnkılap Tarihi', 'Osmanlı Tarihi', 'Genel Dünya Tarihi', 'Yakınçağ Avrupa Tarihi', 'Bizans Tarihi'],
      'Sosyoloji': ['Tüm Dersler', 'Sosyolojiye Giriş', 'Toplumsal Araştırma Yöntemleri', 'Kent Sosyolojisi', 'Aile Sosyolojisi', 'Suç Sosyolojisi', 'Eğitim Sosyolojisi'],
      'Psikoloji': ['Tüm Dersler', 'Gelişim Psikolojisi', 'Bilişsel Psikoloji', 'Klinik Psikoloji', 'Sosyal Psikoloji', 'Psikopatoloji', 'Deneysel Psikoloji'],
      'Fizik': ['Tüm Dersler', 'Klasik Mekanik', 'Elektromanyetik Teori', 'Kuantum Fiziği', 'Termodinamik ve İstatistiksel Fizik', 'Optik'],
      'Kimya': ['Tüm Dersler', 'Genel Kimya', 'Organik Kimya', 'Anorganik Kimya', 'Fizikual Kimya', 'Analitik Kimya', 'Biyokimya'],
    },
    'Eğitim Fakültesi': {
      'Tüm Bölümler': ['Tüm Dersler', 'Sınıf Öğretmenliği', 'İlköğretim Matematik Öğretmenliği', 'Fen Bilgisi Öğretmenliği'],
      'Sınıf Öğretmenliği': ['Tüm Dersler', 'Öğretim İlke ve Yöntemleri', 'Eğitim Psikolojisi', 'İlköğretim Programları', 'Özel Öğretim Yöntemleri', 'Sınıf Yönetimi', 'Türkçe Öğretimi'],
      'İlköğretim Matematik Öğretmenliği': ['Tüm Dersler', 'Matematik Öğretimi', 'Geometri', 'Soyut Matematik', 'Analitik Geometri', 'Olasılık ve İstatistik'],
      'Fen Bilgisi Öğretmenliği': ['Tüm Dersler', 'Fen Öğretimi', 'Biyoloji', 'Fizik', 'Kimya', 'Çevre Bilimi', 'Bilimsel Araştırma Yöntemleri'],
    },
    'Hukuk Fakültesi': {
      'Tüm Bölümler': ['Tüm Dersler', 'Hukuk'],
      'Hukuk': ['Tüm Dersler', 'Anayasa Hukuku', 'Ceza Hukuku', 'Medeni Hukuk', 'Borçlar Hukuku', 'İdare Hukuku', 'İnsan Hakları Hukuku', 'Milletlerarası Hukuk', 'Ticaret Hukuku'],
    },
    'Tıp Fakültesi': {
      'Tüm Bölümler': ['Tüm Dersler', 'Tıp'],
      'Tıp': ['Tüm Dersler', 'Anatomi', 'Fizyoloji', 'Biyokimya', 'Histoloji', 'Patoloji', 'Farmakoloji', 'Mikrobiyoloji', 'Cerrahi Bilimler', 'Dahili Tıp Bilimleri'],
    },
    'Diş Hekimliği Fakültesi': {
      'Tüm Bölümler': ['Tüm Dersler', 'Diş Hekimliği'],
      'Diş Hekimliği': ['Tüm Dersler', 'Ağız, Diş ve Çene Cerrahisi', 'Periodontoloji', 'Restoratif Diş Tedavisi', 'Protetik Diş Tedavisi', 'Endodonti', 'Ortodonti'],
    },
    'Sağlık Bilimleri Fakültesi': {
      'Tüm Bölümler': ['Tüm Dersler', 'Ebelik', 'Hemşirelik'],
      'Ebelik': ['Tüm Dersler', 'Kadın Sağlığı ve Hastalıkları', 'Doğum ve Doğum Sonrası Bakım', 'Yenidoğan Bakımı', 'Üreme Sağlığı'],
      'Hemşirelik': ['Tüm Dersler', 'Temel Hemşirelik', 'Cerrahi Hastalıklar Hemşireliği', 'İç Hastalıkları Hemşireliği', 'Ruh Sağlığı ve Hastalıkları Hemşireliği', 'Çocuk Sağlığı ve Hastalıkları Hemşireliği'],
    },
    'Meslek Yüksekokulu': {
      'Tüm Bölümler': ['Tüm Dersler', 'Anestezi', 'Bilgisayar Programcılığı', 'Elektronik Teknolojisi', 'Halkla İlişkiler ve Tanıtım', 'Makine Resim ve Konstrüksiyonu'],
      'Anestezi': ['Tüm Dersler', 'Anesteziye Giriş', 'Reanimasyon', 'Farmakoloji', 'Yoğun Bakım', 'İlk ve Acil Yardım'],
      'Bilgisayar Programcılığı': ['Tüm Dersler', 'Algoritma ve Programlama', 'Veritabanı', 'Web Tasarımı', 'Mobil Uygulama Geliştirme', 'Grafik ve Animasyon'],
      'Elektronik Teknolojisi': ['Tüm Dersler', 'Elektrik Devreleri', 'Elektronik Ölçme', 'Sayisal Elektronik', 'Mikrodenetleyiciler', 'Otomasyon'],
      'Halkla İlişkiler ve Tanıtım': ['Tüm Dersler', 'Halkla İlişkiler Teorisi', 'Reklamcılık', 'Medya İlişkileri', 'Pazarlama İletişimi', 'Kurumsal İletişim'],
      'Makine Resim ve Konstrüksiyonu': ['Tüm Dersler', 'Teknik Resim', 'Makine Elemanları', 'Autocad', 'Katı Modelleme', 'Tolerans ve Yüzey Kalitesi'],
    },
  };

  List<String> gosterilenBolumler = [];
  List<String> gosterilenDersler = [];
  final List<String> fakulteler = [
    'Tüm Fakülteler', 'İktisadi ve İdari Bilimler Fakültesi', 'Mühendislik Fakültesi',
    'Fen Edebiyat Fakültesei', 'Eğitim Fakültesi', 'Hukuk Fakültesi', 'Tıp Fakültesi',
    'Diş Hekimliği Fakültesi', 'Sağlık Bilimleri Fakültesi', 'Meslek Yüksekokulu',
  ];

  @override
  void initState() {
    super.initState();
    gosterilenBolumler = fakulteBolumDersEslemesi['Tüm Fakülteler']!['Tüm Bölümler']!;
    gosterilenDersler = fakulteBolumDersEslemesi['Tüm Fakülteler']!['Tüm Bölümler']!;
    _checkLegalDisclaimerStatus();
    _loadUserData();
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

  void _signInAnonymously() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
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
      final favoritesSnapshot = await _firestore.collection('users').doc(userId).collection('favorites').get();
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
      
      // If the user is clicking the same reaction again, remove it
      if ((isLike && currentReaction == 'like') || (!isLike && currentReaction == 'dislike')) {
        await docRef.update({
          type: FieldValue.increment(-1),
        });
        await prefs.remove(reactionKey);
      } 
      // If clicking the opposite reaction
      else if ((isLike && currentReaction == 'dislike') || (!isLike && currentReaction == 'like')) {
        await docRef.update({
          type: FieldValue.increment(1),
          (isLike ? 'dislikes' : 'likes'): FieldValue.increment(-1),
        });
        await prefs.setString(reactionKey, isLike ? 'like' : 'dislike');
      }
      // If no previous reaction
      else {
        await docRef.update({
          type: FieldValue.increment(1),
        });
        await prefs.setString(reactionKey, isLike ? 'like' : 'dislike');
      }
      
      // Rozet kontrolü yap
      final docData = await _firestore.collection('ders_notlari').doc(docId).get();
      if (docData.exists) {
        final data = docData.data() as Map<String, dynamic>;
        final paylasenEmail = data['paylasan_kullanici_email'] as String?;
        if (paylasenEmail != null && paylasenEmail.isNotEmpty) {
          await BadgeService.checkAndAwardBadges(paylasenEmail);
        }
      }
      
      // Refresh the UI
      setState(() {});
    } catch (error) {
      print("Beğeni/Beğenmeme işlemi sırasında hata oluştu: $error");
    }
  }

  Future<String?> _getUserReaction(String docId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('reaction_$docId');
  }

  void _toggleFavorite(String docId) async {
    final favRef = _firestore.collection('users').doc(userId).collection('favorites').doc(docId);
    bool isFavorite = userFavorites.contains(docId);

    try {
      if (isFavorite) {
        await favRef.delete();
        setState(() {
          userFavorites.remove(docId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorilerden kaldırıldı!')),
        );
      } else {
        await favRef.set({
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() {
          userFavorites.add(docId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorilere eklendi!')),
        );
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

  void _checkLegalDisclaimerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasAccepted = prefs.getBool('legal_disclaimer_accepted') ?? false;

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
    Timer? timer;

    return showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        int countdown = 15;
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            if (timer == null || !timer!.isActive) {
              timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
                if (countdown > 0) {
                  setStateInDialog(() {
                    countdown--;
                  });
                } else {
                  t.cancel();
                }
              });
            }

            if (scrollController.hasClients) {
              scrollController.addListener(() {
                if (scrollController.offset >= scrollController.position.maxScrollExtent && !hasScrolledToEnd) {
                  setStateInDialog(() {
                    hasScrolledToEnd = true;
                  });
                }
              });
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.only(top: 16, bottom: 0, left: 24, right: 24),
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    _buildDisclaimerSection(
                      icon: Icons.gavel,
                      title: 'Telif Hakkı Uyarısı',
                      description: 'Özellikle akademisyenler tarafından yüklenen ders notları ve materyaller, telif hakkı kapsamında olabilir. Bu tür notları, kişisel kullanımınız dışında (örneğin başka bir platformda izinsiz yayımlamak veya ticari amaçla kullanmak gibi) paylaşırken dikkatli olmanız gerekmektedir. Bu platformdaki notların telif hakları ile ilgili sorumluluklar, notu yükleyen kullanıcıya aittir.',
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerSection(
                      icon: Icons.policy,
                      title: 'Usulsüzlük ve Yasal Süreç',
                      description: 'Bu platformda paylaşılan ders notları sürekli olarak denetlenmektedir. Herhangi bir usulsüz kullanım, intihal, sınav sorularının paylaşımı veya yasalara aykırı başka bir davranış tespit edildiğinde, sistem yöneticileri olarak yasal süreç başlatma ve ilgili kullanıcıyı sistemden kalıcı olarak engelleme hakkımızı saklı tutarız.',
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerSection(
                      icon: Icons.info_outline,
                      title: 'Gizlilik ve Güvenlik',
                      description: 'Bu platform, kişisel verilerinizi korumak için gerekli önlemleri almaktadır. Not paylaşımı sırasında paylaştığınız tüm veriler gizlilik politikamız kapsamında değerlendirilmektedir. Ancak, kullanıcı tarafından paylaşılan bilgilerin doğruluğu ve içeriği tamamen kullanıcının kendi sorumluluğundadır.',
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerSection(
                      icon: Icons.check_circle_outline,
                      title: 'Kabul Beyanı',
                      description: '“Onaylıyorum” diyerek bu sisteme giriş yaptığınızda, yukarıdaki tüm kullanım koşullarını ve yasal uyarıları okuduğunuzu, anladığınızı ve kabul ettiğinizi beyan etmiş olursunuz.',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Bu koşulları kabul etmemeniz halinde, platformu kullanmaya devam etmemeniz gerekmektedir.',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
                    Text(
                      'Onaya kalan süre: $countdown sn',
                      style: TextStyle(
                        color: countdown > 0 ? Colors.red : primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        child: const Text('Onaylıyorum'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 5,
                        ),
                        onPressed: (hasScrolledToEnd && countdown == 0) ? () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('legal_disclaimer_accepted', true);
                          timer?.cancel();
                          Navigator.of(context).pop(true);
                        } : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildDisclaimerSection({required IconData icon, required String title, required String description}) {
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
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
    
    String? selectedFakulteToShare;
    String? selectedBolumToShare;
    String? selectedDersToShare;
    String? selectedDonemToShare;
    final _aciklamaController = TextEditingController();
    final _pdfUrlController = TextEditingController();

    List<String> gosterilenBolumlerToShare = fakulteBolumDersEslemesi['Tüm Fakülteler']!.keys.toList();
    List<String> gosterilenDerslerToShare = fakulteBolumDersEslemesi['Tüm Fakülteler']!['Tüm Bölümler']!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Yeni Not Paylaş', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFiltreDropdown(
                      label: 'Fakülte Seçin',
                      value: selectedFakulteToShare,
                      items: fakulteler,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedFakulteToShare = newValue;
                          selectedBolumToShare = null;
                          selectedDersToShare = null;
                          if (newValue != null && fakulteBolumDersEslemesi.containsKey(newValue)) {
                            gosterilenBolumlerToShare = fakulteBolumDersEslemesi[newValue]!.keys.toList();
                            gosterilenDerslerToShare = fakulteBolumDersEslemesi[newValue]!['Tüm Bölümler'] ?? [];
                          } else {
                            gosterilenBolumlerToShare = fakulteBolumDersEslemesi['Tüm Fakülteler']!.keys.toList();
                            gosterilenDerslerToShare = fakulteBolumDersEslemesi['Tüm Fakülteler']!['Tüm Bölümler'] ?? [];
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFiltreDropdown(
                      label: 'Bölüm Seçin',
                      value: selectedBolumToShare,
                      items: gosterilenBolumlerToShare,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedBolumToShare = newValue;
                          selectedDersToShare = null;
                          if (selectedFakulteToShare != null && newValue != null && fakulteBolumDersEslemesi[selectedFakulteToShare]!.containsKey(newValue)) {
                            gosterilenDerslerToShare = fakulteBolumDersEslemesi[selectedFakulteToShare]![newValue]!;
                          } else {
                            gosterilenDerslerToShare = fakulteBolumDersEslemesi[selectedFakulteToShare]!['Tüm Bölümler'] ?? [];
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFiltreDropdown(
                      label: 'Ders Seçin',
                      value: selectedDersToShare,
                      items: gosterilenDerslerToShare,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDersToShare = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFiltreDropdown(
                      label: 'Dönem Seçin',
                      value: selectedDonemToShare,
                      items: const [
                        'Güz', 'Bahar',
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDonemToShare = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _aciklamaController,
                      decoration: InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: const Text('İptal', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedFakulteToShare != null &&
                        selectedBolumToShare != null &&
                        selectedDersToShare != null &&
                        selectedDonemToShare != null &&
                        _aciklamaController.text.isNotEmpty &&
                        _pdfUrlController.text.isNotEmpty) {
                      try {
                        await _firestore.collection('ders_notlari').add({
                          'fakulte': selectedFakulteToShare,
                          'bolum': selectedBolumToShare,
                          'ders_adi': selectedDersToShare,
                          'aciklama': _aciklamaController.text,
                          'donem': selectedDonemToShare,
                          'pdf_url': _pdfUrlController.text,
                          'eklenme_tarihi': Timestamp.now(),
                          'likes': 0,
                          'dislikes': 0,
                          'downloads': 0,
                          'likedBy': [],
                          'dislikedBy': [],
                          // Yeni eklenen alanlar
                          'paylasan_kullanici_adi': _userName,
                          'paylasan_kullanici_soyadi': _userSurname,
                          'paylasan_kullanici_email': _userEmail,
                        });
                        
                        // Rozet kontrolü yap
                        if (_userEmail.isNotEmpty) {
                          await BadgeService.checkAndAwardBadges(_userEmail);
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notunuz başarıyla gönderildi!')),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata oluştu: $e')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen tüm gerekli alanları doldurunuz.')),
                      );
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

  void _showUserBadges() async {
    if (_userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı')),
      );
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

  Widget _buildNoteCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    final isFavorite = userFavorites.contains(doc.id);

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
            // Paylaşan kullanıcı bilgisi
            if (data['paylasan_kullanici_adi'] != null && data['paylasan_kullanici_soyadi'] != null)
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Paylaşan: ${data['paylasan_kullanici_adi']} ${data['paylasan_kullanici_soyadi']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    if (data['paylasan_kullanici_email'] != null)
                      FutureBuilder<List<UserBadge>>(
                        future: BadgeService.getUserBadges(data['paylasan_kullanici_email']),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const SizedBox();
                          }
                          
                          final badges = snapshot.data!.take(5).toList();
                          return Wrap(
                            spacing: 4,
                            children: badges.map((userBadge) {
                              final badge = BadgeService.getBadgeById(userBadge.badgeId);
                              if (badge == null) return const SizedBox();
                              
                              return Tooltip(
                                message: '${badge.name}: ${badge.description}',
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: badge.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: badge.color.withOpacity(0.3)),
                                  ),
                                  child: Icon(
                                    badge.icon,
                                    size: 18,
                                    color: badge.color,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                  ],
                ),
              ),

            Text(
              'Ders: ${data['ders_adi']}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor),
            ),
            const SizedBox(height: 8),
            Text('Fakülte: ${data['fakulte']}', style: const TextStyle(color: Colors.black87)),
            Text('Bölüm: ${data['bolum']}', style: const TextStyle(color: Colors.black87)),
            Text('Dönem: ${data['donem']}', style: const TextStyle(color: Colors.black87)),
            Text('Açıklama: ${data['aciklama']}', style: const TextStyle(color: Colors.black87)),
            if (data['sinav_turu'] != null)
              Text('Sınav Türü: ${data['sinav_turu']}', style: const TextStyle(color: Colors.black87)),
            Text('Yüklenme Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(data['eklenme_tarihi'].toDate())}', style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 12),
            if (data['pdf_url'] != null && data['pdf_url'].isNotEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (!await launchUrl(Uri.parse(data['pdf_url']))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dosya açılamadı.')),
                      );
                    } else {
                      _incrementDownloadCount(doc.id);
                    }
                  },
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  label: const Text('İndir', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FutureBuilder<String?>(
              future: _getUserReaction(doc.id),
              builder: (context, snapshot) {
                final userReaction = snapshot.data;
                final isLikedByUser = userReaction == 'like';
                final isDislikedByUser = userReaction == 'dislike';
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLikedByUser ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                            color: isLikedByUser ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => _updateReaction(doc.id, 'likes'),
                        ),
                        Text('${data['likes'] ?? 0}', style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isDislikedByUser ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                            color: isDislikedByUser ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _updateReaction(doc.id, 'dislikes'),
                        ),
                        Text('${data['dislikes'] ?? 0}', style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.download, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('${data['downloads'] ?? 0}', style: const TextStyle(color: Colors.black87)),
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

    if (selectedFakulte != 'Tüm Fakülteler' && selectedFakulte != null) {
      query = query.where('fakulte', isEqualTo: selectedFakulte);
    }
    if (selectedBolum != 'Tüm Bölümler' && selectedBolum != null) {
      query = query.where('bolum', isEqualTo: selectedBolum);
    }
    if (selectedDonem != 'Tüm Dönemler' && selectedDonem != null) {
      query = query.where('donem', isEqualTo: selectedDonem);
    }
    if (selectedDers != 'Tüm Dersler' && selectedDers != null) {
      query = query.where('ders_adi', isEqualTo: selectedDers);
    }

    return query.orderBy('eklenme_tarihi', descending: true);
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
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.white),
            onPressed: _showUserBadges,
            tooltip: 'Rozetlerim',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showNotPaylasDialog(context),
          ),
        ],
      ),
      body: _isDisclaimerAccepted
          ? Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              icon: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: Colors.white,
              ),
              label: Text(
                _showFilters ? 'Filtreleri Gizle' : 'Ders Notlarını Filtrele',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Visibility(
            visible: _showFilters,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildFiltreDropdown(
                      label: 'Fakülte Seçin',
                      value: selectedFakulte,
                      items: fakulteler,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedFakulte = newValue;
                          selectedBolum = null;
                          selectedDers = null;
                          if (newValue != null && fakulteBolumDersEslemesi.containsKey(newValue)) {
                            gosterilenBolumler = fakulteBolumDersEslemesi[newValue]!.keys.toList();
                            gosterilenDersler = fakulteBolumDersEslemesi[newValue]!['Tüm Bölümler'] ?? [];
                          } else {
                            gosterilenBolumler = fakulteBolumDersEslemesi['Tüm Fakülteler']!.keys.toList();
                            gosterilenDersler = fakulteBolumDersEslemesi['Tüm Fakülteler']!['Tüm Bölümler'] ?? [];
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFiltreDropdown(
                      label: 'Bölüm Seçin',
                      value: selectedBolum,
                      items: gosterilenBolumler,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedBolum = newValue;
                          selectedDers = null;
                          if (selectedFakulte != null && newValue != null && fakulteBolumDersEslemesi[selectedFakulte]!.containsKey(newValue)) {
                            gosterilenDersler = fakulteBolumDersEslemesi[selectedFakulte]![newValue]!;
                          } else {
                            gosterilenDersler = fakulteBolumDersEslemesi[selectedFakulte]!['Tüm Bölümler'] ?? [];
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFiltreDropdown(
                      label: 'Dönem Seçin',
                      value: selectedDonem,
                      items: const [
                        'Tüm Dönemler', 'Güz', 'Bahar',
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDonem = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFiltreDropdown(
                      label: 'Ders Seçin',
                      value: selectedDers,
                      items: gosterilenDersler,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDers = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Veri çekme hatası! Lütfen Firebase dizinlerini kontrol edin.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Ders notu bulunamadı.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return _buildNoteCard(doc);
                  },
                );
              },
            ),
          ),
        ],
      )
          : Center(
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Anlaşmayı Oku ve Kabul Et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}