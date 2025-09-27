import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaPage extends StatelessWidget {
  const SocialMediaPage({super.key});

  // URL açma fonksiyonu
  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sosyal Medya'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A90E2), // Mavi
              Color(0xFFFFA500), // Turuncu
              Color(0xFFFFD700), // Altın Sarısı
              Color(0xFFFF0000), // Kırmızı
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Instagram Kartı
              Card(
                color: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _launchURL('https://www.instagram.com/kkuekonomi/');
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/instagram.png',
                            height: 80.0,
                            width: 80.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KKÜ Ekonomi Topluluğu',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            const Text(
                              'Kırıkkale Üniversitesi',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            const Text(
                              'Ekonomi Topluluğu Resmi Instagram Hesabıdır.',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                _launchURL(
                                    'https://www.instagram.com/kkuekonomi/');
                              },
                              child: const Text(
                                'Instagram hesabını ziyaret et',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Twitter Kartı
              Card(
                color: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _launchURL('https://x.com/kkuekonomi1');
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/twitterlogo.png',
                            height: 80.0,
                            width: 80.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KKÜ Ekonomi Topluluğu',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            const Text(
                              'Kırıkkale Üniversitesi',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            const Text(
                              'Ekonomi Topluluğu Resmi Twitter (X) Hesabıdır.',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                _launchURL('https://x.com/kkuekonomi1');
                              },
                              child: const Text(
                                'Twitter hesabını ziyaret et',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
