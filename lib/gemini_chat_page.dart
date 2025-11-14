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
              height: 32,
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
  
  final Map<String, String> ekonomiTopluluguBilgileri = {
    "topluluk nedir":
        "Ben KET Asistan, Kırıkkale Üniversitesi Ekonomi Topluluğu'nun dijital yardımcısıyım. Ekonomi alanında faaliyet gösteren bir öğrenci topluluğuyuz.",
    "topluluk amacı":
        "Ekonomi bilincini geliştirmek, seminerler düzenlemek ve öğrencileri ekonomi alanında bilgilendirmek.",
    "topluluk başkanı":
        "Topluluk başkanı hakkında güncel bilgi için ekonomi bölümüne danışabilirsiniz.",
    "enflasyon":
        "Enflasyon, mal ve hizmet fiyatlarının genel seviyesindeki sürekli artıştır.",
    "faiz": "Faiz, borç alınan paranın kullanımı için ödenen bedeldir.",
    "döviz kuru":
        "Döviz kuru, bir ülke parasının diğer bir ülke parası cinsinden değeridir.",
    "büyüme":
        "Ekonomik büyüme, bir ekonominin üretim kapasitesindeki artıştır.",
    "ekonomi":
        "Ekonomi, sınırsız ihtiyaçların sınırlı kaynaklarla nasıl karşılanacağını inceleyen bilim dalıdır.",
    "kırıkkale üniversitesi":
        "Kırıkkale Üniversitesi, 1992 yılında kurulmuş devlet üniversitesidir.",
    "ekonomi bölümü":
        "İktisadi ve İdari Bilimler Fakültesi bünyesinde eğitim vermektedir.",
    "iletişim":
        "Detaylı bilgi için üniversitenin resmi web sitesini ziyaret edebilirsiniz.",
    "kü":
        "Kırıkkale Üniversitesi, 1992 yılında kurulmuş köklü bir devlet üniversitesidir.",
    "makroekonomi": "Makroekonomi, ekonominin bir bütün olarak incelenmesidir.",
    "mikroekonomi":
        "Mikroekonomi, bireysel ekonomik birimlerin davranışlarını inceler.",
    "iktisat":
        "İktisat, sınırsız ihtiyaçların sınırlı, ihtiyaçların sınırsız olduğu durumda optimal dağılımı inceler.",
    "gsyh":
        "GSYH (Gayri Safi Yurtiçi Hasıla), bir ülkenin belirli dönemde ürettiği nihai mal ve hizmetlerin toplam değeridir.",
    "merhaba": "Merhaba! Sana nasıl yardımcı olabilirim?",
    "selam": "Selam! Ekonomi veya topluluk hakkında bir sorun mu var?",
    "nasılsın":
        "Teşekkür ederim, iyiyim! Ekonomi verilerini analiz ediyorum. Senin için ne yapabilirim?",
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR');
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

  String _getFlexibleResponse(
      String userInput, List<Map<String, dynamic>> upcomingEvents) {
    String lowerInput = userInput.toLowerCase();

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

    for (var entry in ekonomiTopluluguBilgileri.entries) {
      if (lowerInput.contains(entry.key)) {
        return entry.value;
      }
    }

    if (lowerInput.contains("teşekkür") ||
        lowerInput.contains("sağ ol") ||
        lowerInput.contains("thanks")) {
      String thanksMsg = "Rica ederim";
      if (widget.userName != null) {
        thanksMsg += " ${widget.userName}";
      }
      thanksMsg += "! Başka bir konuda yardımcı olabilir miyim? 😊";
      return thanksMsg;
    }

    if (lowerInput.contains("görüşürüz") ||
        lowerInput.contains("hoşça kal") ||
        lowerInput.contains("bye")) {
      String goodbyeMsg = "Görüşmek üzere";
      if (widget.userName != null) {
        goodbyeMsg += " ${widget.userName}";
      }
      goodbyeMsg += "! İyi günler dilerim. 🌟";
      return goodbyeMsg;
    }

    if (lowerInput.contains("nasıl") && lowerInput.contains("yardım")) {
      return "Size birçok konuda yardımcı olabilirim:\n\n• Ekonomi terimleri ve kavramları\n• Topluluk etkinlikleri ve duyurular\n• Üniversite hakkında genel bilgiler\n• Akademik konular\n• Genel sorularınız\n\nHangi konuda yardıma ihtiyacınız var?";
    }

    if (lowerInput.contains("naber") || lowerInput.contains("ne haber")) {
      return "İyiyim, teşekkürler! Ekonomi dünyasındaki gelişmeleri takip ediyorum. Sen nasılsın? Hangi konuda sohbet etmek istersin?";
    }

    if (lowerInput.contains("hava durumu") || lowerInput.contains("hava")) {
      return "Hava durumu hakkında güncel bilgim yok, ancak ekonomik iklim hakkında konuşabiliriz! 😄 Ekonomi ile ilgili merak ettiğin bir konu var mı?";
    }

    if (lowerInput.contains("ne yapıyorsun")) {
      return "Şu anda sizinle sohbet ediyorum ve sorularınızı yanıtlamaya hazırım! Ekonomi, topluluk veya başka hangi konuda konuşmak istersiniz?";
    }

    if (lowerInput.contains("hesapla") || lowerInput.contains("matematik") || 
        lowerInput.contains("çarp") || lowerInput.contains("böl") ||
        lowerInput.contains("topla") || lowerInput.contains("çıkar")) {
      return "Basit matematik işlemlerinde yardımcı olabilirim! Hangi hesaplamayı yapmak istiyorsunuz? Özellikle ekonomi ile ilgili hesaplamalarda size yardımcı olabilirim.";
    }

    if (lowerInput.contains("tarih") && !lowerInput.contains("etkinlik")) {
      return "Tarih konusunda genel bilgiler verebilirim, özellikle ekonomi tarihi konularında. Hangi dönem veya olay hakkında bilgi almak istiyorsunuz?";
    }

    if (lowerInput.contains("kitap") || lowerInput.contains("okuma")) {
      return "Ekonomi alanında okuyabileceğiniz harika kitaplar var! Hangi seviyede ve hangi konularda kitap önerisi istiyorsunuz? Mikroekonomi, makroekonomi, finans gibi...";
    }

    if (lowerInput.contains("film") || lowerInput.contains("dizi")) {
      return "Ekonomi ve finans temalı filmler ve diziler oldukça ilginç olabiliyor! 'The Big Short', 'Wall Street', 'Billions' gibi yapımlar ekonomi dünyasını anlamamıza yardımcı olur. Hangi tür içerik arıyorsunuz?";
    }

    if (lowerInput.contains("motivasyon") || lowerInput.contains("başarı")) {
      return "Başarı için sürekli öğrenme ve gelişim çok önemli! Ekonomi alanında kendinizi geliştirmek için topluluk etkinliklerimizi takip edebilir, kitap okuyabilir ve pratik yapabilirsiniz. Hangi alanda gelişmek istiyorsunuz?";
    }

    if (lowerInput.contains("kariyer") || lowerInput.contains("iş") || lowerInput.contains("meslek")) {
      return "Ekonomi mezunları için birçok kariyer fırsatı var: bankacılık, finans, danışmanlık, kamu sektörü, akademi... Hangi alanda çalışmayı düşünüyorsunuz? Size o konuda bilgi verebilirim.";
    }

    if (lowerInput.contains("teknoloji") || lowerInput.contains("yapay zeka") || lowerInput.contains("ai")) {
      return "Teknoloji ekonomiyi büyük ölçüde etkiliyor! Yapay zeka, blockchain, fintech gibi alanlar ekonominin geleceğini şekillendiriyor. Hangi teknoloji konusu ilginizi çekiyor?";
    }

    if (lowerInput.contains("spor") || lowerInput.contains("futbol") || lowerInput.contains("basketbol")) {
      return "Spor da aslında büyük bir ekonomi! Spor ekonomisi, transfer piyasaları, sponsorluklar... İlginç bir alan. Spor ekonomisi hakkında bilgi almak ister misiniz?";
    }

    if (lowerInput.contains("yemek") || lowerInput.contains("kültür")) {
      return "Kültür ve gastronomi de ekonominin önemli parçaları! Turizm ekonomisi, yerel kalkınma gibi konularda konuşabiliriz. Hangi açıdan yaklaşmak istersiniz?";
    }

    if (lowerInput.contains("ders") || lowerInput.contains("sınav") || lowerInput.contains("ödev")) {
      return "Eğitim konularında yardımcı olmaya çalışabilirim! Hangi ders veya konu hakkında bilgi almak istiyorsunuz? Ekonomi derslerinizde size destek olabilirim.";
    }

    if (lowerInput.contains("yaşam") || lowerInput.contains("hayat") || lowerInput.contains("gelecek")) {
      return "Yaşam ve gelecek planları önemli konular! Ekonomi bilgisi günlük hayatta da çok işe yarar. Kişisel finans, yatırım, bütçe yönetimi gibi konularda konuşabiliriz.";
    }

    return "İlginç bir soru! Bu konuda detaylı bilgim olmayabilir, ama elimden geldiğince yardımcı olmaya çalışırım. Daha spesifik bir soru sorarsanız veya ekonomi, topluluk, eğitim gibi konulara yönelirseniz size daha iyi yardımcı olabilirim. 😊\n\nBaşka hangi konularda konuşmak istersiniz?";
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
          .limit(3)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Yaklaşan etkinlikler alınırken hata: $e");
      return [];
    }
  }

  void _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text, "time": DateTime.now()});
    });
    _controller.clear();
    _scrollToBottom();

    final upcomingEvents = await _getUpcomingEvents();
    String response = _getFlexibleResponse(text, upcomingEvents);

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