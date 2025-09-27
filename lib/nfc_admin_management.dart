import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'nfc_service.dart';

class NFCAdminManagement extends StatefulWidget {
  final String currentAdminUsername;
  
  const NFCAdminManagement({Key? key, required this.currentAdminUsername}) : super(key: key);

  @override
  _NFCAdminManagementState createState() => _NFCAdminManagementState();
}

class _NFCAdminManagementState extends State<NFCAdminManagement> {
  bool _isLoading = false;
  String _statusMessage = '';
  List<Map<String, dynamic>> _authorizedAdmins = [];

  @override
  void initState() {
    super.initState();
    _loadAuthorizedAdmins();
  }

  Future<void> _loadAuthorizedAdmins() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('yönetici_tc')
          .orderBy('ekleme_tarihi', descending: true)
          .get();
      
      setState(() {
        _authorizedAdmins = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      });
    } catch (e) {
      print('Admin listesi yükleme hatası: $e');
    }
  }

  Future<void> _addNewNFCAdmin() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'NFC kartını cihaza yaklaştırın...';
    });

    try {
      if (!await NFCService.isNFCEnabled()) {
        setState(() {
          _statusMessage = 'NFC kapalı. Lütfen NFC\'yi aktif edin.';
          _isLoading = false;
        });
        await NFCService.openNFCSettings();
        return;
      }

      final tcData = await NFCService.readTCKimlik();
      
      if (tcData != null && tcData['tcNo']!.isNotEmpty) {
        final tcNo = tcData['tcNo']!;
        final adSoyad = '${tcData['ad']} ${tcData['soyad']}';
        
        // Zaten kayıtlı mı kontrol et
        final existingDoc = await FirebaseFirestore.instance
            .collection('yönetici_tc')
            .doc(tcNo)
            .get();
            
        if (existingDoc.exists) {
          setState(() {
            _statusMessage = 'Bu TC numarası zaten kayıtlı: $tcNo';
            _isLoading = false;
          });
          return;
        }

        // Firebase'e ekle
        await FirebaseFirestore.instance
            .collection('yönetici_tc')
            .doc(tcNo)
            .set({
          'tc_no': tcNo,
          'ad_soyad': adSoyad,
          'aktif': true,
          'ekleme_tarihi': FieldValue.serverTimestamp(),
          'ekleyen_admin': widget.currentAdminUsername,
          'son_giris': null,
          'dogum_tarihi': tcData['dogumTarihi'] ?? '',
        });

        setState(() {
          _statusMessage = 'Yeni admin başarıyla eklendi: $adSoyad ($tcNo)';
          _isLoading = false;
        });
        
        // Listeyi yenile
        _loadAuthorizedAdmins();
        
      } else {
        setState(() {
          _statusMessage = 'TC Kimlik kartı okunamadı. Lütfen tekrar deneyin.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Hata: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAdminStatus(String tcNo, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('yönetici_tc')
          .doc(tcNo)
          .update({
        'aktif': !currentStatus,
        'durum_degistiren': widget.currentAdminUsername,
        'durum_degisim_tarihi': FieldValue.serverTimestamp(),
      });
      
      _loadAuthorizedAdmins();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin durumu güncellendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Admin Yönetimi', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // NFC Kart Ekleme Bölümü
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.nfc, size: 48, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    'Yeni NFC Admin Ekle',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TC Kimlik kartını cihaza yaklaştırarak yeni admin ekleyin',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton.icon(
                      onPressed: _addNewNFCAdmin,
                      icon: const Icon(Icons.add),
                      label: const Text('NFC Kart Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  if (_statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusMessage.contains('başarıyla') 
                            ? Colors.green.shade50 
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _statusMessage.contains('başarıyla') 
                              ? Colors.green 
                              : Colors.orange,
                        ),
                      ),
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _statusMessage.contains('başarıyla') 
                              ? Colors.green.shade700 
                              : Colors.orange.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Yetkili Adminler Listesi
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yetkili Adminler',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _authorizedAdmins.length,
                        itemBuilder: (context, index) {
                          final admin = _authorizedAdmins[index];
                          final isActive = admin['aktif'] ?? false;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isActive ? Colors.green : Colors.red,
                                child: Icon(
                                  isActive ? Icons.check : Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(admin['ad_soyad'] ?? 'Bilinmeyen'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TC: ${admin['tc_no']}'),
                                  if (admin['ekleyen_admin'] != null)
                                    Text('Ekleyen: ${admin['ekleyen_admin']}'),
                                  if (admin['son_giris'] != null)
                                    Text('Son Giriş: ${_formatDate(admin['son_giris'])}'),
                                ],
                              ),
                              trailing: Switch(
                                value: isActive,
                                onChanged: (value) => _toggleAdminStatus(admin['tc_no'], isActive),
                                activeColor: Colors.green,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Hiç';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}