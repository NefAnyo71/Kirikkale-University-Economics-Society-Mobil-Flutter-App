import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// SiteSessionService sınıfı
class SiteSessionService {
  final FirebaseFirestore _db;

  SiteSessionService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchSiteSessions() async {
    try {
      final querySnapshot = await _db.collection('siteSessions').get();
      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['timestamp'] = _formatTimestamp(data['timestamp']);
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Veri çekme hatası: $e');
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      if (timestamp is Timestamp) {
        return timestamp.toDate().toLocal().toString();
      } else if (timestamp is DateTime) {
        return timestamp.toLocal().toString();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp).toLocal().toString();
      } else {
        return timestamp.toString();
      }
    } catch (e) {
      return 'N/A';
    }
  }
}

// Firestore’dan veri çekip listeleyen widget
class SiteSessionsWidget extends StatefulWidget {
  const SiteSessionsWidget({Key? key}) : super(key: key);

  @override
  _SiteSessionsWidgetState createState() => _SiteSessionsWidgetState();
}

class _SiteSessionsWidgetState extends State<SiteSessionsWidget> {
  late final SiteSessionService _service;
  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _service = SiteSessionService();
    _sessionsFuture = _service.fetchSiteSessions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return const Center(child: Text('Veri bulunamadı.'));
        }

        // Benzersiz IP adreslerini al
        final uniqueIps = <String>{};
        for (var session in sessions) {
          final ip = session['ipAddress'] ?? '';
          if (ip.isNotEmpty) uniqueIps.add(ip);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Farklı IP Sayısı: ${uniqueIps.length}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: ListTile(
                      title: Text('Session ID: ${session['sessionId'] ?? 'N/A'}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Page: ${session['page'] ?? 'N/A'}'),
                          Text('IP: ${session['ipAddress'] ?? 'N/A'}'),
                          Text('Consent: ${session['consent'] == true ? '✅' : '❌'}'),
                          Text('Exited: ${session['exited'] == true ? '✅' : '❌'}'),
                          Text('Timestamp: ${session['timestamp'] ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// Flutter uygulaması için ana widget
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Firestore Site Sessions')),
      body: const SiteSessionsWidget(),
    ),
  ));
}
