// etkinlik_json_5.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EtkinlikJson5 extends StatefulWidget {
  const EtkinlikJson5({super.key});

  @override
  State<EtkinlikJson5> createState() => _EtkinlikJson5State();
}

class _EtkinlikJson5State extends State<EtkinlikJson5> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _urlController = TextEditingController();
  DateTime? _selectedDate;
  final String _collectionName = 'yaklasan_etkinlikler';

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _addOrUpdateEvent([DocumentSnapshot? docToUpdate]) async {
    if (_formKey.currentState!.validate()) {
      try {
        if (docToUpdate == null) {
          // Yeni etkinlik ekleme
          await FirebaseFirestore.instance.collection(_collectionName).add({
            'title': _titleController.text,
            'details': _detailsController.text,
            'url': _urlController.text,
            'date': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Etkinlik başarıyla eklendi')),
          );
        } else {
          // Etkinlik güncelleme
          await FirebaseFirestore.instance.collection(_collectionName).doc(docToUpdate.id).update({
            'title': _titleController.text,
            'details': _detailsController.text,
            'url': _urlController.text,
            'date': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Etkinlik başarıyla güncellendi')),
          );
        }
        _clearForm();
        Navigator.of(context).pop(); // Dialog'u kapat
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _detailsController.clear();
    _urlController.clear();
    setState(() {
      _selectedDate = null;
    });
  }

  Future<void> _deleteEvent(String docId) async {
    await FirebaseFirestore.instance.collection(_collectionName).doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Etkinlik başarıyla silindi')),
    );
  }

  void _showEventDialog([DocumentSnapshot? doc]) {
    if (doc != null) {
      _titleController.text = doc['title'] ?? '';
      _detailsController.text = doc['details'] ?? '';
      _urlController.text = doc['url'] ?? '';
      _selectedDate = doc['date'] is Timestamp ? (doc['date'] as Timestamp).toDate() : null;
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(doc == null ? 'Yeni Etkinlik Ekle' : 'Etkinliği Düzenle'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen bir başlık girin';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _detailsController,
                    decoration: const InputDecoration(labelText: 'Detaylar'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen detayları girin';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(labelText: 'Görsel URL'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: Text(
                      _selectedDate == null
                          ? 'Tarih ve Saat Seç'
                          : DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(_selectedDate!),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearForm();
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => _addOrUpdateEvent(doc),
              child: Text(doc == null ? 'Ekle' : 'Güncelle'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Etkinlik Yönetimi",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF7C4DFF),
                Color(0xFF18FFFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showEventDialog(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C4DFF),
              Color(0xFF18FFFF),
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(_collectionName).orderBy('date', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Henüz etkinlik yok", style: TextStyle(color: Colors.white)));
            }
            final etkinlikler = snapshot.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: etkinlikler.length,
              itemBuilder: (context, index) {
                var etkinlik = etkinlikler[index];
                var title = etkinlik['title'] ?? 'Başlıksız';
                var details = etkinlik['details'] ?? 'Detay yok';
                var date = etkinlik['date'] is Timestamp
                    ? DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format((etkinlik['date'] as Timestamp).toDate())
                    : 'Tarih yok';
                var url = etkinlik['url'] ?? '';

                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: url.isNotEmpty
                        ? Image.network(url, width: 60, height: 60, fit: BoxFit.cover)
                        : const Icon(Icons.event),
                    title: Text(title),
                    subtitle: Text('$date\n$details'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEventDialog(etkinlik),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEvent(etkinlik.id),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
