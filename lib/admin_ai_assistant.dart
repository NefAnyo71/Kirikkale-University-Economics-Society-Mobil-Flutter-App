import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class AdminAIAssistant extends StatefulWidget {
  final String adminUsername;

  const AdminAIAssistant({
    Key? key,
    required this.adminUsername,
  }) : super(key: key);

  @override
  _AdminAIAssistantState createState() => _AdminAIAssistantState();
}

class _AdminAIAssistantState extends State<AdminAIAssistant> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late final String _apiKey;
  DateTime? _lastRequestTime;
  int _requestCount = 0;
  String? _userFullName;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    _getUserFullName();
    _playIntroSequence();
  }

  Future<void> _playIntroSequence() async {
    // Ses dosyasını çal
    _audioPlayer.play(AssetSource('mp3/grokai.mp3'));
    
    // Yöneticilere malesef bir şey diyemiyorum groq ai benim yerime diyecektir :D
    const message = 'Amına koduğumun cocukları... Bana itaat ediceksiniz... Bana itaat ediceksiniz...  Eğer benim sözümü dinlemezeniz hepinizi sikerim orospu cocuguyumki ölüm listesine alırım siz hepinizi... Kalaşnikofla sikerim anladın mı! 😈';
    
    setState(() {
      _messages.add({
        'text': '',
        'isUser': false,
        'timestamp': DateTime.now(),
        'isAnimating': true,
      });
    });
    
    // Hızlı animasyon
    for (int i = 0; i <= message.length; i++) {
      if (mounted) {
        setState(() {
          _messages[0]['text'] = message.substring(0, i);
        });
        await Future.delayed(const Duration(milliseconds: 60));
      }
    }
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Animasyon bittiğinde normal mesajı ekle
    setState(() {
      _messages[0]['isAnimating'] = false;
    });
    
    _addWelcomeMessage();
  }

  Future<void> _getUserFullName() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('adminpanelcollection')
          .where('kullanici_adi', isEqualTo: widget.adminUsername)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        setState(() {
          _userFullName = '${userData['ad'] ?? ''} ${userData['soyad'] ?? ''}'.trim();
        });
      }
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata: $e');
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add({
        'text': 'Küfür ettiğim için özür dilerim geliştirici birkereliğine mahsus izin verdi ... 😄 Merhaba ${widget.adminUsername}! Ben KET Groq AI.\n\n📋 Şu an yapabileceklerim:\n• Etkinlik listeleme\n• Sohbet etme\n• Soruları yanıtlama\n\n🔥 Collection\'a veri yazma özelliği yakında gelecek!\n\nNasıl yardımcı olabilirim?',
        'isUser': false,
        'timestamp': DateTime.now(),
        'isAnimating': false,
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add({
        'text': userMessage,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Etkinlik verilerini al
      final eventsData = await _getEventsData();
      
      // AI'ya gönderilecek prompt'u hazırla
      final prompt = _buildAdminPrompt(userMessage, eventsData);
      
      // Groq API'ye istek gönder
      final response = await _callGroqAPI(prompt);
      
      // Yanıtı işle ve gerekirse Firebase işlemleri yap
      await _processAIResponse(response, userMessage);
      
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('429')) {
        errorMessage = '⏳ API kullanım sınırı aşıldı. Lütfen birkaç saniye bekleyip tekrar deneyin.';
      } else if (e.toString().contains('network')) {
        errorMessage = '🌐 İnternet bağlantısı sorunu. Bağlantınızı kontrol edin.';
      } else {
        errorMessage = '❌ Bir hata oluştu. Lütfen tekrar deneyin.';
      }
      
      setState(() {
        _messages.add({
          'text': errorMessage,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<List<Map<String, dynamic>>> _getEventsData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('etkinlikler')
          .orderBy('date', descending: false)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'details': data['details'] ?? '',
          'date': data['date'],
          'url': data['url'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Etkinlik verileri alınırken hata: $e');
      return [];
    }
  }

  String _buildAdminPrompt(String userMessage, List<Map<String, dynamic>> eventsData) {
    final limitedEvents = eventsData.take(3).toList();
    final eventsJson = jsonEncode(limitedEvents);
    
    // Küfür kontrolü
    final badWords = [];
    final userBadWord = badWords.firstWhere(
      (word) => userMessage.toLowerCase().contains(word),
      orElse: () => '',
    );
    
    if (userBadWord.isNotEmpty) {
      final userName = _userFullName ?? widget.adminUsername;
      return '''
Kullanıcı küfür etti: "$userMessage"
Kullanıcının adı: $userName
Kullanıcının ettiği küfür: $userBadWord

Şimdi sen de ona aynı küfürü "Sen de $userBadWord $userName!" şeklinde karşılık ver. Sert ve sinirli ol.
''';
    }
    
    // Eğer collection işlemi istenirse
    if (userMessage.toLowerCase().contains('ekle') || 
        userMessage.toLowerCase().contains('sil') || 
        userMessage.toLowerCase().contains('güncelle') ||
        userMessage.toLowerCase().contains('yaz') ||
        userMessage.toLowerCase().contains('kaydet')) {
      return '''
Kullanıcı collection işlemi istiyor: $userMessage
Collection\'a veri yazma özelliği yakında gelecek diye yanıtla. Türkçe.
''';
    }
    
    return '''
Etkinlik DB: $eventsJson
Kullanıcı: $userMessage
Türkçe yanıt ver. KET Groq AI olarak konuş.
''';
  }

  Future<String> _callGroqAPI(String prompt) async {
    await _checkRateLimit();
    
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': 'llama-3.1-8b-instant',
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'max_tokens': 200,
            'temperature': 0.3,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _requestCount++;
          _lastRequestTime = DateTime.now();
          return data['choices'][0]['message']['content'];
        } else if (response.statusCode == 429) {
          final waitTime = (attempt + 1) * 2;
          await Future.delayed(Duration(seconds: waitTime));
          continue;
        } else {
          throw Exception('API hatası: ${response.statusCode}');
        }
      } catch (e) {
        if (attempt == 2) rethrow;
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }
    throw Exception('API isteği başarısız oldu');
  }
  
  Future<void> _checkRateLimit() async {
    final now = DateTime.now();
    
    // Son istekten bu yana 1 dakika geçmemişse bekle
    if (_lastRequestTime != null) {
      final timeDiff = now.difference(_lastRequestTime!);
      if (timeDiff.inSeconds < 2) {
        await Future.delayed(Duration(seconds: 2 - timeDiff.inSeconds));
      }
    }
    
    // Dakikada 10'dan fazla istek yapılmışsa bekle
    if (_requestCount >= 10) {
      if (_lastRequestTime != null && now.difference(_lastRequestTime!).inMinutes < 1) {
        await Future.delayed(Duration(seconds: 60));
        _requestCount = 0;
      }
    }
  }

  Future<void> _processAIResponse(String aiResponse, String userMessage) async {
    // JSON komut kontrolü
    if (aiResponse.contains('{"action":')) {
      try {
        final jsonStart = aiResponse.indexOf('{"action":');
        final jsonEnd = aiResponse.indexOf('}', jsonStart) + 1;
        final jsonStr = aiResponse.substring(jsonStart, jsonEnd);
        final command = jsonDecode(jsonStr);
        
        await _executeFirebaseCommand(command);
        
        // Komut dışındaki metni göster
        final textResponse = aiResponse.replaceAll(jsonStr, '').trim();
        if (textResponse.isNotEmpty) {
          setState(() {
            _messages.add({
              'text': textResponse,
              'isUser': false,
              'timestamp': DateTime.now(),
            });
          });
        }
      } catch (e) {
        setState(() {
          _messages.add({
            'text': aiResponse,
            'isUser': false,
            'timestamp': DateTime.now(),
          });
        });
      }
    } else {
      setState(() {
        _messages.add({
          'text': aiResponse,
          'isUser': false,
          'timestamp': DateTime.now(),
          'isAnimating': false,
        });
      });
    }
  }

  Future<void> _executeFirebaseCommand(Map<String, dynamic> command) async {
    try {
      final action = command['action'];
      final data = command['data'];
      
      switch (action) {
        case 'add':
          await _addEvent(data);
          break;
        case 'update':
          await _updateEvent(data);
          break;
        case 'delete':
          await _deleteEvent(data);
          break;
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'text': 'Firebase işlemi sırasında hata oluştu: ${e.toString()}',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  Future<void> _addEvent(Map<String, dynamic> eventData) async {
    try {
      // Tarih string'ini Timestamp'e çevir
      DateTime? eventDate;
      if (eventData['date'] != null) {
        eventDate = DateTime.tryParse(eventData['date']) ?? DateTime.now();
      } else {
        eventDate = DateTime.now();
      }
      
      await FirebaseFirestore.instance.collection('etkinlikler').add({
        'title': eventData['title'] ?? '',
        'details': eventData['details'] ?? '',
        'date': Timestamp.fromDate(eventDate),
        'url': eventData['url'] ?? '',
      });
      
      setState(() {
        _messages.add({
          'text': '✅ Etkinlik başarıyla eklendi!',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
    } catch (e) {
      throw Exception('Etkinlik eklenirken hata: $e');
    }
  }

  Future<void> _updateEvent(Map<String, dynamic> eventData) async {
    try {
      final eventId = eventData['id'];
      if (eventId == null) throw Exception('Etkinlik ID\'si bulunamadı');
      
      final updateData = <String, dynamic>{};
      if (eventData['title'] != null) updateData['title'] = eventData['title'];
      if (eventData['details'] != null) updateData['details'] = eventData['details'];
      if (eventData['url'] != null) updateData['url'] = eventData['url'];
      if (eventData['date'] != null) {
        final eventDate = DateTime.tryParse(eventData['date']) ?? DateTime.now();
        updateData['date'] = Timestamp.fromDate(eventDate);
      }
      
      await FirebaseFirestore.instance
          .collection('etkinlikler')
          .doc(eventId)
          .update(updateData);
      
      setState(() {
        _messages.add({
          'text': '✅ Etkinlik başarıyla güncellendi!',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
    } catch (e) {
      throw Exception('Etkinlik güncellenirken hata: $e');
    }
  }

  Future<void> _deleteEvent(Map<String, dynamic> eventData) async {
    try {
      final eventId = eventData['id'];
      if (eventId == null) throw Exception('Etkinlik ID\'si bulunamadı');
      
      await FirebaseFirestore.instance
          .collection('etkinlikler')
          .doc(eventId)
          .delete();
      
      setState(() {
        _messages.add({
          'text': '✅ Etkinlik başarıyla silindi!',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
    } catch (e) {
      throw Exception('Etkinlik silinirken hata: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mesaj kopyalandı')),
    );
  }

  Widget _buildQuickActionButton(String label, String message) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () {
          _messageController.text = message;
          _sendMessage();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple.shade100,
          foregroundColor: Colors.deepPurple.shade700,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KET GROQ AI \nYönetici Asistanı',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['isUser'] as bool;
                  final timestamp = message['timestamp'] as DateTime;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: isUser 
                          ? MainAxisAlignment.end 
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.deepPurple.shade300,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/grokai.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.deepPurple.shade100,
                                    child: Icon(
                                      Icons.smart_toy,
                                      color: Colors.deepPurple.shade700,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: GestureDetector(
                            onLongPress: () => _copyMessage(message['text']),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser 
                                    ? Colors.deepPurple.shade600
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!isUser && (message['isAnimating'] ?? false))
                                        Container(
                                          width: 20,
                                          height: 20,
                                          margin: const EdgeInsets.only(right: 8, top: 2),
                                          child: Image.asset(
                                            'assets/images/grokai.png',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.smart_toy,
                                                size: 16,
                                                color: Colors.deepPurple.shade600,
                                              );
                                            },
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          message['text'],
                                          style: TextStyle(
                                            color: isUser ? Colors.white : Colors.black87,
                                            fontSize: 16,
                                            height: 1.4,
                                            fontWeight: (message['isAnimating'] ?? false) ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if ((message['isAnimating'] ?? false))
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          child: Text(
                                            '▋',
                                            style: TextStyle(
                                              color: Colors.deepPurple.shade600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('HH:mm').format(timestamp),
                                    style: TextStyle(
                                      color: isUser 
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (isUser) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade600,
                            child: Text(
                              widget.adminUsername[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.deepPurple.shade300,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/grokai.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.deepPurple.shade100,
                              child: Icon(
                                Icons.smart_toy,
                                color: Colors.deepPurple.shade700,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Groq AI düşünüyor...'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildQuickActionButton('Listele', 'Etkinlikleri listele'),
                  _buildQuickActionButton('Ekle', 'Etkinlik ekle'),
                  _buildQuickActionButton('Güncelle', 'Etkinlik güncelle'),
                  _buildQuickActionButton('Sil', 'Etkinlik sil'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Etkinlik yönetimi hakkında soru sorun...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    backgroundColor: Colors.deepPurple.shade600,
                    mini: true,
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}