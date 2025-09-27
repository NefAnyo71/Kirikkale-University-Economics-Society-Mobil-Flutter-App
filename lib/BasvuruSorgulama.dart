import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BasvuruSorgulama extends StatefulWidget {
  const BasvuruSorgulama({Key? key}) : super(key: key);

  @override
  _BasvuruSorgulamaState createState() => _BasvuruSorgulamaState();
}

class _BasvuruSorgulamaState extends State<BasvuruSorgulama> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _basvuruSayisi = 0;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  Future<void> _updatePaymentStatus(String docId, String status) async {
    try {
      await _firestore.collection('geziform').doc(docId).update({
        'odemeDurumu': status,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ödeme durumu güncellendi: $status',
                style: const TextStyle(color: Colors.black))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Güncelleme sırasında hata oluştu: $e',
                style: const TextStyle(color: Colors.black))),
      );
    }
  }

  Future<void> _deleteApplication(String docId, BuildContext context) async {
    // İlk onay dialogu
    final bool? firstConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              const Text('Silme Onayı', style: TextStyle(color: Colors.black)),
          content: const Text(
              'Bu başvuruyu silmek istediğinizden emin misiniz?',
              style: TextStyle(color: Colors.black)),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Evet', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (firstConfirm != true) return;

    // İkinci onay dialogu
    final bool? secondConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              const Text('Tekrar Onay', style: TextStyle(color: Colors.black)),
          content: const Text(
              'Bu işlem geri alınamaz. Bu başvuruyu silmek istediğinize emin misiniz?',
              style: TextStyle(color: Colors.black)),
          actions: <Widget>[
            TextButton(
              child: const Text('Hayır', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Evet, Sil',
                  style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (secondConfirm == true) {
      try {
        await _firestore.collection('geziform').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Başvuru başarıyla silindi',
                  style: TextStyle(color: Colors.black))),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Silme işlemi sırasında hata oluştu: $e',
                  style: const TextStyle(color: Colors.black))),
        );
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Ara...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text('Başvuru Sorgulama',
                style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 4,
        actions: [
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('geziform').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      _basvuruSayisi = snapshot.data!.docs.length;
                      return Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_basvuruSayisi',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D47A1),
              Color(0xFFFFA726),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isSearching)
              const Text(
                'Başvuru Listesi',
                style: TextStyle(
                  fontSize: 26.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            const SizedBox(height: 16.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('geziform')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final applications = snapshot.data!.docs;

                  if (applications.isEmpty) {
                    return const Center(
                      child: Text(
                        'Henüz başvuru yok.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    );
                  }

                  // Arama işlemi
                  final filteredApplications = applications.where((doc) {
                    if (_searchQuery.isEmpty) return true;
                    final data = doc.data() as Map<String, dynamic>;

                    // Telefon numarası için özel işlem
                    final phoneNumber = data['telefon']
                            ?.toString()
                            .replaceAll(RegExp(r'[^0-9]'), '') ??
                        '';
                    final searchNumbers =
                        _searchQuery.replaceAll(RegExp(r'[^0-9]'), '');

                    return (data['ad']
                                ?.toString()
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ??
                            false) ||
                        (data['soyad']
                                ?.toString()
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ??
                            false) ||
                        (data['tc']?.toString().contains(_searchQuery) ??
                            false) ||
                        (data['email']
                                ?.toString()
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ??
                            false) ||
                        (phoneNumber.contains(searchNumbers));
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredApplications.length,
                    itemBuilder: (context, index) {
                      final application = filteredApplications[index];
                      final data = application.data() as Map<String, dynamic>;
                      final docId = application.id;
                      final odemeDurumu = data['odemeDurumu'] ?? 'odenmedi';

                      // Firestore'a kaydedilme tarihi (timestamp)
                      // `application['timestamp']` ifadesi bir çalışma zamanı hatasına neden olur.
                      // Veriye her zaman `data` map'i üzerinden erişilmelidir.
                      Timestamp? firestoreTimestamp = data['timestamp'];
                      String firestoreFormattedDate = 'Belirtilmemiş';
                      if (firestoreTimestamp != null) {
                        DateTime date = firestoreTimestamp.toDate().toLocal();
                        firestoreFormattedDate =
                            DateFormat("MMMM d, y 'at' h:mm:ss a")
                                    .format(date) +
                                ' UTC+3';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                  'Ad:', data['ad'] ?? 'Belirtilmemiş'),
                              _buildInfoRow(
                                  'Soyad:', data['soyad'] ?? 'Belirtilmemiş'),
                              _buildInfoRow(
                                  'T.C. No:', data['tc'] ?? 'Belirtilmemiş'),
                              _buildInfoRow(
                                  'Email:', data['email'] ?? 'Belirtilmemiş'),
                              _buildInfoRow('Telefon:',
                                  data['telefon'] ?? 'Belirtilmemiş'),
                              _buildInfoRow('Başvuru Kayıt Tarihi:',
                                  firestoreFormattedDate),
                              _buildInfoRow(
                                'Ödeme Durumu:',
                                odemeDurumu == 'odendi' ? 'Ödendi' : 'Ödenmedi',
                                isPayment: true,
                                status: odemeDurumu,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () =>
                                        _updatePaymentStatus(docId, 'odendi'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: odemeDurumu == 'odendi'
                                          ? Colors.green
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text('Ödendi'),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _updatePaymentStatus(docId, 'odenmedi'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: odemeDurumu == 'odenmedi'
                                          ? Colors.red
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text('Ödenmedi'),
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.delete,
                                        size: 7, color: Colors.white),
                                    label: const Text('Sil',
                                        style: TextStyle(color: Colors.white)),
                                    onPressed: () =>
                                        _deleteApplication(docId, context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
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

  Widget _buildInfoRow(String label, String value,
      {bool isPayment = false, String status = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 6.0),
          if (!isPayment)
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
          if (isPayment)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'odendi' ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
