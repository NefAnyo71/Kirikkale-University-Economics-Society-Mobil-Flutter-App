import 'package:flutter/material.dart';
import 'firebase_service.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  void _submitFeedback() async {
    final feedback = _feedbackController.text;
    final email = _emailController.text;

    if (feedback.isNotEmpty) {
      try {
        await _firebaseService
            .insertFeedback({'feedback': feedback, 'email': email.isNotEmpty ? email : 'Anonim'});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Geri bildiriminiz için teşekkür ederiz!')),
        );
        _feedbackController.clear();
        _emailController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Geri bildirim gönderilirken bir hata oluştu: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geri bildirim alanını doldurun.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geri Bildirim'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Geri Bildirim',
                      style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Bu form tamamen anonimdir. Yöneticiler sadece gönderdiğiniz mesajları görebilir, kimin gönderdiğini bilemezler. Ancak, yasal bir suç içeren içerik tespit edilmesi durumunda yasal takip başlatma hakkımızı saklı tutarız.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: _feedbackController,
                      decoration: const InputDecoration(
                        labelText: 'Geri bildiriminiz*',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta adresiniz (isteğe bağlı)',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: const Text('Gönder'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}