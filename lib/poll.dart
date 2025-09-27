import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyPage extends StatefulWidget {
  @override
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKey = GlobalKey<FormState>();

  // Anket soruları ve cevaplarını saklamak için
  String? _appRating;
  String? _communityFeedback;
  String? _appImprovements;
  String? _eventFeedback;

  Future<void> _submitSurvey() async {
    try {
      await FirebaseFirestore.instance.collection('surveys').add({
        'appRating': _appRating,
        'communityFeedback': _communityFeedback,
        'appImprovements': _appImprovements,
        'eventFeedback': _eventFeedback,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anketiniz kaydedildi. Teşekkür ederiz!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anket kaydedilirken bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Anket Sayfası',
          style: TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 6.0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A90E2),
              Color(0xFFFFA500),
              Color(0xFFFFD700),
              Color(0xFFFF0000),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                color: Colors.deepPurple.shade50,
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anketler anonimdir. Yaptığınız anketlerin sonuçları sadece yöneticiler ile paylaşılmaktadır. Kırıkkale Üniversitesi Ekonomi Topluluğu',
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Mobil Uygulama Hakkında',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Uygulamayı nasıl değerlendiriyorsunuz?',
                        style: TextStyle(color: Colors.black),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'Çok İyi',
                                  groupValue: _appRating,
                                  onChanged: (value) {
                                    setState(() {
                                      _appRating = value;
                                    });
                                  },
                                ),
                                const Text('Çok İyi',
                                    style: TextStyle(color: Colors.black)),
                              ],
                            ),
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'İyi',
                                  groupValue: _appRating,
                                  onChanged: (value) {
                                    setState(() {
                                      _appRating = value;
                                    });
                                  },
                                ),
                                const Text('İyi',
                                    style: TextStyle(color: Colors.black)),
                              ],
                            ),
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'Orta',
                                  groupValue: _appRating,
                                  onChanged: (value) {
                                    setState(() {
                                      _appRating = value;
                                    });
                                  },
                                ),
                                const Text('Orta',
                                    style: TextStyle(color: Colors.black)),
                              ],
                            ),
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'Kötü',
                                  groupValue: _appRating,
                                  onChanged: (value) {
                                    setState(() {
                                      _appRating = value;
                                    });
                                  },
                                ),
                                const Text('Kötü',
                                    style: TextStyle(color: Colors.black)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Topluluk Hakkında',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Topluluk hakkında geri bildiriminiz nedir?',
                        style: TextStyle(color: Colors.black),
                      ),
                      TextFormField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          hintText: 'Görüşlerinizi buraya yazınız...',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _communityFeedback = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Uygulamanın geliştirilmesi için önerileriniz nelerdir?',
                        style: TextStyle(color: Colors.black),
                      ),
                      TextFormField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          hintText: 'Önerilerinizi buraya yazınız...',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _appImprovements = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Son katıldığınız etkinlik hakkında geri bildiriminiz nedir?',
                        style: TextStyle(color: Colors.black),
                      ),
                      TextFormField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          hintText: 'Geri bildiriminizi buraya yazınız...',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _eventFeedback = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            if (_formKey.currentState?.validate() == true) {
                              _submitSurvey();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFF18FFFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(0, 0, 0, 0.3),
                                  blurRadius: 8.0,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 30.0),
                            margin: const EdgeInsets.symmetric(vertical: 10.0),
                            child: const Text(
                              'Anketi Kaydet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
