import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Mail için

class SponsorsPage extends StatelessWidget {
  const SponsorsPage({super.key});

  // Mail göndermek için fonksiyon
  void _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'arifkerem71@gmail.com',
      query:
          'subject=Sponsorluk Anlaşması&body=Merhaba, sponsorluk hakkında bilgi almak istiyorum.',
    );

    if (!await launchUrl(emailUri)) {
      throw 'Mail uygulaması açılamadı.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sponsorlar',
          style: TextStyle(color: Colors.white), // Başlık yazısı beyaz
        ),
        backgroundColor: Colors.black, // Başlık çubuğu siyah
        iconTheme: IconThemeData(color: Colors.white), // Geri butonu beyaz
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.grey[900]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handshake,
                  size: 80, color: Colors.white), // Sponsorluk ikon
              SizedBox(height: 20),
              Text(
                'Şu anda bir sponsorumuz bulunmamaktadır.\n'
                'Sponsorluk anlaşmaları için bizimle iletişime geçin!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _sendEmail, // Mail fonksiyonunu çağırıyor
                icon: Icon(Icons.email, color: Colors.black),
                label: Text(
                  'Sponsorluk için iletişime geç',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, // Dikkat çeken renk
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
