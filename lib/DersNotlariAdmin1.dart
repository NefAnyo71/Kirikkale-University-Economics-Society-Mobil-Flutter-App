import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DersNotlariAdmin1 extends StatefulWidget {
  const DersNotlariAdmin1({Key? key}) : super(key: key);

  @override
  _DersNotlariAdmin1State createState() => _DersNotlariAdmin1State();
}

class _DersNotlariAdmin1State extends State<DersNotlariAdmin1> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  
  // Renkler
  final Color primaryColor = const Color(0xFF5E35B1);
  final Color accentColor = const Color(0xFFFBC02D);
  final Color lightBlue = Colors.lightBlue.shade100;
  final Color lightGreen = Colors.lightGreen.shade100;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ders Notları Yönetim Paneli',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showNotPaylasDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchCard(),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('ders_notlari')
                  .orderBy('eklenme_tarihi', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Veri çekme hatası!'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Ders notu bulunamadı.'));
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (_searchQuery.isEmpty) return true;
                  
                  final searchLower = _searchQuery.toLowerCase();
                  final fakulte = (data['fakulte'] ?? '').toString().toLowerCase();
                  final bolum = (data['bolum'] ?? '').toString().toLowerCase();
                  final dersAdi = (data['ders_adi'] ?? '').toString().toLowerCase();
                  final baslik = (data['baslik'] ?? '').toString().toLowerCase();
                  
                  return fakulte.contains(searchLower) ||
                         bolum.contains(searchLower) ||
                         dersAdi.contains(searchLower) ||
                         baslik.contains(searchLower);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('Arama kriterinize uygun not bulunamadı.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return _buildNotKarti(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, color: primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Ara',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Fakülte, Bölüm, Ders Adı veya Başlık Ara...',
                labelStyle: TextStyle(color: primaryColor),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }




  Widget _buildNotKarti(String docId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      elevation: 12,
      shadowColor: primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: () => _showEditNoteDialog(docId, data),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: primaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data['bolum'] ?? 'Bölüm Yok',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: data['donem'] == 'Güz' 
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (data['donem'] == 'Güz' ? Colors.green : Colors.blue).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        data['donem'] ?? 'Dönem Yok',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor.withOpacity(0.1), accentColor.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    data['ders_adi'] ?? 'Ders Adı Yok',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.school, color: primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Fakülte: ${data['fakulte'] ?? 'Belirtilmemiş'}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (data['sinav_turu'] != null && data['sinav_turu'].toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.assessment, color: Colors.orange.shade700, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sınav Türü: ${data['sinav_turu']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (data['aciklama'] != null && data['aciklama'].isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, color: primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Açıklama:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 32.0, top: 4),
                        child: Text(
                          data['aciklama'],
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                if (data['pdf_url'] != null && data['pdf_url'].isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF Görüntüle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 4,
                      ),
                      onPressed: () {
                        /* PDF Görüntüleme fonksiyonu eklenebilir */
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditNoteDialog(docId, data),
                        tooltip: 'Düzenle',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteNote(docId),
                        tooltip: 'Sil',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteNote(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notu Sil', style: TextStyle(color: Colors.red)),
          content: const Text(
              'Bu ders notunu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestore
                      .collection('ders_notlari')
                      .doc(docId)
                      .delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Not başarıyla silindi.'),
                        backgroundColor: Colors.green),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Hata oluştu: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  void _showEditNoteDialog(String docId, Map<String, dynamic> data) {
    _showFormDialog(
      context: context,
      title: 'Ders Notunu Düzenle',
      initialData: data,
      onSave: (newData) async {
        await _firestore.collection('ders_notlari').doc(docId).update(newData);
      },
    );
  }

  void _showNotPaylasDialog(BuildContext context) {
    _showFormDialog(
      context: context,
      title: 'Yeni Not Paylaş',
      onSave: (newData) async {
        await _firestore.collection('ders_notlari').add(newData);
      },
    );
  }

  // Ortak Form Dialogu
  void _showFormDialog({
    required BuildContext context,
    required String title,
    required Future<void> Function(Map<String, dynamic>) onSave,
    Map<String, dynamic>? initialData,
  }) {
    final formKey = GlobalKey<FormState>();
    final fakulteController =
        TextEditingController(text: initialData?['fakulte'] ?? '');
    final bolumController =
        TextEditingController(text: initialData?['bolum'] ?? '');
    final dersController =
        TextEditingController(text: initialData?['ders_adi'] ?? '');
    final aciklamaController =
        TextEditingController(text: initialData?['aciklama'] ?? '');
    final pdfUrlController =
        TextEditingController(text: initialData?['pdf_url'] ?? '');
    final sinavTuruController =
        TextEditingController(text: initialData?['sinav_turu'] ?? '');
    String? selectedDonem = initialData?['donem'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              titlePadding: EdgeInsets.zero,
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: fakulteController,
                        label: 'Fakülte Adı',
                        icon: Icons.school,
                        validator: (value) => value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: bolumController,
                        label: 'Bölüm Adı',
                        icon: Icons.business,
                        validator: (value) => value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: dersController,
                        label: 'Ders Adı',
                        icon: Icons.book,
                        validator: (value) => value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedDonem,
                        decoration: InputDecoration(
                          labelText: 'Dönem Seçin',
                          prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Güz', child: Text('Güz')),
                          DropdownMenuItem(value: 'Bahar', child: Text('Bahar')),
                        ],
                        onChanged: (value) {
                          setState(() => selectedDonem = value);
                        },
                        validator: (value) => value == null ? 'Lütfen bir dönem seçin' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: sinavTuruController,
                        label: 'Sınav Türü (Vize, Final vb.)',
                        icon: Icons.assessment,
                        required: false,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: aciklamaController,
                        label: 'Açıklama (isteğe bağlı)',
                        icon: Icons.description,
                        maxLines: 3,
                        required: false,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: pdfUrlController,
                        label: 'PDF URL',
                        icon: Icons.link,
                        validator: (value) => value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('İptal', style: TextStyle(fontSize: 16)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                        child: const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final newData = {
                              'fakulte': fakulteController.text,
                              'bolum': bolumController.text,
                              'ders_adi': dersController.text,
                              'aciklama': aciklamaController.text,
                              'donem': selectedDonem,
                              'sinav_turu': sinavTuruController.text,
                              'pdf_url': pdfUrlController.text,
                              'eklenme_tarihi': Timestamp.now(),
                            };

                            try {
                              await onSave(newData);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('İşlem başarıyla tamamlandı.'),
                                    backgroundColor: Colors.green),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Hata oluştu: $e'),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: required ? validator : null,
    );
  }
}
