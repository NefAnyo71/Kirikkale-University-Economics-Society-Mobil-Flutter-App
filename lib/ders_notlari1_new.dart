import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DersNotlari1 extends StatefulWidget { 
  const DersNotlari1({Key? key}) : super(key: key);

  @override
  _DersNotlari1State createState() => _DersNotlari1State();
}

class _DersNotlari1State extends State<DersNotlari1> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  List<String> userFavorites = [];
  String userId = 'guest';

  // Kullanıcı bilgileri
  String _userName = '';
  String _userSurname = '';
  String _userEmail = '';

  bool _isDisclaimerAccepted = false;

  final Color primaryColor = const Color(0xFF5E35B1);
  final Color secondaryColor = const Color(0xFFEDE7F6);
  final Color accentColor = const Color(0xFFFBC02D);

  @override
  void initState() {
    super.initState();
    _checkLegalDisclaimerStatus();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Kullanıcı bilgilerini yükle
  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? '';
      _userSurname = prefs.getString('surname') ?? '';
      _userEmail = prefs.getString('email') ?? '';
    });
    
    // Firebase Auth kullanıcı ID'sini al
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      await _loadUserFavorites();
    }
  }

  // Kullanıcının favori notlarını yükle
  Future<void> _loadUserFavorites() async {
    try {
      final doc = await _firestore.collection('user_favorites').doc(userId).get();
      if (doc.exists) {
        setState(() {
          userFavorites = List<String>.from(doc.data()?['favorites'] ?? []);
        });
      }
    } catch (e) {
      print('Favori notlar yüklenirken hata: $e');
    }
  }

  // Favori durumunu değiştir
  Future<void> _toggleFavorite(String docId) async {
    try {
      if (userFavorites.contains(docId)) {
        userFavorites.remove(docId);
      } else {
        userFavorites.add(docId);
      }

      await _firestore.collection('user_favorites').doc(userId).set({
        'favorites': userFavorites,
        'updated_at': Timestamp.now(),
      });

      setState(() {});
    } catch (e) {
      print('Favori durumu değiştirilirken hata: $e');
    }
  }

  void _signInAnonymously() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        userId = userCredential.user!.uid;
      });
      print("Anonim olarak oturum açıldı: $userId");
      _getFavorites();
    } catch (e) {
      print("Anonim oturum açma hatası: $e");
    }
  }

  void _getFavorites() async {
    try {
      final favoritesSnapshot = await _firestore.collection('users').doc(userId).collection('favorites').get();
      setState(() {
        userFavorites = favoritesSnapshot.docs.map((doc) => doc.id).toList();
      });
      print("Favoriler güncellendi: $userFavorites");
    } catch (e) {
      print("Favori bilgisi alınırken hata oluştu: $e");
    }
  }

  Future<void> _updateReaction(String docId, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String reactionKey = 'reaction_$docId';
      final String? currentReaction = prefs.getString(reactionKey);
      
      final docRef = _firestore.collection('ders_notlari').doc(docId);
      final isLike = type == 'likes';
      
      // If the user is clicking the same reaction again, remove it
      if ((isLike && currentReaction == 'like') || (!isLike && currentReaction == 'dislike')) {
        await docRef.update({
          type: FieldValue.increment(-1),
        });
        await prefs.remove(reactionKey);
      } 
      // If clicking the opposite reaction
      else if ((isLike && currentReaction == 'dislike') || (!isLike && currentReaction == 'like')) {
        await docRef.update({
          type: FieldValue.increment(1),
          (isLike ? 'dislikes' : 'likes'): FieldValue.increment(-1),
        });
        await prefs.setString(reactionKey, isLike ? 'like' : 'dislike');
      }
      // If no previous reaction
      else {
        await docRef.update({
          type: FieldValue.increment(1),
        });
        await prefs.setString(reactionKey, isLike ? 'like' : 'dislike');
      }
      
      // Refresh the UI
      setState(() {});
    } catch (error) {
      print("Beğeni/Beğenmeme işlemi sırasında hata oluştu: $error");
    }
  }

  void _incrementDownloadCount(String docId) async {
    final docRef = _firestore.collection('ders_notlari').doc(docId);
    try {
      await docRef.update({
        'downloads': FieldValue.increment(1),
      });
    } catch (e) {
      print("İndirme sayacı güncellenirken hata oluştu: $e");
    }
  }

  void _checkLegalDisclaimerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasAccepted = prefs.getBool('legal_disclaimer_accepted') ?? false;

    if (!hasAccepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final accepted = await _showLegalDisclaimerDialog();
        if (accepted == true) {
          setState(() {
            _isDisclaimerAccepted = true;
          });
          _signInAnonymously();
        }
      });
    } else {
      setState(() {
        _isDisclaimerAccepted = true;
      });
      _signInAnonymously();
    }
  }

  Future<bool?> _showLegalDisclaimerDialog() {
    bool hasScrolledToEnd = false;
    final ScrollController scrollController = ScrollController();
    Timer? timer;

    return showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        int countdown = 15;
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            if (timer == null || !timer!.isActive) {
              timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
                if (countdown > 0) {
                  setStateInDialog(() {
                    countdown--;
                  });
                } else {
                  t.cancel();
                }
              });
            }

            if (scrollController.hasClients) {
              scrollController.addListener(() {
                if (scrollController.offset >= scrollController.position.maxScrollExtent && !hasScrolledToEnd) {
                  setStateInDialog(() {
                    hasScrolledToEnd = true;
                  });
                }
              });
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.only(top: 16, bottom: 0, left: 24, right: 24),
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'Yasal Uyarı',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bu Ders Notu Paylaşım Sistemi, sadece Kırıkkale Üniversitesi öğrencilerine yönelik bir bilgi paylaşım platformudur. Notları kullanırken ve paylaşırken aşağıdaki kurallara dikkat etmeniz gerekmektedir:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    _buildDisclaimerSection(
                      icon: Icons.gavel,
                      title: 'Telif Hakkı Uyarısı',
                      description: 'Özellikle akademisyenler tarafından yüklenen ders notları ve materyaller, telif hakkı kapsamında olabilir. Bu tür notları, kişisel kullanımınız dışında (örneğin başka bir platformda izinsiz yayımlamak veya ticari amaçla kullanmak gibi) paylaşırken dikkatli olmanız gerekmektedir. Bu platformdaki notların telif hakları ile ilgili sorumluluklar, notu yükleyen kullanıcıya aittir.',
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerSection(
                      icon: Icons.policy,
                      title: 'Usulsüzlük ve Yasal Süreç',
                      description: 'Bu platformda paylaşılan ders notları sürekli olarak denetlenmektedir. Herhangi bir usulsüz kullanım, intihal, sınav sorularının paylaşımı veya yasalara aykırı başka bir davranış tespit edildiğinde, sistem yöneticileri olarak yasal süreç başlatma ve ilgili kullanıcıyı sistemden kalıcı olarak engelleme hakkımızı saklı tutarız.',
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerSection(
                      icon: Icons.info_outline,
                      title: 'Gizlilik ve Güvenlik',
                      description: 'Bu platform, kişisel verilerinizi korumak için gerekli önlemleri almaktadır. Not paylaşımı sırasında paylaştığınız tüm veriler gizlilik politikamız kapsamında değerlendirilmektedir. Ancak, kullanıcı tarafından paylaşılan bilgilerin doğruluğu ve içeriği tamamen kullanıcının kendi sorumluluğundadır.',
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerSection(
                      icon: Icons.check_circle_outline,
                      title: 'Kabul Beyanı',
                      description: '"Onaylıyorum" diyerek bu sisteme giriş yaptığınızda, yukarıdaki tüm kullanım koşullarını ve yasal uyarıları okuduğunuzu, anladığınızı ve kabul ettiğinizi beyan etmiş olursunuz.',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Bu koşulları kabul etmemeniz halinde, platformu kullanmaya devam etmemeniz gerekmektedir.',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Onaya kalan süre: $countdown sn',
                      style: TextStyle(
                        color: countdown > 0 ? Colors.red : primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        child: const Text('Onaylıyorum'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 5,
                        ),
                        onPressed: (hasScrolledToEnd && countdown == 0) ? () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('legal_disclaimer_accepted', true);
                          timer?.cancel();
                          Navigator.of(context).pop(true);
                        } : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Reddediyorum'),
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

  Widget _buildDisclaimerSection({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
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

  void _showNotPaylasDialog(BuildContext context) {
    if (!_isDisclaimerAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce kullanım koşullarını kabul ediniz.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final formKey = GlobalKey<FormState>();
    final fakulteController = TextEditingController();
    final bolumController = TextEditingController();
    final dersController = TextEditingController();
    final aciklamaController = TextEditingController();
    final pdfUrlController = TextEditingController();
    final sinavTuruController = TextEditingController();
    String? selectedDonem;

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                child: const Text(
                  'Yeni Not Paylaş',
                  style: TextStyle(
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
                        label: 'Drive/Dropbox URL',
                        icon: Icons.cloud,
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
                        child: const Text('Paylaş', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            try {
                              await _firestore.collection('ders_notlari').add({
                                'fakulte': fakulteController.text,
                                'bolum': bolumController.text,
                                'ders_adi': dersController.text,
                                'aciklama': aciklamaController.text,
                                'donem': selectedDonem,
                                'sinav_turu': sinavTuruController.text,
                                'pdf_url': pdfUrlController.text,
                                'eklenme_tarihi': Timestamp.now(),
                                'likes': 0,
                                'dislikes': 0,
                                'downloads': 0,
                                'likedBy': [],
                                'dislikedBy': [],
                                'paylasan_kullanici_adi': _userName,
                                'paylasan_kullanici_soyadi': _userSurname,
                                'paylasan_kullanici_email': _userEmail,
                              });
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

  Widget _buildNoteCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    final isFavorite = userFavorites.contains(doc.id);
    final likedBy = List<String>.from(data['likedBy'] ?? []);
    final dislikedBy = List<String>.from(data['dislikedBy'] ?? []);
    final isLikedByUser = likedBy.contains(userId);
    final isDislikedByUser = dislikedBy.contains(userId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      elevation: 12,
      shadowColor: primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
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
              // Paylaşan kullanıcı bilgisi
              if (data['paylasan_kullanici_adi'] != null && data['paylasan_kullanici_soyadi'] != null)
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Paylaşan: ${data['paylasan_kullanici_adi']} ${data['paylasan_kullanici_soyadi']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryColor,
                    ),
                  ),
                ),

              // Ders adı
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

              // Fakülte bilgisi
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
              const SizedBox(height: 8),

              Text('Bölüm: ${data['bolum']}', style: const TextStyle(color: Colors.black87)),
              Text('Dönem: ${data['donem']}', style: const TextStyle(color: Colors.black87)),
              Text('Açıklama: ${data['aciklama']}', style: const TextStyle(color: Colors.black87)),
              if (data['sinav_turu'] != null && data['sinav_turu'].toString().isNotEmpty)
                Text('Sınav Türü: ${data['sinav_turu']}', style: const TextStyle(color: Colors.black87)),
              Text('Yüklenme Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(data['eklenme_tarihi'].toDate())}', style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 12),
              
              if (data['pdf_url'] != null && data['pdf_url'].isNotEmpty)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!await launchUrl(Uri.parse(data['pdf_url']))) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dosya açılamadı.')),
                        );
                      } else {
                        _incrementDownloadCount(doc.id);
                      }
                    },
                    icon: const Icon(Icons.file_download, color: Colors.white),
                    label: const Text('İndir', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLikedByUser ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                          color: isLikedByUser ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => _updateReaction(doc.id, 'likes'),
                      ),
                      Text('${data['likes'] ?? 0}', style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isDislikedByUser ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                          color: isDislikedByUser ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => _updateReaction(doc.id, 'dislikes'),
                      ),
                      Text('${data['dislikes'] ?? 0}', style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.download, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('${data['downloads'] ?? 0}', style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(doc.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KKU Ders Notları',
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
      body: _isDisclaimerAccepted
          ? Column(
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
                  final aciklama = (data['aciklama'] ?? '').toString().toLowerCase();
                  
                  return fakulte.contains(searchLower) ||
                         bolum.contains(searchLower) ||
                         dersAdi.contains(searchLower) ||
                         aciklama.contains(searchLower);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('Arama kriterinize uygun not bulunamadı.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    return _buildNoteCard(doc);
                  },
                );
              },
            ),
          ),
        ],
      )
          : Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 80, color: accentColor),
              const SizedBox(height: 24),
              const Text(
                'Lütfen devam etmek için yasal uyarı metnini kabul edin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _showLegalDisclaimerDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Anlaşmayı Oku ve Kabul Et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}