import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminNoteApproval extends StatefulWidget {
  const AdminNoteApproval({Key? key}) : super(key: key);

  @override
  _AdminNoteApprovalState createState() => _AdminNoteApprovalState();
}

class _AdminNoteApprovalState extends State<AdminNoteApproval> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Color primaryColor = const Color(0xFF5E35B1);
  final Color secondaryColor = const Color(0xFFEDE7F6);
  final Color accentColor = const Color(0xFFFBC02D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Not Onay Sistemi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor.withOpacity(0.1), Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('pending_notes')
              .orderBy('eklenme_tarihi', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Hata: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                return _buildPendingNoteCard(doc);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Onay Bekleyen Not Yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tüm notlar onaylanmış durumda',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingNoteCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve durum
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['ders_adi'] ?? 'İsimsiz Not',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                    'ONAY BEKLİYOR',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Paylaşan bilgileri
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paylaşan: ${data['paylasan_kullanici_adi']} ${data['paylasan_kullanici_soyadi'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('E-posta: ${data['paylasan_kullanici_email']}'),
                  if (data['eklenme_tarihi'] != null)
                    Text(
                      'Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(data['eklenme_tarihi'].toDate())}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Not detayları
            _buildDetailRow('Fakülte', data['fakulte']),
            _buildDetailRow('Bölüm', data['bolum']),
            _buildDetailRow('Dönem', data['donem']),
            if (data['sinav_turu'] != null)
              _buildDetailRow('Sınav Türü', data['sinav_turu']),
            
            const SizedBox(height: 8),
            
            // Açıklama
            if (data['aciklama'] != null && data['aciklama'].isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Açıklama:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(data['aciklama']),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // PDF önizleme butonu
            if (data['pdf_url'] != null && data['pdf_url'].isNotEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _previewPDF(data['pdf_url']),
                  icon: const Icon(Icons.preview),
                  label: const Text('PDF\'i Önizle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Onay/Red butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectNote(doc.id, data),
                    icon: const Icon(Icons.close),
                    label: const Text('REDDET'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveNote(doc.id, data),
                    icon: const Icon(Icons.check),
                    label: const Text('ONAYLA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value ?? '-'),
          ),
        ],
      ),
    );
  }

  Future<void> _previewPDF(String pdfUrl) async {
    try {
      if (!await launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication)) {
        _showSnackBar('PDF açılamadı', isError: true);
      }
    } catch (e) {
      _showSnackBar('PDF açılırken hata oluştu', isError: true);
    }
  }

  Future<void> _approveNote(String docId, Map<String, dynamic> noteData) async {
    try {
      // Onaylanan notu ana koleksiyona taşı
      await _firestore.collection('ders_notlari').add({
        ...noteData,
        'onay_tarihi': FieldValue.serverTimestamp(),
        'onay_durumu': 'onaylandi',
        'likes': 0,
        'dislikes': 0,
        'downloads': 0,
      });

      // Bekleyen notlar koleksiyonundan sil
      await _firestore.collection('pending_notes').doc(docId).delete();

      // Kullanıcıya kredi ver
      final userEmail = noteData['paylasan_kullanici_email'];
      if (userEmail != null) {
        await _addCreditsForApprovedNote(userEmail);
      }

      _showSnackBar('Not başarıyla onaylandı ve yayınlandı!');
    } catch (e) {
      _showSnackBar('Not onaylanırken hata oluştu: $e', isError: true);
    }
  }

  Future<void> _rejectNote(String docId, Map<String, dynamic> noteData) async {
    // Red nedeni sor
    final reason = await _showRejectReasonDialog();
    if (reason == null) return;

    try {
      // Reddedilen notu arşiv koleksiyonuna taşı
      await _firestore.collection('rejected_notes').add({
        ...noteData,
        'red_tarihi': FieldValue.serverTimestamp(),
        'red_nedeni': reason,
        'onay_durumu': 'reddedildi',
      });

      // Bekleyen notlar koleksiyonundan sil
      await _firestore.collection('pending_notes').doc(docId).delete();

      _showSnackBar('Not reddedildi');
    } catch (e) {
      _showSnackBar('Not reddedilirken hata oluştu: $e', isError: true);
    }
  }

  Future<String?> _showRejectReasonDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Red Nedeni'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Notu neden reddediyorsunuz?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Red nedenini yazın...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCreditsForApprovedNote(String userEmail) async {
    try {
      final docRef = _firestore.collection('user_credits').doc(userEmail);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final currentData = doc.data()!;
          transaction.update(docRef, {
            'totalCredits': (currentData['totalCredits'] ?? 0) + 5, // 5 kredi ver
            'totalShares': (currentData['totalShares'] ?? 0) + 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(docRef, {
            'userEmail': userEmail,
            'totalCredits': 8, // 3 başlangıç + 5 paylaşım kredisi
            'usedCredits': 0,
            'totalShares': 1,
            'totalDownloads': 0,
            'likeCredits': 0,
            'dislikeCredits': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Kredi eklenirken hata: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}