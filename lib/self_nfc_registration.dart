import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'nfc_service.dart';

class SelfNFCRegistration extends StatefulWidget {
  final String currentAdminUsername;
  
  const SelfNFCRegistration({Key? key, required this.currentAdminUsername}) : super(key: key);

  @override
  _SelfNFCRegistrationState createState() => _SelfNFCRegistrationState();
}

class _SelfNFCRegistrationState extends State<SelfNFCRegistration> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _addMyTCToNFC() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'TC Kimlik kartınızı cihaza yaklaştırın...';
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
        
        final existingDoc = await FirebaseFirestore.instance
            .collection('yönetici_tc')
            .doc(tcNo)
            .get();
            
        if (existingDoc.exists) {
          setState(() {
            _statusMessage = 'TC numaranız zaten kayıtlı: $tcNo';
            _isLoading = false;
          });
          return;
        }

        await FirebaseFirestore.instance
            .collection('yönetici_tc')
            .doc(tcNo)
            .set({
          'tc_no': tcNo,
          'ad_soyad': adSoyad,
          'aktif': true,
          'ekleme_tarihi': FieldValue.serverTimestamp(),
          'ekleyen_admin': widget.currentAdminUsername,
          'kendi_tc_si': true,
          'son_giris': null,
          'dogum_tarihi': tcData['dogumTarihi'] ?? '',
        });

        setState(() {
          _statusMessage = 'TC numaranız başarıyla eklendi!\n$adSoyad ($tcNo)\n\nArtık NFC ile giriş yapabilirsiniz.';
          _isLoading = false;
        });
        
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kendi TC\'mi NFC\'ye Ekle', style: TextStyle(color: Colors.white)),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add, size: 64, color: Colors.blue),
                    const SizedBox(height: 24),
                    const Text(
                      'TC Kimliğinizi NFC\'ye Ekleyin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Merhaba ${widget.currentAdminUsername}!\n\nTC Kimlik kartınızı cihaza yaklaştırarak NFC giriş sistemine ekleyebilirsiniz. Bu sayede gelecekte sadece kartınızı yaklaştırarak hızlıca giriş yapabilirsiniz.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addMyTCToNFC,
                          icon: const Icon(Icons.nfc),
                          label: const Text('TC Kimliğimi NFC\'ye Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (_statusMessage.isNotEmpty && !_isLoading) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _statusMessage.contains('başarıyla') 
                              ? Colors.green.shade50 
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _statusMessage.contains('başarıyla') 
                                ? Colors.green 
                                : Colors.orange,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _statusMessage.contains('başarıyla') 
                                  ? Icons.check_circle 
                                  : Icons.warning,
                              color: _statusMessage.contains('başarıyla') 
                                  ? Colors.green 
                                  : Colors.orange,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _statusMessage,
                              style: TextStyle(
                                color: _statusMessage.contains('başarıyla') 
                                    ? Colors.green.shade700 
                                    : Colors.orange.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}