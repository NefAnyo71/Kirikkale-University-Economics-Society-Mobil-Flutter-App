import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class KaraListe extends StatefulWidget {
  const KaraListe({Key? key}) : super(key: key);

  @override
  _KaraListeState createState() => _KaraListeState();
}

class _KaraListeState extends State<KaraListe> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  bool _silmeOnay1 = false;
  String? _silinecekId;

  Future<void> _numaraEkle(String numara) async {
    if (_formKey.currentState!.validate()) {
      await _firestore.collection('KaraListe').add({
        'numara': numara,
        'eklenmeTarihi': FieldValue.serverTimestamp(),
      });
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Numara başarıyla eklendi!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _numaraSil(String docId) async {
    if (!_silmeOnay1) {
      setState(() {
        _silmeOnay1 = true;
        _silinecekId = docId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silme işlemini onaylamak için tekrar basın'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _silmeOnay1 = false;
            _silinecekId = null;
          });
        }
      });
      return;
    }

    if (_silinecekId == docId) {
      await _firestore.collection('KaraListe').doc(docId).delete();
      setState(() {
        _silmeOnay1 = false;
        _silinecekId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Numara listeden silindi!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  bool _gecerliTelefon(String numara) {
    final sadeceSayilar = numara.replaceAll(RegExp(r'[^0-9]'), '');
    return sadeceSayilar.length == 11;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kara Liste',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            )),
        backgroundColor: Colors.deepPurple[800],
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Ekleme Kartı
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yeni Numara Ekle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _controller,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Telefon Numarası',
                          hintText: '5051234567 veya 05051234567',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.deepPurple[800]!),
                          ),
                          prefixIcon: const Icon(Icons.phone, color: Colors.deepPurple),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                        ),
                        style: const TextStyle(fontSize: 16),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen bir numara girin';
                          }
                          if (!_gecerliTelefon(value)) {
                            return '11 haneli bir numara girin (5051234567)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _numaraEkle(_controller.text.trim()),
                          child: const Text(
                            'KARA LİSTEYE EKLE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Liste Başlığı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.list, color: Colors.deepPurple, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Kara Listedeki Numaralar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1, height: 1),
            const SizedBox(height: 8),
            // Liste
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('KaraListe')
                    .orderBy('eklenmeTarihi', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Hata: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                      ),
                    );
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Kara Liste Boş',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Yukarıdan numara ekleyebilirsiniz',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final numara = data['numara'] ?? '';
                      final formattedNumara = numara.replaceAllMapped(
                        RegExp(r'(\d{3})(\d{3})(\d{4})'),
                            (match) => '${match[1]} ${match[2]} ${match[3]}',
                      );

                      return Dismissible(
                        key: Key(doc.id),
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_forever,
                              color: Colors.red, size: 30),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Numarayı Sil'),
                              content: const Text('Bu numarayı kara listeden silmek istediğinize emin misiniz?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('İptal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Sil',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) => _numaraSil(doc.id),
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.block,
                                  color: Colors.deepPurple[800]),
                            ),
                            title: Text(
                              formattedNumara,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: data['eklenmeTarihi'] != null
                                ? Text(
                              DateFormat('dd.MM.yyyy HH:mm')
                                  .format((data['eklenmeTarihi'] as Timestamp).toDate()),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            )
                                : null,
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: _silmeOnay1 && _silinecekId == doc.id
                                    ? Colors.red[700]
                                    : Colors.red[400],
                                size: 26,
                              ),
                              onPressed: () => _numaraSil(doc.id),
                            ),
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