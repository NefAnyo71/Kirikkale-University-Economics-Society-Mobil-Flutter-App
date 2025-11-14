import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class UyeKayit extends StatefulWidget {
  const UyeKayit({Key? key}) : super(key: key);

  @override
  _UyeKayitState createState() => _UyeKayitState();
}

class _UyeKayitState extends State<UyeKayit> {
  final String _formUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSc7Lz4uHJ3IMumETY82UDmycO6csWFtHCmmh0YGNjB_4HbS0Q/viewform';
  bool _isAgreementAccepted = false;
  bool _hasCompletedForm = false;
  int _countdown = 15; // Değişiklik: Geri sayım 15 saniyeye çekildi
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToEnd = false;
  bool _isButtonEnabled = false; // Yeni: Butonun aktif olup olmadığını kontrol eden değişken

  @override
  void initState() {
    super.initState();
    _checkAgreementStatus();

    // Kullanıcı sayfanın sonuna geldiğinde geri sayımı başlat
    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_hasScrolledToEnd) {
        setState(() {
          _hasScrolledToEnd = true;
        });
        if (_timer == null || !_timer!.isActive) { // Sayaç zaten çalışmıyorsa başlat
          _startCountdown();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkAgreementStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasAccepted = prefs.getBool('membership_agreement_accepted') ?? false;
    final bool hasCompleted = prefs.getBool('form_completed') ?? false;

    setState(() {
      _isAgreementAccepted = hasAccepted;
      _hasCompletedForm = hasCompleted;
    });
  }

  void _startCountdown() {
    // Geri sayımı başlatan fonksiyon
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _isButtonEnabled = true; // Geri sayım bitince butonu aktif et
          timer.cancel();
        }
      });
    });
  }

  void _acceptAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('membership_agreement_accepted', true);

    setState(() {
      _isAgreementAccepted = true;
    });
  }

  void _openFormLink() async {
    final Uri url = Uri.parse(_formUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);

      // Formu açtıktan sonra tamamlandı olarak işaretle
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('form_completed', true);

      setState(() {
        _hasCompletedForm = true;
      });
    } else {
      throw 'Bağlantı açılamadı: $_formUrl';
    }
  }

  Widget _buildAgreementSection({required IconData icon, required String title, required String description}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4A90E2), size: 24),
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
                    color: Colors.black87,
                  ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kırıkkale Üniversitesi Ekonomi Topluluğu\nTopluluk Üye Kaydı Sistemi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFF4A90E2),
        centerTitle: true,
      ),
      body: _hasCompletedForm
          ? Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A90E2),
              Color(0xFFFFA500),
              Color(0xFFFFD700),
              Color(0xFFFF0000),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kayıt İşlemi Tamamlandı!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Google Form ile kaydınız alınmıştır.\n\nUygulamayı ekrandan kaydırarak kapatın ve tekrar açın. Sisteme erişim sağlamak için ana menüye dönebilirsiniz.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    // hasSeenUyeKayit flag'ini set et
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('hasSeenUyeKayit', true);
                    
                    // Ana menüye dön
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ana Menüye Dön',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          : _isAgreementAccepted
          ? Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A90E2),
              Color(0xFFFFA500),
              Color(0xFFFFD700),
              Color(0xFFFF0000),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Google Form ile Kayıt Ol',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              // Değişiklik: Google Form bilgilendirme metni eklendi
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Anlaşmayı kabul ettikten sonra, kayıt işlemini tamamlamak için Google Formuna yönlendirileceksiniz. Lütfen formu eksiksiz doldurunuz.',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _openFormLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Google Form ile Kayıt Ol',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Üyelik Sözleşmesi ve Kullanım Koşulları',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kırıkkale Üniversitesi Ekonomi Topluluğu uygulamasını kullanmadan önce lütfen aşağıdaki koşulları dikkatlice okuyunuz:',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _buildAgreementSection(
                      icon: Icons.group,
                      title: 'Üyelik Zorunluluğu',
                      description: 'Bu uygulamayı kullanmaya devam edebilmek için aktif olarak Kırıkkale Üniversitesi Ekonomi Topluluğuna üye olmanız şarttır. Google Form ile topluluğa üye olmadığı halde hesap açan kişilerin hesapları kalıcı olarak engellenecektir.',
                    ),
                    _buildAgreementSection(
                      icon: Icons.school,
                      title: 'Öğrencilik Şartı',
                      description: 'Bu uygulamayı kullanmak için Kırıkkale Üniversitesinde aktif öğrenci olmanız gerekmektedir. Mezun durumundaki kullanıcıların erişim hakları sınırlandırılabilir.',
                    ),
                    _buildAgreementSection(
                      icon: Icons.security,
                      title: 'Hesap Güvenliği',
                      description: 'Hesabınızın güvenliğinden siz sorumlusunuz. Şifrenizi kimseyle paylaşmayınız. Şüpheli bir durumda derhal topluluk yönetimiyle iletişime geçiniz.',
                    ),
                    _buildAgreementSection(
                      icon: Icons.gavel,
                      title: 'Kullanım Kuralları',
                      description: 'Uygulamayı kullanırken diğer kullanıcılara saygılı olunuz. Uygunsuz içerik paylaşımı, spam gönderimi veya topluluk kurallarına aykırı davranışlarda bulunmanız durumunda hesabınız askıya alınacaktır.',
                    ),
                    _buildAgreementSection(
                      icon: Icons.privacy_tip,
                      title: 'Gizlilik ve Veri Kullanımı',
                      description: 'Kişisel verileriniz sadece topluluk etkinlikleri ve duyuruları için kullanılacaktır. Üçüncü şahıslarla paylaşılmayacaktır. Üyelikten ayrılmanız durumunda kişisel verileriniz silinecektir.',
                    ),
                    _buildAgreementSection(
                      icon: Icons.event,
                      title: 'Etkinlik Katılımı',
                      description: 'Üyelerin düzenlenen etkinliklere katılımı beklenmektedir. Sürekli olarak etkinliklere katılmayan üyelerin uygulama erişimleri sınırlandırılabilir.',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Bu koşulları kabul etmemeniz halinde, uygulamayı kullanmaya devam etmemeniz gerekmektedir. "Kabul Ediyorum" butonuna tıklayarak yukarıdaki tüm koşulları okuduğunuzu, anladığınızı ve kabul ettiğinizi beyan edersiniz.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Onaya kalan süre: $_countdown sn',
                  style: TextStyle(
                    color: _countdown > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: _isButtonEnabled ? _acceptAgreement : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Kabul Ediyorum'),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
} 
