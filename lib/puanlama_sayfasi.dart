import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PuanlamaSayfasi extends StatefulWidget {
  @override
  _PuanlamaSayfasiState createState() => _PuanlamaSayfasiState();
}

class _PuanlamaSayfasiState extends State<PuanlamaSayfasi> {
  Map<String, int> kullaniciPuani = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    puanlariHesapla();
  }

  Future<void> puanlariHesapla() async {
    Map<String, int> tempPuanlar = {};

    String formatTelefon(String numara) {
      String cleaned = numara.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.startsWith('90')) cleaned = cleaned.substring(2);
      if (cleaned.startsWith('0')) cleaned = cleaned.substring(1);
      return cleaned;
    }

    // 1. GeziForm'dan +10 puan
    QuerySnapshot geziformVeri = await _firestore.collection('geziform').get();
    for (var doc in geziformVeri.docs) {
      String telefon = formatTelefon(doc['telefon'].toString());
      tempPuanlar[telefon] = (tempPuanlar[telefon] ?? 0) + 10;
    }

    // 2. KaraListe'den -50 puan (sadece GeziForm'da varsa)
    QuerySnapshot karaListeVeri =
        await _firestore.collection('KaraListe').get();
    for (var doc in karaListeVeri.docs) {
      String karaTelefon = formatTelefon(doc['numara'].toString());
      if (tempPuanlar.containsKey(karaTelefon)) {
        tempPuanlar[karaTelefon] = tempPuanlar[karaTelefon]! - 50;
      }
    }

    // 3. OnayliListe'den +20 puan
    QuerySnapshot onayliListeVeri =
        await _firestore.collection('onayliliste').get();
    for (var doc in onayliListeVeri.docs) {
      String onayliTelefon = formatTelefon(doc['telefon'].toString());
      tempPuanlar[onayliTelefon] = (tempPuanlar[onayliTelefon] ?? 0) + 20;
    }

    // YapayZeka koleksiyonuna verileri kaydet
    await _updateYapayZekaCollection(tempPuanlar);

    setState(() {
      kullaniciPuani = tempPuanlar;
    });
  }

  Future<void> _updateYapayZekaCollection(Map<String, int> puanlar) async {
    WriteBatch batch = _firestore.batch();
    final yapayZekaRef = _firestore.collection('YapayZeka');

    puanlar.forEach((telefon, puan) {
      final docRef = yapayZekaRef.doc(telefon);
      batch.set(docRef, {
        'telefon': telefon,
        'puan': puan,
        'guncellemeTarihi': FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
  }

  Future<void> _updatePuan(String telefon, int degisimMiktari) async {
    final yeniPuan = (kullaniciPuani[telefon] ?? 0) + degisimMiktari;

    // YapayZeka koleksiyonunda güncelle
    await _firestore.collection('YapayZeka').doc(telefon).update({
      'puan': yeniPuan,
      'manuelGuncelleme': true,
      'guncellemeTarihi': FieldValue.serverTimestamp(),
    });

    // Local state'i güncelle
    setState(() {
      kullaniciPuani[telefon] = yeniPuan;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, int>> siraliListe = kullaniciPuani.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: Color(0xFFEAEAEA),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text("Yapay Zeka Algoritma Listesi"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: puanlariHesapla,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: siraliListe.isEmpty
            ? Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              )
            : ListView.builder(
                itemCount: siraliListe.length,
                itemBuilder: (context, index) {
                  String telefon = siraliListe[index].key;
                  int puan = siraliListe[index].value;

                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        "📱 Telefon: $telefon",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      subtitle: Text("Puan: $puan"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, color: Colors.red),
                            onPressed: () => _updatePuan(telefon, -1),
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text("$puan"),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.green),
                            onPressed: () => _updatePuan(telefon, 1),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
