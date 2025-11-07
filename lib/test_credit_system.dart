import 'package:flutter/material.dart';
import 'services/credit_service.dart';
import 'widgets/credit_display_widget.dart';

class TestCreditSystem extends StatefulWidget {
  const TestCreditSystem({Key? key}) : super(key: key);

  @override
  _TestCreditSystemState createState() => _TestCreditSystemState();
}

class _TestCreditSystemState extends State<TestCreditSystem> {
  final String testEmail = 'test@example.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kredi Sistemi Test'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Kredi gösterge widget'ı
            CreditDisplayWidget(
              userEmail: testEmail,
              showDetails: true,
            ),
            
            const SizedBox(height: 20),
            
            // Test butonları
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await CreditService.addCreditsForAd(testEmail);
                    setState(() {});
                  },
                  child: const Text('Reklam İzle'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await CreditService.addCreditsForLike(testEmail);
                    setState(() {});
                  },
                  child: const Text('Beğeni Al'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await CreditService.removeCreditsForDislike(testEmail);
                    setState(() {});
                  },
                  child: const Text('Beğenmeme Al'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await CreditService.addCreditsForShare(testEmail);
                    setState(() {});
                  },
                  child: const Text('Not Paylaş'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final canDownload = await CreditService.canUserDownload(testEmail);
                    if (canDownload) {
                      await CreditService.useCreditsForDownload(testEmail);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('İndirme başarılı!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yetersiz kredi!')),
                      );
                    }
                    setState(() {});
                  },
                  child: const Text('Not İndir'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Kredi bilgileri
            FutureBuilder<Map<String, dynamic>>(
              future: CreditService.getUserCredits(testEmail),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                
                final credits = snapshot.data!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Toplam Kredi: ${credits['totalCredits']}'),
                        Text('Kullanılan Kredi: ${credits['usedCredits']}'),
                        Text('Mevcut Kredi: ${credits['availableCredits']}'),
                        Text('İzlenen Reklam: ${credits['adsWatched']}'),
                        Text('Alınan Beğeni: ${credits['likesReceived']}'),
                        Text('Alınan Beğenmeme: ${credits['dislikesReceived']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}