import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VotingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VotingScreen(),
    );
  }
}

class VotingScreen extends StatefulWidget {
  @override
  _VotingScreenState createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _pollTitleController = TextEditingController();
  TextEditingController _optionController = TextEditingController();
  List<String> options = [];

  @override
  void initState() {
    super.initState();
    loadPolls(); // Veritabanındaki oylamaları yükle
  }

  // Firestore'dan oylamaları yükleyen fonksiyon
  void loadPolls() async {
    setState(() {}); // Verileri yüklerken ekranı güncelliyoruz.
  }

  // Oylama başlığını ve seçenekleri Firestore'a kaydetme
  void createPoll() async {
    String pollTitle = _pollTitleController.text.trim();
    if (pollTitle.isEmpty || options.isEmpty) {
      return; // Başlık ya da seçenek boş olamaz
    }

    // Oylama başlığını ve seçenekleri Firestore'a ekliyoruz
    DocumentReference pollRef = _firestore.collection('polls').doc();
    await pollRef.set({
      'title': pollTitle,
      'options':
          options.map((option) => {'option': option, 'votes': 0}).toList(),
    });

    // Seçenekleri temizle ve başlığı sıfırla
    setState(() {
      options.clear();
      _pollTitleController.clear();
      _optionController.clear();
    });
  }

  // Oylama fonksiyonu
  void vote(String pollId, String option) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? hasVoted = prefs.getString(
        'hasVoted_$pollId'); // Kullanıcının oy verip vermediğini kontrol et

    if (hasVoted != null && hasVoted == 'true') {
      // Eğer kullanıcı zaten oy verdiyse
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sadece bir kez oy verebilirsiniz!')),
      );
      return;
    }

    DocumentReference pollRef = _firestore.collection('polls').doc(pollId);

    // Firestore işlemi için transaction kullanıyoruz
    _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(pollRef);
      if (snapshot.exists) {
        List<dynamic> currentOptions = snapshot['options'] ?? [];
        for (var opt in currentOptions) {
          if (opt['option'] == option) {
            int currentVotes = opt['votes'] ?? 0;
            opt['votes'] = currentVotes + 1;
            break;
          }
        }
        transaction.update(pollRef, {'options': currentOptions});

        // Kullanıcının oy verdiğini SharedPreferences'e kaydediyoruz
        prefs.setString('hasVoted_$pollId', 'true');
      }
    });

    // Oy verme işlemi tamamlandığında bildirim göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Oyunuzu verdiniz!')),
    );
  }

  // Oylama başlığını ve seçenekleri silme fonksiyonu
  void deletePoll(String pollId) async {
    DocumentReference pollRef = _firestore.collection('polls').doc(pollId);
    await pollRef.delete(); // Oylama kaydını siler
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Oylama Uygulaması"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Oylama başlığı ve seçenek ekleme kısmı
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _pollTitleController,
                  decoration: InputDecoration(
                    labelText: 'Oylama Başlığı',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _optionController,
                  decoration: InputDecoration(
                    labelText: 'Seçenek Ekle',
                    border: OutlineInputBorder(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_optionController.text.isNotEmpty) {
                        options.add(_optionController.text.trim());
                        _optionController.clear();
                      }
                    });
                  },
                  child: Text('Seçenek Ekle'),
                ),
                ElevatedButton(
                  onPressed: createPoll,
                  child: Text('Oylama Başlat'),
                ),
              ],
            ),
          ),

          // Oylama seçeneklerini ve mevcut oyları görüntüleme kısmı
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('polls').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var polls = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: polls.length,
                  itemBuilder: (context, index) {
                    var poll = polls[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ExpansionTile(
                        title:
                            Text(poll['title'], style: TextStyle(fontSize: 18)),
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: poll['options'].length,
                            itemBuilder: (context, optionIndex) {
                              var option = poll['options'][optionIndex];
                              return ListTile(
                                title: Text(option['option']),
                                subtitle: Text("Oylar: ${option['votes']}"),
                                trailing: ElevatedButton(
                                  onPressed: () =>
                                      vote(poll.id, option['option']),
                                  child: Text("Oy Ver"),
                                ),
                              );
                            },
                          ),
                          // Oylama başlığını silme butonu
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () => deletePoll(poll.id),
                              child: Text('Oylamayı Sil'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
