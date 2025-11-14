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
        backgroundColor: Colors.deepPurple.shade700,
        elevation: 4.0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset('assets/images/ekoslogo.png', height: 40),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Anket Sistemi',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Görüşlerinizi Paylaşın',
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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
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
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
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
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() == true) {
                                _submitSurvey();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple.shade600,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 32.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Anketi Kaydet',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
