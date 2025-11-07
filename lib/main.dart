import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'feedback.dart';
import 'current_economy.dart';
import 'live_market.dart';
import 'poll.dart';
import 'sponsors_page.dart';
import 'admin_panel_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'social_media_page.dart';
import 'etkinlik_takvimi2.dart';
import 'community_news2_page.dart';
import 'uyekayıt.dart';
import 'DersNotlarımPage.dart';
import 'ders_notlari1.dart';
import 'yaklasan_etkinlikler.dart';
import 'notification_service.dart';
import 'background_notification_manager.dart';
import 'account_settings_page.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'gemini_chat_page.dart';
import 'weather_service.dart';
import 'services/app_update_service.dart';
import 'services/credit_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables yüklendi');

    await Firebase.initializeApp();
    print('✅ Firebase başlatıldı');

    await MobileAds.instance.initialize();
    print('✅ Mobile Ads SDK başlatıldı');

    await initializeDateFormatting('tr_TR', null);
    print('✅ Tarih formatı başlatıldı');

    runApp(const KetApp());

    _initializeBackgroundTasks();
  } catch (error) {
    print('❌ Başlatma hatası: $error');
    runApp(const KetApp());
  }
}

Future<void> _initializeBackgroundTasks() async {
  try {
    AppUpdateService.checkForUpdate();
    _bildirimIzinleri();
    _fCMTokeniAl();
    print('✅ Arka plan görevleri başlatıldı');
  } catch (e) {
    print('❌ Arka plan görev hatası: $e');
  }
}

Future<void> _bildirimIzinleri() async {
  try {
    PermissionStatus notificationStatus =
        await Permission.notification.request();
    if (notificationStatus.isGranted) {
      print("Bildirim izni verildi!");
    }

    PermissionStatus storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      print("Depolama izni verildi!");
    }
  } catch (e) {
    print('İzin hatası: $e');
  }
}

Future<void> _fCMTokeniAl() async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    print("Firebase Token: $token");
  } catch (e) {
    print('FCM Token alma hatası: $e');
  }
}

Future<void> _kullaniciFirebaseKayit(
    String email, String password, String name, String surname) async {
  try {
    await _firestore.collection('üyelercollection').doc(email).set({
      'email': email,
      'password': password,
      'name': name,
      'surname': surname,
      'hesapEngellendi': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('Kullanıcı Firestore\'a kaydedildi: $email');
  } catch (e) {
    print('Firestore kayıt hatası: $e');
  }
}

Future<Map<String, dynamic>> _kullaniciFirebaseKontrol(
    String email, String password) async {
  try {
    final doc =
        await _firestore.collection('üyelercollection').doc(email).get();
    if (doc.exists) {
      final userData = doc.data() as Map<String, dynamic>;
      final hesapEngellendi = userData['hesapEngellendi'] ?? 0;

      return {
        'isValid': userData['password'] == password,
        'hesapEngellendi': hesapEngellendi,
        'userData': userData
      };
    }
    return {'isValid': false, 'hesapEngellendi': 0};
  } catch (e) {
    print('Firestore doğrulama hatası: $e');
    return {'isValid': false, 'hesapEngellendi': 0};
  }
}

class HesapEngellemeEkrani extends StatelessWidget {
  const HesapEngellemeEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'Hesabınız Engellendi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Yönetici tarafından engellendiniz.\n\n'
                'Olası bir sorunda lütfen aşağıdaki e-posta adresi ile iletişime geçiniz:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'arifkerem71@gmail.com',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const BasitGirisEkrani(),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text(
                  'Çıkış Yap',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BasitGirisEkrani extends StatefulWidget {
  const BasitGirisEkrani({super.key});

  @override
  _GirisSayfasi createState() => _GirisSayfasi();
}

class _GirisSayfasi extends State<BasitGirisEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('KET Giriş', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade300, Colors.cyan.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Image.asset(
                  'assets/images/ekoslogo.png',
                  height: 100.0,
                ),
                const SizedBox(height: 20),
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value!.isEmpty) return 'Adınızı girin';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _surnameController,
                    decoration: const InputDecoration(
                      labelText: 'Soyad',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value!.isEmpty) return 'Soyadınızı girin';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value!.isEmpty || !value.contains('@'))
                      return 'Geçerli e-posta girin';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty || value.length < 4)
                      return 'En az 4 karakter girin';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _isLogin ? _giris : _kayit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                  child: Text(
                    _isLogin
                        ? 'Hesabınız yok mu? Kayıt olun'
                        : 'Zaten hesabınız var mı? Giriş yapın',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _giris() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text;
      final password = _passwordController.text;

      final validationResult = await _kullaniciFirebaseKontrol(email, password);

      if (validationResult['isValid'] == true) {
        final hesapEngellendi = validationResult['hesapEngellendi'] ?? 0;

        if (hesapEngellendi == 1) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const HesapEngellemeEkrani(),
          ));
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setString('password', password);
        final userData = validationResult['userData'] as Map<String, dynamic>;
        await prefs.setString('name', userData['name'] ?? '');
        await prefs.setString('surname', userData['surname'] ?? '');

        await CreditService.getUserCredits(email);
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const GirisEkranSayfasi(),
          ));
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final storedEmail = prefs.getString('email');
        final storedPassword = prefs.getString('password');

        if (email == storedEmail && password == storedPassword) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const GirisEkranSayfasi(),
          ));
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('E-posta veya şifre hatalı')),
            );
          }
        }
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _kayit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text;
      final password = _passwordController.text;
      final name = _nameController.text;
      final surname = _surnameController.text;

      try {
        await _kullaniciFirebaseKayit(email, password, name, surname);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setString('password', password);
        await prefs.setString('name', name);
        await prefs.setString('surname', surname);
        await prefs.setBool('hasSeenUyeKayit', false);

        await CreditService.getUserCredits(email);

        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const GirisEkranSayfasi(),
          ));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt hatası: $e')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }
}

