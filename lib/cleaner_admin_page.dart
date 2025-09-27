import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Admin sayfası widget'ı
class CleanderAdminPage extends StatefulWidget {
  @override
  _CleanerAdminPageState createState() => _CleanerAdminPageState();
}

class _CleanerAdminPageState extends State<CleanderAdminPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // Yeni etkinlik verisini Firebase'e eklemek için fonksiyon
  Future<void> _addEvent() async {
    await FirebaseFirestore.instance.collection('etkinlikler').add({
      'title': _titleController.text,
      'details': _detailsController.text,
      'url': _urlController.text,
      'date': _dateController.text,
    });

    // Formu sıfırlamak için
    _titleController.clear();
    _detailsController.clear();
    _urlController.clear();
    _dateController.clear();
  }

  // Etkinliği silmek için fonksiyon
  Future<void> _deleteEvent(String eventId) async {
    await FirebaseFirestore.instance
        .collection('etkinlikler')
        .doc(eventId) // Etkinliğin ID'si ile silme işlemi
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Etkinlik Yönetim Sayfası'),
        backgroundColor: const Color.fromARGB(0, 50, 31, 160),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Yeni etkinlik eklemek için form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Etkinlik Başlığı'),
                ),
                TextField(
                  controller: _detailsController,
                  decoration: InputDecoration(labelText: 'Etkinlik Detayları'),
                ),
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(labelText: 'Etkinlik URL\'si'),
                ),
                TextField(
                  controller: _dateController,
                  decoration: InputDecoration(labelText: 'Etkinlik Tarihi'),
                ),
                ElevatedButton(
                  onPressed: _addEvent,
                  child: Text('Etkinlik Ekle'),
                ),
              ],
            ),
          ),

          // Etkinlikleri Firebase'den alıp ekranda göstermek için StreamBuilder
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('etkinlikler')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "Henüz etkinlik yok.",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                final etkinlikler = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: etkinlikler.length,
                  itemBuilder: (context, index) {
                    final etkinlik = etkinlikler[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Başlık
                            Text(
                              etkinlik['title'] ?? "Başlık Yok",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 5),

                            // Tarih
                            Text(
                              "📅 Tarih: ${etkinlik['date'] ?? "Belirtilmemiş"}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 10),

                            // Detaylar
                            Text(
                              etkinlik['details'] ?? "Detay Yok",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            SizedBox(height: 10),

                            // Görsel (varsa)
                            if (etkinlik['url'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  etkinlik['url'],
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            SizedBox(height: 10),

                            // Silme Butonu
                            ElevatedButton(
                              onPressed: () => _deleteEvent(etkinlik.id),
                              child: Text('Etkinliği Sil'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.red, // Silme butonunun rengi
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
        ],
      ),
    );
  }
}
