import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class GeminiChatPage extends StatelessWidget {
  GeminiChatPage({
    super.key,
    this.userName,
    this.userSurname,
    this.userEmail,
  });

  final String? userName;
  final String? userSurname;
  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/ketyapayzeka.png',
              height: 32, // İkonun yüksekliğini ayarlayabilirsiniz
            ),
            const SizedBox(width: 12),
            const Text(
              "KET Asistan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      backgroundColor: Colors.grey[100],
      body: ChatBody(
        userName: userName,
        userSurname: userSurname,
        userEmail: userEmail,
      ),
    );
  }
}

class ChatBody extends StatefulWidget {
  final String? userName;
  final String? userSurname;
  final String? userEmail;

  const ChatBody({
    super.key,
    this.userName,
    this.userSurname,
    this.userEmail,
  });

  @override
  State<ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<ChatBody> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  // Bilgi haritasını state içine taşıdık
  final Map<String, String> ekonomiTopluluguBilgileri = {
    // Topluluk hakkında
    "topluluk nedir":
        "Ben KET Asistan, Kırıkkale Üniversitesi Ekonomi Topluluğu'nun dijital yardımcısıyım. Ekonomi alanında faaliyet gösteren bir öğrenci topluluğuyuz.",
    "topluluk amacı":
        "Ekonomi bilincini geliştirmek, seminerler düzenlemek ve öğrencileri ekonomi alanında bilgilendirmek.",
    "topluluk başkanı":
        "Topluluk başkanı hakkında güncel bilgi için ekonomi bölümüne danışabilirsiniz.",

    // Ekonomi terimleri
    "enflasyon":
        "Enflasyon, mal ve hizmet fiyatlarının genel seviyesindeki sürekli artıştır.",
    "faiz": "Faiz, borç alınan paranın kullanımı için ödenen bedeldir.",
    "döviz kuru":
        "Döviz kuru, bir ülke parasının diğer bir ülke parası cinsinden değeridir.",
    "büyüme":
        "Ekonomik büyüme, bir ekonominin üretim kapasitesindeki artıştır.",
    "ekonomi":
        "Ekonomi, sınırsız ihtiyaçların sınırlı kaynaklarla nasıl karşılanacağını inceleyen bilim dalıdır.",

    // Üniversite bilgileri
    "kırıkkale üniversitesi": // "kü" anahtarı ile birleştirilebilir
        "Kırıkkale Üniversitesi, 1992 yılında kurulmuş devlet üniversitesidir.",
    "ekonomi bölümü":
        "İktisadi ve İdari Bilimler Fakültesi bünyesinde eğitim vermektedir.",
    "iletişim":
        "Detaylı bilgi için üniversitenin resmi web sitesini ziyaret edebilirsiniz.",
    "kü":
        "Kırıkkale Üniversitesi, 1992 yılında kurulmuş köklü bir devlet üniversitesidir.",

    // Genel ekonomi
    "makroekonomi": "Makroekonomi, ekonominin bir bütün olarak incelenmesidir.",
    "mikroekonomi":
        "Mikroekonomi, bireysel ekonomik birimlerin davranışlarını inceler.",
    "iktisat":
        "İktisat, sınırsız ihtiyaçların sınırlı, ihtiyaçların sınırsız olduğu durumda optimal dağılımı inceler.",
    "gsyh":
        "GSYH (Gayri Safi Yurtiçi Hasıla), bir ülkenin belirli dönemde ürettiği nihai mal ve hizmetlerin toplam değeridir.",

    // Selamlama ve diğerleri
    "merhaba": "Merhaba! Sana nasıl yardımcı olabilirim?",
    "selam": "Selam! Ekonomi veya topluluk hakkında bir sorun mu var?",
    "nasılsın":
        "Teşekkür ederim, iyiyim! Ekonomi verilerini analiz ediyorum. Senin için ne yapabilirim?",
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR');
    // İlk açılışta hoş geldin mesajı göster
    _showWelcomeMessage();
  }

  String _getPersonalizedGreeting() {
    if (widget.userName != null && widget.userSurname != null) {
      return "Merhaba ${widget.userName} ${widget.userSurname}! Ben KET Asistan. 🎓\n\nSana ekonomi terimleri, topluluk etkinlikleri veya üniversite hakkında nasıl yardımcı olabilirim?";
    } else if (widget.userName != null) {
      return "Merhaba ${widget.userName}! Ben KET Asistan. 🎓\n\nSana ekonomi terimleri, topluluk etkinlikleri veya üniversite hakkında nasıl yardımcı olabilirim?";
    } else {
      return "Merhaba! Ben KET Asistan. 🎓\n\nSana ekonomi terimleri, topluluk etkinlikleri veya üniversite hakkında nasıl yardımcı olabilirim?";
    }
  }