class KetApp extends StatefulWidget {
  const KetApp({super.key});

  @override
  State<KetApp> createState() => _KetAppState();
}

class _KetAppState extends State<KetApp> {
  bool _isLoggedIn = false;
  bool _hasSeenUyeKayit = false;

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final hasSeenUyeKayit = prefs.getBool('hasSeenUyeKayit') ?? false;

    setState(() {
      _isLoggedIn = email != null;
      _hasSeenUyeKayit = hasSeenUyeKayit;
    });

    if (_isLoggedIn && !_hasSeenUyeKayit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => UyeKayit(),
        ));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _initializeBackgroundServices();
  }

  Future<void> _initializeBackgroundServices() async {
    try {
      await BackgroundNotificationManager.initializeNotifications();
      await BackgroundNotificationManager.initializeWorkmanager();
      await BackgroundNotificationManager.performInitialNotificationCheck();
      print('✅ Arka plan servisleri başlatıldı');
    } catch (e) {
      print('❌ Arka plan servis hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KET',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: _isLoggedIn ? const GirisEkranSayfasi() : const BasitGirisEkrani(),
    );
  }
}

class GirisEkranSayfasi extends StatefulWidget {
  const GirisEkranSayfasi({super.key});

  @override
  State<GirisEkranSayfasi> createState() => _GirisEkranSayfasiState();
}

