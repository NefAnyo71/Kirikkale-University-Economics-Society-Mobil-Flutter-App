import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminLogsViewerPage extends StatelessWidget {
  const AdminLogsViewerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yönetici Aktivite Logları',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adminlogs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz log kaydı bulunmuyor.'));
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index].data() as Map<String, dynamic>;
              return _buildLogCard(log);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final type = log['type'] ?? 'unknown';
    final timestamp = log['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('dd.MM.yyyy HH:mm:ss', 'tr_TR').format(timestamp.toDate())
        : 'Tarih yok';

    Widget title;
    Widget subtitle;
    IconData iconData;
    Color iconColor;

    if (type == 'login_attempt') {
      final bool isSuccessful = log['is_successful'] ?? false;
      iconData = isSuccessful ? Icons.login : Icons.warning_amber_rounded;
      iconColor = isSuccessful ? Colors.green.shade600 : Colors.orange.shade700;
      title = Text(
        'Giriş Denemesi: ${isSuccessful ? "Başarılı" : "Başarısız"}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deneyen Admin: ${log['admin_username_attempt'] ?? 'N/A'}'),
          const SizedBox(height: 4),
          Text(
              'Uygulama Kullanıcısı: ${log['app_user_name'] ?? 'N/A'} (${log['app_user_email'] ?? 'N/A'})'),
        ],
      );
    } else if (type == 'navigation') {
      iconData = Icons.navigation_rounded;
      iconColor = Colors.blue.shade600;
      title = Text(
        'Sayfa Gezinmesi: ${log['button_label'] ?? 'Bilinmeyen Buton'}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Giriş Yapan Admin: ${log['admin_username'] ?? 'N/A'}'),
          const SizedBox(height: 4),
          Text(
              'Uygulama Kullanıcısı: ${log['app_user_name'] ?? 'N/A'} (${log['app_user_email'] ?? 'N/A'})'),
        ],
      );
    } else {
      iconData = Icons.help_outline;
      iconColor = Colors.grey;
      title = const Text('Bilinmeyen Log Tipi');
      subtitle = Text(log.toString());
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(iconData, color: iconColor),
        ),
        title: title,
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: subtitle,
        ),
        trailing: Text(
          formattedDate,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}
