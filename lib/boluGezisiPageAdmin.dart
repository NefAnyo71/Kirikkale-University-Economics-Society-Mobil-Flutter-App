import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BoluGezisiPage extends StatefulWidget {
  const BoluGezisiPage({super.key});

  @override
  State<BoluGezisiPage> createState() => _BoluGezisiPageState();
}

class _BoluGezisiPageState extends State<BoluGezisiPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updatePaymentStatus(String documentId, bool newStatus) async {
    try {
      await _firestore
          .collection('gezi3')
          .doc(documentId)
          .update({'odemeDurumu': newStatus});
    } catch (e) {
      print("Ödeme durumu güncellenirken hata oluştu: $e");
    }
  }

  Future<void> _deleteParticipant(String documentId) async {
    try {
      await _firestore.collection('gezi3').doc(documentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Katılımcı başarıyla silindi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Ödeme durumu güncellenirken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bolu Gezisi Başvuruları',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4.0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('gezi3').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Hata oluştu: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('Kayıtlı katılımcı bulunamadı.'),
              );
            }

            final participants = snapshot.data!.docs;
            final paidCount = participants
                .where((doc) =>
                    (doc.data() as Map<String, dynamic>)
                        .containsKey('odemeDurumu') &&
                    (doc.data() as Map<String, dynamic>)['odemeDurumu'] == true)
                .length;

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade400,
                        Colors.deepPurple.shade600
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${participants.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Toplam Katılımcı',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white30,
                      ),
                      Column(
                        children: [
                          Text(
                            '$paidCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Ödeme Yapanlar',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      final data = participant.data() as Map<String, dynamic>;
                      final isPaid = data.containsKey('odemeDurumu') &&
                          data['odemeDurumu'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        shadowColor: Colors.deepPurple.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0)),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey.shade100],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                                color: Colors.deepPurple.shade100, width: 1.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isPaid
                                          ? Colors.green.shade400
                                          : Colors.red.shade400,
                                      child: Icon(
                                        isPaid ? Icons.check : Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['name'] ?? 'İsimsiz',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.deepPurple.shade900,
                                            ),
                                          ),
                                          Text(
                                            data['department'] ??
                                                'Bölüm belirtilmemiş',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isPaid
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isPaid
                                              ? Colors.green.shade200
                                              : Colors.red.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        isPaid ? 'Ödendi' : 'Ödenmedi',
                                        style: TextStyle(
                                          color: isPaid
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.deepPurple.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildInfoRow(Icons.phone, 'Telefon',
                                          data['phone'] ?? 'Belirtilmemiş'),
                                      const SizedBox(height: 4),
                                      _buildInfoRow(
                                          Icons.school,
                                          'Öğrenci No',
                                          data['studentNumber'] ??
                                              'Belirtilmemiş'),
                                      const SizedBox(height: 4),
                                      _buildInfoRow(Icons.credit_card, 'TC No',
                                          data['tcNumber'] ?? 'Belirtilmemiş'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _showPaymentDialog(
                                            context,
                                            participant.id,
                                            data['name'] ?? 'İsimsiz',
                                            isPaid,
                                          );
                                        },
                                        icon: const Icon(Icons.edit,
                                            color: Colors.white, size: 18),
                                        label: const Text('Değiştir',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.deepPurple.shade400,
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _showDeleteConfirmationDialog(
                                            context,
                                            participant.id,
                                            data['name'] ?? 'İsimsiz');
                                      },
                                      icon: const Icon(Icons.delete_forever,
                                          color: Colors.white, size: 18),
                                      label: const Text('Sil',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade400,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.deepPurple.shade300),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple.shade700,
              fontSize: 13,
            ),
          ),
        ),
        Flexible(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: Colors.deepPurple.shade900),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String documentId, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Silme Onayı'),
            ],
          ),
          content: Text(
              '"$name" adlı katılımcıyı kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteParticipant(documentId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, String documentId, String name,
      bool currentStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                currentStatus ? Icons.money_off : Icons.payment,
                color: currentStatus ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              const Text('Ödeme Durumunu\n Güncelle'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Katılımcı: $name'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: currentStatus ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        currentStatus ? Colors.red.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      currentStatus ? Icons.cancel : Icons.check_circle,
                      color: currentStatus ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Şu anki durum: ${currentStatus ? "Ödendi" : "Ödenmedi"}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color:
                            currentStatus ? Colors.red[700] : Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                _updatePaymentStatus(documentId, !currentStatus);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('$name ödeme durumu güncellendi'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: currentStatus ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                currentStatus
                    ? 'Ödenmedi Olarak İşaretle'
                    : 'Ödendi Olarak İşaretle',
              ),
            ),
          ],
        );
      },
    );
  }
}