  String _getRestrictedResponse(
      String userInput, List<Map<String, dynamic>> upcomingEvents) {
    String lowerInput = userInput.toLowerCase();

    // Kullanıcı kendisi hakkında soru soruyorsa
    if (lowerInput.contains("ben kimim") || lowerInput.contains("kimim ben")) {
      if (widget.userName != null &&
          widget.userSurname != null &&
          widget.userEmail != null) {
        return "Siz ${widget.userName} ${widget.userSurname}'siniz. E-posta adresiniz: ${widget.userEmail}";
      } else if (widget.userName != null && widget.userSurname != null) {
        return "Siz ${widget.userName} ${widget.userSurname}'siniz.";
      } else if (widget.userName != null) {
        return "Siz ${widget.userName}'sınız.";
      } else {
        return "Kullanıcı bilgileriniz bulunamadı.";
      }
    }

    // Yaklaşan etkinlikler hakkında soru sorulursa
    if (lowerInput.contains("yaklaşan etkinlik") ||
        lowerInput.contains("gelecek etkinlik") ||
        lowerInput.contains("etkinlikler neler") ||
        lowerInput.contains("etkinlik")) {
      if (upcomingEvents.isEmpty) {
        return "Şu anda planlanmış bir etkinlik bulunmuyor. Takvimi daha sonra tekrar kontrol edebilirsin.";
      }

      String eventList = "İşte yaklaşan etkinliklerimiz:\n\n";
      for (var event in upcomingEvents) {
        String title = event['title'] ?? 'Başlıksız';
        DateTime date = (event['date'] as Timestamp).toDate();
        String formattedDate =
            DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(date);
        eventList += "🗓️ **$title**\n";
        eventList += "   - **Tarih:** $formattedDate\n";
        eventList += "   - **Detay:** ${event['details'] ?? 'Detay yok'}\n\n";
      }
      return eventList.trim();
    }

    // Haritadaki anahtar kelimeleri kontrol et
    for (var entry in ekonomiTopluluguBilgileri.entries) {
      if (lowerInput.contains(entry.key)) {
        return entry.value;
      }
    }

    // Özel durumlar
    if (lowerInput.contains("teşekkür") ||
        lowerInput.contains("sağ ol") ||
        lowerInput.contains("thanks")) {
      String thanksMsg = "Rica ederim";
      if (widget.userName != null) {
        thanksMsg += " ${widget.userName}";
      }
      thanksMsg +=
          "! Başka sorunuz var mı? Ekonomi ile ilgili merak ettiklerinizi sormaktan çekinmeyin. 📈";
      return thanksMsg;
    } else if (lowerInput.contains("görüşürüz") ||
        lowerInput.contains("hoşça kal") ||
        lowerInput.contains("bye")) {
      String goodbyeMsg = "Görüşmek üzere";
      if (widget.userName != null) {
        goodbyeMsg += " ${widget.userName}";
      }
      goodbyeMsg +=
          "! Kırıkkale Üniversitesi Ekonomi Topluluğu olarak başarılar dileriz. 🎯";
      return goodbyeMsg;
    }

    // Konu dışı sorular için
    return "Üzgünüm, bu konuda bilgim yok. Sadece Kırıkkale Üniversitesi Ekonomi Topluluğu ve ekonomi ile ilgili konularda yardımcı olabilirim. \n\nLütfen şu konularda sorular sorun:\n• Ekonomi terimleri\n• Topluluk etkinlikleri\n• Üniversite bilgileri\n• Ekonomi teorileri";
  }

  void _showWelcomeMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add({
          "role": "assistant",
          "text": _getPersonalizedGreeting(),
          "time": DateTime.now()
        });
      });
    });
  }

  Future<List<Map<String, dynamic>>> _getUpcomingEvents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('yaklasan_etkinlikler')
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('date', descending: false)
          .limit(3) // Sohbeti yormamak için ilk 3 etkinliği alalım
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Yaklaşan etkinlikler alınırken hata: $e");
      return [];
    }
  }

  void _sendMessage(String text) async {
    if (text.isEmpty) return;

    // Kullanıcı mesajını ekle
    setState(() {
      _messages.add({"role": "user", "text": text, "time": DateTime.now()});
    });
    _controller.clear();
    _scrollToBottom();

    // Yaklaşan etkinlik verilerini çek
    final upcomingEvents = await _getUpcomingEvents();
    // Kısıtlı yanıtı al
    String response = _getRestrictedResponse(text, upcomingEvents);

    // Asistan yanıtını ekle (küçük gecikme ile)
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(
            {"role": "assistant", "text": response, "time": DateTime.now()});
      });

      _scrollToBottom();
    });
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mesajlar listesi
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 60),
                      Image(
                        image: AssetImage('assets/images/ketyapayzeka.png'),
                        height: 120,
                      ),
                      SizedBox(height: 24),
                      Text(
                        "KET Asistan'a Hoş Geldiniz!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Ekonomi veya topluluk hakkında soru sorarak başlayın",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _MessageBubble(
                      message: message["text"] as String,
                      isUser: message["role"] == "user",
                    );
                  },
                ),
        ),

        // Input alanı
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "KET Asistan'a bir soru sorun...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: () => _sendMessage(_controller.text),
                backgroundColor: Colors.deepPurple.shade600,
                mini: true,
                elevation: 2,
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
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _MessageBubble({
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
                backgroundColor: Color(0xFF1a237e),
                radius: 20,
                backgroundImage: AssetImage('assets/images/ketyapayzeka.png')),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: _buildMessageContainer(context),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                radius: 20,
                child: Icon(Icons.person, color: Colors.white, size: 20)),
        ],
      ),
    );
  }

  Widget _buildMessageContainer(BuildContext context) {
    final borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? Colors.blueAccent : Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: message));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mesaj panoya kopyalandı!')),
          );
        },
        child: Text(
          message,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
