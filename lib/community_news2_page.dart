import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunityNews2Page extends StatelessWidget {
  const CommunityNews2Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Topluluk Haberleri'),
          backgroundColor: Colors.teal),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueAccent.withOpacity(0.7),
              Colors.purple.withOpacity(0.7)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('toplulukhaberleri2')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Haber bulunamadı.'));
            }

            var newsList = snapshot.data!.docs;
            return ListView.builder(
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                var news = newsList[index];
                var date = (news['date'] as Timestamp).toDate();
                var title = news['title'];
                var details = news['details'];
                var url = news['url'];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal)),
                        SizedBox(height: 8),
                        Text(
                            'Tarih: ${date.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600])),
                        SizedBox(height: 8),
                        Text(details,
                            style:
                                TextStyle(fontSize: 16, color: Colors.black87)),
                        if (url.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(url,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover),
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
    );
  }
}
