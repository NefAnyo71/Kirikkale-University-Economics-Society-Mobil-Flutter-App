import 'package:flutter/material.dart';

class MemberProfilesAccountPage extends StatelessWidget {
  const MemberProfilesAccountPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Üye Profilleri - Hesap Bilgileri'),
        backgroundColor: Colors.blueAccent,
      ),
      body: const Center(
        child: Text(
          'Üye bilgileri şu anda kullanılmamaktadır.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
