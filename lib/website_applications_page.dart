import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WebsiteApplicationsPage extends StatefulWidget {
  const WebsiteApplicationsPage({Key? key}) : super(key: key);

  @override
  _WebsiteApplicationsPageState createState() =>
      _WebsiteApplicationsPageState();
}

class _WebsiteApplicationsPageState extends State<WebsiteApplicationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _hasAllRequiredFields(Map<String, dynamic> data) {
    final requiredFields = [
      'email',
      'message',
      'name',
      'phone',
      'subject',
      'timestamp'
    ];
    return requiredFields
        .every((field) => data.containsKey(field) && data[field] != null);
  }

  Future<void> _deleteApplication(String documentId) async {
    // Kullanıcıdan onay almak için diyalog penceresi açılır
    bool confirmDelete = await showDialog<bool>(
          context: context,
          barrierDismissible:
              false, // Kullanıcı diyalogu dışarı tıklayarak kapatamasın
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Başvuru Silme'),
              content: const Text(
                'Bu başvuruyu silmek istediğinize emin misiniz?',
                style: TextStyle(
                    color: Colors.black), // Yazı rengini siyah yapıyoruz
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // 'Hayır' seçeneği
                  },
                  child: const Text('Hayır'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // 'Evet' seçeneği
                  },
                  child: const Text('Evet'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      // Kullanıcı onayladıysa silme işlemi yapılır
      try {
        await _firestore.collection('feedback').doc(documentId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Başvuru başarıyla silindi.',
              style: TextStyle(
                  color: Colors.black), // Yazı rengini siyah yapıyoruz
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hata oluştu: $e',
              style: TextStyle(
                  color: Colors.black), // Yazı rengini siyah yapıyoruz
            ),
          ),
        );
      }
    } else {
      // Kullanıcı onaylamazsa, işlem iptal edilir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silme işlemi iptal edildi.',
            style:
                TextStyle(color: Colors.black), // Yazı rengini siyah yapıyoruz
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'İnternet Sitesi Başvuruları',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A90E2),
              Color(0xFFFFA500),
              Color(0xFFFFD700),
              Color(0xFFFF0000),
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('feedback').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Hata oluştu: ${snapshot.error}',
                      style: TextStyle(color: Colors.black)));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('Başvuru bulunamadı',
                    style: TextStyle(color: Colors.black, fontSize: 18)),
              );
            }

            // Tüm gerekli alanları olan dokümanları filtrele
            var validDocuments = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _hasAllRequiredFields(data);
            }).toList();

            if (validDocuments.isEmpty) {
              return const Center(
                child: Text('Eksiksiz başvuru bulunamadı',
                    style: TextStyle(color: Colors.black, fontSize: 18)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: validDocuments.length,
              itemBuilder: (context, index) {
                var doc = validDocuments[index];
                var data = doc.data() as Map<String, dynamic>;
                Timestamp timestamp = data['timestamp'];
                DateTime date = timestamp.toDate();

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              data['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.email, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(data['email'],
                                style: const TextStyle(color: Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(data['phone'],
                                style: const TextStyle(color: Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.subject, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              data['subject'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mesaj:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        Text(data['message'],
                            style: const TextStyle(color: Colors.black)),
                        const SizedBox(height: 8),
                        Text(
                          'Başvuru Tarihi: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: Colors.black, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        // Silme butonu
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Veriyi sil
                              _deleteApplication(doc.id);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
