import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';

class GeminiChatPage extends StatefulWidget {
  final String userName;
  final String userSurname;
  final String userEmail;

  const GeminiChatPage({
    Key? key,
    required this.userName,
    required this.userSurname,
    required this.userEmail,
  }) : super(key: key);

  @override
  _GeminiChatPageState createState() => _GeminiChatPageState();
}

class _GeminiChatPageState extends State<GeminiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late final String _apiKey;
  final FocusNode _messageFocusNode = FocusNode();
  bool _isDarkMode = false;

  // Ses özellikleri
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  final RecorderController _recorderController = RecorderController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isListening = false;
  bool _isRecording = false;
  bool _isSpeaking = false;

  // Kullanıcı sınırları - Daha sıkı limitler
  int _dailyPromptCount = 0;
  int _fiveMinutePromptCount = 0;
  DateTime? _lastPromptTime;
  DateTime? _dailyResetTime;

  // En çok sorulan sorular
  final List<String> _frequentQuestions = [
    'KET nedir?',
    'Nasıl üye olabilirim?',
    'Etkinlikler ücretsiz mi?',
    'Ders notları nasıl paylaşılır?',
    'Sosyal medya hesapları neler?',
    'İletişim bilgileri neler?',
    'Yaklaşan etkinlikler hakkında bilgi verebilirmisin?',
  ];

  // KET bilgi bankası - Kısaltılmış versiyon
  final Map<String, String> _ketKnowledgeBase = {
  // GENEL BİLGİLER
  'topluluk': 'Kırıkkale Üniversitesi İİBF bünyesinde 2020\'de kurulmuş ekonomi topluluğu. 500+ üye. Üyelik ücretsiz.',
  'üyelik': 'Ücretsiz. Uygulama içindeki "Üye Kaydı" bölümünden formu doldurarak başvurabilirsin.',
  'etkinlikler': 'Seminer, workshop, gezi gibi etkinlikler düzenliyoruz. Katılım çoğunlukla ücretsiz.',
  'iletişim_bilgi': 'E-posta: arifkerem71@gmail.com',

  // DERS NOTU SİSTEMİ
  'ders_notları': 'Üyelerin paylaştığı ders notlarını PDF/JPG formatında indirebilirsin.',
  'ders_notu_indirme': '"Ders Notu Paylaşım Sistemi"ne git > Ders ara > İndir. Günde max. 10 not indirebilirsin. Her indirme 1 puan.',
  'not_değerlendirme': 'İndirdiğin notları 1-5 yıldız ile değerlendir. Not sahibi her yıldız için 2 puan kazanır.',
  'kullanım_kuralları': 'Sadece kendi hazırladığın notları paylaş. Telif hakkı ihlali yasak. Eğitim amaçlı kullan.',
  'sık_sorulan_sorular': 'Not onayı: Kalitesiz/okunaksız/telif içeren notlar onaylanmaz. Puanlar akademik yıl sonunda sıfırlanır.',

  // EKONOMİ HABERLERİ ve PİYASA
  'ekonomi_haberleri': 'Anadolu Ajansı, Bloomberg HT gibi kaynaklardan son ekonomi haberleri. 30 dakikada bir güncellenir.',
  'piyasa_verileri': 'Canlı döviz kuru, emtia, kripto para ve BIST verileri. 10 saniyede bir güncellenir.',
  'grafik_analiz': 'Finansal enstrümanlar için detaylı çizgi, mum ve alan grafikleri. Teknik analiz araçları mevcut.',
  'portföy_takip': 'Kişisel portföy oluşturup alış-satış işlemlerini takip edebilir, kar-zarar durumunu görebilirsin.',
  'ekonomik_takvim': 'Önemli ekonomik verilerin açıklanma tarihleri. Ülke ve önem derecesine göre filtreleme yapabilirsin.',

  // SOSYAL MEDYA ve İLETİŞİM
  'sosyal_medya': 'Instagram: @kku_ekonomi_toplulugu - Twitter: @KET_KKU - LinkedIn: KET - YouTube: KET TV',
  'iletişim': 'İletişim için: arifkerem71@gmail.com',
  'geri_bildirim': 'Geri bildirimlerini uygulama içindeki "Geri Bildirim" bölümünden iletebilirsin.',

  // ÜYELİK ve HESAP
  'üyelik_koşulları': 'Kırıkkale Üniversitesi\'nde aktif öğrenci olmak ve topluluk tüzüğünü kabul etmek yeterli.',
  'hesap_ayarları': 'Profil bilgilerini güncelle, şifre değiştir, bildirim tercihlerini yönet.',
  'bildirim_ayarları': 'Etkinlik hatırlatmaları, yeni etkinlik duyuruları, önemli haber bildirimleri alabilirsin.',
  'hesap_silme': 'Hesabını silersen kişisel verilerin silinir, ancak paylaştığın notlar anonim olarak kalır.',

  // TEKNİK DESTEK
  'sorun_giderme': 'İnternet bağlantını kontrol et > Uygulamayı kapatıp aç > Cihazı yeniden başlat > Uygulamayı güncelle.',
  'destek_iletişim': 'Teknik sorunlar için: arifkerem71@gmail.com adresine cihaz ve yazılım bilgilerini yazarak ulaş.',

  // SIK SORULAN SORULAR
  'üyelik_ücreti': 'Hayır, KET üyeliği ve etkinliklere katılım tamamen ücretsizdir.',
  'mezun_üyelik': 'Evet, Kırıkkale Üniversitesi mezunları da üye olabilir ve etkinliklere katılabilir.',
  'sertifika_geçerlilik': 'Etkinlik katılım sertifikaları CV\'ne ekleyebileceğin Kırıkkale Üniversitesi onaylı belgelerdir.',
  'uygulama_güvenliği': 'Veri iletimi SSL ile şifrelenir, şifreler hash\'lenir, düzenli güvenlik denetimleri yapılır.',
};
  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _loadChatHistory();
    _loadUserLimits();
    _loadThemePreference();
    _initializeTts();
    _initializeSpeech();
    if (_messages.isEmpty) {
      _addMessage('KET',
          'Merhaba ${widget.userName} ${widget.userSurname}! 👋 Ben KET, Kırıkkale Üniversitesi Ekonomi Topluluğu asistanınızım. Sana nasıl yardımcı olabilirim?',
          isWelcome: true);
    }

    // Odak noktasını ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_messageFocusNode);
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _recorderController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _addMessage(String sender, String message,
      {bool isWelcome = false, String? imagePath, String? audioPath}) {
    setState(() {
      _messages.add({
        'sender': sender,
        'message': message,
        'time': DateTime.now().toIso8601String(),
        'isWelcome': isWelcome,
        'imagePath': imagePath,
        'audioPath': audioPath,
      });
    });
    _saveChatHistory();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // Sınır kontrolleri
    if (!_checkUserLimits()) return;

    final userMessage = _messageController.text.trim();
    _addMessage('Sen', userMessage);
    _messageController.clear();

    // Prompt sayısını artır
    _incrementPromptCount();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _callGeminiAPI(userMessage);
      _addMessage('KET', response);
    } catch (e) {
      _addMessage('KET',
          'Üzgünüm, bir hata oluştu. Lütfen daha sonra tekrar deneyin. Eğer sorun devam ederse arifkerem71@gmail.com adresine bildirimde bulunabilirsiniz.');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<String> _getRelevantInfo(String userMessage) async {
    final lowerMessage = userMessage.toLowerCase();
    String relevantInfo = '';

    // Etkinlik sorularını kontrol et
    if (lowerMessage.contains('etkinlik') ||
        lowerMessage.contains('program') ||
        lowerMessage.contains('yaklaşan') ||
        lowerMessage.contains('ne zaman') ||
        lowerMessage.contains('tarih') ||
        lowerMessage.contains('saat')) {
      final eventsInfo = await _getUpcomingEvents();
      if (eventsInfo.isNotEmpty) {
        relevantInfo += eventsInfo;
      }
    }

    _ketKnowledgeBase.forEach((key, value) {
      if (lowerMessage.contains(key) ||
          lowerMessage.contains(key.replaceAll('_', ' ')) ||
          (key == 'etkinlikler' &&
              (lowerMessage.contains('etkinlik') ||
                  lowerMessage.contains('program'))) ||
          (key == 'ders_notları' &&
              (lowerMessage.contains('not') ||
                  lowerMessage.contains('ders'))) ||
          (key == 'ekonomi_haberleri' &&
              (lowerMessage.contains('haber') ||
                  lowerMessage.contains('ekonomi'))) ||
          (key == 'üyelik' &&
              (lowerMessage.contains('üye') ||
                  lowerMessage.contains('kayıt'))) ||
          (key == 'iletişim' &&
              (lowerMessage.contains('iletişim') ||
                  lowerMessage.contains('ulaş'))) ||
          (key == 'sorun_giderme' &&
              (lowerMessage.contains('sorun') ||
                  lowerMessage.contains('hata') ||
                  lowerMessage.contains('çalışmıyor'))) ||
          (key == 'hesap_sorunları' &&
              (lowerMessage.contains('giriş') ||
                  lowerMessage.contains('şifre') ||
                  lowerMessage.contains('hesap'))) ||
          (key == 'bildirim_sorunları' &&
              (lowerMessage.contains('bildirim') ||
                  lowerMessage.contains('uyarı'))) ||
          (key == 'dosya_sorunları' &&
              (lowerMessage.contains('dosya') ||
                  lowerMessage.contains('yükle') ||
                  lowerMessage.contains('indirme')))) {
        relevantInfo += '$value ';
      }
    });

    return relevantInfo.isNotEmpty
        ? relevantInfo
        : _ketKnowledgeBase['topluluk']!;
  }

  Future<String> _getUpcomingEvents() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await FirebaseFirestore.instance
          .collection('yaklasan_etkinlikler')
          .where('date', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('date', descending: false)
          .limit(5)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 'Şu anda yaklaşan etkinlik bulunmamaktadır.';
      }

      String eventsInfo = 'Yaklaşan Etkinlikler:\n';

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final title = data['title'] ?? 'İsimsiz Etkinlik';
        final details = data['details'] ?? '';
        final url = data['url'] ?? '';

        if (data['date'] is Timestamp) {
          final eventDate = (data['date'] as Timestamp).toDate();
          final formattedDate =
              DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(eventDate);
          final difference = eventDate.difference(now);

          String timeLeft = '';
          if (difference.inDays > 0) {
            timeLeft =
                '${difference.inDays} gün ${difference.inHours.remainder(24)} saat kaldı';
          } else if (difference.inHours > 0) {
            timeLeft =
                '${difference.inHours} saat ${difference.inMinutes.remainder(60)} dakika kaldı';
          } else {
            timeLeft = '${difference.inMinutes} dakika kaldı';
          }

          eventsInfo += '\n• $title\n';
          eventsInfo += '  Tarih: $formattedDate\n';
          eventsInfo += '  Kalan Süre: $timeLeft\n';
          if (details.isNotEmpty) {
            eventsInfo += '  Detaylar: $details\n';
          }
          if (url.isNotEmpty) {
            eventsInfo += '  Link: $url\n';
          }
        }
      }

      return eventsInfo;
    } catch (e) {
      print('Etkinlik verilerini alırken hata: $e');
      return 'Etkinlik bilgileri şu anda alınamıyor.';
    }
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatKey = 'chat_history_${widget.userName}_${widget.userSurname}';
    final chatData = prefs.getString(chatKey);
    if (chatData != null) {
      final List<dynamic> decoded = jsonDecode(chatData);
      setState(() {
        _messages.clear();
        _messages
            .addAll(decoded.map((e) => Map<String, dynamic>.from(e)).toList());
      });
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatKey = 'chat_history_${widget.userName}_${widget.userSurname}';
    await prefs.setString(chatKey, jsonEncode(_messages));
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('chat_dark_mode') ?? false;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await prefs.setBool('chat_dark_mode', _isDarkMode);
  }

  void _deleteMessage(int index) {
    setState(() {
      _messages.removeAt(index);
    });
    _saveChatHistory();
  }

  void _copyMessage(String message) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Mesaj kopyalandı'),
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Ses özellikleri başlatma
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('tr-TR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _initializeSpeech() async {
    await _speechToText.initialize();
  }

  // Metni sesli okuma
  Future<void> _speakText(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _flutterTts.speak(text);
      _flutterTts.setCompletionHandler(() {
        setState(() => _isSpeaking = false);
      });
    }
  }

  // Sesli mesaj kaydetme
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorderController.stop();
      setState(() {
        _isRecording = false;
      });
      if (path != null) {
        _addMessage('Sen', 'Sesli mesaj gönderildi', audioPath: path);
        // Sesli mesaj için limit kontrolü ve sayaç artırma
        if (_checkUserLimits()) {
          _incrementPromptCount();
          _addMessage(
              'KET', 'Sesli mesajınızı aldım. Size nasıl yardımcı olabilirim?');
        }
      }
    } else {
      if (await _recorderController.checkPermission()) {
        await _recorderController.record(
            path:
                '/storage/emulated/0/Download/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a');
        setState(() => _isRecording = true);
      }
    }
  }

  // Sesli mesaj çalma
  Future<void> _playAudio(String path) async {
    await _audioPlayer.play(DeviceFileSource(path));
  }

  // Sesle soru sorma
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      if (await _speechToText.initialize()) {
        setState(() => _isListening = true);
        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              _messageController.text = result.recognizedWords;
            });
            if (result.finalResult) {
              setState(() => _isListening = false);
              _sendMessage();
            }
          },
          localeId: 'tr_TR',
        );
      }
    }
  }

  // Fotoğraf gönderme
  Future<void> _pickImage() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _addMessage('Sen', 'Fotoğraf gönderildi', imagePath: image.path);
      _sendImageToGemini(image.path);
    }
  }

  Future<void> _sendImageToGemini(String imagePath) async {
    // Sınır kontrolleri
    if (!_checkUserLimits()) return;

    // Prompt sayısını artır
    _incrementPromptCount();

    setState(() => _isLoading = true);
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await _callGeminiVisionAPI(base64Image);
      _addMessage('KET', response);
    } catch (e) {
      _addMessage('KET', 'Görsel analiz edilemedi. Lütfen tekrar deneyin.');
    }
    setState(() => _isLoading = false);
  }

  Future<String> _callGeminiVisionAPI(String base64Image) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Bu görseli analiz et ve KET (Kırıkkale Üniversitesi Ekonomi Topluluğu) bağlamında açıkla. Eğer ekonomi, finans veya eğitimle ilgiliyse detaylı bilgi ver.'
              },
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
    }
    throw Exception('Görsel analiz hatası');
  }

  String _formatTime(String timeString) {
    final dateTime = DateTime.parse(timeString);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  void _showFrequentQuestions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En Çok Sorulan Sorular',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ..._frequentQuestions
                .map((question) => ListTile(
                      leading: Icon(Icons.help_outline,
                          color:
                              _isDarkMode ? Colors.white70 : Colors.deepPurple),
                      title: Text(question,
                          style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white : Colors.black)),
                      onTap: () {
                        Navigator.pop(context);
                        _messageController.text = question;
                        _sendMessage();
                      },
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUserLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = '${widget.userName}_${widget.userSurname}';
    _dailyPromptCount = prefs.getInt('daily_prompts_$userKey') ?? 0;
    _fiveMinutePromptCount = prefs.getInt('five_min_prompts_$userKey') ?? 0;

    final dailyResetStr = prefs.getString('daily_reset_$userKey');
    final lastPromptStr = prefs.getString('last_prompt_$userKey');

    if (dailyResetStr != null) {
      _dailyResetTime = DateTime.parse(dailyResetStr);
      if (DateTime.now().difference(_dailyResetTime!).inDays >= 1) {
        _dailyPromptCount = 0;
        _dailyResetTime = DateTime.now();
      }
    } else {
      _dailyResetTime = DateTime.now();
    }

    if (lastPromptStr != null) {
      _lastPromptTime = DateTime.parse(lastPromptStr);
      if (DateTime.now().difference(_lastPromptTime!).inMinutes >= 5) {
        _fiveMinutePromptCount = 0;
      }
    }
  }

  bool _checkUserLimits() {
    final now = DateTime.now();

    // Günlük sınır kontrolü - 6 mesaj
    if (_dailyPromptCount >= 6) {
      _addMessage('KET',
          'Günlük mesaj sınırınıza ulaştınız (6 mesaj). Yarın tekrar deneyebilirsiniz.');
      return false;
    }

    // 5 dakikalık sınır kontrolü - 2 mesaj
    if (_lastPromptTime != null &&
        now.difference(_lastPromptTime!).inMinutes < 5) {
      if (_fiveMinutePromptCount >= 2) {
        final remainingTime = 5 - now.difference(_lastPromptTime!).inMinutes;
        _addMessage('KET',
            '5 dakika içinde 2 mesaj sınırınıza ulaştınız. $remainingTime dakika sonra tekrar deneyebilirsiniz.');
        return false;
      }
    } else {
      _fiveMinutePromptCount = 0;
    }

    return true;
  }

  Future<void> _incrementPromptCount() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = '${widget.userName}_${widget.userSurname}';
    final now = DateTime.now();

    _dailyPromptCount++;
    _fiveMinutePromptCount++;
    _lastPromptTime = now;

    await prefs.setInt('daily_prompts_$userKey', _dailyPromptCount);
    await prefs.setInt('five_min_prompts_$userKey', _fiveMinutePromptCount);
    await prefs.setString(
        'daily_reset_$userKey', _dailyResetTime!.toIso8601String());
    await prefs.setString('last_prompt_$userKey', now.toIso8601String());
  }

  Future<String> _callGeminiAPI(String userMessage) async {
    final relevantInfo = await _getRelevantInfo(userMessage);
    final prompt =
        '''Sen KET (Kırıkkale Üniversitesi Ekonomi Topluluğu) asistanısın. Kullanıcılara yardımcı ol.

İlgili bilgiler: $relevantInfo

Kullanıcı sorusu: ÖNEMLİ: Sadece yukarıdaki bilgiler çerçevesinde cevap ver. Bu bilgilerin dışına çıkma. Kullanıcı bir topluluk üyesi olduğunu varsay ve uygulamayı yönetme yetkisi olmadığını hatırlat. $userMessage

Yukarıdaki bilgileri kullanarak Türkçe, samimi ve yardımsever bir şekilde cevap ver. Kendini KET asistanı olarak tanıt. Eğer sorun çözemezsen veya teknik bir problem varsa kullanıcıyı arifkerem71@gmail.com adresine yönlendir. Cevabını markdown formatında hazırla, başlıklar için #, listeler için - kullan.''';

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return 'Üzgünüm, yanıt oluşturamadım. Lütfen daha sonra tekrar deneyin.';
      }
    } else {
      throw Exception('API hatası: ${response.statusCode} - ${response.body}');
    }
  }

  void _clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatKey = 'chat_history_${widget.userName}_${widget.userSurname}';
    await prefs.remove(chatKey);

    setState(() {
      _messages.clear();
    });

    _addMessage('KET',
        'Sohbet geçmişi temizlendi. Merhaba ${widget.userName}! 👋 Size nasıl yardımcı olabilirim?',
        isWelcome: true);
  }

  void _showLimitInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.info_outline, color: Colors.deepPurple.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Kullanım Sınırları', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Günlük mesaj:',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('$_dailyPromptCount/50',
                          style: TextStyle(
                              color: Colors.deepPurple.shade600,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _dailyPromptCount / 50,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepPurple.shade600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('5 dakikadaki:',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('$_fiveMinutePromptCount/10',
                          style: TextStyle(
                              color: Colors.deepPurple.shade600,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _fiveMinutePromptCount / 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepPurple.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bu sınırlar, sistem kaynaklarının adil kullanımı için konulmuştur.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade700,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: DecorationImage(
                  image: AssetImage('assets/images/ketyapayzeka.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('KET Asistan',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                      overflow: TextOverflow.ellipsis),
                  Text('Online',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
            color: _isDarkMode ? Colors.grey[800] : Colors.white,
            onSelected: (value) {
              switch (value) {
                case 'theme':
                  _toggleTheme();
                  break;
                case 'faq':
                  _showFrequentQuestions();
                  break;
                case 'limits':
                  _showLimitInfo();
                  break;
                case 'clear':
                  _clearChatHistory();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: _isDarkMode ? Colors.white : Colors.black),
                    const SizedBox(width: 12),
                    Text('Tema değiştir',
                        style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'faq',
                child: Row(
                  children: [
                    Icon(Icons.help_outline,
                        color: _isDarkMode ? Colors.white : Colors.black),
                    const SizedBox(width: 12),
                    Text('Sık sorulan sorular',
                        style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'limits',
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: _isDarkMode ? Colors.white : Colors.black),
                    const SizedBox(width: 12),
                    Text('Kullanım sınırları',
                        style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    const Text('Sohbeti temizle',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'Sen';
                final isWelcome = message['isWelcome'] == true;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.deepPurple.shade200, width: 2),
                            image: DecorationImage(
                              image:
                                  AssetImage('assets/images/ketyapayzeka.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: GestureDetector(
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor:
                                  _isDarkMode ? Colors.grey[800] : Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.copy,
                                          color: _isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      title: Text('Kopyala',
                                          style: TextStyle(
                                              color: _isDarkMode
                                                  ? Colors.white
                                                  : Colors.black)),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _copyMessage(message['message']!);
                                      },
                                    ),
                                    if (!isUser && !isWelcome)
                                      ListTile(
                                        leading: Icon(Icons.volume_up,
                                            color: _isDarkMode
                                                ? Colors.white
                                                : Colors.black),
                                        title: Text('Sesli Oku',
                                            style: TextStyle(
                                                color: _isDarkMode
                                                    ? Colors.white
                                                    : Colors.black)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _speakText(message['message']!);
                                        },
                                      ),
                                    if (!isWelcome)
                                      ListTile(
                                        leading: Icon(Icons.delete,
                                            color: Colors.red),
                                        title: Text('Sil',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _deleteMessage(index);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: isUser
                                  ? LinearGradient(
                                      colors: [
                                        Colors.deepPurple.shade600,
                                        Colors.deepPurple.shade500
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : isWelcome
                                      ? LinearGradient(
                                          colors: _isDarkMode
                                              ? [
                                                  Colors.deepPurple.shade800,
                                                  Colors.deepPurple.shade700
                                                ]
                                              : [
                                                  Colors.deepPurple.shade50,
                                                  Colors.deepPurple.shade100
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                              color: isUser || isWelcome
                                  ? null
                                  : (_isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(isUser ? 20 : 6),
                                bottomRight: Radius.circular(isUser ? 6 : 20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(_isDarkMode ? 0.3 : 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: isUser || isWelcome
                                  ? null
                                  : Border.all(
                                      color: _isDarkMode
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade200,
                                      width: 1,
                                    ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message['imagePath'] != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(message['imagePath']!),
                                        width: 200,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                if (message['audioPath'] != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.play_arrow,
                                              color: isUser
                                                  ? Colors.white
                                                  : Colors.deepPurple),
                                          onPressed: () =>
                                              _playAudio(message['audioPath']!),
                                        ),
                                        Text('Sesli mesaj',
                                            style: TextStyle(
                                              color: isUser
                                                  ? Colors.white70
                                                  : Colors.grey.shade600,
                                              fontSize: 14,
                                            )),
                                      ],
                                    ),
                                  ),
                                Text(
                                  message['message']!,
                                  style: TextStyle(
                                    color: isUser
                                        ? Colors.white
                                        : isWelcome
                                            ? (_isDarkMode
                                                ? Colors.white
                                                : Colors.deepPurple.shade800)
                                            : (_isDarkMode
                                                ? Colors.white
                                                : Colors.black87),
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(message['time']!),
                                  style: TextStyle(
                                    color: isUser
                                        ? Colors.white70
                                        : (_isDarkMode
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple.shade600,
                                Colors.deepPurple.shade500
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.deepPurple.shade200, width: 2),
                      image: DecorationImage(
                        image: AssetImage('assets/images/ketyapayzeka.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.deepPurple.shade600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('KET düşünüyor...',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (_isRecording || _isListening)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                              _isRecording
                                  ? 'Kaydediliyor...'
                                  : 'Dinleniyor...',
                              style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white
                                      : Colors.black
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                            _isListening
                                ? Icons.mic
                                : _isRecording
                                    ? Icons.stop
                                    : Icons.mic_none,
                            color: (_isListening || _isRecording)
                                ? Colors.red
                                : Colors.grey),
                        onPressed:
                            _isListening ? _toggleListening : _toggleRecording,
                        onLongPress: _isRecording ? null : _toggleListening,
                        tooltip: _isListening
                            ? 'Dinlemeyi durdur'
                            : _isRecording
                                ? 'Kaydı durdur'
                                : 'Kısa bas: Sesli mesaj, Uzun bas: Sesle sor',
                      ),
                      IconButton(
                        icon: Icon(Icons.photo, color: Colors.grey),
                        onPressed: _pickImage,
                        tooltip: 'Fotoğraf gönder',
                      ),
                      IconButton(
                        icon: Icon(
                            _isSpeaking ? Icons.volume_off : Icons.volume_up,
                            color: _isSpeaking ? Colors.red : Colors.grey),
                        onPressed: () {
                          if (_messages.isNotEmpty) {
                            final lastKetMessage =
                                _messages.reversed.firstWhere(
                              (msg) =>
                                  msg['sender'] == 'KET' &&
                                  msg['isWelcome'] != true,
                              orElse: () => {},
                            );
                            if (lastKetMessage.isNotEmpty) {
                              _speakText(lastKetMessage['message']!);
                            }
                          }
                        },
                        tooltip:
                            _isSpeaking ? 'Okumayı durdur' : 'Son mesajı oku',
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isDarkMode
                                ? Colors.grey[800]
                                : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                                color: _isDarkMode
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            decoration: InputDecoration(
                              hintText: 'KET\'e bir şey sor...',
                              hintStyle: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              suffixIcon: Container(
                                margin: const EdgeInsets.all(4),
                                child: CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade600,
                                  child: IconButton(
                                    icon: const Icon(Icons.send,
                                        color: Colors.white, size: 18),
                                    onPressed: _sendMessage,
                                  ),
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            maxLines: null,
                            style: TextStyle(
                                fontSize: 15,
                                color:
                                    _isDarkMode ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
