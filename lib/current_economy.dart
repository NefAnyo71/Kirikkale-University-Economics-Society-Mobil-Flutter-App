import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

// Firebase bağlantısı yerine mock (sahte) sınıflar oluşturuyoruz.
class MockDocumentReference {
  final String id;
  MockDocumentReference(this.id);
}

class MockQuerySnapshot {
  final List<MockQueryDocumentSnapshot> docs;
  MockQuerySnapshot(this.docs);

  int get size => docs.length;
}

class MockQueryDocumentSnapshot {
  final Map<String, dynamic> data;
  MockQueryDocumentSnapshot(this.data);

  Map<String, dynamic> getData() => Map<String, dynamic>.from(data);
}

class MockCollectionReference {
  final String path;
  final MockFirebaseFirestore _firestore;
  MockCollectionReference(this.path, this._firestore);

  Future<MockDocumentReference> add(Map<String, dynamic> data) async {
    print('Simülasyon: Firestore\'a "$path" koleksiyonuna veri eklendi: $data');
    final docId = _firestore.addDocument(path, data);
    return MockDocumentReference(docId);
  }

  Future<MockQuerySnapshot> get() async {
    final documents = _firestore.getDocuments(path);
    return MockQuerySnapshot(documents);
  }

  Future<MockQuerySnapshot> where(String field, {isEqualTo}) async {
    final documents = _firestore.queryDocuments(path, field, isEqualTo);
    return MockQuerySnapshot(documents);
  }
}

class MockFirebaseFirestore {
  MockFirebaseFirestore._privateConstructor();
  static final MockFirebaseFirestore _instance = MockFirebaseFirestore._privateConstructor();
  factory MockFirebaseFirestore() {
    return _instance;
  }

  final Map<String, List<Map<String, dynamic>>> _collections = {};
  int _documentCounter = 0;

  MockCollectionReference collection(String path) {
    if (!_collections.containsKey(path)) {
      _collections[path] = [];
    }
    return MockCollectionReference(path, this);
  }

  String addDocument(String collectionPath, Map<String, dynamic> data) {
    if (!_collections.containsKey(collectionPath)) {
      _collections[collectionPath] = [];
    }

    final documentId = 'doc_${_documentCounter++}';
    final documentData = Map<String, dynamic>.from(data);
    documentData['id'] = documentId;
    documentData['createdAt'] = DateTime.now();
    documentData['updatedAt'] = DateTime.now();

    _collections[collectionPath]!.add(documentData);
    return documentId;
  }

  List<MockQueryDocumentSnapshot> getDocuments(String collectionPath) {
    if (!_collections.containsKey(collectionPath)) {
      return [];
    }
    return _collections[collectionPath]!
        .map((doc) => MockQueryDocumentSnapshot(Map<String, dynamic>.from(doc)))
        .toList();
  }

  List<MockQueryDocumentSnapshot> queryDocuments(String collectionPath, String field, dynamic value) {
    if (!_collections.containsKey(collectionPath)) {
      return [];
    }
    return _collections[collectionPath]!
        .where((doc) => doc[field] == value)
        .map((doc) => MockQueryDocumentSnapshot(Map<String, dynamic>.from(doc)))
        .toList();
  }

  Future<int> getReportCount(String newsTitle) async {
    if (!_collections.containsKey('haber_raporlari')) {
      return 0;
    }
    final reports = _collections['haber_raporlari']!
        .where((report) => report['haber_basligi'] == newsTitle)
        .toList();

    return reports.length;
  }

  void printAllReports() {
    if (!_collections.containsKey('haber_raporlari')) {
      print('Henüz hiç rapor yok');
      return;
    }

    print('=== TÜM RAPORLAR (${_collections['haber_raporlari']!.length} adet) ===');
    for (final report in _collections['haber_raporlari']!) {
      print('Başlık: ${report['haber_basligi']}');
      print('Sebep: ${report['rapor_sebebi']}');
      print('Tarih: ${report['rapor_tarihi']}');
      print('Rapor Sayısı: ${_collections['haber_raporlari']!.where((r) => r['haber_basligi'] == report['haber_basligi']).length}');
      print('---');
    }
  }
}

class MockUser {
  final String uid = 'simulated_user_id';
}

class MockFirebaseAuth {
  MockFirebaseAuth._privateConstructor();
  static final MockFirebaseAuth _instance = MockFirebaseAuth._privateConstructor();
  factory MockFirebaseAuth() {
    return _instance;
  }