class _GirisEkranSayfasiState extends State<GirisEkranSayfasi> {
  String _userName = '';
  String _userSurname = '';
  String _userEmail = '';
  int _eventNotificationCount = 0;
  bool _showKetMessage = false;
  WeatherData? _weatherData;
  StreamSubscription? _userStatusSubscription;
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _notificationCountSubscription;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) {
      if (mounted && _userName.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showWelcomeDialog(context);
        });
      }
    });
    _loadNotificationCount();
    _listenToNotifications();
    _YaklasanEtkinlikler();
    _listenToNotificationCount();
    _loadWeatherData();
    _BannerReklam();
  }

  @override
  void dispose() {
    _userStatusSubscription?.cancel();
    _eventsSubscription?.cancel();
    _notificationCountSubscription?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _BannerReklam() {
    print('🔄 Banner ad yükleniyor...');
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-9077319357175271/3312244062',
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

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('name') ?? '';
      _userSurname = prefs.getString('surname') ?? '';
      _userEmail = prefs.getString('email') ?? '';
    });

    if (_userEmail.isNotEmpty) {
      _listenForBanStatus();
    }
  }

  void _listenForBanStatus() {
    _userStatusSubscription?.cancel();

    _userStatusSubscription = _firestore
        .collection('üyelercollection')
        .doc(_userEmail)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        final isBlocked = userData['hesapEngellendi'] == 1;

        if (isBlocked && mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const HesapEngellemeEkrani()),
            (route) => false,
          );
        }
      }
    });
  }

  Future<void> _loadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _eventNotificationCount = prefs.getInt('event_notification_count') ?? 0;
      });
    }
  }

  void _listenToNotifications() {
    BackgroundNotificationManager.setupFirebaseMessageListeners(
      onNotificationCountUpdate: (count) {
        _incrementNotificationCount();
      },
    );
  }

  Future<void> _incrementNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _eventNotificationCount++;
      });
      await prefs.setInt('event_notification_count', _eventNotificationCount);
      print('✅ Bildirim sayaç artırıldı: $_eventNotificationCount');
    }
  }

  Future<void> _clearNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('event_notification_count', 0);
    if (mounted) {
      setState(() {
        _eventNotificationCount = 0;
      });
    }
  }

  void _YaklasanEtkinlikler() {
    _eventsSubscription = FirebaseFirestore.instance
        .collection('yaklasan_etkinlikler')
        .snapshots()
        .listen((snapshot) {
      print(
          '🔔 Etkinlik değişikliği tespit edildi: ${snapshot.docs.length} etkinlik');

      _etkinlikHesaplayicisi(snapshot.docs.length);

      final prefs = SharedPreferences.getInstance();
      prefs.then((prefs) {
        final lastEventCount = prefs.getInt('last_event_count') ?? 0;
        if (snapshot.docs.length > lastEventCount) {
          print('🎉 Yeni etkinlik eklendi, bildirim gönderiliyor...');
          Future.delayed(const Duration(seconds: 3), () {
            NotificationService.checkNewEventsAndNotify();
          });
        }
        prefs.setInt('last_event_count', snapshot.docs.length);
      });
    });
  }

  void _listenToNotificationCount() {
    _notificationCountSubscription =
        NotificationService.notificationCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _eventNotificationCount = count;
        });
        print('🔔 Bildirim sayacı güncellendi: $count');
      }
    });
  }

  void _etkinlikHesaplayicisi(int eventCount) {
    if (eventCount > 0 && _eventNotificationCount == 0) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _eventNotificationCount = eventCount;
          });
        }
      });
    }
  }

  Future<void> _testBildirimiGonder() async {
    await NotificationService.sendTestNotification();
    await NotificationService.checkForEventsAndSendNotification();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '🔔 Test bildirimi gönderildi ve etkinlik kontrolü yapıldı!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadWeatherData() async {
    // print('🌤️ Hava durumu yükleniyor...');
    final weather = await WeatherService.getCurrentWeather();
    // print('🌤️ Hava durumu sonucu: $weather');
    if (mounted) {
      setState(() {
        _weatherData = weather;
      });
      /*print(
          '🌤️ Hava durumu state güncellendi: ${_weatherData?.temperature}°C'); */
    }
  }

  void _showWelcomeDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Arka Plan',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.waving_hand_rounded,
                      size: 50, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text('Hoş Geldin',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('$_userName $_userSurname',
                      style:
                          TextStyle(fontSize: 18, color: Colors.grey.shade700),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _showKetMessage = true;
            });
            print('KET mesajı gösterildi: $_showKetMessage');

            Future.delayed(const Duration(seconds: 4), () {
              if (mounted) {
                setState(() {
                  _showKetMessage = false;
                });
                print('KET mesajı gizlendi');
              }
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade700,
        elevation: 4.0,
        toolbarHeight: 80,
        title: Row(
          children: [
            Image.asset('assets/images/ekoslogo.png', height: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_userName $_userSurname',
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Ekonomi Topluluğu',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              // print('🌤️ Hava durumu yenileniyor...');
              _loadWeatherData();
            },
            onLongPress: () async {
              // print('🔔 Bildirim sistemi kontrolü...');
              await NotificationService.checkForEventsAndSendNotification();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Kırıkkale',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _weatherData != null
                            ? WeatherService.getWeatherIcon(_weatherData!.icon)
                            : Icons.wb_cloudy,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _weatherData != null
                            ? '${_weatherData!.temperature.round()}°C'
                            : '--°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountSettingsPage(
                    userName: _userName,
                    userSurname: _userSurname,
                    userEmail: _userEmail,
                  ),
                ),
              );
            },
            tooltip: 'Hesap Ayarları',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16.0),
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                children: <Widget>[
                  _buildGridButton(
                    context,
                    'Ders Notu Paylaşım Sistemi',
                    Icons.menu_book,
                    DersNotlari1(),
                  ),
                  _buildGridButton(
                    context,
                    'Ders Notlarım',
                    Icons.menu_book,
                    DersNotlarim(),
                  ),
                  _buildGridButton(
                    context,
                    'Etkinlik Takvimi',
                    Icons.calendar_today,
                    EtkinlikJson(),
                  ),
                  _buildGridButtonWithBadge(
                    context,
                    'Yaklaşan Etkinlikler',
                    Icons.calendar_today,
                    EtkinlikJson2(),
                    _eventNotificationCount,
                    _clearNotificationCount,
                  ),
                  _buildGridButton(
                    context,
                    'Topluluk Haberleri',
                    Icons.newspaper,
                    const CommunityNews2Page(),
                  ),
                  _buildGridButton(
                    context,
                    'Sosyal Medya',
                    Icons.share,
                    const SocialMediaPage(),
                  ),
                  _buildGridButton(
                    context,
                    'Güncel Ekonomi',
                    Icons.bar_chart,
                    const CurrentEconomyPage(),
                  ),
                  _buildGridButton(
                    context,
                    'Canlı Piyasa',
                    Icons.show_chart,
                    LiveMarketPage(),
                  ),
                  _buildGridButton(
                    context,
                    'Sponsorlar',
                    Icons.business,
                    SponsorsPage(),
                  ),
                  _buildGridButton(
                    context,
                    'Anket Butonu',
                    Icons.poll,
                    SurveyPage(),
                  ),
                  _buildGridButton(
                    context,
                    'Yönetici Paneli',
                    Icons.admin_panel_settings,
                    AdminPanelPage(),
                  ),
                  _buildGridButton(
                    context,
                    'Geri Bildirim',
                    Icons.feedback,
                    FeedbackPage(),
                  ),
                  // arka plan bildirim sistemi test için
                  //_buildTestNotificationButton(context),
                ],
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
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 60.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GeminiChatPage(
                        userName: _userName,
                        userSurname: _userSurname,
                        userEmail: _userEmail,
                      ),
                    ),
                  );
                },
                backgroundColor: Colors.transparent,
                child: Container(
                  width: 115,
                  height: 115,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.deepPurple.shade300,
                      width: 1,
                    ),
                    image: DecorationImage(
                        image: AssetImage('assets/images/ketyapayzeka.png'),
                        fit: BoxFit.cover,
                        alignment: AlignmentGeometry.center),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_showKetMessage)
              Positioned(
                right: 90,
                bottom: 20,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.deepPurple.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş geldin $_userName!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sana nasıl yardımcı olabilirim?',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Üstüme tıkla!',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridButton(
      BuildContext context, String title, IconData icon, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.deepPurple.shade100, width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45.0, color: Colors.deepPurple.shade600),
            const SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TEST BİLDİRİM BUTONU
  /* Widget _buildTestNotificationButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await NotificationService.sendNearestEventTestNotification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔔 Test bildirimi gönderildi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade300, Colors.red.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.orange.shade200, width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notification_add, size: 45.0, color: Colors.white),
            const SizedBox(height: 8.0),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Test Bildirimi Gönder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  } */

  Widget _buildGridButtonWithBadge(BuildContext context, String title,
      IconData icon, Widget page, int badgeCount, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: Colors.deepPurple.shade100, width: 1.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 45.0, color: Colors.deepPurple.shade600),
                const SizedBox(height: 8.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
