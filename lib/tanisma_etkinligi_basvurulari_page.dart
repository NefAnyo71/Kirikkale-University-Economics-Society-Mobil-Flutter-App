import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Tarih formatlamak için eklendi
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart'; // Panoya kopyalama için eklendi

class TanismaEtkinligiBasvurulariPage extends StatefulWidget {
  const TanismaEtkinligiBasvurulariPage({Key? key}) : super(key: key);

  @override
  _TanismaEtkinligiBasvurulariPageState createState() =>
      _TanismaEtkinligiBasvurulariPageState();
}

class _TanismaEtkinligiBasvurulariPageState
    extends State<TanismaEtkinligiBasvurulariPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Değişiklik: 'timestamp' alanına göre en yeniden eskiye doğru sırala
      stream: _firestore
          .collection('tanismaEtkinligiBasvurulari')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        int totalApplications = 0;
        int paidApplications = 0;
        int unpaidApplications = 0;
        Widget bodyContent;

        final bool hasData = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        if (snapshot.connectionState == ConnectionState.waiting) {
          bodyContent = _buildShimmerLoading();
        } else if (snapshot.hasError) {
          bodyContent =
              Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        } else if (!hasData) {
          bodyContent = _buildEmptyState();
        } else {
          final applications = snapshot.data!.docs;
          totalApplications = applications.length;
          paidApplications = applications.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data != null && data['odemeDurumu'] == 'odendi';
          }).length;
          unpaidApplications = totalApplications - paidApplications;

          bodyContent = ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final applicationDoc = applications[index];
              final application = applicationDoc.data() as Map<String, dynamic>;
              final name =
                  application['name']?.toString() ?? 'İsim belirtilmemiş';
              final department = application['department']?.toString() ??
                  'Bölüm belirtilmemiş';
              final phone =
                  application['phone']?.toString() ?? 'Telefon belirtilmemiş';
              final odemeDurumu = application['odemeDurumu'] ?? 'odenmedi';

              // Değişiklik: Timestamp'i al ve formatla
              final Timestamp? timestamp =
                  application['timestamp'] as Timestamp?;
              final String formattedDate = timestamp != null
                  ? DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR')
                      .format(timestamp.toDate())
                  : 'Tarih yok';

              return Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Icon(Icons.person_outline,
                                size: 32, color: Colors.deepPurple.shade700),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF333333)),
                                ),
                                const SizedBox(height: 4),
                                Text(phone,
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      _buildInfoRow(Icons.school_outlined, department),
                      const SizedBox(height: 12),
                      // Değişiklik: Tarih bilgisi satırı eklendi
                      _buildInfoRow(
                          Icons.calendar_today_outlined, formattedDate),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildInfoRow(
                            Icons.payment,
                            odemeDurumu == 'odendi' ? 'Ödendi' : 'Ödenmedi',
                            isPayment: true,
                            status: odemeDurumu,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tanışma Etkinliği Başvuruları',
                style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.deepPurple.shade700,
            toolbarHeight: 70, // AppBar yüksekliği artırıldı
            foregroundColor: Colors.white,
            elevation: 4,
            // Geri butonu otomatik olarak eklenecek (leading kaldırıldı)
            actions: [
              // Değişiklik: Kopyalama butonu actions listesine taşındı
              if (hasData) ...[
                IconButton(
                  icon: const Icon(Icons.copy_all_outlined),
                  tooltip: 'Tüm Telefon Numaralarını Kopyala',
                  onPressed: () {
                    final applications = snapshot.data!.docs;
                    final phoneNumbers = applications
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>?;
                          return data?['phone']?.toString() ?? '';
                        })
                        .where((phone) => phone.isNotEmpty)
                        .join('\n');

                    Clipboard.setData(ClipboardData(text: phoneNumbers));

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Tüm telefon numaraları panoya kopyalandı!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Toplam: $totalApplications',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text('Ödendi: $paidApplications',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.greenAccent)),
                            Text('Ödenmedi: $unpaidApplications',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.redAccent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade100, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: bodyContent,
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text,
      {bool isPayment = false, String status = ''}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        if (!isPayment)
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'odendi'
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: TextStyle(
                  color:
                      status == 'odendi' ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 20),
          const Text(
            'Henüz Başvuru Yok',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni başvurular burada görünecektir.',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 6,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                        radius: 28, backgroundColor: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Container(
                              width: 150, height: 16, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(
                              width: 100, height: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                    width: double.infinity, height: 14, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
