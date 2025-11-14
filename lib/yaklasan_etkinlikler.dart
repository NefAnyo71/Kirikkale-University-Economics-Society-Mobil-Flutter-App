import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EtkinlikJson2 extends StatelessWidget {
  const EtkinlikJson2({super.key});

  void _setAlarmForEvent(
      BuildContext context, DateTime eventDate, String eventTitle) {
    final alarmOptions = [
      {'sure': '1 saat', 'time': eventDate.subtract(const Duration(hours: 1))},
      {
        'sure': '1.5 saat',
        'time': eventDate.subtract(const Duration(minutes: 90))
      },
      {'sure': '2 saat', 'time': eventDate.subtract(const Duration(hours: 2))},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alarm Seçeneği ⏰',
              style: TextStyle(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('"$eventTitle" etkinliği için:',
                  style: const TextStyle(color: Colors.black)),
              const SizedBox(height: 16),
              ...alarmOptions.map((option) {
                final time = option['time'] as DateTime;
                return ListTile(
                  leading: const Icon(Icons.alarm, color: Colors.orange),
                  title: Text(
                    '${option['sure']} önce',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(time),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _launchAlarmApp(context, time, eventTitle);
                  },
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('İptal', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchAlarmApp(
      BuildContext context, DateTime alarmTime, String eventTitle) async {
    try {
      final hour = alarmTime.hour;
      final minute = alarmTime.minute;

      // ÖNCELİKLE SAMSUNG İÇİN ÖZEL INTENT'LER
      final samsungIntents = [
        // Samsung için en güncel intent
        'intent://alarm/insert?hour=$hour&minute=$minute&message=${Uri.encodeComponent(eventTitle)}#Intent;package=com.sec.android.app.clockpackage;scheme=clock;end',

        // Samsung alternatif 1
        'intent://com.sec.android.app.clockpackage/alarm/insert?hour=$hour&minute=$minute&message=${Uri.encodeComponent(eventTitle)}#Intent;package=com.sec.android.app.clockpackage;scheme=clock;end',

        // Samsung alternatif 2
        'intent://clock/alarm/insert?hour=$hour&minute=$minute&message=${Uri.encodeComponent(eventTitle)}#Intent;package=com.sec.android.app.clockpackage;scheme=clock;end',

        // Samsung eski versiyon
        'intent://alarm/create?hour=$hour&minute=$minute&message=${Uri.encodeComponent(eventTitle)}#Intent;package=com.sec.android.app.clockpackage;scheme=clock;end',
      ];

      // DİĞER MARKALAR
      final otherIntents = [
        // Android Standart
        'content://com.android.deskclock/alarm/create?message=${Uri.encodeComponent(eventTitle)}&hour=$hour&minutes=$minute',

        // Xiaomi
        'intent://com.android.deskclock/alarm/create?message=${Uri.encodeComponent(eventTitle)}&hour=$hour&minute=$minute#Intent;package=com.android.deskclock;scheme=clock;end',

        // Diğer markalar
        'intent://alarm/create?message=${Uri.encodeComponent(eventTitle)}&hour=$hour&minute=$minute#Intent;scheme=clock;end',
      ];

      bool launched = false;

      // ÖNCE SAMSUNG INTENT'LERİNİ DENE
      print('🔍 Samsung intentleri deneniyor...');
      for (final intent in samsungIntents) {
        try {
          if (await canLaunchUrl(Uri.parse(intent))) {
            print('✅ Samsung intent çalıştı: $intent');
            await launchUrl(Uri.parse(intent));
            launched = true;
            break;
          }
        } catch (e) {
          print('❌ Samsung intent hatası: $e');
          continue;
        }
      }

      // Samsung çalışmazsa DİĞER MARKALARI DENE
      if (!launched) {
        print('🔍 Diğer marka intentleri deneniyor...');
        for (final intent in otherIntents) {
          try {
            if (await canLaunchUrl(Uri.parse(intent))) {
              print('✅ Diğer marka intent çalıştı: $intent');
              await launchUrl(Uri.parse(intent));
              launched = true;
              break;
            }
          } catch (e) {
            print('❌ Diğer marka intent hatası: $e');
            continue;
          }
        }
      }

      // Hiçbiri çalışmazsa SAAT UYGULAMASINI AÇ
      if (!launched) {
        print('🔍 Saat uygulaması açılıyor...');
        await _openClockAppDirectly();
      }
    } catch (e) {
      print('❌ Alarm uygulaması açılamadı: $e');
      _showError(context);
    }
  }

  // Direkt saat uygulamasını aç
  Future<void> _openClockAppDirectly() async {
    try {
      // Samsung saat uygulamasını doğrudan aç
      const samsungClock = 'com.sec.android.app.clockpackage';

      if (await canLaunchUrl(Uri.parse('package:$samsungClock'))) {
        await launchUrl(Uri.parse('package:$samsungClock'));
      } else {
        // Android standart saat
        const androidClock = 'com.android.deskclock';
        if (await canLaunchUrl(Uri.parse('package:$androidClock'))) {
          await launchUrl(Uri.parse('package:$androidClock'));
        } else {
          // Son çare
          await launchUrl(Uri.parse(
              'https://play.google.com/store/search?q=alarm%20clock&c=apps'));
        }
      }
    } catch (e) {
      print('❌ Saat uygulaması açılamadı: $e');
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Alarm uygulaması açılamadı. Lütfen manuel olarak alarm kurun.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade700,
        elevation: 4.0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: Navigator.of(context).pop,
        ),
        title: Row(
          children: [
            // Asset image yerine placeholder - asset dosyanız varsa kullanın
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event, color: Colors.deepPurple),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Yaklaşan Etkinlikler',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Gelecek Etkinlikler',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          stream: FirebaseFirestore.instance
              .collection('yaklasan_etkinlikler')
              .where('date', isGreaterThanOrEqualTo: Timestamp.now())
              .orderBy('date', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.deepPurple.withOpacity(0.8),
                  ),
                  strokeWidth: 3,
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 60,
                      color: Colors.deepPurple.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Yaklaşan etkinlik bulunamadı",
                      style: TextStyle(
                        color: Colors.deepPurple.withOpacity(0.9),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Yakında yeni etkinlikler eklenecek",
                      style: TextStyle(
                        color: Colors.deepPurple.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            final etkinlikler = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: etkinlikler.length,
              itemBuilder: (context, index) {
                var etkinlik = etkinlikler[index];
                var title = etkinlik['title'] ?? 'Başlıksız';
                var details = etkinlik['details'] ?? 'Detay yok';
                var date = etkinlik['date'] is Timestamp
                    ? (etkinlik['date'] as Timestamp).toDate()
                    : DateTime.now();
                var url = etkinlik['url'] ?? '';

                final remainingTime = date.difference(DateTime.now());
                final remainingDays = remainingTime.inDays;
                final remainingHours = remainingTime.inHours.remainder(24);
                final remainingMinutes = remainingTime.inMinutes.remainder(60);

                final formattedDate =
                    DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(date);

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Card(
                    elevation: 4,
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                            color: Colors.deepPurple.shade100, width: 1.0),
                      ),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (url.isNotEmpty)
                            SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  Image.network(
                                    url,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error,
                                            color: Colors.grey),
                                      );
                                    },
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.5),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blueAccent.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "YAKLAŞAN ETKİNLİK",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple.shade900,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.deepPurple.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.deepPurple.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  details,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Kalan Süre: $remainingDays gün, $remainingHours saat, $remainingMinutes dakika',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.alarm_add,
                                        color: Colors.white),
                                    label: const Text('Alarm Kur',
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.deepPurple.shade600,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      _setAlarmForEvent(context, date, title);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
