import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class KapiGorevlisiKontrolPage extends StatefulWidget {
  const KapiGorevlisiKontrolPage({Key? key}) : super(key: key);

  @override
  _KapiGorevlisiKontrolPageState createState() =>
      _KapiGorevlisiKontrolPageState();
}

class _KapiGorevlisiKontrolPageState extends State<KapiGorevlisiKontrolPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _allApplications = [];
  List<QueryDocumentSnapshot> _filteredApplications = [];
  bool _isLoading = true;

  // Renkler ve Stiller
  final Color _primaryColor = Colors.green.shade700;
  final Color _secondaryColor = Colors.blue.shade700;
  final Color _backgroundColor = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      final snapshot = await _firestore
          .collection('tanismaEtkinligiBasvurulari')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _allApplications = snapshot.docs;
        _filteredApplications = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veri yüklenirken hata: $e')),
      );
    }
  }

  void _filterApplications(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredApplications = _allApplications;
      } else {
        _filteredApplications = _allApplications.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          final phone = data['phone']?.toString() ?? '';
          final department = data['department']?.toString().toLowerCase() ?? '';

          return name.contains(query.toLowerCase()) ||
              phone.contains(query) ||
              department.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Widget _buildStatsHeader() {
    final totalCount = _allApplications.length;
    final attendedCount = _allApplications.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['katilimDurumu'] == 'Geldi';
    }).length;

    final paidButNotAttendedCount = _filteredApplications.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['odemeDurumu'] == 'odendi' &&
          (data['katilimDurumu'] == null || data['katilimDurumu'] == 'gelmedi');
    }).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              'Toplam', totalCount, Icons.people_outline, _primaryColor),
          _buildStatItem('Geldi', attendedCount, Icons.check_circle_outline,
              _primaryColor),
          _buildStatItem('Beklenen', paidButNotAttendedCount,
              Icons.hourglass_top_outlined, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: TextField(
          controller: _searchController,
          onChanged: _filterApplications,
          decoration: InputDecoration(
            hintText: 'Ad, telefon veya bölüm ara...',
            prefixIcon: Icon(Icons.search, color: _primaryColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _filterApplications('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> data, String docId) {
    final name = data['name']?.toString() ?? 'İsim belirtilmemiş';
    final department = data['department']?.toString() ?? 'Bölüm belirtilmemiş';
    final phone = data['phone']?.toString() ?? 'Telefon belirtilmemiş';
    final odemeDurumu = data['odemeDurumu'] ?? 'odenmedi';
    final katilimDurumu = data['katilimDurumu'] ?? 'gelmedi';

    final katilimZamani = data['katilimZamani'] as Timestamp?;
    final icerdeZamani = data['icerdeZamani'] as Timestamp?;

    final katilimZamaniStr = katilimZamani != null
        ? DateFormat('HH:mm').format(katilimZamani.toDate())
        : null;
    final icerdeZamaniStr = icerdeZamani != null
        ? DateFormat('HH:mm').format(icerdeZamani.toDate())
        : null;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (katilimDurumu == 'Geldi') {
      statusColor = _primaryColor;
      statusIcon = Icons.check_circle;
      statusText = 'Geldi';
    } else if (odemeDurumu == 'odendi') {
      statusColor = Colors.orange.shade700;
      statusIcon = Icons.how_to_reg;
      statusText = 'Ödendi';
    } else {
      statusColor = Colors.red.shade700;
      statusIcon = Icons.person_off;
      statusText = 'Ödenmedi';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            softWrap: true, // Metnin kaydırılmasını sağlar
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(phone,
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 14)),
                    Text(department,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 8),
                    if (katilimZamaniStr != null || icerdeZamaniStr != null)
                      Row(
                        children: [
                          if (katilimZamaniStr != null) ...[
                            Icon(Icons.login, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Giriş: $katilimZamaniStr',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ],
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          const Text(
            'Sonuç Bulunamadı',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Arama kriterlerinizi değiştirip tekrar deneyin.',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) => Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 20, height: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Container(width: 60, height: 14, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Container(width: 200, height: 18, color: Colors.white),
                const SizedBox(height: 4),
                Container(width: 100, height: 14, color: Colors.white),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(width: 80, height: 30, color: Colors.white),
                    Container(width: 80, height: 30, color: Colors.white),
                    Container(width: 80, height: 30, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Kapı Görevlisi Kontrol',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredApplications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _filteredApplications.length,
                        itemBuilder: (context, index) {
                          final doc = _filteredApplications[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildApplicationCard(data, doc.id);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