  final MockUser _currentUser = MockUser();
  MockUser? get currentUser => _currentUser;
  Future<void> signInAnonymously() async {
    print('Simülasyon: Anonim kullanıcı girişi yapıldı.');
  }
}

void main() {
  runApp(const MaterialApp(home: CurrentEconomyPage()));
}

class NewsArticle {
  final String title;
  final String content;
  final String date;
  final String imageUrl;

  NewsArticle({
    required this.title,
    required this.content,
    required this.date,
    required this.imageUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is NewsArticle &&
              runtimeType == other.runtimeType &&
              title == other.title;

  @override
  int get hashCode => title.hashCode;
}

class CurrentEconomyPage extends StatefulWidget {
  const CurrentEconomyPage({super.key});

  @override
  CurrentEconomyPageState createState() => CurrentEconomyPageState();
}

class CurrentEconomyPageState extends State<CurrentEconomyPage> {
  List<NewsArticle> _newsList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isDarkMode = false;
  bool _showDisclaimer = true;

  final String _rssUrl = 'https://www.aa.com.tr/tr/rss/default?cat=ekonomi';
  late final MockFirebaseAuth _auth;
  late final MockFirebaseFirestore _firestore;

  List<int> _reportTimestamps = [];
  final int _reportLimit = 2;
  final int _globalReportLimit = 2;
  final Duration _reportPeriod = const Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _auth = MockFirebaseAuth();
    _firestore = MockFirebaseFirestore();
    _initializeFirebaseAndLoadPreferences();
  }

  Future<void> _initializeFirebaseAndLoadPreferences() async {
    await _auth.signInAnonymously();
    await _loadReportTimestamps();
    await _loadPreferences();
    await _fetchNewsFromRss();
  }

  Future<void> _loadReportTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> timestampsAsString = prefs.getStringList('reportTimestamps') ?? [];
    _reportTimestamps = timestampsAsString.map(int.parse).toList();
    _reportTimestamps.removeWhere((timestamp) =>
    DateTime.now().millisecondsSinceEpoch - timestamp > _reportPeriod.inMilliseconds);
  }

