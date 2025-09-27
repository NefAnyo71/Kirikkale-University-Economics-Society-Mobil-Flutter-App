import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyPage1 extends StatefulWidget {
  const SurveyPage1({Key? key}) : super(key: key);

  @override
  _SurveyPage1State createState() => _SurveyPage1State();
}

class _SurveyPage1State extends State<SurveyPage1> {
  // Anket verilerini tutacak değişkenler
  int cokIyiCount = 0;
  int iyiCount = 0;
  int ortaCount = 0;
  int kotuCount = 0;

  // Yazılı geri bildirim listeleri
  List<String> communityFeedbackList = [];
  List<String> appImprovementsList = [];
  List<String> eventFeedbackList = [];

  // Firestore'dan verileri çekme metodu
  void _fetchSurveyData() {
    FirebaseFirestore.instance.collection('surveys').snapshots().listen((snapshot) {
      // Sayaçları ve listeleri sıfırla
      cokIyiCount = 0;
      iyiCount = 0;
      ortaCount = 0;
      kotuCount = 0;
      communityFeedbackList.clear();
      appImprovementsList.clear();
      eventFeedbackList.clear();

      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data.containsKey('appRating')) {
          switch (data['appRating']) {
            case 'Çok İyi':
              cokIyiCount++;
              break;
            case 'İyi':
              iyiCount++;
              break;
            case 'Orta':
              ortaCount++;
              break;
            case 'Kötü':
              kotuCount++;
              break;
          }
        }
        if (data.containsKey('communityFeedback') && data['communityFeedback'] != null && data['communityFeedback'].isNotEmpty) {
          communityFeedbackList.add(data['communityFeedback']);
        }
        if (data.containsKey('appImprovements') && data['appImprovements'] != null && data['appImprovements'].isNotEmpty) {
          appImprovementsList.add(data['appImprovements']);
        }
        if (data.containsKey('eventFeedback') && data['eventFeedback'] != null && data['eventFeedback'].isNotEmpty) {
          eventFeedbackList.add(data['eventFeedback']);
        }
      }
      // Veriler güncellendiğinde UI'ı yenile
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchSurveyData();
  }

  // Özel bar grafik widget'ı
  Widget _buildCustomBarChart() {
    final total = cokIyiCount + iyiCount + ortaCount + kotuCount;
    final maxValue = [cokIyiCount, iyiCount, ortaCount, kotuCount].reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        _buildBar('Çok İyi', cokIyiCount, maxValue, total, Colors.green),
        const SizedBox(height: 12),
        _buildBar('İyi', iyiCount, maxValue, total, Colors.lightGreen),
        const SizedBox(height: 12),
        _buildBar('Orta', ortaCount, maxValue, total, Colors.orange),
        const SizedBox(height: 12),
        _buildBar('Kötü', kotuCount, maxValue, total, Colors.red),
      ],
    );
  }

  Widget _buildBar(String label, int value, int maxValue, int total, Color color) {
    final percentage = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '$value ($percentage%)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 24,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: maxValue > 0 ? value / maxValue : 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: color,
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ExpansionTile ile geri bildirimleri gösterme
  Widget _buildFeedbackList(String title, List<String> feedbackList) {
    if (feedbackList.isEmpty) {
      return Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: ListTile(
          title: Text(
            '$title (0)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('Henüz geri bildirim yok'),
          leading: const Icon(Icons.comment, color: Colors.grey),
        ),
      );
    }
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ExpansionTile(
        title: Text(
          '$title (${feedbackList.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: feedbackList.map((feedback) {
          return ListTile(
            title: Text(feedback),
            leading: const Icon(Icons.comment),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yönetici Paneli',
          style: TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 6.0,
        centerTitle: true,
      ),
      body: Container(
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // İstatistikler Bilgi Kartı
              Card(
                color: Colors.white,
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Anket İstatistikleri',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Toplam ${cokIyiCount + iyiCount + ortaCount + kotuCount} anket doldurulmuş',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildStatBox('Çok İyi', cokIyiCount, Colors.green),
                          _buildStatBox('İyi', iyiCount, Colors.lightGreen),
                          _buildStatBox('Orta', ortaCount, Colors.orange),
                          _buildStatBox('Kötü', kotuCount, Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Uygulama Değerlendirmesi Grafiği
              Card(
                color: Colors.white,
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Uygulama Değerlendirmeleri',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildCustomBarChart(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Toplam ${cokIyiCount + iyiCount + ortaCount + kotuCount} değerlendirme',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Yazılı Geri Bildirimler
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Kullanıcı Geri Bildirimleri',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildFeedbackList('Topluluk Hakkında Geri Bildirimler', communityFeedbackList),
              _buildFeedbackList('Uygulama Geliştirme Önerileri', appImprovementsList),
              _buildFeedbackList('Etkinlik Geri Bildirimleri', eventFeedbackList),

              // Bilgi Mesajı
              Card(
                color: Colors.white,
                margin: const EdgeInsets.all(16.0),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anket Bilgisi',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Anketler anonimdir. Yaptığınız anketlerin sonuçları sadece yöneticiler ile paylaşılmaktadır. Kırıkkale Üniversitesi Ekonomi Topluluğu',
                        style: TextStyle(fontSize: 16.0, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
            ),
            Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}