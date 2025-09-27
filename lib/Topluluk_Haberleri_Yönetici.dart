import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ToplulukHaberleriSayfasi extends StatefulWidget {
  const ToplulukHaberleriSayfasi({Key? key}) : super(key: key);

  @override
  _ToplulukHaberleriSayfasiState createState() =>
      _ToplulukHaberleriSayfasiState();
}

class _ToplulukHaberleriSayfasiState extends State<ToplulukHaberleriSayfasi> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  void _addNews() async {
    if (_titleController.text.isNotEmpty &&
        _detailsController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('toplulukhaberleri2').add({
        'title': _titleController.text,
        'details': _detailsController.text,
        'url': _urlController.text,
        'date': FieldValue.serverTimestamp(),
      });
      _titleController.clear();
      _detailsController.clear();
      _urlController.clear();
    }
  }

  void _deleteNews(String id) async {
    await FirebaseFirestore.instance
        .collection('toplulukhaberleri2')
        .doc(id)
        .delete();
  }

  void _updateNews(String id, String title, String details, String url) async {
    await FirebaseFirestore.instance
        .collection('toplulukhaberleri2')
        .doc(id)
        .update({
      'title': title,
      'details': details,
      'url': url,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topluluk Haberleri'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueAccent.withOpacity(0.7),
              Colors.purple.withOpacity(0.7)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                  ),
                  TextField(
                    controller: _detailsController,
                    decoration: const InputDecoration(labelText: 'Detaylar'),
                  ),
                  TextField(
                    controller: _urlController,
                    decoration:
                        const InputDecoration(labelText: 'URL (isteğe bağlı)'),
                  ),
                  ElevatedButton(
                    onPressed: _addNews,
                    child: const Text('Haber Ekle'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('toplulukhaberleri2')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Haber bulunamadı.'));
                  }

                  var newsList = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      var news = newsList[index];
                      var date = news['date'] != null
                          ? (news['date'] as Timestamp).toDate()
                          : DateTime.now();
                      var title = news['title'] ?? 'Başlık yok';
                      var details = news['details'] ?? 'Detay yok';
                      var url = news['url'] ?? '';
                      var newsId = news.id;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal)),
                              const SizedBox(height: 8),
                              Text(
                                  'Tarih: ${date.toLocal().toString().split(' ')[0]}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Text(details,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black87)),
                              if (url.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(url,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteNews(newsId),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      _titleController.text = title;
                                      _detailsController.text = details;
                                      _urlController.text = url;

                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Haber Düzenle'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: _titleController,
                                                  decoration:
                                                      const InputDecoration(
                                                          labelText: 'Başlık'),
                                                ),
                                                TextField(
                                                  controller:
                                                      _detailsController,
                                                  decoration:
                                                      const InputDecoration(
                                                          labelText:
                                                              'Detaylar'),
                                                ),
                                                TextField(
                                                  controller: _urlController,
                                                  decoration:
                                                      const InputDecoration(
                                                          labelText: 'URL'),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  _updateNews(
                                                      newsId,
                                                      _titleController.text,
                                                      _detailsController.text,
                                                      _urlController.text);
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Güncelle'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('İptal'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
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
      ),
    );
  }
}