  Future<void> _saveReportTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> timestampsAsString = _reportTimestamps.map((t) => t.toString()).toList();
    await prefs.setStringList('reportTimestamps', timestampsAsString);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _showDisclaimer = prefs.getBool('showDisclaimer') ?? true;
    });

    if (_showDisclaimer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDisclaimerDialog(context);
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _savePreferences();
  }

  void _showDisclaimerDialog(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white70 : Colors.black87;
    final Color subTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    int _secondsRemaining = 6;
    Timer? _timer;
    bool _canProceed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) {
              if (_timer == null) {
                _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                  if (_secondsRemaining > 0) {
                    setState(() {
                      _secondsRemaining--;
                    });
                  } else {
                    _timer?.cancel();
                    setState(() {
                      _canProceed = true;
                    });
                  }
                });
              }

              return AlertDialog(
                backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.all(24),
                title: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blueAccent,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Önemli Bilgilendirme',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bu uygulama, Anadolu Ajansı\'ndan gelen ekonomi haberlerini otomatik olarak filtreleyip sunar. '
                            'Olası bir yanlış veya usulsüz haberden dolayı sorumluluk kabul edilmez. '
                            '**Biz haberlere yorum katmıyoruz, olduğu gibi önünüze sunuyoruz.** Lütfen sadece usulsüz içerikleri raporlayın, biz de kaldıralım.',
                        style: TextStyle(
                          fontSize: 15,
                          color: subTextColor,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '⚠️ Uyarılar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.yellowAccent[700] : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDisclaimerPoint(
                        text: 'Otomatik filtreleme kullanılır, nadiren yanlış haberler olabilir.',
                        textColor: subTextColor,
                      ),
                      _buildDisclaimerPoint(
                        text: 'Siyasi içerikli ekonomik haberler filtrelenmeye çalışılır.',
                        textColor: subTextColor,
                      ),
                      _buildDisclaimerPoint(
                        text: 'Yorum içeren veya yanlı olduğu düşünülen haberler kaldırılır.',
                        textColor: subTextColor,
                      ),
                      _buildDisclaimerPoint(
                        text: 'Haber içeriklerinin doğruluğundan sorumluluk kabul edilmez.',
                        textColor: subTextColor,
                      ),
                      _buildDisclaimerPoint(
                        text: 'Gözden kaçan içerikler için lütfen bizi bilgilendirin.',
                        textColor: subTextColor,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: false,
                            onChanged: _canProceed ? (value) async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('showDisclaimer', false);
                              _timer?.cancel();
                              Navigator.of(context).pop();
                            } : null,
                          ),
                          Expanded(
                            child: Text(
                              'Bir daha gösterme',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$_secondsRemaining s',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: _canProceed ? () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('showDisclaimer', false);
                          _timer?.cancel();
                          if (mounted) {
                            setState(() {
                              _showDisclaimer = false;
                            });
                          }
                          Navigator.of(context).pop();
                        } : null,
                        child: Text(
                          'Anladım',
                          style: TextStyle(
                            color: _canProceed ? Colors.blueAccent : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
        );
      },
    ).then((_) {
      _timer?.cancel();
    });
  }

  Widget _buildDisclaimerPoint({required String text, required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchNewsFromRss() async {
    try {
      final response = await http.get(Uri.parse(_rssUrl));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        List<NewsArticle> fetchedArticles = items.map((item) {
          final title = item.findElements('title').firstOrNull?.text ?? '';
          final content = item.findElements('description').firstOrNull?.text ?? '';
          final date = _formatDate(item.findElements('pubDate').firstOrNull?.text ?? '');

          final mediaContent = item.findAllElements('content', namespace: 'http://search.yahoo.com/mrss/').firstOrNull;
          final imageUrl = mediaContent?.getAttribute('url') ?? '';

          return NewsArticle(
            title: title,
            content: content,
            date: date,
            imageUrl: imageUrl,
          );
        }).toList();

        final filteredArticles = await _filterReportedNews(fetchedArticles);

        setState(() {
          _newsList = filteredArticles;
          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        String errorMsg = 'Haberler yüklenemedi: ${response.statusCode}';
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
    } on SocketException {
      setState(() {
        _isLoading = false;
        _errorMessage = 'İnternet bağlantınızı kontrol edin.';
      });
    } on HttpException {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Haber sunucusuna ulaşılamadı. Lütfen daha sonra tekrar deneyin.';
      });
    } on FormatException {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Haber verisi formatı hatalı.';
      });
    } catch (e) {
      final String errorMsg = 'Haberleri getirirken bilinmeyen bir hata oluştu: $e';
      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
    }
  }

  Future<List<NewsArticle>> _filterReportedNews(List<NewsArticle> articles) async {
    final filteredArticles = <NewsArticle>[];

    for (final article in articles) {
      final reportCount = await _firestore.getReportCount(article.title);

      if (reportCount < _globalReportLimit) {
        filteredArticles.add(article);
        print('✓ Haber gösterilecek: "${article.title}" (${reportCount} rapor)');
      } else {
        print('✗ Haber filtrelendi: "${article.title}" (${reportCount} rapor - limit: $_globalReportLimit)');
      }
    }

    _firestore.printAllReports();

    return filteredArticles;
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDarkMode
        ? ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.grey[900],
      cardColor: Colors.grey[850],
      cardTheme: CardTheme.of(context).copyWith(
        elevation: 5,
        shadowColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
    )
        : ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      cardColor: Colors.white,
      cardTheme: CardTheme.of(context).copyWith(
        elevation: 3,
        shadowColor: Colors.black26,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Güncel Ekonomi Haberleri',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
              )),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleDarkMode,
              tooltip: _isDarkMode ? 'Aydınlık moda geç' : 'Karanlık moda geç',
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingIndicator()
            : _newsList.isEmpty
            ? _buildEmptyState()
            : _buildNewsList(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
          const SizedBox(height: 16),
          Text(
            'Haberler yükleniyor...',
            style: TextStyle(
              color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 80,
              color: _isDarkMode ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Henüz hiç haber yok',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchNewsFromRss,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tekrar Dene', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: _newsList.length,
      itemBuilder: (context, index) {
        final article = _newsList[index];
        return Dismissible(
          key: Key(article.title + article.date),
          direction: DismissDirection.horizontal,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20.0),
            color: Colors.blueAccent,
            child: const Icon(Icons.share, color: Colors.white, size: 30),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            color: Colors.redAccent,
            child: const Icon(Icons.report_problem, color: Colors.white, size: 30),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _shareNews(article);
              return false;
            } else if (direction == DismissDirection.endToStart) {
              _showReportReasons(context, article, index);
              return false;
            }
            return false;
          },
          child: _buildNewsCard(context, article),
        );
      },
    );
  }

  Future<void> _shareNews(NewsArticle article) async {
    try {
      final String shareText =
          '${article.title}\n\n${_cleanContent(article.content)}\n\nBu haberi "KKU Ekonomi" uygulamasından paylaştım.\nhttps://play.google.com/store/apps/details?id=com.arifozdemir.ekos&hl=tr';
      await Share.share(shareText, subject: 'Ekonomi Haberi');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Haber başarıyla paylaşıldı.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Paylaşım hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Haber paylaşılamadı. Lütfen tekrar deneyin.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showReportReasons(BuildContext context, NewsArticle article, int originalIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    'Raporlama Sebebi Seçin',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              const Divider(),
              _buildReportOption(context, 'Yanlış Bilgi', article),
              _buildReportOption(context, 'Siyasi Propoganda', article),
              _buildReportOption(context, 'Reklam veya SPAM', article),
              _buildReportOption(context, 'Diğer', article),
              const Divider(),
              ListTile(
                leading: Icon(Icons.undo, color: isDarkMode ? Colors.blue[300] : Colors.blue),
                title: Text('İptal Et ve Geri Al',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Haber raporlama işlemi iptal edildi.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportOption(BuildContext context, String reason, NewsArticle article) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(Icons.report_problem, color: isDarkMode ? Colors.red[300] : Colors.red),
      title: Text(reason, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
      onTap: () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        _reportTimestamps.removeWhere((timestamp) =>
        now - timestamp > _reportPeriod.inMilliseconds);

        if (_reportTimestamps.length >= _reportLimit) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Çok fazla raporlama yaptınız, keyfi raporlama yapmaktan kaçının.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        _reportTimestamps.add(now);
        await _saveReportTimestamps();

        print('Rapor verisi "haber_raporlari" collection\'ına kaydediliyor...');
        await _firestore.collection('haber_raporlari').add({
          'haber_basligi': article.title,
          'haber_icerigi': article.content,
          'haber_tarihi': article.date,
          'haber_resim_url': article.imageUrl,
          'rapor_sebebi': reason,
          'rapor_tarihi': DateTime.now().toIso8601String(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${article.title}" adlı haber, "$reason" sebebiyle raporlandı.'),
            backgroundColor: Colors.redAccent,
          ),
        );

        print('Haber Raporlandı: Başlık: "${article.title}", Sebep: "$reason"');
        print('Veri "haber_raporlari" collection\'ına kaydedildi');

        await _fetchNewsFromRss();
      },
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsArticle article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailPage(article: article, isDarkMode: _isDarkMode),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    article.imageUrl,
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(Icons.broken_image, color: Colors.grey[400]),
                          ),
                        ),
                  ),
                ),

              const SizedBox(height: 16.0),

              Text(
                article.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  color: _isDarkMode ? Colors.white : Colors.black,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16.0),

              Text(
                _cleanContent(article.content),
                style: TextStyle(
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  height: 1.5,
                  fontSize: 15.0,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16.0),

              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16,
                      color: _isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    article.date,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: _isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _cleanContent(String content) {
    return content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class NewsDetailPage extends StatelessWidget {
  final NewsArticle article;
  final bool isDarkMode;

  const NewsDetailPage({super.key, required this.article, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final theme = isDarkMode ? ThemeData.dark() : ThemeData.light();
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final sourceContainerColor = isDarkMode ? Colors.grey[800] : Colors.grey[50];
    final sourceTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Haber Detayları',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              )),
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 26.0,
                  color: textColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16.0),

              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 18,
                      color: subTextColor),
                  const SizedBox(width: 8),
                  Text(
                    article.date,
                    style: TextStyle(
                        fontSize: 16.0,
                        color: subTextColor,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              if (article.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    article.imageUrl,
                    fit: BoxFit.cover,
                    height: 220,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 24.0),

              Text(
                _cleanContent(article.content),
                style: TextStyle(
                  fontSize: 17.0,
                  color: textColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 32.0),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: sourceContainerColor,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
                child: Text(
                  'Kaynak: Anadolu Ajansı\nBu haber otomatik olarak filtrelenmiştir',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: sourceTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _cleanContent(String content) {
    return content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
