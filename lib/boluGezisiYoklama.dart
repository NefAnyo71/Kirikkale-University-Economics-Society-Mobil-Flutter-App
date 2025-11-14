import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BoluGezisiYoklama extends StatefulWidget {
  const BoluGezisiYoklama({super.key});

  @override
  State<BoluGezisiYoklama> createState() => _BoluGezisiYoklamaState();
}

class _BoluGezisiYoklamaState extends State<BoluGezisiYoklama> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _yoklamaBasladi = false;
  int _simdikiIndex = 0;
  List<QueryDocumentSnapshot> _katilimcilar = [];
  final Map<String, bool> _yoklamaDurumu = {};

  Future<void> _yoklamaBaslat() async {
    final snapshot = await _firestore
        .collection('gezi3')
        .where('odemeDurumu', isEqualTo: true)
        .get();

    // İsimleri alfabetik sırala
    final docs = snapshot.docs;
    docs.sort((a, b) {
      final nameA = a.data()['name'] ?? '';
      final nameB = b.data()['name'] ?? '';
      return nameA.toString().compareTo(nameB.toString());
    });

    setState(() {
      _katilimcilar = docs;
      _yoklamaBasladi = true;
      _simdikiIndex = 0;
      _yoklamaDurumu.clear();
    });
  }

  void _yoklamaYap(bool burada) {
    final katilimci = _katilimcilar[_simdikiIndex];
    setState(() {
      _yoklamaDurumu[katilimci.id] = burada;
      if (_simdikiIndex < _katilimcilar.length - 1) {
        _simdikiIndex++;
      } else {
        _sonucGoster();
      }
    });
  }

  void _sonucGoster() {
    final buradaOlanlar = _yoklamaDurumu.values.where((durum) => durum).length;
    final toplam = _katilimcilar.length;
    final eksikler = toplam - buradaOlanlar;

    String mesaj = eksikler == 0
        ? "Herkes burada! ✅\nToplam: $toplam kişi"
        : "$eksikler kişi eksik ❌\nBurada: $buradaOlanlar / $toplam";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yoklama Sonucu'),
        content: Text(mesaj),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _yoklamaBasladi = false;
                _simdikiIndex = 0;
                _yoklamaDurumu.clear();
              });
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bolu Gezisi Yoklama'),
        backgroundColor: Colors.deepPurple.shade700,
        centerTitle: true,
      ),
      body: _yoklamaBasladi ? _yoklamaEkrani() : _baslatEkrani(),
    );
  }

  Widget _baslatEkrani() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('gezi3')
          .where('odemeDurumu', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final kisiSayisi = snapshot.data!.docs.length;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ödeme Yapan Katılımcılar',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                '$kisiSayisi kişi',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: kisiSayisi > 0 ? _yoklamaBaslat : null,
                child: const Text('Yoklama Başlat'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _yoklamaEkrani() {
    if (_katilimcilar.isEmpty) return const SizedBox();

    final katilimci = _katilimcilar[_simdikiIndex];
    final data = katilimci.data() as Map<String, dynamic>;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_simdikiIndex + 1} / ${_katilimcilar.length}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 40),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Icon(Icons.person, size: 60),
                  const SizedBox(height: 20),
                  Text(
                    data['name'] ?? 'İsimsiz',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data['department'] ?? 'Bölüm yok',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _yoklamaYap(false),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Burada Değil'),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _yoklamaYap(true),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Burada'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
